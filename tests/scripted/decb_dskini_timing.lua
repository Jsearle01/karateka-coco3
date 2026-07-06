-- decb_dskini_timing.lua — MAME-measure the load time of a disk formatted by DECB's
-- own DSKINI at a chosen SKIP FACTOR, sidestepping MAME's DMK write-back limitation.
-- Sequence in ONE session: boot DECB -> post `DSKINI 0[,skip]` (formats DRIVE 0's
-- in-memory floppy with DECB's real skip-N interleave) -> after the format finishes,
-- hijack the CPU: load the WORSTCASE m=1 read harness and time an 8-track whole-track
-- read of that just-formatted disk. The read TIME reflects DECB's physical sector order
-- (skip 0 = sequential -> fast; skip 4 default = spread -> slow). Content is empty
-- (format fill), so WC_MATCH will mismatch — TIME + no-stall are the escape-hatch proof.
-- Env: DECB_CMD (e.g. "DSKINI 0,0\r" or "DSKINI 0\r"), DECB_LOG.
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox_wc.bin"
local LOG = os.getenv("DECB_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/decb_dskini_timing.log"
local CMD = os.getenv("DECB_CMD") or "DSKINI 0,0\r"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG,"w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
local function emutime() local t=manager.machine.time; local ok,v=pcall(function() return t.seconds+t.attoseconds/1e18 end); return ok and v or 0 end
local kbd = manager.machine.natkeyboard

-- FDC activity watch (idle-detect the DSKINI completion) + reused for the read decomp
_G._fdc_last=0; _G._fdc_n=0
pcall(function() _G._tap=mem:install_write_tap(0x0FF48,0x0FF48,"fdc",function(o,d,m) _G._fdc_last=_G._c or 0; _G._fdc_n=_G._fdc_n+1 end) end)

local function load_decb(path)
  local f=io.open(path,"rb"); if not f then log("NO BIN "..path); return nil end
  local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end

local WC_PHASE,WC_MATCH,WC_STATUS = 0x2530,0x2531,0x2532
_G._c=0; _G._st="boot"; _G._tstart=nil; _G._tdone=nil; _G._loadframe=nil
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="boot" then
    if _G._c>=240 then
      if CMD=="NONE" then
        -- CONTROL: no DSKINI; hijack-read the pristine mounted disk via the SAME path
        log(string.format("[f%d] CONTROL (no DSKINI); hijacking CPU -> WORSTCASE read of pristine drive 0",_G._c))
        local ex=load_decb(BIN); if not ex then log("no bin"); logf:close(); manager.machine:exit(); return end
        cpu.state["PC"].value=ex; _G._st="timing"; _G._loadframe=_G._c; _G._fdc_n0=_G._fdc_n
      else
        log(string.format("[f%d] boot settled; posting %q",_G._c,CMD)); pcall(function() kbd:post(CMD) end); _G._fdc_last=_G._c; _G._st="dskini"
      end
    end
    return
  end
  if _G._st=="dskini" then
    -- wait for DSKINI to start (FDC active) then finish (idle > 400 frames)
    if _G._fdc_n>5 and (_G._c-_G._fdc_last)>400 then
      log(string.format("[f%d] DSKINI done (FDC cmds=%d, idle %d); hijacking CPU -> WORSTCASE read harness",_G._c,_G._fdc_n,_G._c-_G._fdc_last))
      local ex=load_decb(BIN); if not ex then log("no bin"); logf:close(); manager.machine:exit(); return end
      cpu.state["PC"].value=ex; _G._st="timing"; _G._loadframe=_G._c; _G._fdc_n0=_G._fdc_n
    end
    if _G._c>20000 then log(string.format("[f%d] DSKINI never idled (FDC cmds=%d) — infeasible",_G._c,_G._fdc_n)); logf:close(); manager.machine:exit() end
    return
  end
  if _G._st=="timing" then
    local ph=rd(WC_PHASE)
    if ph==1 and not _G._tstart then _G._tstart=emutime() end
    if ph==2 and not _G._tdone then
      _G._tdone=emutime()
      log(string.format("== DECB-DSKINI'd disk read (cmd %q) ==",CMD))
      log(string.format("  LOAD TIME (emulated): %.4f s for 8 tracks (%.1f ms/track)  [DECB's real skip-N order]",_G._tdone-_G._tstart,(_G._tdone-_G._tstart)*1000/8))
      log(string.format("  WC_MATCH[$2531]=$%02X (expect 5A: empty DSKINI'd disk, content mismatch — TIME is the proof)  WC_STATUS=$%02X phase=$%02X",rd(WC_MATCH),rd(WC_STATUS),ph))
      log(string.format("  read FDC cmds=%d ; PC=$%04X",(_G._fdc_n or 0)-(_G._fdc_n0 or 0),cpu.state["PC"].value))
      logf:close(); manager.machine:exit(); return
    end
    if _G._c-_G._loadframe>12000 then
      log(string.format("== read STALLED/incomplete (cmd %q): phase=$%02X PC=$%04X FDC=%d ==",CMD,rd(WC_PHASE),cpu.state["PC"].value,(_G._fdc_n or 0)-(_G._fdc_n0 or 0)))
      logf:close(); manager.machine:exit(); return
    end
    return
  end
end)
