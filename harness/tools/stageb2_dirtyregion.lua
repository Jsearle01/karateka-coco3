-- stageb2_dirtyregion.lua — Stage B2 §2: MEASURE the region that actually changes per scroll step.
-- Not "what band does Stage A choose to redraw" (that is an implementation choice) but "what
-- pixels actually differ" — the true working set that sets the budget.
--
-- Method: at the end of each scroll step (phase 15, after present+flip), snapshot the DISPLAYED
-- framebuffer (200 rows x 80 bytes) and diff it against the previous step's snapshot. Report the
-- changed bounding box (rows, byte-cols) and the changed byte count. Page base follows
-- page_register so we always read what is on screen.
local BIN   = os.getenv("S_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_walk_scrollA_driver.bin"
local OUT   = os.getenv("V_OUT") or "C:/Projects/karateka_coco3/build/logs/stageb2_dirtyregion.txt"
local PHASE   = tonumber(os.getenv("V_PHASE") or "0x049A")
local S52     = tonumber(os.getenv("V_S52")   or "0x049B")
local PAGEREG = tonumber(os.getenv("V_PAGE")  or "0x0050")
local TRIGPH  = tonumber(os.getenv("V_TRIGPH") or "15")   -- last phase of the step machine
-- 192, NOT 200: the GIME mode is 320x192x4 (gfx.s:165-170, $FF99=$15). The buffer holds 200
-- rows' worth of bytes but rows 192-199 are NEVER DISPLAYED. Diffing them counted 634 bytes/step
-- of off-screen garbage (pages A and B differ there in 634/640 bytes — they are simply never
-- painted or synced), which inflated the first measurement of the working set by ~4x.
local ROWS, STRIDE = 192, 80
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f   = io.open(OUT, "w")
f:write("# per-step framebuffer diff: the REAL changing region (rows x byte-cols)\n")

local prev, armed, base_f, steps = nil, false, nil, 0
local function grab()
  local pr = mem:read_u8(PAGEREG)
  local base = (pr == 0x40) and 0x8000 or 0xC000      -- PAGE_A_TOKEN=$40 -> $8000 else $C000
  local t = {}
  for r = 0, ROWS-1 do
    local row, o = {}, base + r*STRIDE
    for c = 0, STRIDE-1 do row[c] = mem:read_u8(o+c) end
    t[r] = row
  end
  return t, base
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

local last_phase = -1
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
  if not armed or fn - base_f < 60 then return end
  local ph = mem:read_u8(PHASE)
  if ph == TRIGPH and last_phase ~= TRIGPH then         -- once per step, after the flip
    local cur, base = grab()
    if prev then
      local r0, r1, c0, c1, n = 999, -1, 999, -1, 0
      for r = 0, ROWS-1 do
        for c = 0, STRIDE-1 do
          if cur[r][c] ~= prev[r][c] then
            n = n + 1
            if r < r0 then r0 = r end;  if r > r1 then r1 = r end
            if c < c0 then c0 = c end;  if c > c1 then c1 = c end
          end
        end
      end
      steps = steps + 1
      -- per-COLUMN histogram: tests whether the scroll really lives in x=19..279
      -- (byte-cols 4..69) or spills into the border columns.
      local colhist = {}
      for c = 0, STRIDE-1 do
        local k = 0
        for r = 0, ROWS-1 do if cur[r][c] ~= prev[r][c] then k = k + 1 end end
        colhist[c] = k
      end
      local parts = {}
      for c = 0, STRIDE-1 do if colhist[c] > 0 then parts[#parts+1] = string.format("%d:%d", c, colhist[c]) end end
      f:write("  cols  " .. table.concat(parts, " ") .. "\n")
      -- per-ROW histogram: identifies any FULL-WIDTH band (a row changing across all 80 cols is
      -- not scroll content clipped to the play area — it is something else, and worth naming).
      local rparts = {}
      for r = 0, ROWS-1 do
        local k = 0
        for c = 0, STRIDE-1 do if cur[r][c] ~= prev[r][c] then k = k + 1 end end
        if k > 0 then rparts[#rparts+1] = string.format("y%d:%d", r, k) end
      end
      f:write("  rows  " .. table.concat(rparts, " ") .. "\n")
      local inreg, outreg = 0, 0
      for c = 0, STRIDE-1 do
        if c >= 4 and c <= 69 then inreg = inreg + colhist[c] else outreg = outreg + colhist[c] end
      end
      f:write(string.format("  split in x19..279 (cols 4-69) = %d bytes ; OUTSIDE = %d bytes\n", inreg, outreg))
      if n > 0 then
        f:write(string.format("step=%-3d cur52=%02X changed_bytes=%-6d rows=%d..%d (%d) cols=%d..%d (%d bytes = %d px)  bbox=%d B\n",
          steps, mem:read_u8(S52), n, r0, r1, r1-r0+1, c0, c1, c1-c0+1, (c1-c0+1)*4,
          (r1-r0+1)*(c1-c0+1)))
      else
        f:write(string.format("step=%-3d cur52=%02X changed_bytes=0 (identical frame)\n", steps, mem:read_u8(S52)))
      end
      f:flush()
    end
    prev = cur
    if steps >= 8 then f:close(); manager.machine:exit() end
  end
  last_phase = ph
end)
