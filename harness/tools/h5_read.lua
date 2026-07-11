local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/h5.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7250 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- READ-watchpoint on $B6/$B7 (data reads fire on 6502; opcode-fetch bypass is code-only)
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"r",0xB6,1,nil,'tracelog "<<<R B6 pc=%04X>>>",pc; go') end)
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"r",0xB7,1,nil,'tracelog "<<<R B7 pc=%04X>>>",pc; go') end)
  end
  if _G._f>7256 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
