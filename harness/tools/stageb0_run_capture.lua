-- stageb0_run_capture.lua — Stage B0: capture the oracle's RUN animation draw program.
-- Read-tap the blit trampolines $1903/$1906/$1909/$190C (these DO fire on 6502 — idioms §7b;
-- JMP-trampoline entries, not a §1 routine-body false-0). Per draw log: cel src $04:$03,
-- col $05, SUB-BYTE $10 (X = $05*7 + $10 — the sub is load-bearing, never dropped),
-- row $06, blend/flip $0F, and the scene vars $52/$62/$72, tagged by frame.
-- FILTER: only cels in the run bank $9B00-$9EB7 (8 legs $9B00-$9D1E + 8 torsos $9D68-$9E92)
-- unless RUN_ALL=1, so the log is readable over a whole attract cycle.
-- Keep tap + notifier returns referenced (idioms §2). io.open output (§6). Forward slashes.
local OUT   = os.getenv("RUN_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb0_run.txt"
local FLO   = tonumber(os.getenv("RUN_FLO") or "2000")
local FHI   = tonumber(os.getenv("RUN_FHI") or "999999")
local ALL   = (os.getenv("RUN_ALL") == "1")
local LO    = tonumber(os.getenv("RUN_LO") or "0x9B", 16) or 0x9B
local HI    = tonumber(os.getenv("RUN_HI") or "0x9E", 16) or 0x9E
local mem   = manager.machine.devices[":maincpu"].spaces["program"]
local scr   = manager.machine.screens:at(1)
local f     = io.open(OUT, "w")
f:write(string.format("# run-anim draw program f%d..f%d  filter=%s  (ENTRY cel col sub row flip)\n",
  FLO, FHI, ALL and "ALL" or string.format("$%02X..$%02Xxx", LO, HI)))
local function tapdraw(addr, tag)
  return mem:install_read_tap(addr, addr, "draw"..tag, function()
    local fn = scr:frame_number()
    if fn < FLO or fn > FHI then return end
    local hi = mem:read_u8(0x04)
    if not ALL and (hi < LO or hi > HI) then return end
    f:write(string.format("%-2s cel=%02X%02X col=%02X sub=%02X row=%02X flip=%02X  52=%02X 62=%02X 72=%02X  f=%d\n",
      tag, hi, mem:read_u8(0x03), mem:read_u8(0x05), mem:read_u8(0x10), mem:read_u8(0x06),
      mem:read_u8(0x0F), mem:read_u8(0x52), mem:read_u8(0x62), mem:read_u8(0x72), fn))
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
