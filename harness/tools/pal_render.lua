-- pal_render.lua — load the fallback, run to a stable frame, poke $FFB1 (orange) = B1 and
-- $FFB2 (blue) = B2 to a candidate palette, snapshot. For the palette-study comparison (report-only).
local BIN=os.getenv("S_BIN"); local B1=tonumber(os.getenv("B1") or "0x26"); local B2=tonumber(os.getenv("B2") or "0x1B")
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
local st="wait"; local to=0
_G._pr=emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if st=="wait" and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="settle"; to=fn+220 end
  elseif st=="settle" and fn>=to then
    mem:write_u8(0xFFB1,B1); mem:write_u8(0xFFB2,B2); st="shot"; to=fn+4
  elseif st=="shot" and fn>=to then
    pcall(function() scr:snapshot() end); manager.machine:exit()
  end
end)
