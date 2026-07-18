-- climb_live.lua — LIVE operator gate for a boot-excluded climb-crawl .bin (S_BIN env).
-- Boots coco3 to BASIC, loads the DECB .bin, sets PC=exec, runs LIVE (no exit) so Jay
-- watches the crawl animate. Windowed: -speed 8 -prescale 3 -resolution 1920x1152 -window -nomax.
-- Three-up gate: run once each for the fallback / variant_a / variant_b .bin.
--
-- Monitor Type is a machine-config ioport (screen_config), NOT a MAME CLI flag, so it can only be set
-- from here: MONITOR=1 (default) = RGB (the standing gate mode); MONITOR=0 = Composite.
local BIN = os.getenv("S_BIN")
local MON = tonumber(os.getenv("MONITOR") or "1")   -- default RGB (matches the RGB default build + CLAUDE.md 4)
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function set_monitor(v)
  for _,port in pairs(manager.machine.ioport.ports) do
    for fn,field in pairs(port.fields) do if fn=="Monitor Type" then field.user_value=v; return end end
  end
end
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
local st = "wait"; local set = false
_G._live = emu.add_machine_frame_notifier(function()
  if not set and scr:frame_number()>=2 then set_monitor(MON); set=true end  -- set before the palette write
  if st=="wait" and scr:frame_number()>=300 and cpu.state["PC"].value>=0x8000 then
    local ex = load(BIN); if ex then cpu.state["PC"].value = ex; st = "run" end
  end
end)
