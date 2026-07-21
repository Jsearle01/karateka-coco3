-- oracle_fillpath_trace.lua — capture the oracle's PATTERN-FILL path, which the blit-trampoline
-- traces are structurally blind to.
--
-- Why: scene-6 content is drawn by (at least) two mechanisms — cel blits through the $1903/$1906/
-- $1909/$190C trampolines, and PATTERN FILLS through $0A00/$0A03/$0A09/$0A40 (render_pass_a/b).
-- Recon 1 already recorded that the castle "uses the fill path (not the $1903 trampolines), so the
-- trampoline draw trace did not see it". Tapping only the trampolines therefore reports a region as
-- EMPTY when it is in fact filled — which is exactly how the scene-6 walk-off right side looked
-- black-by-omission when only cel blits were captured.
--
-- Captures each fill call with the ZP argument block so the filled region can be reconstructed:
--   $05 col, $06 row, plus $00-$10 (the fill's parameter scratch) and $52 (scroll) / $E1 (gate).
local OUT = os.getenv("F_OUT") or "C:/Projects/karateka_coco3/build/logs/oracle_fillpath.txt"
local FLO = tonumber(os.getenv("F_FLO") or "8580")
local FHI = tonumber(os.getenv("F_FHI") or "8960")
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens:at(1)
local f   = io.open(OUT, "w")
f:write("# fill-path calls: entry, col/row, ZP $00-$10, $52 scroll, $E1 gate\n")

local ENT = { [0x0A00]="A00", [0x0A03]="A03", [0x0A09]="pass_a", [0x0A40]="pass_b" }
local taps = {}
for addr, name in pairs(ENT) do
  taps[#taps+1] = mem:install_read_tap(addr, addr, "f"..name, function()
    local fn = scr:frame_number()
    if fn < FLO or fn > FHI then return end
    local zp = {}
    for a = 0x00, 0x10 do zp[#zp+1] = string.format("%02X", mem:read_u8(a)) end
    f:write(string.format("%-6s col=%02X row=%02X  zp[00-10]=%s  52=%02X E1=%02X  f=%d\n",
      name, mem:read_u8(0x05), mem:read_u8(0x06), table.concat(zp, " "),
      mem:read_u8(0x52), mem:read_u8(0xE1), fn))
    f:flush()
  end)
end
_G._taps = taps                                  -- keep referenced (idioms §2 GC gotcha)
