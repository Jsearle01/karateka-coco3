-- harness/smoke/smoke_test.lua
-- Karateka-coco3 P1.1 smoke test.
--
-- P1.1 check: CoCo3 boots and PC is in ROM range ($8000-$FFFF) by
-- frame 300 (~5s), confirming Color BASIC is running.
-- No game binary exists yet; this validates harness scaffolding only.
--
-- Result files (written to MAME working dir = C:\karateka-capture\):
--   tools/coco3_smoke.log   — per-event log
--   tools/coco3_smoke_PASS  — written on PASS
--   tools/coco3_smoke_FAIL  — written on FAIL
--
-- Invocation (from run_smoke.sh via cmd.exe):
--   mame.exe coco3 -rompath C:\mame\roms -window -nothrottle
--     -seconds_to_run 10 -autoboot_script tools\coco3_smoke_test.lua

local LOG_PATH  = "tools/coco3_smoke.log"
local PASS_PATH = "tools/coco3_smoke_PASS"
local FAIL_PATH = "tools/coco3_smoke_FAIL"

local CHECK_FRAME = 300        -- ~5s at 60fps
local EXIT_FRAME  = 360
local ROM_LOW     = 0x8000
local ROM_HIGH    = 0xFFFF

local log_file = io.open(LOG_PATH, "w")
if not log_file then
    print("[coco3_smoke] ERROR: cannot open " .. LOG_PATH)
    return
end

local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[coco3_smoke] " .. msg)
end

log("# coco3_smoke_test.lua — " .. os.date())
log("# Check: PC in $8000-$FFFF (ROM/BASIC) at frame " .. CHECK_FRAME)
log("#")
log("# frame, pc, event")

local checks_passed = 0
local checks_failed = 0
local snap_frames = {[100]=true, [300]=true}

_G._coco3_smoke_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = manager.machine.devices[":maincpu"].state["PC"].value

    if snap_frames[frame] then
        pcall(function() screen:snapshot() end)
        log(string.format("%d,$%04X,snapshot", frame, pc))
    end

    if frame == CHECK_FRAME then
        if pc >= ROM_LOW and pc <= ROM_HIGH then
            log(string.format("%d,$%04X,PASS pc_in_rom_range ($8000-$FFFF)", frame, pc))
            checks_passed = checks_passed + 1
        else
            log(string.format("%d,$%04X,FAIL unexpected_pc (want $8000-$FFFF)", frame, pc))
            checks_failed = checks_failed + 1
        end
    end

    if frame >= EXIT_FRAME then
        log("")
        log(string.format("# EXIT frame=%d PC=$%04X", frame, pc))
        log(string.format("# checks_passed=%d checks_failed=%d", checks_passed, checks_failed))
        log_file:close()

        if checks_failed == 0 and checks_passed > 0 then
            local f = io.open(PASS_PATH, "w"); if f then f:write("PASS\n"); f:close() end
            print("[coco3_smoke] BOOT TEST: PASS")
        else
            local f = io.open(FAIL_PATH, "w")
            if f then
                f:write(string.format("FAIL: %d failed, %d passed\n", checks_failed, checks_passed))
                f:close()
            end
            print("[coco3_smoke] BOOT TEST: FAIL")
        end

        manager.machine:exit()
    end
end)

print("[coco3_smoke] boot test active -> " .. LOG_PATH)
