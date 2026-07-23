-- b2prime_live_loop.lua — LIVE operator gate for the Stage-B2' core scroll, LOOPED.
--
-- The driver's halt at $52==$1A is an ACCEPTANCE CRITERION (phase 1 ends, scene freezes), so it
-- must NOT be turned into a loop in the shipped code. Looping is a viewing concern, so the harness
-- does it: watch scroll_halted, hold the frozen end-state briefly so it can be judged, then reset
-- the driver's scroll/animation state to restart the sweep. Same pattern as the oracle save-state
-- loop (apple2e idioms §13) — replay a segment without re-booting.
--
-- Env: S_BIN (.bin), MONITOR (1=RGB default), HOLD (frames to dwell on the frozen end-state),
--      plus the driver's state addresses (they move whenever the driver is rebuilt — take them
--      from `lwasm --symbol-dump`).
local BIN   = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_b2prime_driver.bin"
local MON   = tonumber(os.getenv("MONITOR") or "1")
local HOLD  = tonumber(os.getenv("HOLD") or "90")          -- ~1.5 s on the frozen end-state
local LOOP  = tonumber(os.getenv("LOOP") or "0")           -- 0 = STOP at the frozen halt; 1 = re-sweep
local A = {
  mg_phase      = tonumber(os.getenv("A_PHASE")  or "0x04D6"),
  cur52         = tonumber(os.getenv("A_S52")    or "0x04D7"),
  scroll_shift  = tonumber(os.getenv("A_SHIFT")  or "0x04D8"),
  strip_row     = tonumber(os.getenv("A_SROW")   or "0x04D9"),
  player_dx     = tonumber(os.getenv("A_PDX")    or "0x04DF"),
  player_dctr   = tonumber(os.getenv("A_PDCTR")  or "0x04E0"),
  run_idx       = tonumber(os.getenv("A_RUNIDX") or "0x04E1"),
  scroll_halted = tonumber(os.getenv("A_HALTED") or "0x04E2"),
}
local S52_HI = tonumber(os.getenv("A_S52HI") or "0x30")    -- sweep start (SA_S52_HI)

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)

local function set_monitor(v)
  for _, port in pairs(manager.machine.ioport.ports) do
    for fn, field in pairs(port.fields) do
      if fn == "Monitor Type" then field.user_value = v; return end
    end
  end
end

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

local st, mon, hold_ctr, loops = "wait", false, 0, 0
_G._live = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not mon and fn >= 2 then set_monitor(MON); mon = true end
  if st == "wait" and fn >= 300 and cpu.state["PC"].value >= 0x8000 then
    local ex = load_bin(BIN)
    if ex then cpu.state["PC"].value = ex; st = "run" end
    return
  end
  if st ~= "run" then return end
  if mem:read_u8(A.scroll_halted) == 0 then hold_ctr = 0; return end
  -- halted: the driver freezes here on its own (halt is an acceptance criterion). Default is to
  -- STOP on the frozen end-state; only re-sweep when LOOP=1.
  if LOOP == 0 then return end
  -- dwell on the frozen end-state, then restart the sweep
  hold_ctr = hold_ctr + 1
  if hold_ctr < HOLD then return end
  hold_ctr = 0; loops = loops + 1
  -- restart the sweep: scroll back to the top and re-arm the animation from its first pose
  mem:write_u8(A.cur52,         S52_HI)
  mem:write_u8(A.scroll_shift,  0)
  mem:write_u8(A.strip_row,     0)
  mem:write_u8(A.mg_phase,      0)
  mem:write_u8(A.run_idx,       0)      -- back to s0 so the run plays in again
  mem:write_u8(A.player_dx,     0)
  mem:write_u8(A.player_dctr,   0)
  mem:write_u8(A.scroll_halted, 0)
end)
