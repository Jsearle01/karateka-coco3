local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open("C:/Projects/karateka_coco3/build/logs/fight_actions.txt","w")
f:write("# action stream: frame $29(action) $33(state) $2F $20 $59(LCG) $5E\n")
_G._t=mem:install_write_tap(0x29,0x29,"a",function(off,data)
  local fn=scr:frame_number()
  if fn<6650 or fn>8720 then return end
  f:write(string.format("f%-5d 29=%02X 33=%02X 2F=%02X 20=%02X 59=%02X 5E=%02X\n",
    fn,data,mem:read_u8(0x33),mem:read_u8(0x2F),mem:read_u8(0x20),mem:read_u8(0x59),mem:read_u8(0x5E)))
  f:flush()
end)
_G._n=emu.add_machine_frame_notifier(function() if scr:frame_number()>8725 then f:close(); manager.machine:exit() end end)
