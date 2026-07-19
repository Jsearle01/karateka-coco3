-- zp_panel_trace.lua — FIND the mid-ground scroll register S (walk-phase), empirically.
-- Jay's eye: the mid-ground (ground/wall/wall-top) scrolls as the player walks forward, while
-- $52 stays $30 (climb/walk value, guard-phase $52 excluded). So S is a register that MOVES while
-- $52 holds $30 — one not yet watched. This dumps a ZP panel ($40-$7F) each frame, logging any byte
-- that CHANGED, so a smoothly-ramping scroll register reveals itself and its active window.
-- Read-only; clean recipe. Env: S_OUTDIR, FSTART (default 2500), FEND (default 9500),
--   LO (default 0x40), HI (default 0x7F).
local OUT = os.getenv("S_OUTDIR") or "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/scroll"
local FST = tonumber(os.getenv("FSTART") or "2500")
local FEN = tonumber(os.getenv("FEND")   or "9500")
local LO  = tonumber(os.getenv("LO") or "0x40")
local HI  = tonumber(os.getenv("HI") or "0x7F")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local log = io.open(OUT.."/zp_panel.txt","w")
local prev = {}

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if fn < FST then return end
  if fn > FEN then log:write(string.format("# end f%d\n", fn)); log:close(); manager.machine:exit(); return end
  local changes = {}
  for a=LO,HI do
    local v = mem:read_u8(a)
    if prev[a]==nil then prev[a]=v
    elseif v~=prev[a] then
      changes[#changes+1] = string.format("$%02X:%02X>%02X", a, prev[a], v)
      prev[a]=v
    end
  end
  if #changes>0 then
    log:write(string.format("f%d  %s\n", fn, table.concat(changes, "  ")))
  end
end)
