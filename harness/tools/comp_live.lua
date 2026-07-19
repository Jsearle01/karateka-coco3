local BIN="tests/scene5_composite.bin"
local cpu=manager.machine.devices[":maincpu"]; local mem=cpu.spaces["program"]
local scr=manager.machine.screens[":screen"]
local function load(p) local f=io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end end
  return ex end
local st="wait"
_G._c=emu.add_machine_frame_notifier(function()
  if st=="wait" and scr:frame_number()>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex end st="run" end
end)
