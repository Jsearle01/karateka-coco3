-- climb_pose_capture.lua — capture EACH crawl pose from the LIVE running sequence, in order.
-- The carryover artifact only exists in the running animation (restore-previous -> draw-current);
-- a per-pose clean render CANNOT reproduce it. So we run the gated fallback and dump the DISPLAYED
-- framebuffer memory once per pose, detected live via cl_idx ($0040), first cycle 0..6 only.
--
-- Buffer model (src/hal/coco3-dsk/gfx.s + climb_controller.s): page_register ($0050) holds the BACK
-- buffer; cl_render draws to back, presents, toggles. So the DISPLAYED buffer = opposite of
-- page_register: pr==$20 (PAGE_A) -> displaying $C000 ; pr==$40 (PAGE_B) -> displaying $8000.
-- We dump the DISPLAYED buffer (15360 bytes) so render_square.py gives a true square-pixel frame
-- (idiom 11b: scr:snapshot() stretches; dump memory instead).
--
-- Env: S_BIN=fallback .bin  S_OUTDIR=dir for pose_N.bin + capture_log.txt
local BIN = os.getenv("S_BIN")
local OUT = os.getenv("S_OUTDIR")
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)

local function load(p)
  local f = io.open(p, "rb"); if not f then return end
  local d = f:read("*a"); f:close(); local i = 1; local ex
  while i <= #d do local t = string.byte(d, i)
    if t == 0 then
      local n = string.byte(d, i+1)*256 + string.byte(d, i+2)
      local a = string.byte(d, i+3)*256 + string.byte(d, i+4)
      for j = 0, n-1 do mem:write_u8(a+j, string.byte(d, i+5+j)) end
      i = i + 5 + n
    elseif t == 0xFF then ex = string.byte(d, i+3)*256 + string.byte(d, i+4); break
    else break end
  end
  return ex
end

local function dump_displayed(idx)
  local pr = mem:read_u8(0x0050)
  local base = (pr == 0x20) and 0xC000 or 0x8000   -- displayed = opposite of back(page_register)
  local path = OUT .. "/pose_" .. idx .. ".bin"
  local o = io.open(path, "wb")
  for a = base, base + 15360 - 1 do o:write(string.char(mem:read_u8(a))) end
  o:close()
  local log = io.open(OUT .. "/capture_log.txt", "a")
  log:write(string.format("pose %d: fn=%d cl_idx=%d page_register=0x%02X displayed_base=0x%04X -> %s\n",
    idx, scr:frame_number(), mem:read_u8(0x0040), pr, base, path))
  log:close()
end

local st = "wait"
local captured = {}
local last_idx = -1
local settle = 0
_G._cpc = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if st == "wait" then
    if fn >= 300 and cpu.state["PC"].value >= 0x8000 then
      local ex = load(BIN)
      if ex then cpu.state["PC"].value = ex; st = "watch"; last_idx = -1; settle = 0 end
    end
    return
  end
  -- st == "watch": run the live crawl; dump each pose 2 frames after cl_idx settles on it.
  -- GATE: cl_dwctr ($0041) is 0 until cl_init runs cl_load_dwell (loads dwell 21). The substrate
  -- blitting takes several frames after PC=exec; cl_idx reads 0 even before init. Waiting for
  -- cl_dwctr != 0 guarantees the full substrate is drawn AND cl_init has rendered pose 0 fresh,
  -- so anim_00 is the true clean no-predecessor frame (HS-2), not a half-drawn substrate.
  if mem:read_u8(0x0041) == 0 then return end
  local idx = mem:read_u8(0x0040)
  if idx ~= last_idx then last_idx = idx; settle = 0 else settle = settle + 1 end
  if idx >= 0 and idx <= 6 and not captured[idx] and settle >= 2 then
    dump_displayed(idx)
    captured[idx] = true
    local done = true
    for i = 0, 6 do if not captured[i] then done = false end end
    if done then manager.machine:exit() end
  end
end)
