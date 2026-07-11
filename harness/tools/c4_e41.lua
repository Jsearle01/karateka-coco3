local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/c4_e41.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- ONE watchpoint: writes to $41 (guard pending-event). Who sets it nonzero = the hit collision (cross-actor?)
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0x41,1,nil,
      'tracelog "<<<W41 pc=%04X val=%02X 62=%02X 72=%02X B6=%02X B7=%02X>>>",pc,b@0x41,b@0x62,b@0x72,b@0xb6,b@0xb7; go') end)
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
