-- tests/scripted/prod_boot_test_clean.lua
-- HARNESS 1 (CLEAN): Phase 2 approved state — no supplementary instrumentation.
-- V-counter-rate + screenshots only. Used for reproducibility comparison runs A/B.
--
-- Expected sequence (R-boot):
--   elapsed ~0-160:  Broderbund logos + "presents" visible
--   elapsed ~160-162: screen clears
--   elapsed ~162-242: blank screen (80-frame transition)
--   elapsed ~242+:   halted (bra *); screen remains blank

local LOG_PATH  = "tools/prod_boot_test.log"
local BIN_PATH  = "tests/karateka.bin"
local OBSERVE   = 900

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[prod_boot] " .. msg)
end
log("# prod_boot_test.lua (CLEAN/H1) -- " .. os.date())

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
local shot1, shot2   = false, false
local rate_start_lo  = nil
local rate_logged    = false

_G._prod_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: karateka.bin loaded; exec=$%04X", frame, exec))
        log("Observing for " .. OBSERVE .. " frames -- Jay please watch the screen")
        log("Expected sequence:")
        log("  elapsed ~0-160:  Broderbund logos + 'presents' visible")
        log("  elapsed ~160-162: screen clears")
        log("  elapsed ~162-242: blank screen (80-frame transition)")
        log("  elapsed ~242+:   halted (bra *); screen remains blank")
    end

    if state == "running" then
        local elapsed = frame - load_frame

        -- V-counter-rate start: sample hal_frame_lo at elapsed=20
        if rate_start_lo == nil and elapsed >= 20 then
            rate_start_lo = mem:read_u8(0x0011)
            log(string.format("V-counter-rate start: elapsed=%d hal_frame_lo=$%02X",
                elapsed, rate_start_lo))
        end

        -- Screenshot 1 + V-counter-rate finish at elapsed=80
        if not shot1 and elapsed >= 80 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT 1 (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
            if rate_start_lo ~= nil and not rate_logged then
                rate_logged = true
                local rate_finish = mem:read_u8(0x0011)
                local delta = (rate_finish - rate_start_lo) & 0xFF
                log(string.format(
                    "V-counter-rate: hal_frame_lo start=$%02X finish=$%02X delta=%d (expect ~60)",
                    rate_start_lo, rate_finish, delta))
                if delta >= 55 and delta <= 65 then
                    log("V-counter-rate: PASS (real-VBL active in production)")
                else
                    log(string.format(
                        "V-counter-rate: FAIL (delta=%d outside [55,65])", delta))
                end
            end
        end

        -- Screenshot 2 at elapsed=250
        if not shot2 and elapsed >= 250 then
            shot2 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT 2 (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
        end

        if elapsed >= OBSERVE then
            log(string.format("Observation complete (elapsed=%d)", elapsed))
            log(string.format("  page_register=$%02X frame_done=$%02X",
                mem:read_u8(0x0050), mem:read_u8(0x0052)))
            log_file:close()
            manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready state (frame 300+)...")
