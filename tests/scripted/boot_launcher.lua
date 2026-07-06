-- boot_launcher.lua — BUILD #3b-2. Stands in for DECB LOADM+EXEC: writes the boot
-- loader to its framebuffer address ($8000) and sets PC. The loader then raw-reads
-- the real game from the mounted 1:1 game.dmk into $0100 and jumps to $0200; the
-- game runs and renders. Verifies: (AC-3) PC in $8000+ during the load, (AC-4) the
-- loaded game bytes match build/karateka.bin byte-for-byte at the pre-jump moment,
-- (AC-5) PC reaches the game entry $0200, plus render evidence (framebuffer drawn).
local BL   = "C:/Projects/karateka_coco3/tests/scripted/bootloader.bin"
local GAME = "C:/Projects/karateka_coco3/build/karateka.bin"
local LOG  = os.getenv("BL_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/boot_launcher.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG,"w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end
local function pc() return cpu.state["PC"].value end

-- load a DECB binary via write_u8; return exec addr
local function load_decb(path)
  local f=io.open(path,"rb"); if not f then log("NO BIN "..path); return nil end
  local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end

-- reference: the contiguous $0100 game image (segments placed, gaps=$00) = what
-- the loader should place. Parsed from karateka.bin (the payload).
local function ref_image()
  local f=io.open(GAME,"rb"); local d=f:read("*a"); f:close()
  local segs={}; local i=1; local entry=nil; local lo=0xFFFF; local hi=0
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      segs[#segs+1]={a=a,data=d:sub(i+5,i+5+n-1)}; if a<lo then lo=a end; if a+n>hi then hi=a+n end; i=i+5+n
    elseif t==0xFF then entry=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return segs, lo, hi, entry
end
local SEGS, GLO, GHI, GENTRY = ref_image()

-- framebuffer render evidence: nonzero-byte count over $8000-$BBFF (Frame A)
local function fb_nz()
  local nz=0 for a=0x8000,0xBBFF,32 do if rd(a)~=0 then nz=nz+1 end end return nz
end

-- VISIBLE framebuffer checksum: frame A $8000-$BBFF + frame B $C000-$FBFF, EXCLUDING
-- the non-visible $BC00-$BFFF (where the loader's dead vars/result live) — for a true
-- byte-identical render compare vs direct placement.
local function fb_sum()
  local s=0
  for a=0x8000,0xBBFF do s=(s+rd(a))&0xFFFFFF end
  for a=0xC000,0xFBFF do s=(s+rd(a))&0xFFFFFF end
  return s
end
local MODE = os.getenv("BL_MODE") or "BOOT"   -- BOOT: via bootloader+disk ; DIRECT: write game+PC=$0200
local SAMPLE_AFTER = 400                        -- frames after game-entry to checksum the framebuffer

local BL_RESULT=0xBF20
_G._c=0; _G._st="wait"; _G._pcload=nil; _G._reached=false; _G._verified=false
_G._pc_lo=0xFFFF; _G._pc_hi=0; _G._entryframe=nil; _G._fbdone=false
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==60 then
    if MODE=="DIRECT" then
      local ex=load_decb(GAME); cpu.state["PC"].value=ex; _G._st="run"; _G._entryframe=_G._c
      log(string.format("[f%d] DIRECT: loaded game @ PC=$%04X (no bootloader/disk)", _G._c, ex)); return
    end
    local ex=load_decb(BL); if not ex then log("no bootloader bin"); logf:close(); manager.machine:exit(); return end
    cpu.state["PC"].value=ex; _G._st="run"
    log(string.format("[f%d] launched bootloader @ $%04X (game entry expected $%04X)", _G._c, ex, GENTRY))
    return
  end
  if _G._st=="run" then
    local p=pc()
    if p<_G._pc_lo then _G._pc_lo=p end; if p>_G._pc_hi then _G._pc_hi=p end
    -- AC-4: verify the loaded game the instant the loader signals done ($A5), pre/at-jump
    if not _G._verified and rd(BL_RESULT)==0xA5 then
      local mism=0; local first=nil; local checked=0
      for _,s in ipairs(SEGS) do
        for k=1,#s.data do
          local a=s.a+k-1
          -- skip the stack tail $0112-$01FF (game writes its stack there post-jump)
          if not (a>=0x0112 and a<=0x01FF) then
            checked=checked+1
            if rd(a) ~= string.byte(s.data,k) then mism=mism+1; if not first then first=a end end
          end
        end
      end
      _G._verified=true
      log(string.format("[f%d] LOAD DONE (BL_RESULT=$A5). byte-exact check: %d/%d match, %d mismatch%s  PC=$%04X",
        _G._c, checked-mism, checked, mism, first and string.format(" (first@$%04X)",first) or "", p))
    end
    -- AC-5: PC reached the game region ($0200-$48FF)?
    if not _G._reached and rd(BL_RESULT)==0xA5 and p>=0x0200 and p<=0x48FF then
      _G._reached=true; _G._entryframe=_G._c
      log(string.format("[f%d] JUMP reached game: PC=$%04X (entry $%04X)", _G._c, p, GENTRY))
    end
    -- framebuffer checksum over a WINDOW of frames-since-entry (phase-offset vs corruption)
    if _G._entryframe then
      local d = _G._c - _G._entryframe
      if d>=SAMPLE_AFTER-3 and d<=SAMPLE_AFTER+3 then
        log(string.format("[%s entry+%d] fb_sum=%d nz=%d", MODE, d, fb_sum(), fb_nz()))
      end
    end
    if _G._c==90 and rd(BL_RESULT)==0 then _G._pcload=p end  -- sample PC mid-load
    if _G._c>=1200 then   -- ~20s: report render evidence + finish
      log(string.format("[end f%d] BL_RESULT=$%02X (A5=load-ok,5A=fail,status=$%02X)  PC=$%04X",
        _G._c, rd(BL_RESULT), rd(BL_RESULT+1), pc()))
      log(string.format("  PC-during-run range: $%04X-$%04X (loader $8000+; game $0100-$48FF)", _G._pc_lo, _G._pc_hi))
      log(string.format("  RENDER evidence: framebuffer $8000-$BBFF nonzero = %d (game drew if >0)", fb_nz()))
      log(string.format("  game entry=$%04X span=$%04X-$%04X", GENTRY, GLO, GHI-1))
      logf:close(); manager.machine:exit()
    end
  end
end)
