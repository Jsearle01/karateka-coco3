local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/h1_blink.log","w")
_G._f=0
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f>=7300 and _G._f<=7500 then mem:write_u8(0xB6,0x01) end  -- force player count low (blink territory)
  if _G._f==7305 then
    -- bp the low-health $07 check ($0B3D lda $07) — log $07 + whether the draw fires ($0B5D)
    pcall(function() dbg:command("trace C:/Projects/karateka_dissasembly_claude/build/logs/h1_blink.tr,0") end)
    pcall(function() cpu.debug:bpset(0x0B3D,nil,'tracelog "<<<CHK 07=%02X>>>",b@0x07; go') end)
    pcall(function() cpu.debug:bpset(0x0B5D,nil,'tracelog "<<<DRAW>>>"; go') end)
  end
  if _G._f>7460 then pcall(function() dbg:command("trace off") end); out:close(); manager.machine:exit() end
end)
