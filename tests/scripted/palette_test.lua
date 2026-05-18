-- tests/scripted/palette_test.lua
-- P2.3a.6-followup-2 palette diagnostic — 4-band color test.
--
-- Loads palette_test_driver.bin after BASIC-ready state.
-- Driver displays 4 horizontal bands each filled with a single
-- palette index:
--   Band 0 (rows   0-47):  index 0 ($FFB0=$00) → expected black
--   Band 1 (rows  48-95):  index 1 ($FFB1=$26) → expected orange
--   Band 2 (rows 96-143):  index 2 ($FFB2=$1B) → expected blue
--   Band 3 (rows 144-191): index 3 ($FFB3=$3F) → expected white
--
-- Jay observes what each band renders as on screen.
-- Framebuffer dump validates byte content independently of screenshot.
-- [ref: docs/methodology.md — screenshot != live display; framebuffer dump is canonical]

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH  = "tools/palette_test.log"
local BIN_PATH  = "tests/palette_test_driver.bin"

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[palette_test] " .. msg)
end
log("# palette_test.lua -- " .. os.date())
log("# 4-band palette diagnostic test")

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

_G._pal_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: palette_test_driver.bin loaded; exec=$%04X", frame, exec))
        log("Jay: observe 4 horizontal bands on screen.")
        log("  Band 0 (top quarter):    index 0 / $FFB1=$00 → expected BLACK")
        log("  Band 1 (2nd quarter):    index 1 / $FFB1=$2C → what color?")
        log("  Band 2 (3rd quarter):    index 2 / $FFB2=$03 → what color?")
        log("  Band 3 (bottom quarter): index 3 / $FFB3=$3F → expected WHITE")
    end

    if state == "running" then
        local elapsed = frame - load_frame
        if not shot1 and elapsed >= 120 then
            shot1 = true
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT (elapsed=%d)", elapsed))
            local ok, path, err = fb_dump_frameA("palette_test_shot001", mem)
            if ok then
                log("DUMP frameA: " .. path)
            else
                log("DUMP ERROR: " .. tostring(err))
            end
        end
        if elapsed >= 1800 then
            log("Observation complete.")
            log_file:close()
            manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready state (frame 300+)...")
