-- akuma_pos.lua — precise Akuma part positions: tap $06 (y set last), read
-- src $04$03 + x $05 + y $06 + $3B. Akuma/robe banks; dedupe on src.
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/akuma_pos.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local B = {[0x98]=1,[0x99]=1,[0x9a]=1,[0x9f]=1,[0x97]=1,[0x9e]=1}
local seen = {}
_G._t = mem:install_write_tap(0x06, 0x06, "t", function(off,data)
  if mem:read_u8(0x3d) ~= 1 then return end
  local hi = mem:read_u8(0x04); if not B[hi] then return end
  local src = hi*256 + mem:read_u8(0x03)
  local key=string.format("%04X",src); if seen[key] then return end
  seen[key]=true
  log(string.format("src=%04X x=%02X(px=%d,byte=%d) y=%02X(%d) 3B=%02X",
      src, mem:read_u8(0x05), mem:read_u8(0x05)*7+20, (mem:read_u8(0x05)*7+20)//4,
      data, data, mem:read_u8(0x3b)))
end)
_G._a = emu.add_machine_frame_notifier(function()
  if scr:frame_number()>=4200 then log("[done]"); logf:close(); manager.machine:exit() end
end)
