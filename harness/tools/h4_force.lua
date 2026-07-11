local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local TR="C:/Projects/karateka_dissasembly_claude/build/logs/h4_force.tr"
_G._f=0; _G._armed=false
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==7245 and not _G._armed then _G._armed=true
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- watch $B7 (guard count) writes: with a low regen threshold we should now see INCREMENTS
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0xB7,1,nil,'tracelog "<<<B7 pc=%04X val=%02X>>>",pc,b@0xb7; go') end)
    -- read $B8
    pcall(function() cpu.debug:wpset(cpu.spaces["program"],"w",0xB6,1,nil,'tracelog "<<<B6 pc=%04X val=%02X>>>",pc,b@0xb6; go') end)
  end
  -- FORCE a low guard-regen threshold ($B9) every frame so regen fires between hits (HS-5 force)
  if _G._f>=7245 and _G._f<=8145 then mem:write_u8(0xB9,0x04) end
  if _G._f==7600 then local o=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/h4_b8.log","w"); o:write(string.format("B8=%02X B9(forced)=%02X\n",mem:read_u8(0xB8),mem:read_u8(0xB9))); o:close() end
  if _G._f>8145 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
