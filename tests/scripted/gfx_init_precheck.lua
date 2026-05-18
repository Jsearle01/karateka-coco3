-- tests/scripted/gfx_init_precheck.lua
-- §2.2 pre-binary validation for P2.3a remediation attempt 2.
--
-- Purpose: boot CoCo3 to BASIC-ready state WITHOUT loading any
-- binary. Capture DP $00-$FF and MMU task registers FFA0-FFAF
-- to confirm the post-BASIC memory environment is suitable for
-- gfx_init_driver.bin execution.
--
-- Pass criterion: DP $0000-$00FF is NOT all $FF. If BASIC ran and
-- initialized ZP, at least some bytes will differ from $FF.
--
-- BASIC-ready detection: frame >= 300 AND PC in ROM range ($8000-$FFFF).
-- (Smoke test P1.1 confirmed CoCo3 reaches BASIC at frame 300.)
--
-- Invocation (from run_gfx_init_precheck.sh):
--   mame.exe coco3 -rompath C:\mame\roms -window -nothrottle
--     -seconds_to_run 40 -autoboot_script tools\gfx_init_precheck.lua

local LOG_PATH  = "tools/gfxprecheck.log"
local PASS_PATH = "tools/gfxprecheck_PASS"
local FAIL_PATH = "tools/gfxprecheck_FAIL"

local BASIC_FRAME_MIN  = 300
local SAFETY_EXIT_FRAME = 2000

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[gfxprecheck] " .. msg)
end
log("# gfx_init_precheck.lua -- " .. os.date())
log("waiting for BASIC-ready state (frame " .. BASIC_FRAME_MIN ..
    "+ with PC in ROM $8000-$FFFF)...")

local cpu  = manager.machine.devices[":maincpu"]
local mem  = cpu.spaces["program"]
local done = false

_G._gfxprecheck_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    if not done and frame >= BASIC_FRAME_MIN and pc >= 0x8000 then
        done = true
        log(string.format("frame=%d: BASIC-ready (PC=$%04X)", frame, pc))

        -- Screenshot
        pcall(function() screen:snapshot() end)
        log("snapshot taken")

        -- DP $00-$FF hex dump
        log("--- DP $0000-$00FF ---")
        local dp_all_ff = true
        for row = 0, 15 do
            local line = string.format("  $%04X:", row * 16)
            for col = 0, 15 do
                local addr = row * 16 + col
                local b = mem:read_u8(addr)
                if b ~= 0xFF then dp_all_ff = false end
                line = line .. string.format(" %02X", b)
            end
            log(line)
        end

        -- MMU task 0 registers FFA0-FFA7 (the 8 page slots)
        log("--- MMU task 0 registers (FFA0-FFA7) ---")
        for addr = 0xFFA0, 0xFFA7 do
            local slot = addr - 0xFFA0
            local val  = mem:read_u8(addr)
            log(string.format("  FFA%d ($%04X) = $%02X  -> physical $%05X-$%05X",
                slot, addr, val, val * 0x2000, val * 0x2000 + 0x1FFF))
        end

        -- MMU task 1 registers FFA8-FFAF
        log("--- MMU task 1 registers (FFA8-FFAF) ---")
        for addr = 0xFFA8, 0xFFAF do
            log(string.format("  $%04X = $%02X", addr, mem:read_u8(addr)))
        end

        -- $FF91 task select
        log(string.format("--- $FF91 (task select) = $%02X ---", mem:read_u8(0xFF91)))

        -- Key GIME state
        log(string.format("--- $FF90 (INIT0)  = $%02X ---", mem:read_u8(0xFF90)))

        -- Pass/fail
        log("")
        if not dp_all_ff then
            log("RESULT: PASS -- DP not all $FF; BASIC initialized ZP")
            local f = io.open(PASS_PATH, "w")
            if f then f:write("PASS\n"); f:close() end
        else
            log("RESULT: FAIL -- DP all $FF; BASIC did not reach ZP init")
            local f = io.open(FAIL_PATH, "w")
            if f then f:write("FAIL: DP all $FF\n"); f:close() end
        end
        log_file:close()
        manager.machine:exit()
    end

    if not done and frame >= SAFETY_EXIT_FRAME then
        log("TIMEOUT at frame " .. frame)
        local f = io.open(FAIL_PATH, "w")
        if f then f:write("FAIL: timeout (no BASIC-ready state)\n"); f:close() end
        log_file:close()
        manager.machine:exit()
    end
end)
