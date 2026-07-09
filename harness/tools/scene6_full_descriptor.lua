-- scene6_full_descriptor.lua — extend the proven $1903 tap (fired 6967x last pass) to capture
-- the FULL per-draw descriptor over f6000-7400, for player compositing. Per draw at the L1903
-- entry: src ptr ($04$03), height/width (sprite header ($03)+0/+1), screen X = $05*7+$10 (parity),
-- screen Y = $06, blend/flip ($0F: bit7=reversed/h-flip, >0=skip, 0=normal), draw-ORDER index
-- within the frame, and the frame number (co-occurrence key). Exclude $A400-$ACFF scroll (fills
-- go through $0A00, not here). Read-only. Emits: (1) per-cel aggregate, (2) per-frame co-occurrence
-- groups (>=2 draws = compositing-relevant), (3) draws-per-frame histogram (sparsity check).
local LOG = os.getenv("FD_LOG") or "C:/Projects/karateka_dissasembly_claude/build/logs/scene6_full_descriptor.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local CSV = os.getenv("FD_CSV") or "C:/Projects/karateka_dissasembly_claude/build/logs/scene6_draws.csv"
local logf = io.open(LOG,"w")
local csvf = io.open(CSV,"w"); csvf:write("frame,ord,ptr,x,y,h,w,flip,par\n")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
local FSTART,FEND = 6000,7400
_G._c=0; _G._hits=0; _G._ord=0
_G._cel={}                 -- ptr -> {n,h,w,even,odd,blend{},xmin,xmax, y, first,last}
_G._frames={}              -- frame -> ordered list of {ord,ptr,x,y,h,w,fl,par}
_G._hist={}                -- draws-per-frame -> count
local function flipstr(fl) if fl>=0x80 then return "FLIP" elseif fl>0 then return "skip" else return "norm" end end
pcall(function()
  _G._tap = mem:install_read_tap(0x1903,0x1903,"L1903",function(o,d,m)
    if _G._c<FSTART or _G._c>FEND then return end
    local lo,hi=rd(0x03),rd(0x04); local src=hi*256+lo
    if src>=0xA400 and src<=0xACFF then return end
    _G._hits=_G._hits+1; _G._ord=_G._ord+1
    local x,sh,y,fl = rd(0x05),rd(0x10),rd(0x06),rd(0x0F)
    local h,w = mem:read_u8(src), mem:read_u8(src+1)
    local px = x*7+sh; local par = px%2
    local e=_G._cel[src]
    if not e then e={n=0,h=h,w=w,even=0,odd=0,bl={},xmin=px,xmax=px,y=y,first=_G._c,last=_G._c}; _G._cel[src]=e end
    e.n=e.n+1; e.last=_G._c; if par==0 then e.even=e.even+1 else e.odd=e.odd+1 end
    e.bl[flipstr(fl)]=(e.bl[flipstr(fl)] or 0)+1
    if px<e.xmin then e.xmin=px end; if px>e.xmax then e.xmax=px end
    local fr=_G._frames[_G._c]; if not fr then fr={}; _G._frames[_G._c]=fr end
    fr[#fr+1]={ord=_G._ord,ptr=src,x=px,y=y,h=h,w=w,fl=flipstr(fl),par=par==0 and "E" or "O"}
    csvf:write(string.format("%d,%d,%04X,%d,%d,%d,%d,%s,%s\n",_G._c,_G._ord,src,px,y,h,w,flipstr(fl),par==0 and "E" or "O"))
  end)
end)
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1; _G._ord=0
  if _G._c>FEND then
    log(string.format("== HS-1: tap fired %d times over f%d-%d ==",_G._hits,FSTART,FEND))
    -- (1) per-cel aggregate
    local rows={} for p,e in pairs(_G._cel) do rows[#rows+1]={p=p,e=e} end
    table.sort(rows,function(a,b) return a.e.n>b.e.n end)
    log(string.format("== PER-CEL descriptor (%d non-scroll cels): handle ptr HxW draws parity blend Xrange Y ==",#rows))
    for _,r in ipairs(rows) do local e=r.e
      local par=(e.even>0 and e.odd>0) and "CROSS" or (e.odd>0 and "ODD" or "EVEN")
      local bl=""; for k,v in pairs(e.bl) do bl=bl..k..":"..v.." " end
      log(string.format("cel@$%04X ptr=$%04X %dx%d draws=%d par=%s(E%d/O%d) blend=[%s] X=%d-%d Y=%d f%d-%d",
        r.p,r.p,e.h,e.w,e.n,par,e.even,e.odd,bl,e.xmin,e.xmax,e.y,e.first,e.last)) end
    -- (3) draws-per-frame histogram
    for fr,list in pairs(_G._frames) do local n=#list; _G._hist[n]=(_G._hist[n] or 0)+1 end
    local hk={} for k in pairs(_G._hist) do hk[#hk+1]=k end; table.sort(hk)
    log("== DRAWS-PER-FRAME histogram (co-occurrence sparsity) ==")
    for _,k in ipairs(hk) do log(string.format("   %d draws/frame : %d frames",k,_G._hist[k])) end
    -- (2) multi-part co-occurrence groups (>=2 draws in one frame = a redraw the compositor uses)
    local mf={} for fr,list in pairs(_G._frames) do if #list>=2 then mf[#mf+1]=fr end end
    table.sort(mf)
    log(string.format("== MULTI-PART FRAMES (>=2 co-occurring draws): %d frames ==",#mf))
    for _,fr in ipairs(mf) do
      local parts={} for _,d in ipairs(_G._frames[fr]) do
        parts[#parts+1]=string.format("[%d]$%04X X%d Y%d %dx%d %s %s",d.ord,d.ptr,d.x,d.y,d.h,d.w,d.fl,d.par) end
      log(string.format("f%d: %s",fr,table.concat(parts," | ")))
    end
    logf:close(); csvf:close(); manager.machine:exit()
  end
end)
