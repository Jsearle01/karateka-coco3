-- tests/scripted/presents_test.lua
-- P2.3a.11 "presents" text visual test harness.
--
-- Loads presents_test_driver.bin after BASIC-ready state.
-- Displays "presents" in 8 glyphs at row 110.
-- Screenshot + framebuffer dump at elapsed=120.
--
-- Visual predictions (Jay-authoritative):
--   V1: "presents" text visible on screen
--   V2: All 8 letters visible in order (p-r-e-s-e-n-t-s)
--   V3: Text at approximately row 110, byte cols 30-51
--   V4: White letter strokes with chromatic fringing
--
-- [ref: docs/conventions.md §18 — canonical start_col=119]
-- [ref: docs/conventions.md §19 — border offset formula]
-- [ref: docs/methodology.md — screenshot != live display; framebuffer dump canonical]

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH  = "tools/presents_test.log"
local BIN_PATH  = "tests/presents_test_driver.bin"
local OBSERVE   = 1800  -- frames to observe (~30 seconds at 60fps)

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[presents_test] " .. msg)
end
log("# presents_test.lua -- " .. os.date())
log("# P2.3a.11 presents text visual test")

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a")
    f:close()
    local pos = 1; local exec_addr = nil
    while pos <= #data do
        local block_type = string.byte(data, pos)
        if block_type == 0x00 then
            local len  = string.byte(data, pos+1) * 256 + string.byte(data, pos+2)
            local addr = string.byte(data, pos+3) * 256 + string.byte(data, pos+4)
            for i = 0, len-1 do
                mem:write_u8(addr + i, string.byte(data, pos+5+i))
            end
            pos = pos + 5 + len
        elseif block_type == 0xFF then
            exec_addr = string.byte(data, pos+3) * 256 + string.byte(data, pos+4)
            break
        else break end
    end
    return exec_addr
end

local state      = "waiting_basic"
local load_frame = 0
local cpu        = manager.machine.devices[":maincpu"]
local mem        = cpu.spaces["program"]
local shot1      = false

_G._presents_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "loading"
        log(string.format("frame=%d: BASIC-ready (PC=$%04X)", frame, pc))
    end

    if state == "loading" then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR: " .. tostring(err)); log_file:close()
            manager.machine:exit(); return
        end
        load_frame = frame
        cpu.state["PC"].value = exec
        state = "running"
        log(string.format("frame=%d: presents_test_driver.bin loaded; exec=$%04X", frame, exec))
        log("Jay: watch the MAME window -- 'presents' text should appear at row 110")
        log("  Expected: p-r-e-s-e-n-t-s at byte cols 30,33,35,38,40,42,44,47")
    end

    if state == "running" then
        local elapsed = frame - load_frame

        if not shot1 and elapsed >= 120 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
            local ok, path, err = fb_dump_frameA("presents_shot001", mem)
            if ok then
                log("DUMP frameA: " .. path)
                log("  Expected pixels at rows 110-121 (p=12 rows, others=10 rows)")
                log("  Expected byte cols 30-50 (8 glyphs × ~4 bytes/glyph)")
            else
                log("DUMP ERROR: " .. tostring(err))
            end
        end

        if elapsed >= OBSERVE then
            log(string.format("Observation complete (elapsed=%d)", elapsed))
            log_file:close()
            manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready state (frame 300+)...")
