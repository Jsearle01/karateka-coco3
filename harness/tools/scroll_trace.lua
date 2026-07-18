-- scroll_trace.lua — is $52 the WALK-DRIVEN scroll driver? (scene-6 fight recon step 2)
-- Mechanism under test (attract_dispatch.s load_scene_sprite_ae3f, a HYPOTHESIS past scene 4):
--   scene sprites are drawn via 4 parallel tables $ADF7-$AE3E (X=0..17):
--     lo[$ADF7] hi[$AE09] xadj[$AE1B] y[$AE2D]; addr = hi:lo, row $06 = y[X]
--   col $05 = ($52 >= $14) ? $52 + xadj[X]  (normal L1903)
--                          : $52 - xadj[X]  (mirror  L190C)
-- So the scene-sprite GROUP is locked to $52 (each at its own xadj offset); a fixed backdrop
-- drawn via a different path (fill $0A09/$0A40) never reads $52 -> col constant.
-- This trace (reusing the walk_guard machinery — write/notifier reads + $1903/06/09/0C trampoline
-- read-taps DO fire on 6502, §7b; install late, keep referenced):
--   (1) baseline: $52,$62,$72 timeline over the walk window -> does $52 move off pin? dead-band?
--   (2) locked-group: per drawn cel, does col track $52 at col=$52±xadj? (>=3 table cels)
--   (3) upper-fixed: non-table cels' col constant across $52 changes?
--   (5) causal: env PIN62 -> PER-FRAME FORCE $62=PIN (a write-tap re-clamp fails, walk-guard §4f);
--       if $52 then freezes => walk-driven; keeps moving => $52 runs independently.
-- Env: S_OUTDIR, PIN62 (nil=baseline), FSTART (default 2500), FEND (default 7200).
local OUT   = os.getenv("S_OUTDIR") or "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/scroll"
local PIN   = os.getenv("PIN62"); if PIN then PIN = tonumber(PIN) end
local FST   = tonumber(os.getenv("FSTART") or "2500")
local FEN   = tonumber(os.getenv("FEND")   or "7200")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function rd(a) return mem:read_u8(a) end

local tag = PIN and ("_pin"..string.format("%02X",PIN)) or "_baseline"
local log = io.open(OUT.."/scroll"..tag..".txt","w")

-- accumulators
local last52, last62, last72 = -1,-1,-1
local cels = {}                 -- key "HHLL" -> {n, colmin,colmax, s52min,s52max, table_x, xadj, mismatch}
local tblmap = {}               -- "HHLL" -> {x, xadj, y}   (built at install from live memory)
local s52seen = {}              -- set of distinct $52 values observed at draws
local installed = false

local function note_draw(hi, lo, col, row, s52)
  local key = string.format("%02X%02X", hi, lo)
  local c = cels[key]
  if not c then
    c = {n=0, colmin=col, colmax=col, s52min=s52, s52max=s52, mism=0}
    local t = tblmap[key]; if t then c.table_x=t.x; c.xadj=t.xadj end
    cels[key]=c
  end
  c.n = c.n+1
  if col<c.colmin then c.colmin=col end;  if col>c.colmax then c.colmax=col end
  if s52<c.s52min then c.s52min=s52 end;  if s52>c.s52max then c.s52max=s52 end
  s52seen[s52]=true
  -- verify col == $52 ± xadj for table cels
  if c.xadj then
    local exp = (s52>=0x14 and s52<0x80) and ((s52 + c.xadj)&0xFF) or ((s52 - c.xadj)&0xFF)
    if exp ~= col then c.mism = c.mism+1 end
  end
end

local function on_draw(off, data, mask)
  local lo, hi = rd(0x03), rd(0x04)
  note_draw(hi, lo, rd(0x05), rd(0x06), rd(0x52))
end

_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()

  if not installed and fn >= FST then
    -- dump the 4 scene-sprite tables from LIVE memory (authority; static-from-load) + build map
    local lo_t, hi_t, xa_t, y_t = {},{},{},{}
    for i=0,17 do
      lo_t[i]=rd(0xADF7+i); hi_t[i]=rd(0xAE09+i); xa_t[i]=rd(0xAE1B+i); y_t[i]=rd(0xAE2D+i)
      tblmap[string.format("%02X%02X",hi_t[i],lo_t[i])] = {x=i, xadj=xa_t[i], y=y_t[i]}
    end
    local function hx(t) local s="" for i=0,17 do s=s..string.format("%02X ",t[i]) end return s end
    log:write("# scene-sprite tables (live mem $ADF7-$AE3E):\n")
    log:write("#  lo   : "..hx(lo_t).."\n#  hi   : "..hx(hi_t).."\n#  xadj : "..hx(xa_t).."\n#  y    : "..hx(y_t).."\n")
    for _,e in ipairs({0x1903,0x1906,0x1909,0x190C}) do
      _G["d"..e] = mem:install_read_tap(e,e,"draw",on_draw)
    end
    installed = true
    log:write(string.format("# taps installed f%d  mode=%s  window=[%d,%d]\n",
              fn, PIN and ("PIN $62="..string.format("%02X",PIN)) or "BASELINE", FST, FEN))
  end

  if fn>=FST and fn<=FEN then
    if PIN then mem:write_u8(0x62, PIN) end                    -- per-frame FORCE (pin the walk)
    local v52,v62,v72,v4c = rd(0x52),rd(0x62),rd(0x72),rd(0x4C)
    if v52~=last52 or v62~=last62 or v72~=last72 then
      log:write(string.format("f%d  $52=%02X  $62=%02X $72=%02X $4C=%02X\n", fn, v52, v62, v72, v4c))
      last52,last62,last72 = v52,v62,v72
    end
  end

  if fn>FEN and installed then
    -- per-cel summary
    log:write("\n# === per-cel summary (HHLL = hi:lo addr) ===\n")
    log:write("# key   n     colrange   $52range   table_x xadj  scrolls?  mism\n")
    local keys={}; for k,_ in pairs(cels) do keys[#keys+1]=k end; table.sort(keys)
    for _,k in ipairs(keys) do
      local c=cels[k]
      local scrolls = (c.colmax~=c.colmin) and "COL-VARIES" or "col-fixed "
      log:write(string.format("%s  %5d  %02X-%02X      %02X-%02X       %s   %s   %s  %d\n",
        k, c.n, c.colmin, c.colmax, c.s52min, c.s52max,
        c.table_x and string.format("X=%2d",c.table_x) or "  -  ",
        c.xadj and string.format("%02X",c.xadj) or "--", scrolls, c.mism))
    end
    local n52=0; for _ in pairs(s52seen) do n52=n52+1 end
    log:write(string.format("# distinct $52 values seen at draws = %d\n", n52))
    log:write(string.format("# end f%d\n", fn))
    log:close(); manager.machine:exit()
  end
end)
