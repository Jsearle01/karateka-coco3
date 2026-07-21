-- stageb2_stepcost.lua — Stage B2 budget CORRECTION: measure the REAL per-SCROLL-STEP work.
--
-- What the voided gate got wrong: it measured the Stage-A INIT (a one-shot build path that the
-- running loop never executes) and compared it against a 1-VBL FRAME budget. The oracle steps the
-- scroll once per ~11 VBL (B0 run-pose dwell), so the correct denominator is the STEP interval.
--
-- The instrument that was missing: the VBL spin-wait is a cycle counter (coco3 idioms §0a) —
--   work_cycles(frame) = VBL_CYCLES - spins*7
-- so per-frame WORK is directly measurable, and summing over one 16-phase step gives the true
-- per-step cost. Phase-tagged, so each component (strip chunk / Fuji / cliff+seam / present) is
-- itemised separately and the actor costs can be priced against the same scale.
local BIN   = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT   = os.getenv("V_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb2_stepcost.txt"
local SPIN  = 0x23E8        -- hal_vbl_spin (7 cycles/iteration)
local PHASE = 0x049A        -- mg_phase
local S52   = 0x049B        -- cur52
local VBLC  = 29859         -- verified window @1.78 MHz (reports/20260720-225328-verify-cpu-speed.md)
local BLIT, BLITO = 0x1EFB, 0x1EF1
local cpu   = manager.machine.devices[":maincpu"]
local mem   = cpu.spaces["program"]
local scr   = manager.machine.screens:at(1)
local f     = io.open(OUT, "w")
f:write(string.format("# VBL=%d cycles. work = VBL - spins*7. per-frame, phase-tagged.\n", VBLC))

-- ⚠ PHASE ATTRIBUTION: `ml_next` does `inc mg_phase` at the END of each frame's work, so reading
-- mg_phase in the frame notifier (frame end) reports P+1 for work done by phase P — an off-by-one
-- that mis-assigns every cost. Sample the phase at WORK START instead: tap main_loop+3 ($0268),
-- reached right after HAL_time_vbl_wait returns, where mg_phase still holds the phase about to run.
local WORK0 = 0x0268
local cur_phase = -1
local spins, blits, armed, base_f = 0, 0, false, nil
_G._w0 = mem:install_read_tap(WORK0, WORK0, "w0", function()
  if armed then cur_phase = mem:read_u8(PHASE) end
end)
_G._spin = mem:install_read_tap(SPIN, SPIN, "spin", function() spins = spins + 1 end)
_G._b1 = mem:install_read_tap(BLIT,  BLIT,  "b1", function() if armed then blits = blits + 1 end end)
_G._b2 = mem:install_read_tap(BLITO, BLITO, "b2", function() if armed then blits = blits + 1 end end)

local function load_bin(p)
  local fh = io.open(p, "rb"); if not fh then return end
  local d = fh:read("*a"); fh:close(); local i, ex = 1, nil
  while i <= #d do
    local t = string.byte(d, i)
    if t == 0 then
      local nn = string.byte(d,i+1)*256 + string.byte(d,i+2)
      local a  = string.byte(d,i+3)*256 + string.byte(d,i+4)
      for j = 0, nn-1 do mem:write_u8(a+j, string.byte(d, i+5+j)) end
      i = i + 5 + nn
    elseif t == 0xFF then ex = string.byte(d,i+3)*256 + string.byte(d,i+4); break
    else break end
  end
  return ex
end

local st, mon = "wait", false
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not mon and fn >= 2 then
    for _, port in pairs(manager.machine.ioport.ports) do
      for k, fld in pairs(port.fields) do
        if k == "Monitor Type" then fld.user_value = 1 end
      end
    end
    mon = true
  end
  if st == "wait" and fn >= 300 and cpu.state["PC"].value >= 0x8000 then
    local ex = load_bin(BIN)
    if ex then cpu.state["PC"].value = ex; st = "run"; armed = true; base_f = fn end
  end
  if not armed then spins, blits = 0, 0; return end
  local rel = fn - base_f
  if rel > 40 then                                  -- past init; steady-state scrolling only
    local work = VBLC - spins * 7
    f:write(string.format("f=%-6d phase=%02X cur52=%02X spins=%-6d work=%-7d work_pct=%5.1f blits=%d\n",
      fn, cur_phase, mem:read_u8(S52), spins, work, work * 100 / VBLC, blits)); f:flush()
  end
  spins, blits = 0, 0
  if rel >= 300 then f:close(); manager.machine:exit() end
end)
