-- verify_cpu_speed.lua — execution-confirm the LIVE CPU clock during the scene-6 scroll.
--
-- Why not just read it: MAME 0.281's Lua device wrapper exposes NO clock accessor at all
-- (cpu.clock / configured_clock / unscaled_clock / clock_scale all nil — probed,
-- build/logs/clk_probe.txt), so the speed must be established BEHAVIOURALLY.
--
-- The instrument: HAL_time_vbl_wait's spin loop IS a cycle counter.
--     hal_vbl_spin:  cmpb <hal_frame_lo   ; 6809 CMPB direct = 4 cycles
--                    beq  hal_vbl_spin    ; BEQ taken        = 3 cycles   => 7 cycles/iteration
-- Every cycle the engine is NOT working, it spins here. So per frame:
--     cycles_per_frame ~= spins*7 + work_cycles      (work ~ 0 in the idle phase)
--     clock            ~= cycles_per_frame * 59.94
-- Counting spins per frame therefore measures the live clock, needing only a 2-instruction
-- cycle count rather than any emulator introspection.
--
-- A/B/A CONTROL (the part that makes it conclusive): mid-run, poke $FFD8 (SAM speed LO) and
-- watch the spin rate; then restore $FFD9 (HI). If the engine was running double-speed the
-- count HALVES and recovers. A self-controlled differential — no datasheet trust required.
-- Also write-taps $FFD8/$FFD9 so every guest speed write is logged with its PC (§1.1/§1.3).
local BIN  = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT  = os.getenv("V_OUT") or "C:/Projects/karateka_coco3/build/logs/verify_cpu_speed.txt"
local SPIN = tonumber(os.getenv("V_SPIN") or "0x23E8")   -- hal_vbl_spin
local PHASE= 0x049A
local cpu  = manager.machine.devices[":maincpu"]
local mem  = cpu.spaces["program"]
local scr  = manager.machine.screens:at(1)
local f    = io.open(OUT, "w")
f:write("# spins/frame (7 cyc each) -> cycles/frame -> clock. A/B/A: fast -> $FFD8 slow -> $FFD9 fast\n")

local spins, armed, st, mon = 0, false, "wait", false
local base_f, phase_name = nil, "boot(DECB)"

-- every guest write to the SAM speed registers, with PC (execution, not a grep)
for _, a in ipairs({0xFFD8, 0xFFD9}) do
  _G["_w"..a] = mem:install_write_tap(a, a, "spd", function(o, d, m)
    f:write(string.format("SPEEDWRITE $%04X val=%02X pc=%04X f=%d  (%s)\n",
      a, d, cpu.state["PC"].value, scr:frame_number(),
      a == 0xFFD9 and "SAM speed HI = fast" or "SAM speed LO = slow")); f:flush()
  end)
end

_G._spin = mem:install_read_tap(SPIN, SPIN, "spin", function() spins = spins + 1 end)

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

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not mon and fn >= 2 then
    for _, port in pairs(manager.machine.ioport.ports) do
      for k, field in pairs(port.fields) do
        if k == "Monitor Type" then field.user_value = 1 end
      end
    end
    mon = true
  end
  if st == "wait" and fn >= 300 and cpu.state["PC"].value >= 0x8000 then
    local ex = load_bin(BIN)
    if ex then cpu.state["PC"].value = ex; st = "run"; armed = true; base_f = fn
      phase_name = "A: as the engine set it" end
  end
  if not armed then spins = 0; return end
  local rel = fn - base_f
  -- A/B/A: let the driver settle, then force slow, then restore fast
  if rel == 120 then mem:write_u8(0xFFD8, 0); phase_name = "B: FORCED SLOW ($FFD8)"
    f:write("# --- poked $FFD8 (SAM speed LO) from Lua ---\n")
  elseif rel == 200 then mem:write_u8(0xFFD9, 0); phase_name = "C: RESTORED FAST ($FFD9)"
    f:write("# --- poked $FFD9 (SAM speed HI) from Lua ---\n")
  end
  if rel > 40 and spins > 0 then
    local cyc = spins * 7
    f:write(string.format("f=%-6d rel=%-4d spins=%-6d cyc/frame~%-7d clock~%.2f MHz  phase=%02X  [%s]\n",
      fn, rel, spins, cyc, cyc * 59.94 / 1e6, mem:read_u8(PHASE), phase_name)); f:flush()
  end
  spins = 0
  if rel >= 260 then f:close(); manager.machine:exit() end
end)
