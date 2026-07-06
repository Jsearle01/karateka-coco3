-- disk_worstcase_decomp.lua — DECOMPOSE the worst-case single-call load time into
-- its components, NON-INVASIVELY (HS-3): timestamp the FDC command-register ($FF48)
-- and DSKREG ($FF40) writes the primitive already issues, then split the total into
--   spin-up (one-time)  |  Restore  |  per-track Seek  |  per-track m=1 read (rotational
--   + transfer — the ONLY interleave-tunable component)  |  per-track settle.
-- The primitive (disk_read.s) is UNCHANGED — all timing is observed from the Lua side.
-- Runs the EXISTING WORSTCASE build (8 tracks / 144 sec, one Restore) against whatever
-- fixture is mounted (1:1 baseline or a skew variant), so the same harness decomposes
-- every skew in the sweep. Fixture path is passed via the FIX env-style constant below.
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox_wc.bin"
local LOG = os.getenv("DECOMP_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/disk_worstcase_decomp.log"
local SKEW = os.getenv("DECOMP_SKEW") or "1:1"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
local function emutime()
  local t = manager.machine.time
  local ok,v = pcall(function() return t.seconds + t.attoseconds/1e18 end)
  return ok and v or t:as_double()
end

-- TIMESTAMPED taps: record (reg,val,t) for every FDC-cmd / DSKREG write, in order.
_G._ev = {}
pcall(function()
  _G._t1 = mem:install_write_tap(0x0FF40,0x0FF40,"dskreg",function(o,d,m) _G._ev[#_G._ev+1]={reg=0x40,val=d&0xff,t=emutime()} end)
  _G._t2 = mem:install_write_tap(0x0FF48,0x0FF48,"fdccmd",function(o,d,m) _G._ev[#_G._ev+1]={reg=0x48,val=d&0xff,t=emutime()} end)
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

local WC_PHASE, WC_MATCH = 0x2530, 0x2531
local START_FRAME, END_FRAME = 150, 2640

local function decompose()
  local ev=_G._ev
  -- find the FDC command events (reg 0x48): Restore $00, then per track Seek $10 / Read $90 / ForceInt $D0
  local cmds={}   -- {val,t}
  for _,e in ipairs(ev) do if e.reg==0x48 then cmds[#cmds+1]=e end end
  -- Restore ($00) is the first FDC command of disk_read_range
  local iRestore=nil
  for i,c in ipairs(cmds) do if c.val==0x00 then iRestore=i; break end end
  if not iRestore then log("  (no Restore observed — cannot decompose)"); return end
  local t_restore=cmds[iRestore].t
  -- spin-up (dr_spinup): the DSKREG $29 write IMMEDIATELY PRECEDING the Restore is the
  -- disk_read_range entry pos-write; spin-up = t(Restore) - t(that DSKREG). (NOT the first-
  -- ever DSKREG write, which is a boot-time write and would smear in the frame-150 offset.)
  local t_entry=nil
  for _,e in ipairs(ev) do if e.reg==0x40 and e.t<=t_restore then t_entry=e.t end end
  local spinup = (t_entry and t_restore) and (t_restore - t_entry) or 0
  -- walk the per-track cmd triples after Restore
  log(("== DECOMPOSITION (skew %s) — non-invasive Lua timestamps on $FF48/$FF40 (primitive UNCHANGED) =="):format(SKEW))
  log(string.format("  one-time  spin-up = %.4f s   Restore = %.4f s",
      spinup, (#cmds>iRestore) and (cmds[iRestore+1].t - t_restore) or 0))
  log("  per-track:  trk   seek(s)   read=rot+xfer(s)   settle(s)   track_total(s)")
  local i=iRestore+1
  local trk=0
  local sum_seek,sum_read,sum_settle=0,0,0
  local read0=nil
  local reads={}
  while i<=#cmds do
    -- expect Seek $10
    if cmds[i].val~=0x10 then break end
    local tSeek=cmds[i].t
    local tRead = (cmds[i+1] and cmds[i+1].val==0x90) and cmds[i+1].t or nil
    local tFInt = (cmds[i+2] and cmds[i+2].val==0xD0) and cmds[i+2].t or nil
    if not (tRead and tFInt) then break end
    local seek = tRead - tSeek
    local read = tFInt - tRead
    -- settle = up to next Seek (or end-of-data time)
    local tNext = (cmds[i+3] and cmds[i+3].val==0x10) and cmds[i+3].t or nil
    local settle = tNext and (tNext - tFInt) or 0
    reads[#reads+1]=read
    if trk==0 then read0=read end
    sum_seek=sum_seek+seek; sum_read=sum_read+read; sum_settle=sum_settle+settle
    log(string.format("             %2d   %.4f   %.4f           %.4f     %.4f",
        trk, seek, read, settle, seek+read+settle))
    trk=trk+1; i=i+3
  end
  local ntrk=trk
  log(string.format("  TOTALS(%d trk): Sum seek=%.4f  Sum read=%.4f  Sum settle=%.4f",
      ntrk, sum_seek, sum_read, sum_settle))
  -- steady-state (tracks 1..n-1, excludes spin-up-bearing track 0's read if heavier)
  local ss_read = ntrk>1 and (sum_read-reads[1])/(ntrk-1) or sum_read/math.max(ntrk,1)
  log(string.format("  read/track: track0=%.4f  steady-state(trk1..%d) avg=%.4f  (delta=%.4f = spin-up-in-read?)",
      reads[1] or 0, ntrk-1, ss_read, (reads[1] or 0)-ss_read))
  local marg = (sum_seek+sum_read+sum_settle)/math.max(ntrk,1)
  log(string.format("  MARGINAL per-track (seek+read+settle, no spin-up/Restore) = %.4f s", marg))
  local total = spinup + (cmds[iRestore+1] and (cmds[iRestore+1].t - t_restore) or 0) + sum_seek+sum_read+sum_settle
  log(string.format("  READ TOTAL (Restore->last ForceInt+settle) approx = %.4f s", total))
  -- dominance verdict
  local rotfrac = sum_read/(sum_seek+sum_read+sum_settle)
  log(string.format("  ROTATIONAL/TRANSFER fraction of steady work = %.1f%%  (this is the interleave-tunable part)", rotfrac*100))
  log(string.format("  SEEK fraction = %.1f%%   SETTLE fraction = %.1f%%   one-time spin-up+Restore = %.4f s",
      sum_seek/(sum_seek+sum_read+sum_settle)*100, sum_settle/(sum_seek+sum_read+sum_settle)*100,
      spinup + (cmds[iRestore+1] and (cmds[iRestore+1].t - t_restore) or 0)))
end

local function report(reason)
  local emu=(_G._tdone and _G._tstart) and (_G._tdone-_G._tstart) or nil
  log(("== worst-case decomposition run (%s), fixture skew=%s =="):format(reason, SKEW))
  log(string.format("  correctness WC_MATCH[$2531]=$%02X (A5=byte-for-byte OK)   phase=$%02X",
      rd(WC_MATCH), rd(WC_PHASE)))
  if emu then log(string.format("  WHOLE-OP load time (bracket, same as redux): %.4f s for 8 tracks (%.1f ms/track)", emu, emu*1000/8)) end
  decompose()
  logf:close(); manager.machine:exit()
end

_G._c=0; _G._st="wait"; _G._tstart=nil; _G._tdone=nil
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==START_FRAME then
    local ex=load_decb(BIN); if not ex then report("no bin"); return end
    cpu.state["PC"].value=ex; _G._st="run"; return
  end
  if _G._st=="run" then
    local ph=rd(WC_PHASE)
    if ph==1 and not _G._tstart then _G._tstart=emutime() end
    if ph==2 and not _G._tdone then _G._tdone=emutime(); report("completed"); return end
    if _G._c>=END_FRAME then report("hard-cap timeout"); return end
  end
end)
