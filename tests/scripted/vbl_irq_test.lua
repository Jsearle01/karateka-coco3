-- tests/scripted/vbl_irq_test.lua
-- R-vbl VBL IRQ behavioral test.
--
-- Loads vbl_irq_test_driver.bin into CoCo3 at frame 300+ (BASIC ready).
-- Driver opts in to real VBL via andcc #$EF, then spins.
--
-- Verifications (X5 V-* methods):
--   V-mem-read:      P-W1.a ($010C=$7E), P-W1.bc (handler address),
--                    P-W2.a ($FF90=$6C), P-W2.d (frame counter zeroed)
--   V-cc-trace:      P-W2.c (sys_init_cc_mask at DP$13 shows CC.I=1)
--   V-counter-rate:  P-INT.a, P-W4.b (counter ~= 1 per MAME frame)
--   V-monotonic:     P-W5.d (counter non-decreasing)
--
-- Writes PASS/FAIL sentinel and log to tools/.

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH  = "tools/vbltest.log"
local PASS_PATH = "tools/vbltest_PASS"
local FAIL_PATH = "tools/vbltest_FAIL"
local BIN_PATH  = "tests/vbl_irq_test_driver.bin"

local RATE_MEASURE_FRAMES = 60   -- frames to measure counter rate
local MONOTONIC_READS     = 30   -- consecutive frame_count reads for V-monotonic

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[vbltest] " .. msg)
end
log("# vbl_irq_test.lua -- " .. os.date())

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

local cpu        = manager.machine.devices[":maincpu"]
local mem        = cpu.spaces["program"]
local state      = "waiting_basic"
local load_frame = 0
local rate_start_lo  = nil
local rate_start_hi  = nil
local rate_start_frame = nil
local mono_prev_d    = -1
local mono_ok        = true
local mono_count     = 0
local results        = {}

_G._vbltest_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    -- Wait for BASIC ready (frame 300+, PC in ROM)
    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "loading"
        log(string.format("frame=%d: BASIC-ready (PC=$%04X)", frame, pc))
    end

    if state == "loading" then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR: " .. tostring(err))
            local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: binary load\n"); f:close() end
            log_file:close(); manager.machine:exit(); return
        end
        load_frame = frame
        cpu.state["PC"].value = exec
        state = "initializing"
        log(string.format("frame=%d: vbl_irq_test_driver.bin loaded; exec=$%04X", frame, exec))
    end

    -- Allow 2 frames for driver init to complete and counter to be zeroed
    if state == "initializing" then
        local elapsed = frame - load_frame
        if elapsed >= 2 then
            state = "mem_check"
        end
    end

    -- V-mem-read: check memory state after init
    if state == "mem_check" then
        local elapsed = frame - load_frame

        -- P-W1.a: $010C should contain JMP opcode ($7E)
        local b010C = mem:read_u8(0x010C)
        -- P-W1.bc: $010D/$010E = handler address
        local b010D = mem:read_u8(0x010D)
        local b010E = mem:read_u8(0x010E)
        local handler_addr = b010D * 256 + b010E
        -- P-W2.a: $FF90 should be $6C (IEN=1)
        local ff90 = mem:read_u8(0xFF90)
        -- P-W2.d: frame counter should be non-negative (zeroed at init, then advancing)
        local frame_hi = mem:read_u8(0x0010)
        local frame_lo = mem:read_u8(0x0011)
        -- P-W2.c: sys_init_cc_mask at DP$13 ($50 = CC.I+CC.F set by orcc #$50)
        local cc_mask = mem:read_u8(0x0013)

        log(string.format("V-mem-read (elapsed=%d):", elapsed))
        log(string.format("  P-W1.a  $010C=%02X (expect $7E=JMP)", b010C))
        log(string.format("  P-W1.bc $010D/$010E=%02X%02X handler_addr=$%04X", b010D, b010E, handler_addr))
        log(string.format("  P-W2.a  $FF90=%02X (expect $6C)", ff90))
        log(string.format("  P-W2.d  frame_hi=%02X frame_lo=%02X (expect zeroed or small)", frame_hi, frame_lo))
        log(string.format("  P-W2.c  sys_init_cc_mask=$%02X (expect $50 = CC.I+CC.F masked)", cc_mask))

        results.w1a  = (b010C == 0x7E)
        results.w1bc = (handler_addr ~= 0x0000 and handler_addr ~= 0xFFFF)
        -- P-W2.a: $FF90 is write-only on GIME hardware; reading returns bus/status
        -- state, not the written value. Read-back $1B is expected MAME behavior.
        -- Functional proof of IEN=1 comes from V-counter-rate (delta~=N).
        results.w2a_raw  = ff90
        results.w2a      = true   -- informational; not required for PASS
        results.w2c  = ((cc_mask & 0x50) == 0x50)  -- CC.I and CC.F both set
        results.w2d  = (frame_hi == 0x00)           -- counter hi should still be 0

        -- Capture rate_start after V-mem-read
        rate_start_lo    = mem:read_u8(0x0011)
        rate_start_hi    = mem:read_u8(0x0010)
        rate_start_frame = frame
        log(string.format("V-counter-rate start: frame=%d lo=%02X hi=%02X",
            frame, rate_start_lo, rate_start_hi))

        state = "measuring"
    end

    -- V-counter-rate measurement period
    if state == "measuring" then
        local elapsed_since_start = frame - rate_start_frame

        -- V-monotonic: read counter every frame during measurement
        if mono_count < MONOTONIC_READS then
            local hi = mem:read_u8(0x0010)
            local lo = mem:read_u8(0x0011)
            local d  = hi * 256 + lo
            if mono_prev_d >= 0 then
                -- Allow for $FFFF->$0000 wrap
                local diff = (d - mono_prev_d) & 0xFFFF
                if diff > 2 then
                    -- More than 2 advance per frame: unexpected burst
                    log(string.format("  V-monotonic warn: jump of %d at frame %d", diff, frame))
                end
                if d < mono_prev_d and not (mono_prev_d > 0xFFF0 and d < 0x0010) then
                    log(string.format("  V-monotonic FAIL: counter went backward (%04X -> %04X)",
                        mono_prev_d, d))
                    mono_ok = false
                end
            end
            mono_prev_d = d
            mono_count  = mono_count + 1
        end

        if elapsed_since_start >= RATE_MEASURE_FRAMES then
            state = "done"
        end
    end

    if state == "done" then
        local rate_end_lo = mem:read_u8(0x0011)
        local rate_end_hi = mem:read_u8(0x0010)
        local delta = ((rate_end_hi * 256 + rate_end_lo) -
                       (rate_start_hi * 256 + rate_start_lo)) & 0xFFFF

        log(string.format("V-counter-rate end: frame=%d lo=%02X hi=%02X",
            frame, rate_end_lo, rate_end_hi))
        log(string.format("V-counter-rate delta=%d over %d MAME frames",
            delta, RATE_MEASURE_FRAMES))
        log(string.format("  Expected: delta in [%d, %d] (±8%% of %d)",
            RATE_MEASURE_FRAMES - 5, RATE_MEASURE_FRAMES + 5, RATE_MEASURE_FRAMES))

        -- Tolerance: ±5 counts over 60 frames (~8%)
        local rate_lo = RATE_MEASURE_FRAMES - 5
        local rate_hi = RATE_MEASURE_FRAMES + 5
        results.counter_rate = (delta >= rate_lo and delta <= rate_hi)
        results.monotonic    = mono_ok

        log("")
        log("=== Verification summary ===")
        log(string.format("  P-W1.a   $010C=$7E (JMP):           %s", results.w1a  and "PASS" or "FAIL"))
        log(string.format("  P-W1.bc  handler addr non-zero:      %s", results.w1bc and "PASS" or "FAIL"))
        log(string.format("  P-W2.a   $FF90 read=$%02X (write-only; IEN proved by counter-rate): INFO",
            results.w2a_raw))
        log(string.format("  P-W2.c   sys_init_cc CC.I+CC.F set: %s", results.w2c  and "PASS" or "FAIL"))
        log(string.format("  P-W2.d   frame_hi=0 (counter zeroed):%s", results.w2d  and "PASS" or "FAIL"))
        log(string.format("  P-INT.a  counter rate in [%d,%d]:  %s (delta=%d)",
            rate_lo, rate_hi, results.counter_rate and "PASS" or "FAIL", delta))
        log(string.format("  P-W5.d   counter monotonic:          %s (%d reads)",
            results.monotonic and "PASS" or "FAIL", mono_count))

        local all_pass = results.w1a and results.w1bc and results.w2a
                     and results.w2c and results.w2d
                     and results.counter_rate and results.monotonic

        log("")
        if all_pass then
            log("RESULT: PASS")
            local f = io.open(PASS_PATH, "w"); if f then f:write("PASS\n"); f:close() end
        else
            log("RESULT: FAIL")
            local f = io.open(FAIL_PATH, "w")
            if f then f:write("FAIL\n"); f:close() end
        end

        log_file:close()
        manager.machine:exit()
        state = "exited"
    end
end)

log("waiting for BASIC-ready (frame 300+)...")
