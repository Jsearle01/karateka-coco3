-- harness/lib/coco3_capture.lua
-- CoCo3 memory-region capture module for karateka-coco3 P2.0b verification kit.
--
-- Produces JSON files in the IDENTICAL schema to karateka_dissasembly_claude's
-- Apple II capture instrumentation (tools/capture_regions.lua), with only
-- "platform" changed to "coco3". This allows compare.py to read both sides.
--
-- Two trigger types:
--   frame-boundary:  fire when screen:frame_number() reaches target_frame
--   write_tap:       fire when watch_addr is written (at or after min_frame)
--                    Uses space:install_write_tap (MAME 0.237+, no -debug)
--
-- CoCo3-specific notes:
--   - CPU: 6809 at :maincpu (state keys "PC", "A", "B", "X", "Y", "U", "S")
--   - GIME VBL: hardware VBL flag at $FF03 bit 7 (PIA0-B7) or GIME interrupt.
--     For frame-boundary triggers, MAME's screen frame notifier is sufficient
--     (matches the Apple II instrumentation approach). Per-instruction VBL
--     trapping uses write_tap on the engine's page-flip DP register (analogous
--     to the Apple II write_tap on ZP$07).
--   - Memory space: "program" (single unified space, no softswitch banking
--     visible from CPU address space — MMU handled by GIME transparently).
--
-- Usage (from a test script via dofile):
--   _G.COCO3_CAPTURE_OUTPUT_DIR = "captures/"
--   _G.COCO3_CAPTURE_EXIT_FRAME = 500
--   dofile("harness/lib/coco3_capture.lua")
--   local cc = _G.coco3_capture
--   cc.capture_at_frame(400, 0x0000, 0x00FF, "my_dp_capture")
--   cc.capture_at_write_tap(0x0020, 0x0000, 0x00FF, "my_write_capture", 100)
--   cc.install_notifier()
--
-- Output JSON schema (identical to Apple II captures except platform field):
--   { "platform": "coco3",
--     "trigger": {"type": "frame"|"write_tap", "value": N},
--     "region": {"start": "0xXXXX", "end": "0xXXXX"},
--     "frame": N,
--     "bytes": ["0xXX", ...] }
--
-- See verification/README.md for how this fits the P2.0b verification kit.

local M = {}

M.OUTPUT_DIR = _G.COCO3_CAPTURE_OUTPUT_DIR or "captures/"
M.EXIT_FRAME = _G.COCO3_CAPTURE_EXIT_FRAME or 400

M._frame_captures     = {}
M._write_tap_captures = {}

local function ensure_output_dir()
    os.execute('mkdir "' .. M.OUTPUT_DIR:gsub("[/\\]$", "") .. '" 2>nul')
end

local function get_mem()
    return manager.machine.devices[":maincpu"].spaces["program"]
end

local function get_frame()
    local s = manager.machine.screens[":screen"]
    return s and s:frame_number() or 0
end

local function snapshot_region(start_addr, end_addr)
    local mem = get_mem()
    local bytes = {}
    for addr = start_addr, end_addr do
        bytes[#bytes + 1] = mem:read_u8(addr)
    end
    return bytes
end

local function write_capture(name, trigger_type, trigger_value, start_addr, end_addr, frame)
    ensure_output_dir()
    local path = M.OUTPUT_DIR .. name .. ".json"
    local bytes = snapshot_region(start_addr, end_addr)
    local f = io.open(path, "w")
    if not f then
        print("[coco3_capture] ERROR: cannot open " .. path)
        return false
    end
    f:write("{\n")
    f:write('  "platform": "coco3",\n')
    f:write(string.format('  "trigger": {"type": "%s", "value": %d},\n',
        trigger_type, trigger_value))
    f:write(string.format('  "region": {"start": "0x%04X", "end": "0x%04X"},\n',
        start_addr, end_addr))
    f:write(string.format('  "frame": %d,\n', frame))
    f:write('  "bytes": [')
    for i, b in ipairs(bytes) do
        if i > 1 then f:write(", ") end
        f:write(string.format('"0x%02X"', b))
    end
    f:write("]\n}\n")
    f:close()
    print(string.format("[coco3_capture] %s.json  frame=%d  trigger=%s/$%04X  %d bytes",
        name, frame, trigger_type, trigger_value, #bytes))
    return true
end

--- Register a frame-boundary capture.
function M.capture_at_frame(target_frame, start_addr, end_addr, name)
    M._frame_captures[#M._frame_captures + 1] = {
        target = target_frame, start_addr = start_addr,
        end_addr = end_addr, name = name, fired = false,
    }
end

--- Register a write-tap capture.
-- Fires the first time watch_addr is written AT OR AFTER min_frame.
-- No -debug required (space:install_write_tap, MAME 0.237+).
-- min_frame: skip hardware-init writes before engine is running.
--
-- TIMING NOTE (P2.3a.2): MAME Lua write-tap callbacks fire BEFORE the
-- underlying RAM array is updated (the tap intercepts the bus write at
-- the address-decode phase). Reading memory inside the callback returns
-- pre-write values. This module defers the actual memory snapshot to the
-- frame notifier, 1 frame after the tap fires, by which point:
--   (a) the tapped write has committed to RAM, and
--   (b) any subsequent CPU instructions have executed.
function M.capture_at_write_tap(watch_addr, start_addr, end_addr, name, min_frame)
    M._write_tap_captures[#M._write_tap_captures + 1] = {
        watch_addr = watch_addr, start_addr = start_addr,
        end_addr = end_addr, name = name,
        min_frame = min_frame or 0,
        fired = false, pending = false, tap_frame = 0, _tap = nil,
    }
end

--- Install all triggers and the frame notifier.
-- Call once after all capture_at_* registrations.
function M.install_notifier()
    local mem_space = get_mem()

    for _, c in ipairs(M._write_tap_captures) do
        local cap = c
        cap._tap = mem_space:install_write_tap(
            cap.watch_addr, cap.watch_addr,
            "coco3cap_" .. cap.name,
            function(offset, data, mask)
                -- Fire only once, only after min_frame.
                -- Do NOT read memory here: tap fires before RAM commit.
                -- Set pending flag; frame notifier reads 1 frame later.
                if not cap.fired and not cap.pending
                        and get_frame() >= cap.min_frame then
                    cap.pending   = true
                    cap.tap_frame = get_frame()
                    if cap._tap then pcall(function() cap._tap:remove() end) end
                end
            end
        )
        print(string.format("[coco3_capture] write_tap $%04X -> %s (min_frame=%d)",
            cap.watch_addr, cap.name, cap.min_frame or 0))
    end

    _G._coco3_capture_notifier = emu.add_machine_frame_notifier(function()
        local frame = get_frame()

        for _, c in ipairs(M._frame_captures) do
            if not c.fired and frame == c.target then
                c.fired = true
                write_capture(c.name, "frame", frame,
                    c.start_addr, c.end_addr, frame)
            end
        end

        -- Deferred write-tap captures: read 1 frame after tap fired.
        -- (tap fires before RAM commit; this frame notifier fires after commit)
        for _, c in ipairs(M._write_tap_captures) do
            if c.pending and not c.fired and frame > c.tap_frame then
                c.fired   = true
                c.pending = false
                write_capture(c.name, "write_tap", c.watch_addr,
                    c.start_addr, c.end_addr, frame)
            end
        end

        -- Collect unfired for exit logic.
        local unfired = {}
        for _, c in ipairs(M._frame_captures) do
            if not c.fired then unfired[#unfired+1] = c.name end
        end
        for _, c in ipairs(M._write_tap_captures) do
            if not c.fired then unfired[#unfired+1] = c.name end
        end

        local total = #M._frame_captures + #M._write_tap_captures
        local last_target = 0
        for _, c in ipairs(M._frame_captures) do
            if c.target > last_target then last_target = c.target end
        end

        if #unfired == 0 and frame > last_target + 5 then
            print(string.format("[coco3_capture] all captures fired; exit frame=%d  %d/%d",
                frame, total, total))
            manager.machine:exit()
            return
        end

        if frame >= M.EXIT_FRAME then
            if #unfired > 0 then
                print("[coco3_capture] WARNING: unfired at frame "
                    .. frame .. ": " .. table.concat(unfired, ", "))
            end
            print(string.format("[coco3_capture] exit frame=%d  %d/%d captures fired",
                frame, total - #unfired, total))
            manager.machine:exit()
        end
    end)
end

print("[coco3_capture] loaded  OUTPUT_DIR=" .. M.OUTPUT_DIR
    .. "  EXIT_FRAME=" .. M.EXIT_FRAME)

_G.coco3_capture = M
return M
