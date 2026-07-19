-- climb_view.lua — LIVE viewing of the oracle apple2e attract, started at the CLIMB, looping.
-- Fast-forward (unthrottled) through the pre-climb intro, then throttle to normal speed so the
-- climb plays at real speed; the attract loops on its own (natural attract loop). Keyboard is
-- disabled at the CLI (-keyboardprovider none) so no stray host key leaks the disk into the
-- ACTUAL game (§10a) — this stays cleanly in the attract.
-- Env: FF (fast-forward-to frame, default 5900 — just before the climb ~f6000).
local FF  = tonumber(os.getenv("FF") or "5900")
local scr = manager.machine.screens:at(1)
local ff_done = false
manager.machine.video.throttled = false          -- start fast (skip the intro quickly)

_G._view = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not ff_done and fn >= FF then
    manager.machine.video.throttled = true        -- drop to real speed at the climb
    ff_done = true
  end
end)
