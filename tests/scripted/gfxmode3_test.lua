-- tests/scripted/gfxmode3_test.lua
-- GFXMODE3 working-reference verification.
-- Loads build/gfxmode3.bin after BASIC-ready state.
-- Jay observes: how many colors? orange? blue?
-- [ref: refs/GFXMODE3.ASM — Jay-authored Nov 2025, "MAME-verified at authorship"]
-- [ref: docs/methodology.md — screenshot != live display; framebuffer dump is canonical]
--
-- Note: GFXMODE3 renders to DRAW_SCREEN=$6000 (displayed) and WORK_SCREEN=$A000.
-- Framebuffer dumps capture the DRAW_SCREEN ($6000-$9FFF) and WORK_SCREEN ($A000-$DBFF).

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH = "tools/gfxmode3_test.log"
local BIN_PATH = "tests/gfxmode3.bin"

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[gfxmode3] " .. msg)
end
log("# gfxmode3_test.lua -- " .. os.date())
log("# GFXMODE3 working-reference verification")

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a")
    f:close()
    local pos = 1; local exec_addr = nil
    while pos <= #data do
        local block_type = string.byte(data, pos)
        if block_type == 0x00 then
            local len  = string.byte(data, pos+1)*256 + string.byte(data, pos+2)
            local addr = string.byte(data, pos+3)*256 + string.byte(data, pos+4)
            for i = 0, len-1 do
                mem:write_u8(addr+i, string.byte(data, pos+5+i))
            end
            pos = pos + 5 + len
        elseif block_type == 0xFF then
            exec_addr = string.byte(data, pos+3)*256 + string.byte(data, pos+4)
            break
        else break end
    end
    return exec_addr
end

local state      = "waiting_basic"
local load_frame = 0
local cpu        = manager.machine.devices[":maincpu"]
local mem        = cpu.spaces["program"]
local shots = {120, 240, 360, 480, 600, 720, 900, 1100}
local shot_idx = 1

_G._gfx3_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: gfxmode3.bin loaded; exec=$%04X", frame, exec))
        log("Jay: observe screen -- how many colors? orange? blue? scrolling text?")
    end

    if state == "running" then
        local elapsed = frame - load_frame
        if shot_idx <= #shots and elapsed >= shots[shot_idx] then
            pcall(function() screen:snapshot() end)
            log(string.format("SCREENSHOT %d (elapsed=%d)", shot_idx, elapsed))
            local prefix = string.format("gfxmode3_shot%03d", shot_idx)
            -- GFXMODE3 draw screen = $6000 (VOFFSET=$EC00); dump as "draw_screen"
            local ok, path, err = fb_dump_frame(prefix, "draw_screen", mem, 0x6000)
            if ok then
                log("DUMP draw_screen: " .. path)
            else
                log("DUMP ERROR: " .. tostring(err))
            end
            shot_idx = shot_idx + 1
        end
        if elapsed >= 1300 then
            log(string.format("Observation complete (elapsed=%d)", elapsed))
            log_file:close()
            manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready state (frame 300+)...")
