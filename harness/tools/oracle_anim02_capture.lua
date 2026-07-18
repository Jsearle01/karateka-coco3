-- oracle_anim02_capture.lua — capture the APPLE2E oracle's climb anim_02 frame, content-anchored.
-- anim_02 = torso $A45A (col 0C,row 8B) + legs $A4A4 (col 0A,row 8F) per the clean climb-beat trace.
-- We tap the draw-entry trampolines $1903/$1906/$1909/$190C (these DO fire on 6502 — JMP-trampoline,
-- not the routine-body false-0 of idiom §1), read src=$04:$03, col=$05, row=$06. On the anim_02 legs
-- draw ($A4A4 @ col 0x0A row 0x8F — the LAST part, so the pose is complete), wait a few frames for the
-- page flip, then dump BOTH HGR pages ($2000-$3FFF, $4000-$5FFF) + the RDPAGE2 status so the displayed
-- page is known. Read-only against the oracle disk; clean recipe. Env: S_OUTDIR.
local OUT = os.getenv("S_OUTDIR") or
  "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/oracle_anim02"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)

local function rd(a) return mem:read_u8(a) end
local trace = io.open(OUT .. "/oracle_climb_trace.txt", "w")
local hit = nil            -- frame of the anim_02 legs draw
local installed = false

local function tap(entry)
  return function(off, data, mask)
    local src = rd(0x04) * 256 + rd(0x03)
    if src < 0x8900 or src > 0xA5FF then return end   -- climb cel range only
    local col = rd(0x05); local row = rd(0x06)
    trace:write(string.format("f%d ent=%s src=%04X col=%02X row=%02X\n",
      scr:frame_number(), entry, src, col, row))
    if src == 0xA4A4 and col == 0x0A and row == 0x8F and not hit then
      hit = scr:frame_number()
      trace:write(string.format("  >>> ANIM_02 ANCHOR at f%d\n", hit))
    end
  end
end

local function dump_page(base, name)
  local o = io.open(OUT .. "/" .. name, "wb")
  for a = base, base + 0x2000 - 1 do o:write(string.char(rd(a))) end
  o:close()
end

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if not installed and fn >= 2500 then           -- install after boot transients settle (§2)
    for _, e in ipairs({0x1903, 0x1906, 0x1909, 0x190C}) do
      local tg = ({[0x1903] = "A", [0x1906] = "Ay", [0x1909] = "B", [0x190C] = "By"})[e]
      _G["t" .. e] = mem:install_read_tap(e, e, tg, tap(tg))   -- keep referenced (§2 GC gotcha)
    end
    installed = true
  end
  if hit and fn >= hit + 4 then
    local pg2 = rd(0xC01C)          -- RDPAGE2 status: bit7=1 -> page2 ($4000) displayed
    dump_page(0x2000, "oracle_hgr_page1.bin")
    dump_page(0x4000, "oracle_hgr_page2.bin")
    pcall(function() scr:snapshot() end)   -- MAME-rendered artifact-colour frame (video on)
    local log = io.open(OUT .. "/capture_log.txt", "w")
    log:write(string.format("anim_02 anchor f=%d dump f=%d RDPAGE2(C01C)=0x%02X displayed=%s\n",
      hit, fn, pg2, (pg2 >= 0x80) and "page2($4000)" or "page1($2000)"))
    log:close(); trace:close(); manager.machine:exit()
  end
  if fn > 9000 then                 -- safety: never found the climb
    if trace then trace:write("NO ANIM_02 ANCHOR FOUND by f9000\n"); trace:close() end
    manager.machine:exit()
  end
end)
