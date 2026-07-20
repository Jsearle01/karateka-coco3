-- recon1_scroll_traj.lua — Recon 1 measurement 1 (LOCATE): trajectory of the scroll cluster.
-- Write-taps $52 (scene scroll), $62 (player pos), $72 (guard pos), $51 (column) — write-taps
-- FIRE on 6502 (only READ-taps false-0, apple2e idioms §1/§2). Log each CHANGE with pc+frame,
-- so the scroll's advance-then-halt shows as: value ramps, then the writes stop / value pins.
-- Keep tap returns referenced (_G._*) or they GC and silently stop firing (idioms §2).
-- Output via io.open (print() is NOT captured headless, idioms §6). Windows path = forward slashes.
local OUT = os.getenv("RECON1_OUT") or "C:/Projects/karateka_coco3/build/logs/recon1_traj.txt"
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open(OUT, "w")
f:write("# recon1 scroll-cluster trajectory: pc,frame = value (change-only)\n")
local last = {}
local function watch(addr, name)
  return mem:install_write_tap(addr, addr, name, function(offset, data, mask)
    if last[addr] ~= data then
      last[addr] = data
      f:write(string.format("%s f=%d %02X\n", name, scr:frame_number(), data))
      f:flush()
    end
  end)
end
-- install AFTER boot transients (idioms §2: taps at t=0 no-op). Arm at ~f2000 via a notifier.
_G._armed = false
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not _G._armed and fn >= 2000 then
    _G._t52 = watch(0x52, "S52")
    _G._t62 = watch(0x62, "P62")
    _G._t72 = watch(0x72, "G72")
    _G._t51 = watch(0x51, "C51")
    _G._armed = true
    f:write(string.format("# taps armed at f=%d\n", fn)); f:flush()
  end
end)
