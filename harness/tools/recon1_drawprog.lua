-- recon1_drawprog.lua — Recon 1 measurements 2/3/4: the draw program at the walk-off.
-- Read-tap the blit trampolines $1903/$1906/$1909/$190C (these DO fire on 6502 — idioms §7b,
-- JMP-trampoline entries, not §1 routine-body false-0). Capture per-draw: cel src $04:$03,
-- col $05, row $06, and the scroll $52 + player $62 + guard $72 at the draw, tagged by frame.
-- GATE logging to the end window (fight-end -> walk-off -> loop-back) so the log is readable.
-- Keep tap returns referenced (idioms §2). Output via io.open (§6). Forward-slash path.
local OUT   = os.getenv("RECON1_OUT") or "C:/Projects/karateka_coco3/build/logs/recon1_draw.txt"
local FLO   = tonumber(os.getenv("RECON1_FLO") or "8400")
local FHI   = tonumber(os.getenv("RECON1_FHI") or "9300")
local mem   = manager.machine.devices[":maincpu"].spaces["program"]
local scr   = manager.machine.screens:at(1)
local f     = io.open(OUT, "w")
f:write(string.format("# draw program, window f%d..f%d: ENTRY cel col row  $52 $62 $72  frame\n", FLO, FHI))
local ENT = { [0x1903]="A", [0x1906]="Ay", [0x1909]="B", [0x190C]="By" }
local function tapdraw(addr, tag)
  return mem:install_read_tap(addr, addr, "draw"..tag, function()
    local fn = scr:frame_number()
    if fn < FLO or fn > FHI then return end
    f:write(string.format("%-2s cel=%02X%02X col=%02X row=%02X  52=%02X 62=%02X 72=%02X  f=%d\n",
      tag, mem:read_u8(0x04), mem:read_u8(0x03), mem:read_u8(0x05), mem:read_u8(0x06),
      mem:read_u8(0x52), mem:read_u8(0x62), mem:read_u8(0x72), fn))
    f:flush()
  end)
end
_G._armed = false
_G._n = emu.add_machine_frame_notifier(function()
  if not _G._armed and scr:frame_number() >= 2000 then
    _G._dA  = tapdraw(0x1903, "A")
    _G._dAy = tapdraw(0x1906, "Ay")
    _G._dB  = tapdraw(0x1909, "B")
    _G._dBy = tapdraw(0x190C, "By")
    _G._armed = true
  end
end)
