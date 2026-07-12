-- Headless Frame-A dump for a scene6 stage driver. Boots coco3 to BASIC, loads the
-- .bin (S_BIN), sets PC=exec, runs to a stable static frame, dumps $8000-$BBFF (15360B)
-- to S_OUT. For the HS-5 Stage-2 pixel-identical check + Stage-3 render evidence.
local BIN = os.getenv("S_BIN"); local OUT = os.getenv("S_OUT")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function load(p)
  local f = io.open(p, "rb"); if not f then return end
  local d = f:read("*a"); f:close(); local i = 1; local ex
  while i <= #d do local t = string.byte(d, i)
    if t == 0 then local n = string.byte(d,i+1)*256+string.byte(d,i+2)
      local a = string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j, string.byte(d,i+5+j)) end
      i = i+5+n
    elseif t == 0xFF then ex = string.byte(d,i+3)*256+string.byte(d,i+4); break
    else break end
  end
  return ex
end
local st="wait"
_G._fb = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if st=="wait" and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex = load(BIN); if ex then cpu.state["PC"].value=ex; st="run" end
  elseif st=="run" and fn>=520 then
    local f=io.open(OUT,"wb")
    for i=0,15359 do f:write(string.char(mem:read_u8(0x8000+i))) end
    f:close(); manager.machine:exit()
  end
end)
