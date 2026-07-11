local cpu=manager.machine.devices[":maincpu"]
local dbg=manager.machine.debugger
pcall(function() dbg.execution_state="run" end)
local V=tonumber(os.getenv("C2_V72"))
local TR=os.getenv("C2_TR")
_G._f=0
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7240 then
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- force $72 at its read in update_range_flag ($70BE), then log resulting $33 (computed at $70C3)
    pcall(function() cpu.debug:bpset(0x70BE,nil,string.format("pb@0x72=0x%X; go",V)) end)
    pcall(function() cpu.debug:bpset(0x70C3,nil,'tracelog "<<<D33 33-in=%02X 62=%02X 72=%02X>>>",b@0x33,b@0x62,b@0x72; go') end)
    pcall(function() cpu.debug:bpset(0x6540,nil,'tracelog "<<<ACT 29=%02X>>>",a; go') end)
  end
  if _G._f>7700 then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
