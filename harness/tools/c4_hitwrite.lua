local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger
pcall(function() dbg.execution_state="run" end)
_G._f=0
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/c4_hit.tr"
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7240 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- watch WRITES to $9A (the hit-state byte: $9A==$FE gates the $93AB hit marker)
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0x9A,1,nil,
      'tracelog "<<<W9A pc=%04X val=%02X 20=%02X 22=%02X 50=%02X 33=%02X 2F=%02X>>>",pc,b@0x9a,b@0x20,b@0x22,b@0x50,b@0x33,b@0x2f; go') end)
  end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
