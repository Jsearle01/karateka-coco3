-- walltop_overlap.lua  (TRANSIENT — remove after; oracle repo read-only)
-- Resolve the $AA23/$AA31 wall-top overlap: same-frame composite or alternate-frame animation?
-- Read-taps the cel DATA regions (data reads fire on 6502; only opcode-FETCH taps false-0):
--   AA23 data $AA25-$AA30 | AA31 data $AA33-$AA3E | Fuji A948 data $A94A-$A968
-- Logs frame + tag + addr + curpc. Post-process: per-frame co-occurrence + draw order.
-- Clean recipe: -video none -keyboardprovider none.
local cpu = manager.machine.devices[":maincpu"]
local sp  = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local f = io.open("C:/Projects/karateka_coco3/build/logs/wt_overlap.txt","w")

local function mk(lo, hi, tag)
  return sp:install_read_tap(lo, hi, tag, function(offset, data, mask)
    local fn = scr:frame_number()
    if fn >= 5900 and fn <= 6300 then
      local pc = cpu.state["CURPC"].value
      -- only the masked wall-top read loop ($1BDA-$1BF9) matters; Fuji via its std blit
      f:write(string.format("%s f=%d addr=%04X pc=%04X\n", tag, fn, offset, pc))
    end
  end)
end

_G._t1 = mk(0xAA25, 0xAA30, "AA23")
_G._t2 = mk(0xAA33, 0xAA3E, "AA31")
_G._t3 = mk(0xA94A, 0xA968, "FUJI")

_G._n = emu.add_machine_frame_notifier(function()
  if scr:frame_number() > 6305 then f:flush(); f:close(); manager.machine:exit() end
end)
