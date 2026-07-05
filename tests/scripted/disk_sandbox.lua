-- disk_sandbox.lua — drive the disk-read sandbox (Build #1 single-sector regression
-- + Build #2 multi-track m=1 range) against the mounted DD fixture; capture
-- match/status/NMI + the FDC command trace (m=1 $90, Seek $10) + DSKREG b7 ($A9).
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox.bin"
local LOG = "C:/Projects/karateka_coco3/build/logs/unit/disk_sandbox.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end

_G._dskreg, _G._cmd = {}, {}
pcall(function()
  _G._t1 = mem:install_write_tap(0x0FF40,0x0FF40,"dskreg",function(o,d,m) _G._dskreg[#_G._dskreg+1]=d&0xff end)
  _G._t2 = mem:install_write_tap(0x0FF48,0x0FF48,"fdccmd",function(o,d,m) _G._cmd[#_G._cmd+1]=d&0xff end)
end)

local function load_decb(path)
  local f=io.open(path,"rb"); if not f then log("NO BIN"); return nil end
  local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end
local function tally(t)
  local c={} for _,v in ipairs(t) do c[v]=(c[v] or 0)+1 end
  local out={} for k,n in pairs(c) do out[#out+1]=string.format("%02X x%d",k,n) end
  table.sort(out); return table.concat(out,", ")
end

_G._c=0; _G._st="wait"
_G._n = emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==150 then
    local ex=load_decb(BIN); cpu.state["PC"].value=ex; _G._st="run"; return
  end
  if _G._st=="run" and _G._c==900 then
    log("== BUILD #1 regression (single sector) ==")
    log(string.format("  single-sector PASS[$2200]=$%02X  nmi[$2202]=$%02X  badsec RNF[$2204]=$%02X cc[$2205]=$%02X",
        rd(0x2200), rd(0x2202), rd(0x2204), rd(0x2205)))
    log("== BUILD #2 multi-track range (tracks 33-34, 36 sectors) ==")
    log(string.format("  RANGE PASS[$2206]=$%02X (A5=match)  status[$2207]=$%02X",
        rd(0x2206), rd(0x2207)))
    log(string.format("  OFF-END catch (correction): off-end track40 CC[$2208]=$%02X (expect $01 = caught, was $00 silent in Build #2)",
        rd(0x2208)))
    -- track-boundary contiguity: first byte of ordinals 16,17,18,19 (=$4000+k*256)
    local bnd={} for _,k in ipairs({16,17,18,19}) do bnd[#bnd+1]=string.format("ord%d=%02X",k,rd(0x4000+k*256)) end
    log("  boundary first-bytes (expect =ordinal; T33/S18=ord17, T34/S1=ord18): "..table.concat(bnd," "))
    log("== mechanism trace ==")
    log("  FDC cmd writes: "..tally(_G._cmd).."  (90=Read m=1, 10=Seek, D0=ForceInt, 00=Restore, 80=Read m=0)")
    log("  DSKREG writes:  "..tally(_G._dskreg).."  (A9=HALT b7 armed, 29=positioning)")
    logf:close(); manager.machine:exit()
  end
end)
