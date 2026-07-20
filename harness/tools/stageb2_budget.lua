-- stageb2_budget.lua — Stage B2 §0 VBL-BUDGET GATE: measure the port's per-frame WORK in real
-- 6809 cycles against the VBL window, on the running coco3 (execution, not estimation).
--
-- Method: 6809 read-taps DO fire on opcode fetch (coco3 idioms §10 — the apple2e §1 false-0
-- hazard is 6502-only), so tapping a routine's entry address is a reliable execution timestamp.
--   $23E0 HAL_time_vbl_wait entry  -> the frame's work has ENDED (about to sleep to VBL)
--   $0268 main_loop+3              -> vbl_wait returned; the frame's work BEGINS
-- work_cycles = cycles($23E0) - cycles($0268)   per frame, tagged with mg_phase ($049A).
-- Also logs the frame PERIOD (vbl-entry to vbl-entry): if the work overran, the period is 2 VBL.
-- Cycles come from cpu:total_cycles() when available, else machine.time * clock (both logged).
--
-- Boot/load per climb_live.lua: boot to BASIC, poke the DECB .bin, set PC=exec.
-- Env: S_BIN (the .bin), B2_OUT, B2_FRAMES (how many work-samples to collect).
local BIN    = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT    = os.getenv("B2_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb2_budget.txt"
local NEED   = tonumber(os.getenv("B2_FRAMES") or "200")
local VBLW   = tonumber(os.getenv("B2_VBLWAIT") or "0x23E0")   -- HAL_time_vbl_wait
local WORK0  = tonumber(os.getenv("B2_WORK0")  or "0x0268")    -- main_loop+3 (vbl_wait returned)
local PHASE  = tonumber(os.getenv("B2_PHASE")  or "0x049A")    -- mg_phase
local S52    = tonumber(os.getenv("B2_S52")    or "0x049B")    -- cur52
local cpu    = manager.machine.devices[":maincpu"]
local mem    = cpu.spaces["program"]
local scr    = manager.machine.screens:at(1)
local f      = io.open(OUT, "w")

-- MAME 0.281's Lua device wrapper exposes NEITHER cpu.clock NOR cpu:total_cycles() (probed —
-- both nil, see build/logs/b2_probe.txt). So measure emulated SECONDS via machine.time and
-- convert with the known clock: coco3 maincpu = 894886 Hz (mame -listxml coco3), and
-- HAL_gfx_init writes $FFD9 = SAM 1.78 MHz double speed (src/hal/coco3-dsk/gfx.s:198), so the
-- port runs at 2x. VBL window @59.94 Hz = CLOCK/59.94 cycles.
local CLOCK = tonumber(os.getenv("B2_CLOCK") or "1789772")
local function cyc() return manager.machine.time:as_double() * CLOCK end
f:write(string.format("# clock=%d Hz  VBL window=%d cycles (%.2f ms)\n",
        CLOCK, math.floor(CLOCK/59.94), 1000/59.94))

local t_work0, t_vbl_prev, n = nil, nil, 0
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

_G._tw = mem:install_read_tap(WORK0, WORK0, "work0", function()
  t_work0 = cyc()
end)
_G._tv = mem:install_read_tap(VBLW, VBLW, "vblw", function()
  local t = cyc()
  if t_work0 then
    n = n + 1
    local period = t_vbl_prev and (t - t_vbl_prev) or 0
    f:write(string.format("work=%d period=%d work_us=%.1f phase=%02X cur52=%02X f=%d\n",
      math.floor(t - t_work0 + 0.5), math.floor(period + 0.5),
      (t - t_work0) / CLOCK * 1e6, mem:read_u8(PHASE), mem:read_u8(S52), scr:frame_number()))
    f:flush()
    t_work0 = nil
    if n >= NEED then f:close(); manager.machine:exit() end
  end
  t_vbl_prev = t
end)

local st, mon = "wait", false
_G._n = emu.add_machine_frame_notifier(function()
  if not mon and scr:frame_number() >= 2 then                   -- RGB (CLAUDE.md §4 standing mode)
    for _, port in pairs(manager.machine.ioport.ports) do
      for fn, field in pairs(port.fields) do
        if fn == "Monitor Type" then field.user_value = 1 end
      end
    end
    mon = true
  end
  if st == "wait" and scr:frame_number() >= 300 and cpu.state["PC"].value >= 0x8000 then
    local ex = load_bin(BIN)
    if ex then cpu.state["PC"].value = ex; st = "run" end
  end
end)
