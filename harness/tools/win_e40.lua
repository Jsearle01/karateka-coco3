local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/win_e40.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- $40 = PLAYER event. Does a guard attack ever set it nonzero (= player takes a hit)?
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0x40,1,nil,
      'tracelog "<<<W40 pc=%04X val=%02X B6=%02X B7=%02X>>>",pc,b@0x40,b@0xb6,b@0xb7; go') end)
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
