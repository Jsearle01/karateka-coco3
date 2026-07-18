-- set_monitor.lua — set ONLY the coco3 "Monitor Type" config (screen_config ioport) and let the machine
-- run. Composes with a real disk boot: `-flop1 <disk> -autoboot_script set_monitor.lua`. Monitor Type is
-- a machine config, NOT a MAME CLI flag, so this is how you pick RGB/Composite from the command line.
-- Env: MONITOR (1=RGB default, 0=Composite). Loads nothing, exits nothing.
local MON = tonumber(os.getenv("MONITOR") or "1")
local set = false
_G._sm = emu.add_machine_frame_notifier(function()
  if not set and manager.machine.screens:at(1):frame_number() >= 2 then
    for _, port in pairs(manager.machine.ioport.ports) do
      for fn, field in pairs(port.fields) do
        if fn == "Monitor Type" then field.user_value = MON end
      end
    end
    print(string.format("[set_monitor] Monitor Type -> %d (%s)", MON, MON == 1 and "RGB" or "Composite"))
    set = true
  end
end)
