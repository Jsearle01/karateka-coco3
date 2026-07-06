-- disk_fullimage.lua — drive BUILD #3b-1: the full-image-SIZED single-session
-- multi-read. Loads the FULLIMAGE build, lets it read 32 data tracks (8 chunks x
-- 4 tracks) in ONE continuous MAME session against fullimage_test.dsk, and MEASURES
-- the emulated load time (manager.machine.time between the read-start and read-done
-- phase markers — HS-5, the KI-disk-01 decision input). Also reports host wall-clock
-- for the emulated-vs-host contrast, and localizes a stall (FI_DONE < 8 + PC in the
-- m=1 read loop = the 3a FDC-state pathology at scale).
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox_fi.bin"
local LOG = "C:/Projects/karateka_coco3/build/logs/unit/disk_fullimage.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end

-- emulated time (seconds, double) from the machine attotime
local function emutime()
  local t = manager.machine.time
  local ok, v = pcall(function() return t.seconds + t.attoseconds/1e18 end)
  if ok then return v end
  return t:as_double()             -- fallback for older bindings
end

-- FDC command / DSKREG trace (proves m=1 $90 is actually used across the long read)
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

local FI_PHASE, FI_DONE, FI_MATCH, FI_FAILCHK, FI_STATUS = 0x2520,0x2521,0x2522,0x2523,0x2524
local START_FRAME, END_FRAME = 150, 1150     -- load at ~2.5s; hard cap ~19s emulated

local function report(reason)
  local emu_elapsed = (_G._tdone and _G._tstart) and (_G._tdone - _G._tstart) or nil
  local host_elapsed = (_G._hdone and _G._hstart) and (_G._hdone - _G._hstart) or nil
  log("== BUILD #3b-1: full-image-sized single-session multi-read ("..reason..") ==")
  log(string.format("  chunks completed FI_DONE[$2521]=%d of %d   match FI_MATCH[$2522]=$%02X (A5=all match)",
      rd(FI_DONE), 8, rd(FI_MATCH)))
  log(string.format("  fail/last-chunk FI_FAILCHK[$2523]=%d   last dr_status FI_STATUS[$2524]=$%02X",
      rd(FI_FAILCHK), rd(FI_STATUS)))
  log(string.format("  phase FI_PHASE[$2520]=$%02X (1=reading,2=done)   PC=$%04X", rd(FI_PHASE), cpu.state["PC"].value))
  if emu_elapsed then
    log(string.format("  LOAD TIME (emulated): %.4f s  for 32 tracks (%.1f ms/track avg)  [HS-5: what the game experiences]",
        emu_elapsed, emu_elapsed*1000/32))
  else
    log("  LOAD TIME (emulated): full read did NOT complete (stall) — extrapolating from the chunk(s) that DID read:")
  end
  -- per-chunk load-time data point (chunk 0 = 4 tracks completed even when a later chunk stalls)
  if _G._tchunk1 and _G._tstart then
    local t1 = _G._tchunk1 - _G._tstart
    log(string.format("  LOAD TIME (emulated, chunk 0 = 4 tracks incl. Restore+seeks+spinup): %.4f s  => %.1f ms/track",
        t1, t1*1000/4))
    log(string.format("  EXTRAPOLATED full 32-track m=1 load time: ~%.2f s emulated  [KI-disk-01 input — IF the stall did not occur]",
        t1*8))
  end
  if host_elapsed then
    log(string.format("  host wall-clock (approx, -nothrottle): %.4f s  [contrast only; emulated time is authoritative]", host_elapsed))
  end
  -- stall localization
  if rd(FI_PHASE) ~= 2 then
    log(string.format("  ** STALL: read did not complete. Stopped after %d/8 chunks; PC=$%04X (m=1 read loop if in disk_read.s). **",
        rd(FI_DONE), cpu.state["PC"].value))
  end
  log("  FDC cmd writes: "..tally(_G._cmd).."  (90=Read m=1, 10=Seek, 00=Restore, D0=ForceInt)")
  log("  DSKREG writes:  "..tally(_G._dskreg).."  (A9=HALT b7 armed, 29=positioning)")
  -- DIAG: dump the FI_BUF buffer's per-sector first bytes vs expected (base=fail-chunk*72)
  local base = (rd(FI_FAILCHK)*72) % 256
  local diag = {}
  for n=0,7 do diag[#diag+1]=string.format("sec%d:[%02X]exp%02X", n, rd(0x3000+n*256), (base+n)%256) end
  log("  DIAG buf$3000 sector starts (fail-chunk base="..base.."): "..table.concat(diag," "))
  local b2={}
  for _,a in ipairs({0x3000,0x3001,0x3002,0x30FF,0x3100,0x3101}) do b2[#b2+1]=string.format("$%04X=%02X",a,rd(a)) end
  log("  DIAG raw: "..table.concat(b2," "))
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
    local ph = rd(FI_PHASE)
    if ph==1 and _G._prevphase~=1 and not _G._tstart then
      _G._tstart=emutime(); _G._hstart=os.clock()          -- read started
    end
    _G._prevphase=ph
    if not _G._tchunk1 and rd(FI_DONE)>=1 then _G._tchunk1=emutime() end   -- chunk 0 (4 tracks) done
    if ph==2 and not _G._tdone then
      _G._tdone=emutime(); _G._hdone=os.clock(); report("completed"); return
    end
    if _G._c>=END_FRAME then
      if _G._tstart then _G._hdone=os.clock() end
      report("hard-cap timeout"); return
    end
  end
end)
