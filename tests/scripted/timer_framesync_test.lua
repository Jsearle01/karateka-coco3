-- tests/scripted/timer_framesync_test.lua
-- P2.1 timer/frame-sync behavioral test.
--
-- Loads timer_framesync_driver.bin into CoCo3 RAM, executes it,
-- and captures DP state before and after page_flip calls for
-- comparison against Apple II reference captures.
--
-- See tests/scripted/run_timer_framesync_test.sh for invocation.
-- Writes captures to captures/ (relative to MAME CWD).

local LOG_PATH  = "tools/tftest.log"
local PASS_PATH = "tools/tftest_PASS"
local FAIL_PATH = "tools/tftest_FAIL"

local BIN_PATH  = "tests/timer_framesync_driver.bin"
local LOAD_ADDR = 0x0200       -- org address in driver.s
local EXEC_ADDR = 0x0200       -- test_start (same as load addr in DECB)

-- DP region to capture: full DP $00-$00FF
local CAP_START = 0x0000
local CAP_END   = 0x00FF

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[tftest] " .. msg)
end

log("# timer_framesync_test.lua -- " .. os.date())

-- ---------------------------------------------------------------
-- Load the DECB binary: parse the 5-byte block header and load
-- data bytes into CoCo3 RAM. Returns exec address or nil.
-- DECB format: [0x00, lenHI, lenLO, addrHI, addrLO, <bytes...>] ...
--              [0xFF, 00, 00, execHI, execLO]
-- ---------------------------------------------------------------
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
        else
            break
        end
    end
    return exec_addr
end

-- ---------------------------------------------------------------
-- Capture DP $00-$FF and write a JSON file.
-- ---------------------------------------------------------------
local function capture_dp(name, trigger_type, trigger_value, frame, mem)
    local path = "captures/" .. name .. ".json"
    local f = io.open(path, "w")
    if not f then log("ERROR: cannot open " .. path); return false end
    f:write("{\n")
    f:write('  "platform": "coco3",\n')
    f:write(string.format('  "trigger": {"type": "%s", "value": %d},\n',
        trigger_type, trigger_value))
    f:write(string.format('  "region": {"start": "0x%04X", "end": "0x%04X"},\n',
        CAP_START, CAP_END))
    f:write(string.format('  "frame": %d,\n', frame))
    f:write('  "bytes": [')
    for addr = CAP_START, CAP_END do
        if addr > CAP_START then f:write(", ") end
        f:write(string.format('"0x%02X"', mem:read_u8(addr)))
    end
    f:write("]\n}\n")
    f:close()
    log(string.format("capture: %s (frame=%d trigger=%s/%d)", name, frame, trigger_type, trigger_value))
    return true
end

-- ---------------------------------------------------------------
-- Main: wait for BASIC boot, load binary, execute, capture.
-- ---------------------------------------------------------------
local state       = "waiting_boot"
local cpu         = manager.machine.devices[":maincpu"]
local mem         = cpu.spaces["program"]
local captured_pre  = false
local captured_post = false

_G._tftest_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame  = screen:frame_number()
    local pc     = cpu.state["PC"].value

    if state == "waiting_boot" and frame >= 10 then
        -- BASIC is running; load test binary into RAM
        log("frame=" .. frame .. ": loading " .. BIN_PATH)
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR loading binary: " .. tostring(err))
            local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: binary load\n"); f:close() end
            manager.machine:exit(); return
        end
        log(string.format("binary loaded; exec=$%04X", exec))

        -- Capture DP BEFORE execution (initial state)
        capture_dp("p2_1a_coco3_pre_pageflip", "frame", frame, frame, mem)
        captured_pre = true

        -- Set PC to test entry point
        cpu.state["PC"].value = exec

        state = "running"
        log("state -> running; PC set to $" .. string.format("%04X", exec))
    end

    -- After execution: give it 3 frames to run through all 3 page_flip calls,
    -- then capture the settled state (test_loop is a tight BRA loop after the calls)
    if state == "running" and frame >= 15 then
        if not captured_post then
            captured_post = true
            -- Capture DP AFTER 3 page_flip calls
            capture_dp("p2_1a_coco3_post_pageflip", "frame", frame, frame, mem)

            -- Read key DP addresses for quick pass/fail logging
            local page_reg  = mem:read_u8(0x50)
            local page_src  = mem:read_u8(0x51)
            local frame_hi  = mem:read_u8(0x10)
            local frame_lo  = mem:read_u8(0x11)
            log(string.format("DP$50 page_register    = 0x%02X (expect 0x40)", page_reg))
            log(string.format("DP$51 page_source_blit = 0x%02X (expect 0x20)", page_src))
            log(string.format("DP$10/$11 frame_count  = 0x%02X%02X (expect 0x0003)", frame_hi, frame_lo))
            local invariant = page_reg + page_src
            log(string.format("invariant $50+$51 = 0x%02X (expect 0x60)", invariant))

            -- Pass/fail evaluation
            local pass = (page_reg == 0x40 and page_src == 0x20
                          and frame_lo == 0x03 and invariant == 0x60)
            log("")
            if pass then
                log("RESULT: PASS")
                log("  page_register=$40 page_source_blit=$20 invariant=$60 frame_count=3")
                local f = io.open(PASS_PATH, "w"); if f then f:write("PASS\n"); f:close() end
            else
                log("RESULT: FAIL")
                local f = io.open(FAIL_PATH, "w")
                if f then
                    f:write(string.format("FAIL: page_reg=0x%02X page_src=0x%02X fc=%02X%02X inv=0x%02X\n",
                        page_reg, page_src, frame_hi, frame_lo, invariant))
                    f:close()
                end
            end
            log_file:close()
            manager.machine:exit()
        end
    end
end)

log("test harness active; waiting for BASIC boot (frame 10)...")
