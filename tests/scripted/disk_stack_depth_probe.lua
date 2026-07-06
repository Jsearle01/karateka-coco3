-- disk_stack_depth_probe.lua — measure the disk-access path's worst-case stack DEPTH
-- (bytes below the SP at disk_read_range entry — BASE-INDEPENDENT), over the worst-case
-- 8-track single-call m=1 read. Separates the synchronous CALL depth from the NMI frame,
-- and resolves ADD-vs-MAX by capturing the SP when the disk NMI handler fires.
--   disk_read_range entry = $04A8 (fetch tap -> entry-SP)
--   NMI handler           = $FE20 (fetch tap -> SP inside handler = after the 12B NMI frame)
--   stack writes          = write tap -> deepest byte the stack touches
-- Read-only; the primitive runs AS-IS. Predictive input for the split-$01xx trigger-2.
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox_wc.bin"
local LOG = os.getenv("DSD_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/disk_stack_depth.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG,"w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function S() return cpu.state["S"].value & 0xFFFF end

local function load_decb(path)
  local f=io.open(path,"rb"); if not f then log("NO BIN"); return nil end
  local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end

local DRR=0x04A8; local NMIH=0x0FE20
_G._c=0; _G._st="wait"
_G._entrySP=nil; _G._minwr=0xFFFF; _G._nmi_cnt=0; _G._nmi_minS=0xFFFF; _G._minS=0xFFFF
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==150 then
    local ex=load_decb(BIN); if not ex then logf:close(); manager.machine:exit(); return end
    cpu.state["PC"].value=ex; _G._st="run"
    -- taps armed after load
    pcall(function()
      _G._t1 = mem:install_read_tap(DRR,DRR,"drr",function(o,d,m) if not _G._entrySP then _G._entrySP=S() end end)
      _G._t2 = mem:install_read_tap(NMIH,NMIH,"nmi",function(o,d,m) _G._nmi_cnt=_G._nmi_cnt+1; local s=S(); if s<_G._nmi_minS then _G._nmi_minS=s end end)
      -- stack write window (sandbox stack $1F00 down); record deepest written addr
      _G._t3 = mem:install_write_tap(0x1A00,0x1EFF,"stk",function(o,d,m) local a=o&0xFFFF; if a<_G._minwr then _G._minwr=a end end)
    end)
    log(string.format("[f%d] worstcase running; taps: DRR=$%04X NMIH=$%04X", _G._c, DRR, NMIH))
    return
  end
  if _G._st=="run" then
    local s=S(); if s>=0x1A00 and s<=0x1F00 and s<_G._minS then _G._minS=s end
    if _G._c>=1400 then   -- ~21s: worstcase 8-track read completes ~11s in
      local eSP = _G._entrySP or 0
      log("== DISK-PATH STACK DEPTH (worst-case 8-track m=1 read) ==")
      log(string.format("  entry-SP at disk_read_range ($04A8) = $%04X", eSP))
      log(string.format("  deepest stack byte WRITTEN          = $%04X", _G._minwr))
      log(string.format("  deepest S sampled                   = $%04X", _G._minS))
      log(string.format("  NMI handler fires = %d ; deepest S inside NMI handler = $%04X", _G._nmi_cnt, _G._nmi_minS))
      if eSP>0 and _G._minwr<0xFFFF then
        local depth = eSP - _G._minwr
        -- synchronous depth at the deepest NMI: entry-SP - (nmi_minS + 12)  [12B NMI frame]
        local sync_at_nmi = (_G._nmi_minS<0xFFFF) and (eSP - (_G._nmi_minS+12)) or nil
        log(string.format("  >> WORST-CASE DEPTH D = entry-SP - deepest-write = %d bytes below entry", depth))
        if sync_at_nmi then
          log(string.format("  >> components: NMI frame = 12 B ; synchronous call depth at deepest NMI = %d B (ADD => total %d)",
            sync_at_nmi, sync_at_nmi+12))
        end
      end
      logf:close(); manager.machine:exit()
    end
  end
end)
