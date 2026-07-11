-- scene6_bg_layers.lua — separate the scene-6 background into FIXED backdrop / SCROLLING midground
-- / actors, by measuring per-cel X-span, AND capturing the non-$1903 FILL path (the sky/Fuji is a
-- fill / one-time draw, not a $1903 blit). Over f6000-7400 (same window the midground scrolls span
-- 94). Read-only.
--  (a) $1903-family draws: for every $Axxx scenery cel, track X min/max -> span. span<=4 = FIXED,
--      span>=20 = SCROLLS. This finds any constant-X backdrop sprite mixed in the stream.
--  (b) FILL family $0A00/$0A03/$0A06: aggregate by signature (rowstart,rowend,pattern) + col range
--      + frame span -> a top-rows / constant-coord fill that is the sky is the fixed backdrop.
local mem=manager.machine.devices[":maincpu"].spaces["program"]
local LOG=os.getenv("BG_LOG") or "C:/Projects/karateka_dissasembly_claude/build/logs/bg_layers.log"
local FS=tonumber(os.getenv("BG_FS")) or 6000
local FE=tonumber(os.getenv("BG_FE")) or 7400
local logf=io.open(LOG,"w"); local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
_G._c=0; _G._cel={}; _G._fill={}
local function drawtap(o,d,m)
  if _G._c<FS or _G._c>FE then return end
  local src=rd(0x04)*256+rd(0x03); local x=rd(0x05)*7+rd(0x10); local y=rd(0x06)
  if src>=0xA000 and src<=0xACFF then       -- scenery bank ($Axxx): the bg/scroll layers
    local e=_G._cel[src]; if not e then e={mn=x,mx=x,ymn=y,ymx=y,n=0,f0=_G._c,f1=_G._c}; _G._cel[src]=e end
    if x<e.mn then e.mn=x end; if x>e.mx then e.mx=x end
    if y<e.ymn then e.ymn=y end; if y>e.ymx then e.ymx=y end
    e.n=e.n+1; e.f1=_G._c
  end
end
for _,en in ipairs({0x1903,0x1906,0x1909,0x190C}) do pcall(function() _G["d"..en]=mem:install_read_tap(en,en,"d",drawtap) end) end
-- FILL family: read $05(colstart) $09(colend) $06(rowstart) $08(rowend) $02(pattern) at entry
local function filltap(name) return function(o,d,m)
  if _G._c<FS or _G._c>FE then return end
  local cs,ce,rs,re,pat=rd(0x05),rd(0x09),rd(0x06),rd(0x08),rd(0x02)
  local sig=string.format("%s r%d-%d c%d-%d pat$%02X",name,rs,re,cs,ce,pat)
  local e=_G._fill[sig]; if not e then e={n=0,f0=_G._c,f1=_G._c}; _G._fill[sig]=e end
  e.n=e.n+1; e.f1=_G._c
end end
pcall(function() _G.f0=mem:install_read_tap(0x0A00,0x0A00,"pa",filltap("passA")) end)
pcall(function() _G.f3=mem:install_read_tap(0x0A03,0x0A03,"pb",filltap("passB")) end)
pcall(function() _G.f6=mem:install_read_tap(0x0A06,0x0A06,"clr",filltap("clear")) end)
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._c>FE then
    -- (a) scenery cels split by X-span
    local fixed,scroll,other={},{},{}
    for s,e in pairs(_G._cel) do local sp=e.mx-e.mn
      local row={s=s,e=e,sp=sp}
      if sp<=4 then fixed[#fixed+1]=row elseif sp>=20 then scroll[#scroll+1]=row else other[#other+1]=row end
    end
    local function dump(nm,t) table.sort(t,function(a,b) return a.e.n>b.e.n end)
      log(string.format("== %s: %d $Axxx cels ==",nm,#t))
      for i,r in ipairs(t) do if i<=14 then
        log(string.format("   $%04X  Xspan=%d (X%d-%d)  Y%d-%d  draws=%d  f%d-%d",
          r.s,r.sp,r.e.mn,r.e.mx,r.e.ymn,r.e.ymx,r.e.n,r.e.f0,r.e.f1)) end end
    end
    dump("FIXED (Xspan<=4) — candidate fixed backdrop",fixed)
    dump("SCROLLS (Xspan>=20) — midground",scroll)
    dump("intermediate (5-19)",other)
    -- (b) fills
    log("== FILL family (non-$1903 path): signature -> draws, frames ==")
    local fl={} for sig,e in pairs(_G._fill) do fl[#fl+1]={sig=sig,e=e} end
    table.sort(fl,function(a,b) return a.e.n>b.e.n end)
    for i,r in ipairs(fl) do if i<=24 then log(string.format("   %s  draws=%d  f%d-%d",r.sig,r.e.n,r.e.f0,r.e.f1)) end end
    logf:close(); manager.machine:exit()
  end
end)
