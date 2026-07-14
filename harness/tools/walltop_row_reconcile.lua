-- walltop_row_reconcile.lua  (TRANSIENT — remove after use; oracle repo is read-only)
-- Settle the runner render ROW (100 vs 104) from WRITE-POINTER evidence.
-- Captures the effective write address (w@$00 + y) of the FIRST bytes of:
--   RUN = wall-top runner masked-blit $1BF4, cel $AA25..$AA30
--   LDG = $AA11 ledge std-blit inner write $19E8  (KNOWN row -> calibrates the decode)
-- Also logs arg $05/$06 so we see nominal-arg vs actual-write-row.
-- Clean recipe assumed: -video none -keyboardprovider none  (no key leak -> real attract climb)

local cpu = manager.machine.devices[":maincpu"]
local dbg = manager.machine.debugger
local scr = manager.machine.screens:at(1)
local installed = false
local traced = false

pcall(function() dbg.execution_state = "run" end)

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if (not installed) and fn >= 5900 then
    installed = true
    dbg:command("trace C:/Projects/karateka_coco3/build/logs/wt_scratch.tr,0")
    traced = true
    -- runner: masked-blit inner write, cel = $AA25..$AA30
    cpu.debug:bpset(0x1BF4,
      "(b@0x04==0xAA)&&(b@0x03>=0x25)&&(b@0x03<=0x30)",
      'tracelog "RUN cel=AA%02X a05=%02X a06=%02X eff=%04X y=%02X f=%d\n",b@0x03,b@0x05,b@0x06,w@0x00+y,y,'..string.format("%d", 0)..'; go')
    -- ledge calibration: std-blit inner write, cel = $AA11 (known row)
    cpu.debug:bpset(0x19E8,
      "(b@0x04==0xAA)&&(b@0x03==0x11)",
      'tracelog "LDG cel=AA11 a05=%02X a06=%02X eff=%04X y=%02X\n",b@0x05,b@0x06,w@0x00+y,y; go')
  end
  if installed and fn > 6300 then
    if traced then dbg:command("trace off"); traced = false end
    manager.machine:exit()
  end
end)
