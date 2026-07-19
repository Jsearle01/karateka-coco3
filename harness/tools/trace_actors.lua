-- trace_actors.lua (diagnostic) — tap ZP $04 writes; confirm the tap fires +
-- log actor-bank writes regardless of $3D, with $3D/$3B/frame.
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/actors.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local ACTOR = {[0x89]=1,[0x8a]=1,[0x8f]=1,[0x98]=1,[0x99]=1,[0x9a]=1,[0x9f]=1,[0x9b]=1,[0x97]=1}
local total, actorw = 0, 0
local last = {}
log("# diag: $04 write tap (actor banks, any $3D)")
_G._tap = mem:install_write_tap(0x04, 0x04, "actortap", function(offset, data, mask)
  total = total + 1
  if not ACTOR[data] then return end
  actorw = actorw + 1
  local lo = mem:read_u8(0x03)
  local src = data*256 + lo
  local b3b, s3d = mem:read_u8(0x3b), mem:read_u8(0x3d)
  local k = string.format("%02x", data)
  local cur = string.format("%04x:%02x:%d", src, b3b, s3d)
  if last[k] ~= cur then
    log(string.format("f=%-6d 3D=%02X 3B=%02X 39=%02X src=%04X x=%02X y=%02X",
        scr:frame_number(), s3d, b3b, mem:read_u8(0x39), src, mem:read_u8(0x05), mem:read_u8(0x06)))
    last[k] = cur
  end
end)
_G._a = emu.add_machine_frame_notifier(function()
  if scr:frame_number() >= 6000 then
    log(string.format("[done] total $04 writes=%d, actor-bank=%d", total, actorw))
    logf:close(); manager.machine:exit() end
end)
