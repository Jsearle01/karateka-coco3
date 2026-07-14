-- walltop_masked_inventory.lua  (TRANSIENT — remove after; oracle repo read-only)
-- Full wall-top masked-blit inventory during the clean climb: every $AA-bank masked
-- draw ($1BF4), logging the source ptr $03/$04 (cel base = first data ptr - 2),
-- position $05/$06, and eff write addr. Post-process groups fires into draws.
-- Clean recipe: -video none -keyboardprovider none.
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
    dbg:command("trace C:/Projects/karateka_coco3/build/logs/wt_inv.tr,0")
    traced = true
    cpu.debug:bpset(0x1BF4, "b@0x04==0xAA",
      'tracelog "M src=%02X%02X a05=%02X a06=%02X eff=%04X y=%02X\n",b@0x04,b@0x03,b@0x05,b@0x06,w@0x00+y,y; go')
  end
  if installed and fn > 6300 then
    if traced then dbg:command("trace off"); traced = false end
    manager.machine:exit()
  end
end)
