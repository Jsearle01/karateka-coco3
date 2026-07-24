local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open("C:/Projects/karateka_coco3/build/logs/fight_poswriter.txt","w")
f:write("# fight-window writers of $62/$72 : frame addr val <- writerPC ($52 $59 $33)\n")
local function pcnow()
  local ok,v = pcall(function() return cpu.state["CURPC"].value end)
  if ok and v then return v end
  return cpu.state["PC"].value
end
local function tap(addr,name)
  return mem:install_write_tap(addr,addr,name,function(off,data)
    local fn=scr:frame_number()
    if fn<6650 or fn>8720 then return end
    f:write(string.format("f%-5d $%02X <-%02X  PC=%04X  52=%02X 59=%02X 33=%02X\n",
      fn,addr,data,pcnow(),mem:read_u8(0x52),mem:read_u8(0x59),(mem:read_u8(0x72)-mem:read_u8(0x62))%256))
    f:flush()
  end)
end
_G._t62=tap(0x62,"w62"); _G._t72=tap(0x72,"w72")
_G._n=emu.add_machine_frame_notifier(function()
  if scr:frame_number()>8725 then f:close(); manager.machine:exit() end
end)
