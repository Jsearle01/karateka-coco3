-- tests/scripted/visual_smoke_test.lua
-- P2.3a.5 visual smoke test harness.
--
-- Loads visual_smoke_driver.bin after BASIC-ready state (frame 300+).
-- Driver runs FOREVER in draw-flip loop — no natural exit point.
-- Harness takes two screenshots at different frames to capture
-- different buffer states (different square positions).
-- Exits after OBSERVE_FRAMES frames.
--
-- Intentionally runs WITHOUT -nothrottle so Jay can observe
-- real-time animation (alternating squares in MAME window).
-- At CoCo3 1.78 MHz with no VBL sync, the flip loop runs
-- many iterations per frame; visual result is rapid flicker
-- between the two square positions.

local LOG_PATH  = "tools/smoketest.log"
local BIN_PATH  = "tests/visual_smoke_driver.bin"

-- Frames after binary load to take screenshots (to catch different
-- buffer states). At 60fps these are ~5s and ~8s after binary loads.
local SCREENSHOT_FRAME_1 = 600
local SCREENSHOT_FRAME_2 = 900

-- Exit after this many frames from binary load
local OBSERVE_FRAMES = 1200   -- ~20 seconds at 60fps

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[smoketest] " .. msg)
end
log("# visual_smoke_test.lua -- " .. os.date())
log("OBSERVE_FRAMES=" .. OBSERVE_FRAMES ..
    "  SCREENSHOT_FRAMES=" .. SCREENSHOT_FRAME_1 .. "," .. SCREENSHOT_FRAME_2)

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a")
    f:close()
    local pos = 1
    local exec_addr = nil
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
local shot1_done = false
local shot2_done = false

_G._smoketest_notifier = emu.add_machine_frame_notifier(function()
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
            log("ERROR: " .. tostring(err))
            log_file:close()
            manager.machine:exit(); return
        end
        load_frame = frame
        cpu.state["PC"].value = exec
        state = "running"
        log(string.format("frame=%d: binary loaded; exec=$%04X; observing for %d frames",
            frame, exec, OBSERVE_FRAMES))
        log("Jay: observe the MAME window for alternating white squares")
    end

    if state == "running" then
        local elapsed = frame - load_frame

        -- Screenshot 1: capture one buffer state
        if not shot1_done and elapsed >= SCREENSHOT_FRAME_1 then
            shot1_done = true
            pcall(function() screen:snapshot() end)
            local pr = mem:read_u8(0x0050)
            log(string.format("SCREENSHOT 1 (elapsed=%d): page_register=$%02X", elapsed, pr))
        end

        -- Screenshot 2: capture other buffer state
        if not shot2_done and elapsed >= SCREENSHOT_FRAME_2 then
            shot2_done = true
            pcall(function() screen:snapshot() end)
            local pr = mem:read_u8(0x0050)
            log(string.format("SCREENSHOT 2 (elapsed=%d): page_register=$%02X", elapsed, pr))
        end

        -- Exit after observation window
        if elapsed >= OBSERVE_FRAMES then
            local pr = mem:read_u8(0x0050)
            log(string.format("OBSERVE COMPLETE at elapsed=%d: page_register=$%02X", elapsed, pr))
            log("Observation window complete. Jay: report what you saw.")
            log_file:close()
            manager.machine:exit()
        end
    end
end)

log("test harness active; waiting for BASIC-ready state...")
log("NOTE: Running at real speed (no -nothrottle) for visual observation.")
