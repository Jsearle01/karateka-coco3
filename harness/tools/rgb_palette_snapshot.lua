-- rgb_palette_snapshot.lua — set Monitor Type (screen_config: 0=Composite,1=RGB) AND poke the palette
-- registers $FFB1 (orange) = B1 and $FFB2 (blue) = B2, load the fallback, settle, snapshot. Measures a
-- candidate palette pair as REAL MAME renders it under the chosen monitor. Env: S_BIN, MONITOR, B1, B2.
local BIN=os.getenv("S_BIN"); local MON=tonumber(os.getenv("MONITOR") or "1")
local B1=tonumber(os.getenv("B1") or "0x26"); local B2=tonumber(os.getenv("B2") or "0x2D")
local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]; local scr=manager.machine.screens:at(1)
local function load(p)
  local f=io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end; i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end
local function set_mon(v)
  for _,port in pairs(manager.machine.ioport.ports) do
    for fn,field in pairs(port.fields) do if fn=="Monitor Type" then field.user_value=v; return end end
  end
end
local st="wait"; local to=0; local set=false
_G._rp=emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if not set and fn>=2 then set_mon(MON); set=true end
  if st=="wait" and set and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="settle"; to=fn+250 end
  elseif st=="settle" and fn>=to then
    mem:write_u8(0xFFB1,B1); mem:write_u8(0xFFB2,B2)      -- poke candidate AFTER the build's own palette write
    print(string.format("[rgb] mon=%d B1(orange)=%02X B2(blue)=%02X",MON,B1,B2)); to=fn+4; st="shot"
  elseif st=="shot" and fn>=to then pcall(function() scr:snapshot() end); to=fn+3; st="done"
  elseif st=="done" and fn>=to then manager.machine:exit() end
end)
