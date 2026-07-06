-- disk_worstcase.lua — drive BUILD #3b-1-REDUX: the worst-case single-CALL scene
-- load. Loads the WORSTCASE build, lets it read 8 whole tracks (144 sec = 36 KB,
-- covering the 32 KB / 4-block target) in ONE disk_read_range call (one Restore,
-- one continuous session), and MEASURES the emulated load time (manager.machine.time
-- between the read-start and read-done phase markers — HS-5, the mechanism-decision
-- input). Reports host wall-clock for contrast, verifies the byte-for-byte match, and
-- localizes any stall (phase never reaching 2 + PC in the m=1 read loop).
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox_wc.bin"
local LOG = "C:/Projects/karateka_coco3/build/logs/unit/disk_worstcase.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end

local function emutime()
  local t = manager.machine.time
  local ok, v = pcall(function() return t.seconds + t.attoseconds/1e18 end)
  if ok then return v end
  return t:as_double()
end

-- FDC command / DSKREG trace (proves ONE Restore + m=1 across the single call)
_G._dskreg, _G._cmd = {}, {}
pcall(function()
  _G._t1 = mem:install_write_tap(0x0FF40,0x0FF40,"dskreg",function(o,d,m) _G._dskreg[#_G._dskreg+1]=d&0xff end)
  _G._t2 = mem:install_write_tap(0x0FF48,0x0FF48,"fdccmd",function(o,d,m) _G._cmd[#_G._cmd+1]=d&0xff end)
end)

local function load_decb(path)
  local f=io.open(path,"rb"); if not f then log("NO BIN "..path); return nil end
  local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end
local function tally(t)
  local c={} for _,v in ipairs(t) do c[v]=(c[v] or 0)+1 end
  local out={} for k,n in pairs(c) do out[#out+1]=string.format("%02X x%d",k,n) end
  table.sort(out); return table.concat(out,", ")
end

local WC_PHASE, WC_MATCH, WC_STATUS, WC_FAILSEC = 0x2530,0x2531,0x2532,0x2533
local START_FRAME, END_FRAME = 150, 2640     -- load at ~2.5s; hard cap ~44s emulated

local function report(reason)
  local emu_elapsed = (_G._tdone and _G._tstart) and (_G._tdone - _G._tstart) or nil
  local host_elapsed = (_G._hdone and _G._hstart) and (_G._hdone - _G._hstart) or nil
  log("== BUILD #3b-1-REDUX: worst-case single-CALL scene load ("..reason..") ==")
  log(string.format("  8 tracks / 144 sectors / 36 KB (covers 32 KB / 4x8KB blocks), ONE disk_read_range call"))
  log(string.format("  match WC_MATCH[$2531]=$%02X (A5=all 144 sectors byte-for-byte)   dr_status WC_STATUS[$2532]=$%02X",
      rd(WC_MATCH), rd(WC_STATUS)))
  log(string.format("  fail sector WC_FAILSEC[$2533]=%d (only meaningful if mismatch)   phase WC_PHASE[$2530]=$%02X   PC=$%04X",
      rd(WC_FAILSEC), rd(WC_PHASE), cpu.state["PC"].value))
  if emu_elapsed then
    log(string.format("  LOAD TIME (emulated): %.4f s  for 8 tracks (%.1f ms/track avg)  [HS-5: what the game experiences]",
        emu_elapsed, emu_elapsed*1000/8))
  else
    log("  LOAD TIME (emulated): NOT MEASURED — read never reached done phase (see stall below)")
  end
  if host_elapsed then
    log(string.format("  host wall-clock (approx, -nothrottle): %.4f s  [contrast only; emulated time is authoritative]", host_elapsed))
  end
  if rd(WC_PHASE) ~= 2 then
    log(string.format("  ** STALL: single-call read did not complete; PC=$%04X (m=1 read loop if in disk_read.s) — a REAL m=1 failure (F1). **",
        cpu.state["PC"].value))
  end
  -- spot-check the contiguous dest: sector starts across the 8 tracks (n=0,17,18,71,72,143)
  local sc = {}
  for _,n in ipairs({0,17,18,71,72,143}) do sc[#sc+1]=string.format("sec%d:[%02X]exp%02X", n, rd(0x3000+n*256), n%256) end
  log("  dest $3000 sector starts (expect =ordinal): "..table.concat(sc," "))
  log("  FDC cmd writes: "..tally(_G._cmd).."  (90=Read m=1, 10=Seek, 00=Restore, D0=ForceInt)  [expect 00 x1 = ONE Restore]")
  log("  DSKREG writes:  "..tally(_G._dskreg).."  (A9=HALT b7 armed, 29=positioning)")
  logf:close(); manager.machine:exit()
end

_G._c=0; _G._st="wait"; _G._prevphase=0
_G._tstart=nil; _G._tdone=nil; _G._hstart=nil; _G._hdone=nil
_G._n = emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==START_FRAME then
    local ex=load_decb(BIN); if not ex then report("no bin"); return end
    cpu.state["PC"].value=ex; _G._st="run"; return
  end
  if _G._st=="run" then
    local ph = rd(WC_PHASE)
    if ph==1 and _G._prevphase~=1 and not _G._tstart then
      _G._tstart=emutime(); _G._hstart=os.clock()
    end
    _G._prevphase=ph
    if ph==2 and not _G._tdone then
      _G._tdone=emutime(); _G._hdone=os.clock(); report("completed"); return
    end
    if _G._c>=END_FRAME then
      if _G._tstart then _G._hdone=os.clock() end
      report("hard-cap timeout"); return
    end
  end
end)
