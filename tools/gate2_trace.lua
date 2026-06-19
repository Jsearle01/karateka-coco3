-- gate2_trace.lua — load princess_gate2.bin; trace the clock/phase/state +
-- snapshot the arc: throne walk, just-after-transition (cell+princess), cell
-- walk, stopped. Verifies the transition (clock $22->$04, phase 0->1) + continuity.
local BIN="tests/princess_gate2.bin"
local CLK,PHASE,STATE,LEG,PX = 0x42,0x3E,0x49,0x43,0x46
local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local scr=manager.machine.screens[":screen"]
local logf=io.open("C:/karateka-capture/gate2.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function load(p) local f=io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex end
local SNAPS={ {600,false},{2200,false},{3120,false},{3380,false},{3780,false},{4060,false} }
local st="wait"; local f0; local pkey
_G._g2=emu.add_machine_frame_notifier(function()
  local f=scr:frame_number()
  if st=="wait" and f>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex end st="run"; f0=f
    log("[g2] loaded @f="..f); return end
  if st~="run" then return end
  local rel=f-f0
  local c,ph,s,l=mem:read_u8(CLK),mem:read_u8(PHASE),mem:read_u8(STATE),mem:read_u8(LEG)
  local key=string.format("%02x%d%d%d",c,ph,s,l)
  if key~=pkey then
    log(string.format("rel=%-5d CLK=%02X phase=%d state=%d leg=%d px=%d",rel,c,ph,s,l,mem:read_u8(PX)))
    pkey=key end
  for _,t in ipairs(SNAPS) do
    if not t[2] and rel>=t[1] then t[2]=true
      pcall(function() scr:snapshot() end)
      log(string.format("  SNAP rel=%d CLK=%02X phase=%d state=%d px=%d",rel,c,ph,s,mem:read_u8(PX)))
    end end
  if rel>=4200 then log("[g2] done"); logf:close(); manager.machine:exit() end
end)
