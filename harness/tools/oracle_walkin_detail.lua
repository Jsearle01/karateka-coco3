local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open("C:/Projects/karateka_coco3/build/logs/walkin_detail.txt","w")
f:write("# walk-in detail: $50(subbyte) $51(col) $52 $62 $72  + cluster-inc witness\n")
local last=nil
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if fn < 6000 or fn > 6470 then if fn>6470 then f:close(); manager.machine:exit() end return end
  local s50=mem:read_u8(0x50); local s51=mem:read_u8(0x51); local s52=mem:read_u8(0x52)
  local s62=mem:read_u8(0x62); local s72=mem:read_u8(0x72)
  local key=string.format("%02X%02X%02X%02X%02X",s50,s51,s52,s62,s72)
  if key~=last then last=key
    f:write(string.format("f%-5d 50=%02X 51=%02X 52=%02X 62=%02X 72=%02X\n",fn,s50,s51,s52,s62,s72)); f:flush()
  end
end)
