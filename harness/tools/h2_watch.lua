local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger
pcall(function() dbg.execution_state="run" end)
_G._f=0
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/h2_watch.tr"
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    for _,a in ipairs({0xB6,0xB7,0x65,0x66}) do
      pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",a,1,nil,
        string.format('tracelog "<<<W%02X pc=%%04X val=%%02X>>>",pc,b@0x%X; go',a,a)) end)
    end
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
