-- akuma_drawprog.lua — authoritative draw-program capture. Read-tap the sprite
-- bank; the blit reads the src HEADER at [$04$03] first (all ZP set by then),
-- so when a read address == the current src pointer, log src/$05/$06 IN ORDER.
-- Captures ONE frame's actor draw program (parts + positions + draw order).
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/akuma_drawprog.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local started, fr0, n = false, -1, 0
local done = false
_G._t = mem:install_read_tap(0x8900, 0x9FFF, "t", function(off,data)
  if done then return end
  if mem:read_u8(0x3d) ~= 1 then return end
  local src = mem:read_u8(0x04)*256 + mem:read_u8(0x03)
  if off ~= src then return end          -- only the header read (first byte)
  local f = scr:frame_number()
  if not started then
    if mem:read_u8(0x3b) ~= 0x15 then return end  -- throne start frame
    started = true; fr0 = f
    log("# Akuma draw program, ONE frame @ 3B=15 (order = draw order):")
  end
  if f > fr0 then done = true; log("[frame end]"); logf:close(); return end
  n = n + 1
  log(string.format("%2d src=%04X x=%02X(byte=%d) y=%02X(%d)",
      n, src, mem:read_u8(0x05), (mem:read_u8(0x05)*7+20)//4, mem:read_u8(0x06), mem:read_u8(0x06)))
end)
_G._a = emu.add_machine_frame_notifier(function()
  if done or scr:frame_number()>=4000 then if not done then log("[timeout]") end
    pcall(function() logf:close() end); manager.machine:exit() end
end)
