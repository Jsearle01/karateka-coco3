-- diag_sprite_ptr.lua — diagnose where the sprite-source pointer lives + when
-- scene 5 is on screen. Polls $03/$04 and $1B/$1C each frame, counts raw write
-- taps on the whole zero page, and snapshots at several frames.

local OUT = "C:\\karateka-capture\\tools\\diag_sprite_ptr.log"
local out = io.open(OUT, "w")
local function log(s) out:write(s .. "\n"); out:flush() end

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local function frame()
    local s = manager.machine.screens[":screen"]
    return s and s:frame_number() or -1
end

-- raw counters: how many writes hit ZP $00-$1F and $03/$04 specifically
local zp_writes, p34_writes = 0, 0
pcall(function()
    mem:install_write_tap(0x0000, 0x001F, "zp", function(off, data)
        zp_writes = zp_writes + 1
        if off == 0x03 or off == 0x04 then p34_writes = p34_writes + 1 end
    end)
end)

local seen34, seen1b = {}, {}
local SHOTS = {2000, 3500, 4200, 5000, 6000, 7000}
local shot_done = {}

_G._diag = emu.add_machine_frame_notifier(function()
    local f = frame()
    local p34 = mem:read_u8(0x04) * 256 + mem:read_u8(0x03)
    local p1b = mem:read_u8(0x1C) * 256 + mem:read_u8(0x1B)
    if p34 >= 0x0400 and not seen34[p34] then
        seen34[p34] = f
        log(string.format("$03/$04=$%04X first@frame %d ($3D=$%02X)", p34, f, mem:read_u8(0x3D)))
    end
    if p1b >= 0x0400 and not seen1b[p1b] then
        seen1b[p1b] = f
        log(string.format("$1B/$1C=$%04X first@frame %d", p1b, f))
    end
    for _, sf in ipairs(SHOTS) do
        if not shot_done[sf] and f >= sf then
            shot_done[sf] = true
            pcall(function() manager.machine.screens[":screen"]:snapshot() end)
            log(string.format("SNAPSHOT @frame %d  $03/$04=$%04X $1B/$1C=$%04X $3D=$%02X",
                f, p34, p1b, mem:read_u8(0x3D)))
        end
    end
    if f >= 7200 then
        log("")
        log(string.format("zp_writes(total $00-$1F)=%d  p34_writes($03/$04)=%d", zp_writes, p34_writes))
        out:close()
        manager.machine:exit()
    end
end)

log("# diag_sprite_ptr.lua -- " .. os.date())
