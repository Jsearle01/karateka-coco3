-- trace_cell_arc.lua (apple2e oracle) — poll the princess cell arc:
-- $3B (scene clock), $39 (pose/sub-state), $84 (door), $3A. Log every change
-- with the frame number so hold durations (HS-1) + the turn trigger (GATE D2)
-- are measurable. Karateka boots straight into the imprisonment cutscene.
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/cell_arc.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local p3b,p39,p84,p3a = -1,-1,-1,-1
local lastf = 0
log("# cell-arc trace: f $3B $39 $84 $3A  (dwell = frames since last change)")
_G._t = emu.add_machine_frame_notifier(function()
  local f = scr:frame_number()
  local v3b,v39,v84,v3a = mem:read_u8(0x3B),mem:read_u8(0x39),mem:read_u8(0x84),mem:read_u8(0x3A)
  if v3b~=p3b or v39~=p39 or v84~=p84 or v3a~=p3a then
    log(string.format("f=%-6d $3B=%02X $39=%02X $84=%02X $3A=%02X   dwell=%d",
        f, v3b, v39, v84, v3a, f-lastf))
    p3b,p39,p84,p3a = v3b,v39,v84,v3a
    lastf = f
  end
  if f>=6000 then log("[done] f="..f); logf:close(); manager.machine:exit() end
end)
