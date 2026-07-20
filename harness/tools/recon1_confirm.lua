-- recon1_confirm.lua — Recon 1 execution-confirm M1 (scroll halt PC) + M5 (PRGEND arm).
-- DATA write-taps (fire on 6502; only READ-taps false-0). Log the writing instruction's PC via
-- cpu.state["CURPC"] (idioms §4c: readable from plain Lua).
--   $52 : every change -> value + PC + frame  (the last-changing PC = the halt/phase-wrap site)
--   $AF : PRGEND -> when set !=0, log PC + $62/$44/$30 + frame (the loop-back arm; M5)
--   $62 : log when it first reaches >= $2A (the arm bound) + PC + frame
-- Keep tap returns referenced (§2). io.open output (§6). Forward-slash path.
local OUT  = os.getenv("RECON1_OUT") or "C:/Projects/karateka_coco3/build/logs/recon1_confirm.txt"
local cpu  = manager.machine.devices[":maincpu"]
local mem  = cpu.spaces["program"]
local scr  = manager.machine.screens:at(1)
local f    = io.open(OUT, "w")
local function pc() return cpu.state["CURPC"].value end
local last52, armed62 = nil, false
f:write("# recon1 confirm: S52 changes / AF PRGEND arm / 62>=2A first-reach\n")
_G._armed = false
_G._n = emu.add_machine_frame_notifier(function()
  if _G._armed or scr:frame_number() < 2000 then return end
  _G._armed = true
  _G._t52 = mem:install_write_tap(0x52,0x52,"s52", function(o,d,m)
    if last52 ~= d then last52 = d
      f:write(string.format("S52 f=%d val=%02X pc=%04X\n", scr:frame_number(), d, pc())); f:flush() end
  end)
  _G._taf = mem:install_write_tap(0xAF,0xAF,"af", function(o,d,m)
    if d ~= 0 then
      f:write(string.format("PRGEND f=%d af=%02X pc=%04X  62=%02X 44=%02X 30=%02X\n",
        scr:frame_number(), d, pc(), mem:read_u8(0x62), mem:read_u8(0x44), mem:read_u8(0x30))); f:flush() end
  end)
  _G._t62 = mem:install_write_tap(0x62,0x62,"p62", function(o,d,m)
    if not armed62 and d >= 0x2A and d < 0x80 then armed62 = true
      f:write(string.format("P62>=2A f=%d val=%02X pc=%04X\n", scr:frame_number(), d, pc())); f:flush() end
  end)
end)
