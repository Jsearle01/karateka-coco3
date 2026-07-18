-- gime_artifact_snapshot.lua — set BOTH the coco3 "Monitor Type" (screen_config: 0=Composite,1=RGB)
-- and "Artifacting" (gime:artifacting: 0=Off,1=Standard,2=Reverse) configs, load the fallback, settle,
-- snapshot. Classifies gime:artifacting: does it change composite only (A) or monitor-independently (B)?
-- Env: S_BIN, MONITOR (0|1), ARTIFACT (0|1|2). Snapshot -> -snapshot_directory.
local BIN=os.getenv("S_BIN"); local MON=tonumber(os.getenv("MONITOR") or "0"); local ART=tonumber(os.getenv("ARTIFACT") or "1")
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
local function set_field(fname,v)
  for ptag,port in pairs(manager.machine.ioport.ports) do
    for fn,field in pairs(port.fields) do
      if fn==fname then field.user_value=v
        print(string.format("[cfg] %s @ %s -> %d",fname,ptag,v)); return true end
    end
  end
  print("[cfg] field NOT FOUND: "..fname); return false
end
local st="wait"; local to=0; local set=false
_G._ga=emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if not set and fn>=2 then set_field("Monitor Type",MON); set_field("Artifacting",ART); set=true end
  if st=="wait" and set and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="settle"; to=fn+250 end
  elseif st=="settle" and fn>=to then
    pcall(function() scr:snapshot() end); to=fn+3; st="done"
  elseif st=="done" and fn>=to then manager.machine:exit() end
end)
