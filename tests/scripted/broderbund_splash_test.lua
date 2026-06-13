-- tests/scripted/broderbund_splash_test.lua
-- P2.3a.6 Brøderbund splash visual test harness.
--
-- Loads tests/scripted/broderbund_splash_driver.bin after BASIC-ready
-- state. Displays both Brøderbund logo sprites on CoCo3 screen.
-- Screenshots at elapsed=120. Exits at elapsed=1800.
--
-- Visual predictions (Jay-authoritative):
--   V1: Brøderbund logo visible
--   V2: Two logo elements (Logo 1 upper-narrower, Logo 2 lower-wider)
--   V3: Correct colors (orange, blue, white on black)
--   V4: Approximately correct position (centered, upper-mid screen)
--
-- [ref: plan P2.3a.6-plan-v1 §4 predictions]
-- [ref: docs/methodology.md — screenshot != live display; framebuffer dump is canonical]

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH  = "tools/broderbund_splash_test.log"
local BIN_PATH  = "tests/broderbund_splash_driver.bin"
local OBSERVE   = 200   -- frames to observe (snapshot at elapsed 120; small margin)

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[broderbund_splash] " .. msg)
end
log("# broderbund_splash_test.lua -- " .. os.date())
log("# P2.3a.6 first visible Karateka asset milestone")

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

_G._brod_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: broderbund_splash_driver.bin loaded; exec=$%04X",
            frame, exec))
        log("Jay: watch the MAME window -- Broderbund logos should appear immediately")
    end

    if state == "running" then
        local elapsed = frame - load_frame

        if not shot1 and elapsed >= 120 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
            local ok, path, err = fb_dump_frameA("broderbund_splash_shot001", mem)
            if ok then
                log("DUMP frameA: " .. path)
            else
                log("DUMP ERROR: " .. tostring(err))
            end
        end

        if elapsed >= OBSERVE then
            log(string.format("Observation complete (elapsed=%d)", elapsed))
            log(string.format("  page_register=$%02X", mem:read_u8(0x0050)))
            log_file:close()
            manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready state (frame 300+)...")
