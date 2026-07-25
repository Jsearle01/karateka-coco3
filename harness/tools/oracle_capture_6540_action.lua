local cpu = manager.machine.devices[":maincpu"]
local dbg = manager.machine.debugger
local scr = manager.machine.screens:at(1)
pcall(function() dbg.execution_state = "run" end)   -- unpause (headless -debug hangs otherwise)
local opened, done = false, false
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not opened and fn >= 6700 then
    opened = true
    dbg:command("trace C:/Projects/karateka_coco3/build/logs/fight_6540.tr,0,noloop")
    cpu.debug:bpset(0x6540, nil,
      'tracelog "<<<D A=%02X 33=%02X 59=%02X 2F=%02X 20=%02X 5E=%02X>>>",a,b@0x33,b@0x59,b@0x2f,b@0x20,b@0x5e; go')
  end
  if opened and not done and fn >= 7250 then
    done = true
    dbg:command("trace off")
    manager.machine:exit()
  end
end)
