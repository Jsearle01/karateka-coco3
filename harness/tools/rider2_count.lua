local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/rider2_count.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==100 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- watch $B6 (player count) and $B7 (guard count) writes: find the scene-entry INIT + its source
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0xB6,1,nil,'tracelog "<<<WB6 pc=%04X val=%02X>>>",pc,b@0xb6; go') end)
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0xB7,1,nil,'tracelog "<<<WB7 pc=%04X val=%02X>>>",pc,b@0xb7; go') end)
  end
  if _G._f>7260 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
