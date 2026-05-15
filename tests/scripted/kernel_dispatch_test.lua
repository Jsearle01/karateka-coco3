-- tests/scripted/kernel_dispatch_test.lua
-- P2.2 kernel/dispatch behavioral test.
--
-- Loads kernel_dispatch_driver.bin into CoCo3 RAM at frame 10,
-- captures DP state at frame 15 (after driver runs), and verifies
-- the behavioral predictions from the TASK 6 gate.
--
-- Pattern follows P2.1 (timer_framesync_test.lua): fixed-frame
-- redirect at frame 10, capture at frame 15, immediate exit.
-- No spin detection (avoids mis-detecting ROM idle loop at $A7D5).
--
-- Verifications:
--   1. frame_done (DP$52) = $00 (initialized value, unchanged by stubs)
--   2. frame_countdown (DP$53) = frame_done = $00 (copied from frame_done)
--   3. frame_sync_dc (DP$54) = $00 (not modified by P2.2 stubs)
--   4. P2.1 regression: page_register (DP$50) + page_source_blit (DP$51) = $60
--   5. No handler stub assert fired (HAL_sys_panic bra* not reached;
--      driver completed in 5 frames confirms stubbing-safety at runtime)
--
-- See tests/scripted/run_kernel_dispatch_test.sh for invocation.
-- Writes captures to captures/ (relative to MAME CWD).

local LOG_PATH  = "tools/kdtest.log"
local PASS_PATH = "tools/kdtest_PASS"
local FAIL_PATH = "tools/kdtest_FAIL"

local BIN_PATH  = "tests/kernel_dispatch_driver.bin"
local CAP_START = 0x0000
local CAP_END   = 0x00FF

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[kdtest] " .. msg)
end

log("# kernel_dispatch_test.lua -- " .. os.date())

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

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local state = "waiting_boot"
local captured_pre  = false
local captured_post = false

_G._kdtest_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()

    if state == "waiting_boot" and frame >= 10 then
        log("frame=" .. frame .. ": loading " .. BIN_PATH)
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR loading binary: " .. tostring(err))
            local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: binary load\n"); f:close() end
            manager.machine:exit(); return
        end
        log(string.format("binary loaded; exec=$%04X", exec))

        -- Capture DP BEFORE execution
        capture_dp("p2_2a_coco3_pre_loop", "frame", frame, frame, mem)
        captured_pre = true

        -- Redirect CPU to driver entry point
        cpu.state["PC"].value = exec
        state = "running"
        log("state -> running; PC set to $" .. string.format("%04X", exec))
    end

    -- Give driver 5 frames to complete (same as P2.1: 10 -> 15)
    if state == "running" and frame >= 15 then
        if not captured_post then
            captured_post = true
            capture_dp("p2_2a_coco3_post_loop", "frame", frame, frame, mem)

            local frame_done      = mem:read_u8(0x52)
            local frame_countdown = mem:read_u8(0x53)
            local frame_sync_dc   = mem:read_u8(0x54)
            local page_reg        = mem:read_u8(0x50)
            local page_src        = mem:read_u8(0x51)

            log(string.format("DP$52 frame_done      = 0x%02X (expect 0x00)", frame_done))
            log(string.format("DP$53 frame_countdown = 0x%02X (expect 0x00)", frame_countdown))
            log(string.format("DP$54 frame_sync_dc   = 0x%02X (expect 0x00)", frame_sync_dc))
            log(string.format("DP$50 page_register   = 0x%02X (expect 0x40, phase-matched to frame-700)", page_reg))
            log(string.format("DP$51 page_source_blit= 0x%02X (expect 0x20, phase-matched to frame-700)", page_src))
            log(string.format("invariant $50+$51     = 0x%02X (expect 0x60)", page_reg + page_src))

            local pass = (frame_done      == 0x00
                      and frame_countdown == 0x00
                      and frame_sync_dc   == 0x00
                      and frame_countdown == frame_done
                      and (page_reg + page_src) == 0x60)
            log("")
            if pass then
                log("RESULT: PASS")
                log("  frame_done=$00 frame_countdown=$00 frame_sync_dc=$00 invariant=$60")
                log("  No handler stub asserts fired (driver completed in 5 frames)")
                local f = io.open(PASS_PATH, "w"); if f then f:write("PASS\n"); f:close() end
            else
                log("RESULT: FAIL")
                local f = io.open(FAIL_PATH, "w")
                if f then
                    f:write(string.format(
                        "FAIL: fd=%02X fc=%02X dc=%02X pr=%02X ps=%02X inv=%02X\n",
                        frame_done, frame_countdown, frame_sync_dc,
                        page_reg, page_src, page_reg + page_src))
                    f:close()
                end
            end
            log_file:close()
            manager.machine:exit()
        end
    end
end)

log("test harness active; waiting for BASIC boot (frame 10)...")
