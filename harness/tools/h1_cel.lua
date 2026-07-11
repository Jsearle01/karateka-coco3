local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local dbg=manager.machine.debugger; pcall(function() if dbg then dbg.execution_state="run" end end)
local out=io.open("C:/Projects/karateka_dissasembly_claude/build/logs/h1_cel.csv","w"); out:write("frame,src,x,y,flip,b6,b7\n")
_G._f=0
local function rd(a) return mem:read_u8(a) end
local function tap(o,d,m)
  if _G._f<7250 or _G._f>7320 then return end
  local src=rd(0x04)*256+rd(0x03)
  if src<0x0B00 or src>0x0B20 then return end  -- the $0B12 arrow-cel region only
  out:write(string.format("%d,%04X,%d,%d,%02X,%02X,%02X\n",_G._f,src,rd(0x05)*7+rd(0x10),rd(0x06),rd(0x0F),rd(0xB6),rd(0xB7)))
end
pcall(function() for _,a in ipairs({0x1903,0x1906,0x1909,0x190C}) do _G["_t"..a]=mem:install_read_tap(a,a,"t",tap) end end)
_G._n=emu.add_machine_frame_notifier(function() _G._f=_G._f+1; if _G._f>7320 then out:close(); manager.machine:exit() end end)
