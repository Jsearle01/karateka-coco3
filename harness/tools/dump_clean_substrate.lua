-- dump_clean_substrate.lua — dump buffer B ($C000) at the pose-0 moment (cl_dwctr!=0).
-- At pose 0 the driver has drawn the substrate into A and copy_a_to_b'd it into B; cl_render(0)
-- draws pose 0 into A only. So buffer B = the CLEAN full-frame substrate (no actor). Reference
-- for the anim_02 carryover diff. Env: S_BIN, S_OUT.
local BIN = os.getenv("S_BIN"); local OUT = os.getenv("S_OUT")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function load(p)
  local f=io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2); local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end; i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex
end
local st="wait"
_G._ds = emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if st=="wait" then
    if fn>=300 and cpu.state["PC"].value>=0x8000 then local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="run" end end
    return
  end
  if mem:read_u8(0x0041)~=0 then           -- cl_init done, pose 0 rendered; B still clean substrate
    local o=io.open(OUT,"wb")
    for a=0xC000,0xC000+15360-1 do o:write(string.char(mem:read_u8(a))) end
    o:close(); manager.machine:exit()
  end
end)
