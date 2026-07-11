-- scene6_fight_control.lua — Tracks A2 (control) + B (scroll) + A1 (anim union) over the full
-- fight window. A2: tap fight_ai_a000 ($A000) + lcg_step_a0a2 ($A0A2, the LCG $59=$59*5+$13);
-- per frame sample $59(seed) $29(action) $52(scroll) $70/$33(state) -> a control CSV to diff
-- across runs (stochastic test). B: midground $A684 X per frame (scroll ΔX) + upper-bg (low Y)
-- X (fixed?). A1: union of actor cels ($8xxx/$9xxx). Read-only. Env FD_SEEDPOKE=val pokes $59 at
-- FD_POKEF (seed-perturbation demo).
local mem=manager.machine.devices[":maincpu"].spaces["program"]
local LOG=os.getenv("FC_LOG") or "C:/Projects/karateka_dissasembly_claude/build/logs/fc.log"
local CSV=os.getenv("FC_CSV") or "C:/Projects/karateka_dissasembly_claude/build/logs/fc.csv"
local FS=tonumber(os.getenv("FC_FS")) or 6400
local FE=tonumber(os.getenv("FC_FE")) or 9500
local POKE=tonumber(os.getenv("FD_SEEDPOKE")); local POKEF=tonumber(os.getenv("FD_POKEF")) or 6484
local logf=io.open(LOG,"w"); local csvf=io.open(CSV,"w"); csvf:write("frame,s59,a29,s52,s70,s33\n")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
_G._c=0; _G._ai=0; _G._lcg=0; _G._mgx={}; _G._ubg={}; _G._act={}; _G._a29={}
pcall(function() _G._tai=mem:install_read_tap(0xA000,0xA000,"ai",function() if _G._c>=FS and _G._c<=FE then _G._ai=_G._ai+1 end end) end)
pcall(function() _G._tl=mem:install_read_tap(0xA0A2,0xA0A2,"lcg",function() if _G._c>=FS and _G._c<=FE then _G._lcg=_G._lcg+1 end end) end)
local function draws(entry) return function(o,d,m)
  if _G._c<FS or _G._c>FE then return end
  local src=rd(0x04)*256+rd(0x03); local x=rd(0x05)*7+rd(0x10); local y=rd(0x06)
  if src==0xA684 then _G._mgx[_G._c]=x                      -- midground ref tile
  elseif src>=0xA64A and src<=0xACFF then if y<70 then local e=_G._ubg[src]; if not e then _G._ubg[src]={mn=x,mx=x} else if x<e.mn then e.mn=x end; if x>e.mx then e.mx=x end end end   -- upper-bg (low Y)
  elseif (src>=0x8000 and src<=0x9FFF) or (src>=0xA3C5 and src<=0xA649) then _G._act[src]=(_G._act[src] or 0)+1 end
end end
for _,e in ipairs({0x1903,0x1906,0x1909,0x190C}) do pcall(function() _G["t"..e]=mem:install_read_tap(e,e,"d",draws(e)) end) end
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if POKE and _G._c==POKEF then mem:write_u8(0x59,POKE); log(string.format("== POKED $59=%02X at f%d ==",POKE,POKEF)) end
  if _G._c>=FS and _G._c<=FE then
    local a29=rd(0x29)
    csvf:write(string.format("%d,%02X,%02X,%02X,%02X,%02X\n",_G._c,rd(0x59),a29,rd(0x52),rd(0x70),rd(0x33)))
    _G._a29[a29]=(_G._a29[a29] or 0)+1
  end
  if _G._c>FE then
    log(string.format("== fight_ai_a000 fires=%d | lcg_step fires=%d over f%d-%d ==",_G._ai,_G._lcg,FS,FE))
    local a={} for k,v in pairs(_G._a29) do a[#a+1]=string.format("$%02X:%d",k,v) end
    log("$29 action-code distribution: "..table.concat(a," "))
    -- midground scroll: X range
    local xs={} for f,x in pairs(_G._mgx) do xs[#xs+1]=x end table.sort(xs)
    if #xs>0 then log(string.format("MIDGROUND $A684 X: min=%d max=%d span=%d (%d frames) -> %s",
      xs[1],xs[#xs],xs[#xs]-xs[1],#xs, (xs[#xs]-xs[1])>4 and "SCROLLS" or "fixed")) end
    local ub={} for s,x in pairs(_G._ubg) do ub[#ub+1]=string.format("$%04X span=%d(%d-%d)",s,x.mx-x.mn,x.mn,x.mx) end
    log("UPPER-BG (Y<70) cels: "..(#ub>0 and table.concat(ub," ") or "(none drawn in low-Y band)"))
    local ac={} for s,n in pairs(_G._act) do ac[#ac+1]={s=s,n=n} end
    table.sort(ac,function(p,q) return p.n>q.n end)
    local s=""; for i,r in ipairs(ac) do if i<=40 then s=s..string.format("$%04X:%d ",r.s,r.n) end end
    log(string.format("ACTOR cel union (%d cels): %s",#ac,s))
    logf:close(); csvf:close(); manager.machine:exit()
  end
end)
