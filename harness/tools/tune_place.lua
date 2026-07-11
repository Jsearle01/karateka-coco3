local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/tune_place.log","w")
_G._f=0; _G._lastclimb=0
-- climb cels ($A3C5-$A649): track the LAST climb-cel draw frame (climb-completion) via the draw tap
local function climbtap(o,d,m)
  local src=mem:read_u8(0x04)*256+mem:read_u8(0x03)
  if src>=0xA3C5 and src<=0xA649 then _G._lastclimb=_G._f end
end
pcall(function() for _,a in ipairs({0x1903,0x1906,0x1909,0x190C}) do _G["_t"..a]=mem:install_read_tap(a,a,"c",climbtap) end end)
-- tune fires: write-tap on $F7 (record ptr store) gives the FRAME + which record + $20
_G._tap=mem:install_write_tap(0xF7,0xF7,"t",function(o,d,m)
  out:write(string.format("f%d TUNE F8:F7=%02X%02X 20=%02X\n",_G._f,mem:read_u8(0xF8),d,mem:read_u8(0x20))); out:flush()
end)
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1
  if _G._f==6300 then out:write(string.format("[climb-completion = last climb-cel draw @ f%d]\n",_G._lastclimb)) end
  if _G._f>9443 then out:write(string.format("[final climb-completion f%d]\n",_G._lastclimb)); out:close(); manager.machine:exit() end
end)
