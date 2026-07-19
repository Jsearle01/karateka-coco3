-- guard_pos.lua — precise guard part positions: tap $06 (y, set last), read
-- src $04$03 + $05 (x) + $06 (y); log guard-bank draws (dedupe on src).
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/guard_pos.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local G = {[0x8f]=1,[0x89]=1,[0x8a]=1}
local seen = {}
_G._t = mem:install_write_tap(0x06, 0x06, "t", function(off,data)
  if mem:read_u8(0x3d) ~= 1 then return end
  local hi = mem:read_u8(0x04)
  if not G[hi] then return end
  local src = hi*256 + mem:read_u8(0x03)
  local key = string.format("%04X", src)
  if seen[key] then return end
  seen[key] = true
  log(string.format("f=%-6d 3B=%02X src=%04X x=%02X(px=%d) y=%02X(%d)",
      scr:frame_number(), mem:read_u8(0x3b), src, mem:read_u8(0x05),
      mem:read_u8(0x05)*7+20, data, data))
end)
_G._a = emu.add_machine_frame_notifier(function()
  if scr:frame_number()>=4200 then log("[done]"); logf:close(); manager.machine:exit() end
end)
