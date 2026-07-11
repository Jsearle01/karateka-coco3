local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger; pcall(function() dbg.execution_state="run" end)
local A=tonumber(os.getenv("FW_A")); local B=tonumber(os.getenv("FW_B")); local TR=os.getenv("FW_TR")
_G._f=0; _G._armed=false
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==A and not _G._armed then _G._armed=true
    pcall(function() dbg:command("trace "..TR..",0") end)
    pcall(function() cpu.debug:bpset(0x0CB0,nil,'tracelog "<<<STEP 20=%02X>>>",b@0x20; go') end)
  end
  if _G._f>B then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
