-- oracle_climb_fight_loop.lua — LOOP the oracle apple2e attract over the CLIMB -> FIGHT segment
-- for visual comparison. Fast-forwards the intro, SAVE-STATEs at the climb-start, plays
-- climb->walk->guard->fight at normal speed, then LOAD-STATEs back to the climb — repeating just
-- that segment (deterministic: identical each loop). Keyboard is disabled at the CLI
-- (-keyboardprovider none) so a windowed run stays in the ATTRACT (no host-key leak, §10a).
-- Env: FF (save/climb-start frame, default 5900), SEG (frames climb->reload, default 3500).
local FF  = tonumber(os.getenv("FF")  or "5900")
local SEG = tonumber(os.getenv("SEG") or "3500")
local NAME = "climbfight"
local scr = manager.machine.screens:at(1)
local m = manager.machine
m.video.throttled = false          -- fast-forward the intro to the climb-start

local state = "ff"; local base = 0
_G._loop = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if state == "ff" then
    if fn >= FF then
      m:save(NAME)                  -- snapshot the climb-start
      m.video.throttled = true      -- normal speed for viewing
      base = fn
      state = "play"
    end
  elseif state == "play" then
    if fn - base >= SEG then
      m:load(NAME)                  -- snap back to the climb-start
      state = "reanchor"
    end
  elseif state == "reanchor" then
    base = fn                       -- re-anchor after the state reload
    state = "play"
  end
end)
