-- walk_guard_trace.lua — does the WALK (the $B29D servo driving $62 -> $0F) TRIGGER the guard/fight?
-- Baseline: log $62 (walk position), $59 (fight LCG seed — starts evolving when the fight is live), and
-- the first guard-head draw ($8ECB via the $1903/06/09/0C blit trampolines — these DO fire on 6502, §7b).
-- Intervention (env PIN62): after every $62 write, force $62 back to PIN62 (a value far from $0F) so the
-- servo can never settle at the fighting distance; if the guard/fight then never activates => WALK-TRIGGERED.
-- Write-taps work headless (§2); install late (after boot settles); keep referenced. Env: S_OUTDIR, PIN62.
local OUT = os.getenv("S_OUTDIR") or "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/walkguard"
local PIN = os.getenv("PIN62")            -- nil = baseline; a hex/dec value = pin $62 there (intervention)
if PIN then PIN = tonumber(PIN) end
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]; local scr = manager.machine.screens:at(1)
local function rd(a) return mem:read_u8(a) end
local log = io.open(OUT .. "/trace" .. (PIN and ("_pin" .. string.format("%02X", PIN)) or "_baseline") .. ".txt", "w")
local last62, last59 = -1, -1
local guard_seen, fight_seen = nil, nil
local installed, reent = false, false

local function on_write_62(off, data, mask)
  local v = rd(0x62)                                -- log-only (the per-frame FORCE below does the pinning)
  if v ~= last62 then last62 = v
    log:write(string.format("f%d $62=%02X  $72=%02X $33=%02X $53=%02X\n", scr:frame_number(), v, rd(0x72), rd(0x33), rd(0x53)))
  end
end
local function on_write_59(off, data, mask)
  local v = rd(0x59)
  if v ~= last59 then last59 = v
    if not fight_seen and v ~= 0 then fight_seen = scr:frame_number()
      log:write(string.format("f%d >>> FIGHT SEED $59 first non-zero = %02X (fight/guard AI live)\n", fight_seen, v)) end
  end
end
local function on_blit(entry) return function(off, data, mask)
  local src = rd(0x04)*256 + rd(0x03)
  if src == 0x8ECB and not guard_seen then guard_seen = scr:frame_number()
    log:write(string.format("f%d >>> GUARD HEAD $8ECB first draw (ent=%s) $62=%02X\n", guard_seen, entry, rd(0x62))) end
end end

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if PIN and installed and fn >= 6000 and fn <= 7200 then
    mem:write_u8(0x62, PIN)                                     -- FORCE $62 each frame (pin)
    if fn % 100 == 0 then log:write(string.format("f%d [pinned] $62=%02X $72=%02X $53=%02X\n", fn, rd(0x62), rd(0x72), rd(0x53))) end
  end
  if not installed and fn >= 2500 then
    _G.t62 = mem:install_write_tap(0x62, 0x62, "w62", on_write_62)
    _G.t59 = mem:install_write_tap(0x59, 0x59, "w59", on_write_59)
    for _, e in ipairs({0x1903, 0x1906, 0x1909, 0x190C}) do
      _G["b" .. e] = mem:install_read_tap(e, e, "blit", on_blit(({[0x1903]="A",[0x1906]="Ay",[0x1909]="B",[0x190C]="By"})[e]))
    end
    installed = true
    log:write(string.format("# taps installed f%d  mode=%s\n", fn, PIN and ("PIN $62="..string.format("%02X",PIN)) or "BASELINE"))
  end
  if fn > 7200 then
    log:write(string.format("# end f%d  guard_draw=%s fight_seed=%s\n", fn, tostring(guard_seen), tostring(fight_seen)))
    log:close(); manager.machine:exit()
  end
end)
