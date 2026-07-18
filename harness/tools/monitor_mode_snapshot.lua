-- monitor_mode_snapshot.lua — set the coco3 "Monitor Type" config (screen_config: 0=Composite,1=RGB)
-- to env MONITOR, load the fallback, settle, scr:snapshot(). Real MAME render under the chosen monitor.
-- Env: S_BIN, MONITOR (0|1). Snapshot -> -snapshot_directory.
local BIN=os.getenv("S_BIN"); local MON=tonumber(os.getenv("MONITOR") or "0")
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
-- find + set the Monitor Type config field
local function set_monitor(v)
  for ptag,port in pairs(manager.machine.ioport.ports) do
    for fname,field in pairs(port.fields) do
      if fname=="Monitor Type" then
        field.user_value=v
        print(string.format("[monitor] set '%s' @ %s -> %d (%s)", fname, ptag, v, v==1 and "RGB" or "Composite"))
        return true
      end
    end
  end
  print("[monitor] Monitor Type field NOT FOUND"); return false
end
local st="wait"; local to=0; local set=false
_G._mm=emu.add_machine_frame_notifier(function()
  local fn=scr:frame_number()
  if not set and fn>=2 then set_monitor(MON); set=true end  -- set ONCE, early (before the palette write)
  if st=="wait" and set and fn>=300 and cpu.state["PC"].value>=0x8000 then
    local ex=load(BIN); if ex then cpu.state["PC"].value=ex; st="settle"; to=fn+250 end
  elseif st=="settle" and fn>=to then
    print(string.format("[monitor] screen %dx%d at snapshot", scr.width, scr.height))
    pcall(function() scr:snapshot() end); to=fn+3; st="done"
  elseif st=="done" and fn>=to then                          -- let the PNG flush before exit
    manager.machine:exit()
  end
end)
