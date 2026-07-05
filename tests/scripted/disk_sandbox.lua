-- disk_sandbox.lua — load the standalone HALT-read sandbox, drive it against the
-- mounted DD test .dsk, capture buffer-match + status + NMI-reached + DSKREG b7.
local BIN = "C:/Projects/karateka_coco3/tests/scripted/disk_sandbox.bin"
local LOG = "C:/Projects/karateka_coco3/build/logs/unit/disk_sandbox.log"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function rd(a) return mem:read_u8(a) end

-- capture DSKREG ($FF40) writes — AC-5 proof that b7 (HALT, $80) was armed
_G._dskreg = {}
local ok,err = pcall(function()
  _G._tap = mem:install_write_tap(0x0FF40, 0x0FF40, "dskreg", function(off,data,mask)
    local v = data & 0xff
    _G._dskreg[#_G._dskreg+1] = v
  end)
end)
log("dskreg tap ok="..tostring(ok).." err="..tostring(err))

local function load_decb(path)
  local f = io.open(path,"rb"); if not f then log("NO BIN "..path); return nil end
  local d = f:read("*a"); f:close(); local i=1; local ex=nil
  while i <= #d do
    local t = string.byte(d,i)
    if t==0 then
      local n = string.byte(d,i+1)*256 + string.byte(d,i+2)
      local a = string.byte(d,i+3)*256 + string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j, string.byte(d,i+5+j)) end
      i = i + 5 + n
    elseif t==0xFF then
      ex = string.byte(d,i+3)*256 + string.byte(d,i+4); break
    else break end
  end
  return ex
end

_G._c = 0; _G._st = "wait"
_G._n = emu.add_machine_frame_notifier(function()
  _G._c = _G._c + 1
  if _G._st=="wait" and _G._c==150 then
    local ex = load_decb(BIN)
    log(string.format("loaded sandbox, exec=$%04X; NMI vec $FFFC=%02X%02X (expect FE FD)",
        ex or 0, rd(0xFFFC), rd(0xFFFD)))
    cpu.state["PC"].value = ex
    _G._st = "run"; return
  end
  if _G._st=="run" and _G._c==520 then
    log(string.format("RESULT  PASS[$2200]=$%02X (A5=match,5A=fail)  status[$2201]=$%02X  nmi_done[$2202]=$%02X  ccerr[$2203]=$%02X",
        rd(0x2200), rd(0x2201), rd(0x2202), rd(0x2203)))
    local b={} for k=0,15 do b[#b+1]=string.format("%02X",rd(0x2000+k)) end
    log("buffer $2000..200F: "..table.concat(b," ").."  (expect 00 01 02 03 ...)")
    local last={} for k=248,255 do last[#last+1]=string.format("%02X",rd(0x2000+k)) end
    log("buffer $20F8..20FF: "..table.concat(last," ").."  (expect F8 F9 ... FF)")
    log(string.format("AC7 bad-sector: status[$2204]=$%02X (RNF b4=$10 expected)  ccerr[$2205]=$%02X (01 expected; 00=hang)",
        rd(0x2204), rd(0x2205)))
    -- DSKREG writes seen (look for $A9 = b7 armed, $29 = positioning)
    local seen={} for _,v in ipairs(_G._dskreg) do seen[#seen+1]=string.format("%02X",v) end
    log("DSKREG writes: "..table.concat(seen," ").."  (A9 => HALT b7 armed for transfer)")
    logf:close(); manager.machine:exit()
  end
end)
