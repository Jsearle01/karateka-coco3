local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/snd_trig.tr"
_G._f=0; _G._voiced=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==150 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- every sound trigger routes through handler_tail's 'sta $F7' (record ptr lo). Log ptr + gate.
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0xF7,1,nil,
      'tracelog "<<<TRIG f pc=%04X F7=%02X F8=%02X 4F=%02X 86=%02X>>>",pc,b@0xf7,b@0xf8,b@0x4f,b@0x86; go') end)
    -- $0D00 = sound engine = a VOICED sound (gate was open)
    pcall(function() cpu.debug:bpset(0x0D00,nil,'tracelog "<<<VOICE F7=%02X F8=%02X>>>",b@0xf7,b@0xf8; go') end)
  end
  if _G._f>8200 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
