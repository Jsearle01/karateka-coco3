local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/snd_place.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- hit-SPKR handlers, the $93AB marker draw, the damage decrements — inline order shows the sequence
    for _,a in ipairs({0x0C55,0x0C64,0x0C74,0x0C84}) do
      pcall(function() cpu.debug:bpset(a,nil,string.format('tracelog "<<<HITSPKR %04X 20=%%02X 40=%%02X 41=%%02X>>>",b@0x20,b@0x40,b@0x41',a)..'; go') end)
    end
    pcall(function() cpu.debug:bpset(0x1903,"b@0x04==0x93 && b@0x03==0xab",'tracelog "<<<MARKER93AB 20=%02X>>>",b@0x20; go') end)
    pcall(function() cpu.debug:bpset(0x0BC9,nil,'tracelog "<<<DEC-PLAYER b6=%02X>>>",b@0xb6; go') end)
    pcall(function() cpu.debug:bpset(0x0BDA,nil,'tracelog "<<<DEC-GUARD b7=%02X>>>",b@0xb7; go') end)
  end
  if _G._f>7700 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
