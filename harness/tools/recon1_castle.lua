-- recon1_castle.lua — Recon 1 M2 definitive: does draw_castle_af76 ($AF76) EVER run in attract?
-- Read-taps false-0 on routine bodies (idioms §1), so use a DEBUGGER breakpoint. The bp-action
-- sets a RAM sentinel ($1FFE:=1) + continues (go); a frame-notifier reads the sentinel each
-- frame, logs any fire (frame + $52/$62), and resets it. Zero CASTLE lines over a full attract
-- cycle == the archway routine never executes in attract (execution-confirms gameplay-only).
-- -debug launches PAUSED headless -> unpause via execution_state="run" (idioms §4a).
local OUT = os.getenv("RECON1_OUT") or "C:/Projects/karateka_coco3/build/logs/recon1_castle.txt"
local dbg = manager.machine.debugger
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f   = io.open(OUT, "w")
f:write("# castle($AF76) fire detector: CASTLE lines = archway drew in attract\n")
pcall(function() dbg.execution_state = "run" end)
_G._init = false
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not _G._init and fn >= 300 then
    mem:write_u8(0x1FFE, 0)
    cpu.debug:bpset(0xAF76, nil, "pb@0x1FFE=0x01; go")   -- castle draw entry -> sentinel
    _G._init = true
    f:write(string.format("# bp armed at f=%d\n", fn)); f:flush()
  end
  if _G._init and mem:read_u8(0x1FFE) == 0x01 then
    f:write(string.format("CASTLE f=%d 52=%02X 62=%02X\n", fn, mem:read_u8(0x52), mem:read_u8(0x62)))
    f:flush()
    mem:write_u8(0x1FFE, 0)
  end
  if fn == 10200 then f:write("# reached f=10200 (full cycle covered)\n"); f:flush() end
end)
