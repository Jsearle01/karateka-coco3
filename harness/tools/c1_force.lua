local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger
pcall(function() dbg.execution_state="run" end)
local ADDR=tonumber(os.getenv("C1_ADDR")); local VAL=tonumber(os.getenv("C1_VAL")); local TR=os.getenv("C1_TR")
_G._f=0
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7240 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    pcall(function() cpu.debug:bpset(0xA000,nil,string.format("pb@0x%X=0x%X; go",ADDR,VAL)) end)
    pcall(function() cpu.debug:bpset(0x6540,nil,'tracelog "<<<ACT 29=%02X>>>",a; go') end)
  end
  if _G._f>7600 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
