-- tests/scripted/trace_scene5_sprites.lua
--
-- Instrument apple2e Karateka and trace WHERE sprites are pulled from across
-- the whole attract run (so scene 5 / imprisonment -> climbing is captured),
-- EMPIRICALLY — no inference.
--
-- Method: the sprite descriptor pointer is ZP $03/$04 (lo/hi) — the "sprite
-- source" (docs/differential-analysis.md; d05=$9858, d06=$9980). A memory
-- WRITE TAP on $0003-$0004 fires on every assignment of that pointer (no
-- -debug, reliable, unlike the debugger `do`-action path). Each distinct
-- sprite-source address is logged with its first/last frame + hit count, so
-- the frame timeline reveals scene boundaries (scene 5 imprisonment sprites
-- appear ~frame 4000-6000; the climbing scene's $A3xx-$A6xx sprites mark the
-- imprisonment->climbing boundary).
--
-- Run (NO -debug needed):
--   cd /d C:\karateka-capture
--   C:\mame\mame.exe apple2e -rompath C:\mame\roms -window -nothrottle \
--       -seconds_to_run 170 \
--       -flop1 C:\Projects\karateka_dissasembly_claude\dumps\karateka.dsk \
--       -autoboot_script C:\Projects\karateka_coco3\tests\scripted\trace_scene5_sprites.lua

local OUT        = "C:\\karateka-capture\\tools\\scene5_sprite_trace.log"
local EXIT_FRAME = 8000          -- whole attract: scenes 1-4 + scene5 + climbing(+)

local out = io.open(OUT, "w")
local function log(s) out:write(s .. "\n"); out:flush() end

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local function frame()
    local s = manager.machine.screens[":screen"]
    return s and s:frame_number() or -1
end

local seen  = {}     -- addr -> {first,last,count}
local order = {}
local taps  = {}

local function note(addr)
    -- ignore zero-page / low garbage; sprite data lives at >= $0400
    if addr < 0x0400 then return end
    local f = frame()
    local e = seen[addr]
    if not e then
        e = { first = f, last = f, count = 0 }
        seen[addr] = e
        order[#order + 1] = addr
        log(string.format("NEW  src=$%04X  frame=%d", addr, f))
    end
    e.last = f
    e.count = e.count + 1
end

-- write tap on $03 and $04: compute the full pointer using the just-written
-- byte (`data`) for the tapped address and memory for the companion byte.
local ok3, t3 = pcall(function()
    return mem:install_write_tap(0x0003, 0x0003, "src_lo", function(offset, data)
        note(mem:read_u8(0x04) * 256 + (data & 0xFF))
    end)
end)
local ok4, t4 = pcall(function()
    return mem:install_write_tap(0x0004, 0x0004, "src_hi", function(offset, data)
        note((data & 0xFF) * 256 + mem:read_u8(0x03))
    end)
end)
taps[1], taps[2] = t3, t4

local function dump_and_exit(reason)
    log("")
    log("=== SUMMARY (" .. reason .. ") — distinct $03/$04 sprite sources ===")
    log(string.format("distinct=%d", #order))
    table.sort(order)
    for _, a in ipairs(order) do
        local e = seen[a]
        log(string.format("$%04X  first=%d  last=%d  x%d", a, e.first, e.last, e.count))
    end
    out:close()
    manager.machine:exit()
end

_G._trace_notifier = emu.add_machine_frame_notifier(function()
    if frame() >= EXIT_FRAME then dump_and_exit("frame cap") end
end)

log("# trace_scene5_sprites.lua -- " .. os.date())
log(string.format("write-tap install: $03 ok=%s  $04 ok=%s", tostring(ok3), tostring(ok4)))
if not (ok3 and ok4) then
    log("WARNING: install_write_tap unavailable in this MAME — tap-based trace will be empty.")
end
log("tracing $03/$04 sprite-source writes through frame " .. EXIT_FRAME .. " ...")
