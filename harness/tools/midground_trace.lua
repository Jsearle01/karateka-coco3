-- midground_trace.lua — does the MID-GROUND (ground/wall/wall-top, banks $A9/$AA/$AB) TRANSLATE
-- during the walk, and driven by which register? Taps the draw entries (std $1903/06/09, mirror
-- $190C, masked wall-top $1BF4 — these fire on 6502, §7b), and for each mid-ground-bank cel logs
-- col=$05 alongside the candidate scroll registers ($5B/$5C ramp at the walk onset f6418; $50/$51
-- = player/combatant-A pos; $52 = the excluded guard scroll). Accumulates per-cel col-range so a
-- translating cel (COL-VARIES) vs a fixed one is obvious, and whether its col tracks $5B or $50.
-- Read-only, clean recipe. Env: S_OUTDIR, FSTART (default 6200), FEND (default 7500).
local OUT = os.getenv("S_OUTDIR") or "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/scroll"
local FST = tonumber(os.getenv("FSTART") or "6200")
local FEN = tonumber(os.getenv("FEND")   or "7500")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function rd(a) return mem:read_u8(a) end
local log = io.open(OUT.."/midground.txt","w")
local installed = false
local cels = {}   -- "HHLL" -> {n, colmin,colmax, corr5B, corr50, samples}

local function acc(hi, lo, col, s5b, s50)
  local k = string.format("%02X%02X", hi, lo)
  local c = cels[k]
  if not c then c={n=0,colmin=col,colmax=col,s={}} ; cels[k]=c end
  c.n=c.n+1
  if col<c.colmin then c.colmin=col end
  if col>c.colmax then c.colmax=col end
  if c.n<=6 then c.s[#c.s+1]=string.format("col%02X:5B%02X:50%02X",col,s5b,s50) end
end

local function on_draw(off,data,mask)
  local lo,hi = rd(0x03), rd(0x04)
  if hi==0xA9 or hi==0xAA or hi==0xAB then
    local col=rd(0x05)
    acc(hi,lo,col,rd(0x5B),rd(0x50))
    log:write(string.format("f%d cel=%02X%02X col=%02X row=%02X | 5B=%02X 5C=%02X 50=%02X 51=%02X 52=%02X 62=%02X\n",
      scr:frame_number(), hi,lo, col, rd(0x06), rd(0x5B),rd(0x5C),rd(0x50),rd(0x51),rd(0x52),rd(0x62)))
  end
end

local PIN = os.getenv("PIN62"); if PIN then PIN = tonumber(PIN) end
_G._n = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if PIN and fn>=2500 and fn<=FEN then mem:write_u8(0x62, PIN) end   -- causal pin (per-frame force)
  if not installed and fn>=FST then
    for _,e in ipairs({0x1903,0x1906,0x1909,0x190C,0x1BF4}) do
      _G["d"..e]=mem:install_read_tap(e,e,"d",on_draw)
    end
    installed=true
    log:write(string.format("# taps installed f%d window=[%d,%d]\n",fn,FST,FEN))
  end
  if fn>FEN and installed then
    log:write("\n# === per mid-ground cel: col range + first samples ===\n")
    local ks={}; for k in pairs(cels) do ks[#ks+1]=k end; table.sort(ks)
    for _,k in ipairs(ks) do
      local c=cels[k]
      log:write(string.format("%s n=%-4d col %02X-%02X  %s  %s\n", k, c.n, c.colmin, c.colmax,
        (c.colmax~=c.colmin) and "TRANSLATES" or "fixed     ", table.concat(c.s,"  ")))
    end
    log:write(string.format("# end f%d\n",fn)); log:close(); manager.machine:exit()
  end
end)
