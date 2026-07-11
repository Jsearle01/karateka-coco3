local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/snd_vic.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==8140 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    pcall(function() cpu.debug:bpset(0x0D00,nil,'tracelog "<<<TUNE F7=%02X F8=%02X>>>",b@0xf7,b@0xf8; go') end)
    for _,a in ipairs({0x0C55,0x0C64,0x0C74,0x0C84,0x0C92,0x0CA0,0x0CB0}) do
      pcall(function() cpu.debug:bpset(a,nil,string.format('tracelog "<<<SPKR %04X>>>"; go',a)) end)
    end
  end
  if _G._f>9443 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
