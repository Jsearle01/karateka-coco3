-- stageb2_phasecost.lua — Stage B2' §4: per-ITERATION phase cost + a direct overrun detector.
--
-- Why not per-frame: the loop can run MORE THAN ONE iteration inside a single MAME frame (phase 14
-- present is a bare VOFFSET register write, so its iteration is nearly free and `HAL_time_vbl_wait`
-- for the NEXT phase can return immediately if the VBL IRQ already ticked). Per-frame sampling
-- therefore lumps phases together and mis-attributes cost — which is why the earlier per-phase
-- table showed no phase 14 at all and dumped 20,073 cycles onto "idle".
--
-- Per-ITERATION method: the spin counter is reset at HAL_time_vbl_wait ENTRY ($23E0) and read at
-- WORK START ($0268, where mg_phase still holds the phase about to run). So for each iteration:
--     idle_cycles  = spins*7            (time that iteration spent waiting for VBL)
--     work_of_PREV = VBL - idle_cycles  (what the previous phase consumed)
-- and, directly: **spins == 0 means the wait did not wait — the previous phase used the whole
-- frame or overran it.** That is the acceptance signal for "0 overruns", independent of any
-- cycle arithmetic.
local BIN   = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT   = os.getenv("V_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb2_phasecost.txt"
-- addresses are per-driver (the symbol dump moves when code is added) — override via env
local SPIN  = tonumber(os.getenv("V_SPIN")  or "0x23E8")
local WORK0 = tonumber(os.getenv("V_WORK0") or "0x0268")
local VBLW  = tonumber(os.getenv("V_VBLW")  or "0x23E0")
local PHASE = tonumber(os.getenv("V_PHASE") or "0x049A")
local S52   = tonumber(os.getenv("V_S52")   or "0x049B")
local RUNIDX = tonumber(os.getenv("V_RUNIDX") or "0")
local HALTED = tonumber(os.getenv("V_HALTED") or "0")
local VBLC = 29859
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f   = io.open(OUT, "w")
f:write("# per-ITERATION: phase that ran, cycles it consumed, and whether its VBL wait actually waited\n")

local spins, armed, base_f, prev_phase, iters = 0, false, nil, nil, 0
_G._spin = mem:install_read_tap(SPIN, SPIN, "spin", function() spins = spins + 1 end)
_G._vw   = mem:install_read_tap(VBLW, VBLW, "vw", function() spins = 0 end)   -- wait begins
_G._w0   = mem:install_read_tap(WORK0, WORK0, "w0", function()
  if not armed then return end
  local idle = spins * 7
  local work = VBLC - idle
  if prev_phase then
    iters = iters + 1
    f:write(string.format("phase=%02X work=%-7d pct=%5.1f idle_spins=%-6d %s cur52=%02X f=%d\n",
      prev_phase, work, work * 100 / VBLC, spins,
      spins == 0 and "*** NO-WAIT (previous phase consumed the whole frame) ***" or "ok",
      mem:read_u8(S52), scr:frame_number())
      .. (RUNIDX > 0 and string.format("   run_idx=%d halted=%d",
           mem:read_u8(RUNIDX), mem:read_u8(HALTED)) or "") .. "\n"); f:flush()
  end
  prev_phase = mem:read_u8(PHASE)     -- the phase about to run this iteration
  if iters >= (tonumber(os.getenv("V_ITERS") or "400")) then f:close(); manager.machine:exit() end
end)

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
end)
