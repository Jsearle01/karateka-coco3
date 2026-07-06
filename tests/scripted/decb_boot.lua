-- decb_boot.lua — BUILD #3b-3 full boot chain: BASIC -> LOADM"BOOT":EXEC -> the 3b-2
-- bootloader (loaded to $8000) -> reads the real game from the FAT-reserved raw tracks
-- 1-4 into $0100 -> jmp $0200 -> renders. This is the REAL LOADM+EXEC handoff (G2), not
-- the 3b-2 write_u8 stand-in. Verifies: bootloader reached (BL_RESULT), game byte-exact,
-- jump to game, and render BYTE-IDENTICAL to the 3b-2 direct-placement baseline (45470).
local GAME = "C:/Projects/karateka_coco3/build/karateka.bin"
local LOG  = os.getenv("DB_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/decb_boot.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG,"w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
local function pc() return cpu.state["PC"].value end
local kbd = manager.machine.natkeyboard

-- reference game segments (byte-exact check)
local function ref()
  local f=io.open(GAME,"rb"); local d=f:read("*a"); f:close(); local i=1; local segs={}; local e=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      segs[#segs+1]={a=a,data=d:sub(i+5,i+5+n-1)}; i=i+5+n
    elseif t==0xFF then e=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return segs,e
end
local SEGS,GENTRY = ref()
-- visible framebuffer checksum (exclude $BC00-$BFFF loader vars), for the render compare
local function fb_sum() local s=0 for a=0x8000,0xBBFF do s=(s+rd(a))&0xFFFFFF end for a=0xC000,0xFBFF do s=(s+rd(a))&0xFFFFFF end return s end

local BL_RESULT=0xBF20; local SAMPLE_AFTER=400
_G._c=0; _G._st="boot"; _G._typed=false; _G._verified=false; _G._reached=false; _G._entry=nil; _G._fbdone=false
_G._pc_lo=0xFFFF; _G._pc_hi=0
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="boot" then
    if _G._c>=240 and not _G._typed then
      log(string.format("[f%d] BASIC settled; typing LOADM\"BOOT\":EXEC", _G._c))
      pcall(function() kbd:post('LOADM"BOOT":EXEC\n') end); _G._typed=true; _G._st="run"
    end
    return
  end
  if _G._st=="run" then
    local p=pc(); if p<_G._pc_lo then _G._pc_lo=p end; if p>_G._pc_hi then _G._pc_hi=p end
    if not _G._verified and rd(BL_RESULT)==0xA5 then
      local mism=0; local first=nil; local checked=0
      for _,s in ipairs(SEGS) do for k=1,#s.data do local a=s.a+k-1
        if not (a>=0x0112 and a<=0x01FF) then checked=checked+1
          if rd(a)~=string.byte(s.data,k) then mism=mism+1; if not first then first=a end end end end end
      _G._verified=true
      log(string.format("[f%d] BL_RESULT=$A5 (bootloader loaded game). byte-exact %d/%d, %d mismatch%s PC=$%04X",
        _G._c, checked-mism, checked, mism, first and string.format(" (first@$%04X)",first) or "", p))
    end
    if not _G._reached and rd(BL_RESULT)==0xA5 and p>=0x0200 and p<=0x48FF then
      _G._reached=true; _G._entry=_G._c; log(string.format("[f%d] JUMP reached game: PC=$%04X", _G._c, p))
    end
    if not _G._fbdone and _G._entry and _G._c>=_G._entry+SAMPLE_AFTER then
      _G._fbdone=true
      log(string.format("[f%d] FB visible-checksum (entry+%d) = %d  (3b-2 direct baseline = 45470)", _G._c, SAMPLE_AFTER, fb_sum()))
    end
    if _G._c>=1600 then
      log(string.format("[end f%d] BL_RESULT=$%02X (A5=ok,5A=fail,status=$%02X) PC=$%04X  PC-range $%04X-$%04X",
        _G._c, rd(BL_RESULT), rd(BL_RESULT+1), pc(), _G._pc_lo, _G._pc_hi))
      log(string.format("  render: visible fb=%d ; game entry=$%04X", fb_sum(), GENTRY))
      logf:close(); manager.machine:exit()
    end
  end
end)
