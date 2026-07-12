local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/rider2_dump.log","w")
_G._f=0
local function d(t) out:write(string.format("%s f%d: B0=%02X B1=%02X B6=%02X B7=%02X B8=%02X B9=%02X\n",
  t,_G._f,mem:read_u8(0xB0),mem:read_u8(0xB1),mem:read_u8(0xB6),mem:read_u8(0xB7),mem:read_u8(0xB8),mem:read_u8(0xB9))); out:flush() end
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==6000 then d("pre-climb") end
  if _G._f==6300 then d("climb") end
  if _G._f==6600 then d("walk") end
  if _G._f==7000 then d("approach") end
  if _G._f==7100 then d("pre-fight") end
  if _G._f==7250 then d("FIGHT-START") end
  if _G._f==7280 then d("fight"); out:close(); manager.machine:exit() end
end)
