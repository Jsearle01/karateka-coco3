-- tests/scripted/broderbund_presents_scene_test.lua
-- Combined Brøderbund splash scene: Logo 2 + Logo 1 + "presents" text.
-- Static display — no delays. Screenshot + framebuffer dump at elapsed=120.

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH = "tools/broderbund_presents_scene_test.log"
local BIN_PATH = "tests/broderbund_presents_scene_driver.bin"
local OBSERVE  = 200   -- frames to observe (snapshot at elapsed 120; small margin)

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[bp_scene_test] " .. msg)
end
log("# broderbund_presents_scene_test.lua -- " .. os.date())
log("# Combined Brøderbund scene: Logo2 + Logo1 + presents")

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

_G._bp_scene_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: broderbund_presents_scene_driver.bin loaded; exec=$%04X",
            frame, exec))
        log("Jay: observe the MAME window --")
        log("  Logo 2 (wordmark): col=26, row=88")
        log("  Logo 1 (badge):    col=35, row=72")
        log("  'presents':        row=110, cols 33-52")
    end

    if state == "running" then
        local elapsed = frame - load_frame

        if not shot1 and elapsed >= 120 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT (elapsed=%d) page_register=$%02X",
                elapsed, mem:read_u8(0x0050)))
            local ok, path, err = fb_dump_frameA("broderbund_presents_scene_shot001", mem)
            if ok then
                log("DUMP frameA: " .. path)
                log("  Logo 1 expected at rows 72-85, cols 35-44")
                log("  Logo 2 expected at rows 88-97, cols 26-42")
                log("  presents expected at rows 110-121, cols 33-52")
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
