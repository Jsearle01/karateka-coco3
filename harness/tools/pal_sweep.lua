-- pal_sweep.lua — load the fallback, run to a stable frame, then sweep $FFB2 (index-2 = blue/sky)
-- across all 64 composite values 0..63, snapshotting each, to read MAME's ACTUAL composite->RGB.
-- Snapshots -> -snapshot_directory/coco3/NNNN.png (order == value). Palette study, report-only.
local BIN = os.getenv("S_BIN")
local REG = tonumber(os.getenv("POKE_REG") or "0xFFB2")
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function load(p)
  local f = io.open(p,"rb"); if not f then return end
  local d=f:read("*a"); f:close(); local i=1; local ex
  while i<=#d do local t=string.byte(d,i)
    if t==0 then local n=string.byte(d,i+1)*256+string.byte(d,i+2)
      local a=string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j,string.byte(d,i+5+j)) end
      i=i+5+n
    elseif t==0xFF then ex=string.byte(d,i+3)*256+string.byte(d,i+4); break else break end
  end
  return ex
end
local st="wait"; local val=0; local wait_to=0
_G._ps = emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if st=="wait" and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="settle"; wait_to=fn+220 end
  elseif st=="settle" and fn>=wait_to then
    st="sweep"; val=0; mem:write_u8(REG, val); wait_to=fn+3
  elseif st=="sweep" and fn>=wait_to then
    pcall(function() scr:snapshot() end)         -- snapshot for current val
    val=val+1
    if val>63 then manager.machine:exit() return end
    mem:write_u8(REG, val); wait_to=fn+3
  end
end)
