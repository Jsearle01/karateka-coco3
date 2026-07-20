-- stageb2_initcost.lua — Stage B2 §0 gate, part 2: cost of a FULL-SCENE DRAW in VBL units.
--
-- The dispatch's phase-1 mechanic is DRAW-ON-DEMAND: re-blit the whole scene at $52-recomputed
-- columns EVERY frame. The Stage-A driver already performs exactly that work once, in its init
-- (draw the whole gated tableau), so its init decomposes into the per-component cost of one
-- full-scene draw — measured on the running port, not estimated.
--
-- MAME 0.281 exposes no per-instruction cycle counter to Lua (cpu.clock / cpu:total_cycles() are
-- both nil — probed) and machine.time is quantised to the scheduler timeslice, so intra-frame
-- cycle deltas are unusable. frame_number IS exact, so cost is measured in VBLs (1 VBL = the
-- whole budget) via a read-tap on each routine's entry address (6809 read-taps fire on opcode
-- fetch — coco3 idioms §10; the 6502 false-0 hazard is apple-only).
local BIN  = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT  = os.getenv("B2_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb2_initcost.txt"
local cpu  = manager.machine.devices[":maincpu"]
local mem  = cpu.spaces["program"]
local scr  = manager.machine.screens:at(1)
local f    = io.open(OUT, "w")
f:write("# routine entry marks during the Stage-A init = one full-scene draw. VBL = frame delta.\n")

local MARKS = {
  {0x0200, "test_start"},            {0x247E, "fill_sky"},
  {0x245E, "fill_walltop"},          {0x265C, "draw_climb_scenery_back"},
  {0x2D82, "draw_climb_striations"}, {0x2DCC, "draw_climb_ground_right"},
  {0x2E18, "draw_hud_player"},       {0x0354, "snapshot_band"},
  {0x03F7, "draw_cliff_cels"},       {0x2419, "draw_fuji_cels"},
  {0x0365, "copy_a_to_b"},           {0x1ED9, "HAL_gfx_present"},
  {0x0265, "main_loop"},
}
-- ARMED gate: several driver routines live in low RAM ($02xx-$04xx) which DECB/BASIC itself
-- uses (coco3 idioms §5 — DECB's live low RAM overlaps the game's load region), so these taps
-- fire spuriously during boot. Only count hits AFTER the .bin is loaded and PC is set.
local armed = false
local seen, taps = {}, {}
for _, m in ipairs(MARKS) do
  local addr, name = m[1], m[2]
  taps[#taps+1] = mem:install_read_tap(addr, addr, "m"..name, function()
    if not armed or seen[name] then return end       -- FIRST hit after arming: the init pass
    seen[name] = true
    f:write(string.format("%-24s f=%d\n", name, scr:frame_number())); f:flush()
    if name == "main_loop" then f:close(); manager.machine:exit() end
  end)
end
_G._taps = taps                                       -- keep referenced (idioms §2 GC gotcha)

-- per-cel blit cost: count every blit call during the init so cost/cel can be derived
local nblit = 0
_G._tb = mem:install_read_tap(0x1EFB, 0x1EFB, "blit", function() if armed then nblit = nblit + 1 end end)
_G._tbo = mem:install_read_tap(0x1EF1, 0x1EF1, "blito", function() if armed then nblit = nblit + 1 end end)
_G._nb = emu.add_machine_frame_notifier(function()
  if seen["main_loop"] then return end
  if seen["test_start"] then f:write(string.format("#blits_so_far=%d f=%d\n", nblit, scr:frame_number())) end
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
  if not mon and scr:frame_number() >= 2 then
    for _, port in pairs(manager.machine.ioport.ports) do
      for fn, field in pairs(port.fields) do
        if fn == "Monitor Type" then field.user_value = 1 end
      end
    end
    mon = true
  end
  if st == "wait" and scr:frame_number() >= 300 and cpu.state["PC"].value >= 0x8000 then
    local ex = load_bin(BIN)
    if ex then cpu.state["PC"].value = ex; st = "run"; armed = true
      f:write(string.format("# armed at f=%d (bin loaded, PC=%04X)\n", scr:frame_number(), ex)); f:flush()
    end
  end
end)
