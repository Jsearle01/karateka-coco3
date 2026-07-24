local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open("C:/Projects/karateka_coco3/build/logs/fight_compo.txt","w")
f:write("# f : $52(scroll) $62(playerpos) $72(guard) $53(state) $59(fightseed) $33=$72-$62(dist)\n")
local last=nil
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if fn < 6000 or fn > 9200 then return end
  local s52=mem:read_u8(0x52); local s62=mem:read_u8(0x62); local s72=mem:read_u8(0x72)
  local s53=mem:read_u8(0x53); local s59=mem:read_u8(0x59)
  local key=string.format("%02X%02X%02X%02X%02X",s52,s62,s72,s53,s59)
  if key~=last then                 -- log only when a tracked byte CHANGES (compact trajectory)
    last=key
    f:write(string.format("f%-5d 52=%02X 62=%02X 72=%02X 53=%02X 59=%02X 33=%02X\n",
      fn,s52,s62,s72,s53,s59,(s72-s62)%256)); f:flush()
  end
  if fn>=9199 then f:close(); manager.machine:exit() end
end)
