local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/c4_events.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- WRITES to the event codes $40 (player) / $41 (guard): who sets the hit event? (the cross-actor test)
    for _,a in ipairs({0x40,0x41}) do
      pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",a,1,nil,
        string.format('tracelog "<<<W%02X pc=%%04X val=%%02X 22=%%02X 62=%%02X 72=%%02X B6=%%02X B7=%%02X>>>",pc,b@0x%X,b@0x22,b@0x62,b@0x72,b@0xb6,b@0xb7',a,a)) end)
    end
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
