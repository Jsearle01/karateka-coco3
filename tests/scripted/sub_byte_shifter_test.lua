-- tests/scripted/sub_byte_shifter_test.lua
-- P2.4.1 sub-byte shifter unit test harness.
--
-- Loads sub_byte_shifter_test_driver.bin; blits one sprite 4 times
-- at subbytes 0, 1, 2, 3 at byte_col=10, rows 20, 35, 50, 65.
-- Screenshot + framebuffer dump at elapsed=120.
--
-- Expected framebuffer (structural, Clyde-verifiable):
--   rows 20-27, col 10-11: $FF $FF (subbyte=0, 8 white pixels, no overflow)
--   rows 35-42, col 10-12: $3F $FF $C0 (subbyte=1: 3px output, 8px, 1px overflow)
--   rows 50-57, col 10-12: $0F $FF $F0 (subbyte=2: 2px output, 8px, 2px overflow)
--   rows 65-72, col 10-12: $03 $FF $FC (subbyte=3: 1px output, 8px, 3px overflow)
--
-- Visual gate (Jay): 4 horizontal white bands at increasing right offset.
-- [ref: docs/methodology.md — framebuffer dump is structural; visual is Jay's]

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH = "tools/sub_byte_shifter_test.log"
local BIN_PATH = "tests/sub_byte_shifter_test_driver.bin"
local OBSERVE  = 1800

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[sb_shifter] " .. msg)
end
log("# sub_byte_shifter_test.lua -- " .. os.date())
log("# P2.4.1 sub-byte runtime shifter unit test")

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

_G._sb_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame  = screen:frame_number()
    local pc     = cpu.state["PC"].value

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
        log(string.format("frame=%d: sub_byte_shifter_test_driver.bin loaded; exec=$%04X", frame, exec))
        log("Jay: observe 4 white bands at rows 20, 35, 50, 65")
        log("  Each band should be slightly further right than the previous")
        log("  (subbyte=0 leftmost, subbyte=3 rightmost)")
    end

    if state == "running" then
        local elapsed = frame - load_frame
        if not shot1 and elapsed >= 120 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT (elapsed=%d)", elapsed))
            local ok, path, err = fb_dump_frameA("sb_shifter_shot001", mem)
            if ok then
                log("DUMP frameA: " .. path)
                log("  Expected: rows 20-27 bytes10-11=$FF (subbyte=0)")
                log("  Expected: rows 35-42 bytes10-12=$3F/$FF/$C0 (subbyte=1)")
                log("  Expected: rows 50-57 bytes10-12=$0F/$FF/$F0 (subbyte=2)")
                log("  Expected: rows 65-72 bytes10-12=$03/$FF/$FC (subbyte=3)")
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
