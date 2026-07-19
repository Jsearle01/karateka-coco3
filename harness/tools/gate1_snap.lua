-- gate1_snap.lua — load princess_gate1.bin (throne composite) + snap PNGs at
-- the pre-walk STAND and two mid-walk points. Saves to MAME snaps/ folder.
local BIN="tests/princess_gate1.bin"
local CLK,STATE,LEG,PX = 0x42,0x49,0x43,0x46
local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local scr=manager.machine.screens[":screen"]
local logf=io.open("C:/karateka-capture/gate1_snap.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function load(p) local f=io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex end
-- snap targets: rel frame -> taken?  (stand, early walk, mid walk)
local SNAPS={ {400,false}, {1400,false}, {2560,false} }
local st="wait"; local f0
log("# gate1 snapshot run (throne composite)")
_G._g1=emu.add_machine_frame_notifier(function()
  local f=scr:frame_number()
  if st=="wait" and f>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex end st="run"; f0=f
    log("[g1] loaded @f="..f); return end
  if st~="run" then return end
  local rel=f-f0
  for _,t in ipairs(SNAPS) do
    if not t[2] and rel>=t[1] then
      t[2]=true
      pcall(function() scr:snapshot() end)
      log(string.format("SNAP rel=%-5d CLK=%02X state=%d leg=%d px=%d",
          rel, mem:read_u8(CLK), mem:read_u8(STATE), mem:read_u8(LEG), mem:read_u8(PX)))
    end
  end
  if rel>=2600 then log("[g1] done"); logf:close(); manager.machine:exit() end
end)
