local cpu=manager.machine.devices[":maincpu"]
local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger
pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/h2_zp.log","w")
_G._f=0
local function dumpzp(tag)
  out:write(tag)
  for a=0,0xFF do out:write(string.format(" %02X:%02X",a,mem:read_u8(a))) end
  out:write("\n"); out:flush()
end
_G._n=emu.add_machine_frame_notifier(function()
  _G._f=_G._f+1
  if _G._f==7250 then dumpzp("START") end
  if _G._f==7700 then dumpzp("MID") end
  if _G._f==8140 then dumpzp("END"); out:close(); manager.machine:exit() end
end)
