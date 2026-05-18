-- tests/scripted/prod_boot_test.lua
-- P2.3a.3 production boot integration test harness.
--
-- Loads build/karateka.bin (production multi-file binary) after
-- BASIC-ready state. Observes boot sequence and steady-state.
-- Expects: black screen, no crash, per_frame_main_loop running.
-- Screenshots at elapsed=300 and elapsed=600.
-- Exits at elapsed=900.

local LOG_PATH  = "tools/prod_boot_test.log"
local BIN_PATH  = "tests/karateka.bin"
local OBSERVE   = 900

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[prod_boot] " .. msg)
end
log("# prod_boot_test.lua -- " .. os.date())

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

local state     = "waiting_basic"
local load_frame = 0
local cpu       = manager.machine.devices[":maincpu"]
local mem       = cpu.spaces["program"]
local shot1, shot2 = false, false

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
    end

    if state == "running" then
        local elapsed = frame - load_frame
        if not shot1 and elapsed >= 300 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT 1 (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
        end
        if not shot2 and elapsed >= 600 then
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
