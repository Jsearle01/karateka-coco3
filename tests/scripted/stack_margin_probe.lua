-- stack_margin_probe.lua — verify the split $01xx-page collision margin (KNOWN ISSUE).
-- Low-end DATA high-water = $0111 (game seg1 = the $0100-$0111 dispatch block, from the
-- DECB segments). This measures the DEEPEST STACK reach during a real run: a write tap on
-- $0100-$01FF records the LOWEST address the stack actually writes (stack grows DOWN from
-- $01FF; the deepest written byte incl. interrupt frames is the collision-relevant point).
-- Also samples the S register min as a cross-check. Direct-placement run (the game's stack
-- behavior is identical whether loaded by the bootloader or direct). Read-only.
local GAME = "C:/Projects/karateka_coco3/build/karateka.bin"
local LOG  = os.getenv("SM_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/stack_margin.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG,"w")
local function log(s) logf:write(s.."\n"); logf:flush() end

local function load_decb(path)
  local f=io.open(path,"rb"); local d=f:read("*a"); f:close(); local i=1; local ex=nil
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end

local DATA_HW = 0x0111        -- low-end data high-water (dispatch block top)
_G._minwr = 0x0200            -- lowest $01xx address written (init above the page)
_G._minS  = 0xFFFF            -- lowest S seen
_G._buckets = {}              -- 16-byte write histogram over $0100-$01FF
_G._irqinstall = 0            -- writes at $010C-$010E (the game's own IRQ-vector install)

_G._c=0; _G._st="wait"
_G._tap = nil
_G._n=emu.add_machine_frame_notifier(function()
  _G._c=_G._c+1
  if _G._st=="wait" and _G._c==60 then
    local ex=load_decb(GAME); cpu.state["PC"].value=ex; _G._st="run"
    -- install the stack-region write tap AFTER load (so the load itself isn't counted)
    pcall(function()
      _G._tap = mem:install_write_tap(0x0100,0x01FF,"stk",function(o,d,m)
        local a=o & 0xFFFF
        if a>=0x010C and a<=0x010E then _G._irqinstall=_G._irqinstall+1; return end  -- game's IRQ install, not stack
        if a<_G._minwr then _G._minwr=a end
        local b=(a-0x0100)>>4; _G._buckets[b]=(_G._buckets[b] or 0)+1
      end)
    end)
    log(string.format("[f%d] game running (PC=$%04X); stack tap on $0100-$01FF armed", _G._c, ex))
    return
  end
  if _G._st=="run" then
    local s = cpu.state["S"].value & 0xFFFF
    if s>=0x0100 and s<=0x01FF and s<_G._minS then _G._minS=s end
    if _G._c>=2100 then   -- ~35s: scenes 1-4
      log(string.format("[end f%d] DATA high-water=$%04X", _G._c, DATA_HW))
      log(string.format("  deepest stack WRITE (lowest $01xx addr written) = $%04X", _G._minwr))
      log(string.format("  deepest S register sampled                     = $%04X", _G._minS))
      log(string.format("  game IRQ-vector-install writes at $010C-$010E   = %d (not stack)", _G._irqinstall))
      local deepest = math.min(_G._minwr, _G._minS)
      log(string.format("  MARGIN = deepest($%04X) - data_hw($%04X) = %d bytes  => %s",
        deepest, DATA_HW, deepest-DATA_HW, (deepest-DATA_HW)>0 and "SAFE (positive)" or "COLLISION RISK"))
      log("  $01xx write histogram (16-byte buckets, $0100 + bucket*16):")
      for b=0,15 do if (_G._buckets[b] or 0)>0 then
        log(string.format("    $%04X-$%04X : %d writes", 0x0100+b*16, 0x0100+b*16+15, _G._buckets[b])) end end
      logf:close(); manager.machine:exit()
    end
  end
end)
