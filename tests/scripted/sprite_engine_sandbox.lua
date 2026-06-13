-- tests/scripted/sprite_engine_sandbox.lua
-- R-engine sprite/animation engine sandbox harness.
--
-- Loads sprite_engine_sandbox.bin after BASIC-ready, then VERIFIES THE
-- ENGINE FROM MEMORY (not pixels): samples eng_idx ($32) + page_register
-- ($50) every emulated frame and logs each transition. This proves:
--   P3a (cadence): eng_idx advances once per AKUMA_CADENCE VBLs;
--   P3b (cycle):   eng_idx walks 0..8 and wraps to 0;
--   P3c (flip):    page_register toggles $20<->$40 on each advance.
-- Memory reads are reliable under -nothrottle; pixel MOTION is NOT, so
-- motion fidelity is left to Jay's live (throttled) P4 gate. The two
-- snapshots here are STATIC single-frame captures (P2) only.
--
-- [ref: tests/scripted/visual_smoke_test.lua — harness pattern]
-- [ref: lesson — -nothrottle snapshots misrepresent motion; trust memory + live gate]

local LOG_PATH = "tools/sprite_engine_sandbox.log"
local BIN_PATH = "tests/sprite_engine_trace.bin"   -- auto free-run driver (P2/P3)

local ENG_IDX_ADDR  = 0x0032   -- eng_idx     (globals.s)
local ENG_CADCTR    = 0x0035   -- eng_cadctr  (globals.s)
local PAGE_REG_ADDR = 0x0050   -- page_register (globals.s)

local SNAPSHOT_FRAME_1 = 90
local SNAPSHOT_FRAME_2 = 200
local OBSERVE_FRAMES   = 260    -- ~3 full 9-frame cycles (9*8=72 VBL/cycle)

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[engsandbox] " .. msg)
end
log("# sprite_engine_sandbox.lua -- " .. os.date())

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a"); f:close()
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

local state      = "waiting_basic"
local load_frame = 0
local cpu        = manager.machine.devices[":maincpu"]
local mem        = cpu.spaces["program"]
local shot1_done = false
local shot2_done = false
local last_idx   = -1
local last_advance_frame = -1
local advances   = 0

_G._engsandbox_notifier = emu.add_machine_frame_notifier(function()
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
        log(string.format("frame=%d: binary loaded; exec=$%04X; observing %d frames",
            frame, exec, OBSERVE_FRAMES))
        log("idx,page transitions follow (delta = VBLs since previous advance):")
    end

    if state == "running" then
        local elapsed = frame - load_frame
        local idx  = mem:read_u8(ENG_IDX_ADDR)
        local page = mem:read_u8(PAGE_REG_ADDR)

        if idx ~= last_idx then
            local delta = (last_advance_frame < 0) and 0 or (elapsed - last_advance_frame)
            log(string.format("  elapsed=%3d  eng_idx=%d  page_register=$%02X  delta=%d",
                elapsed, idx, page, delta))
            last_idx = idx
            last_advance_frame = elapsed
            advances = advances + 1
        end

        if not shot1_done and elapsed >= SNAPSHOT_FRAME_1 then
            shot1_done = true
            pcall(function() screen:snapshot() end)
            log(string.format("SNAPSHOT 1 (elapsed=%d): eng_idx=%d page=$%02X (static frame)",
                elapsed, idx, page))
        end
        if not shot2_done and elapsed >= SNAPSHOT_FRAME_2 then
            shot2_done = true
            pcall(function() screen:snapshot() end)
            log(string.format("SNAPSHOT 2 (elapsed=%d): eng_idx=%d page=$%02X (static frame)",
                elapsed, idx, page))
        end

        if elapsed >= OBSERVE_FRAMES then
            log(string.format("OBSERVE COMPLETE: %d frame-advances in %d VBLs", advances, elapsed))
            log("P3 check: deltas should be ~AKUMA_CADENCE(8); eng_idx should cycle 0..8 wrapping;")
            log("          page_register should toggle $20<->$40 each advance.")
            log_file:close()
            manager.machine:exit()
        end
    end
end)

log("harness active; waiting for BASIC-ready state...")
