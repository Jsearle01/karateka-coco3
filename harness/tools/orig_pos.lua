local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/orig_pos.log","w")
_G._f=0
local function dump(tag) out:write(string.format("%s f%d: 62=%02X 72=%02X 22=%02X 33=%02X B6=%02X B7=%02X\n",
  tag,_G._f,mem:read_u8(0x62),mem:read_u8(0x72),mem:read_u8(0x22),mem:read_u8(0x33),mem:read_u8(0xB6),mem:read_u8(0xB7))); out:flush() end
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==6100 then dump("climb") end
  if _G._f==6500 then dump("walkin1") end
  if _G._f==7000 then dump("approach") end
  if _G._f==7200 then dump("pre-fight") end
  if _G._f==7247 then dump("FIGHT-START") end
  if _G._f==7400 then dump("mid-fight"); out:close(); manager.machine:exit() end
end)
