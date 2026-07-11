local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger
pcall(function() dbg.execution_state="run" end)
_G._f=0
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/c3_2f.tr"
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7240 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- force $2F=1 at fight_ai entry so the AI takes the $2F!=0 (suppressed/guard) branch (LA013)
    pcall(function() cpu.debug:bpset(0xA000,nil,"pb@0x2f=0x01; go") end)
    -- log the executed branch just after LA013 + the action
    pcall(function() cpu.debug:bpset(0x6540,nil,'tracelog "<<<ACT 29=%02X 2F=%02X>>>",a,b@0x2f; go') end)
  end
  if _G._f>7700 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
