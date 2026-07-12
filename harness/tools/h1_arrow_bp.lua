local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/h1_arrow.tr"
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- bp the sprite draw when the cel is the arrow $0B12 (NOT a read-tap): capture X ($05), flip ($0F), counts
    pcall(function() cpu.debug:bpset(0x1903,"b@0x04==0x0b && b@0x03==0x12",
      'tracelog "<<<ARROW x=%02X x10=%02X flip=%02X y=%02X b6=%02X b7=%02X>>>",b@0x05,b@0x10,b@0x0f,b@0x06,b@0xb6,b@0xb7; go') end)
  end
  if _G._f>7400 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
