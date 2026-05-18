-- tests/scripted/gfx_init_test.lua
-- P2.3a HAL graphics init behavioral test.
--
-- BOOT CONTEXT (remediation attempt 2, 2026-05-16):
--   Binary is loaded AFTER BASIC reaches ready state (frame 300+ with
--   PC in ROM $8000-$FFFF). This ensures post-BASIC MMU and ZP state,
--   matching the environment a real DECB LOADM/EXEC would deliver.
--   Previously used frame 10 (pre-BASIC; identical failure across runs).
--
-- Loads gfx_init_driver.bin into CoCo3 RAM, executes it,
-- waits for HAL_gfx_init to complete (write-tap on gfx_initialized=$12),
-- then captures:
--   - DP $00-$1F (HAL scratch band including gfx_initialized at $12)
--   - Framebuffer sample bytes: $8000, $BBFF, $C000, $FBFF
--   - GIME registers $FF90, $FF98, $FF99, $FF9C, $FF9D, $FF9E, $FF9F,
--     $FFB0-$FFB3, $FFD9, $FFDF (observability probe)
--   - MMU task registers $FFA0-$FFAF (diagnostic)
-- Produces:
--   captures/p2_3a_coco3_gfx_init.json  (DP + FB samples; compare.py input)
--   tools/gfxtest.log                   (GIME register probe results)
--   tools/gfxtest_PASS or _FAIL

local LOG_PATH  = "tools/gfxtest.log"
local PASS_PATH = "tools/gfxtest_PASS"
local FAIL_PATH = "tools/gfxtest_FAIL"
local BIN_PATH  = "tests/gfx_init_driver.bin"

local GFX_INITIALIZED_DP = 0x0012  -- gfx_initialized flag
local PAGE_REG_DP = 0x0050          -- page_register
local FB_A_BASE  = 0x8000
local FB_A_TAIL  = 0xBBFF
local FB_B_BASE  = 0xC000
local FB_B_TAIL  = 0xFBFF

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[gfxtest] " .. msg)
end
log("# gfx_init_test.lua -- " .. os.date())

-- DECB binary loader (same pattern as timer_framesync_test.lua)
local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a")
    f:close()
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

-- Write compare.py-compatible CoCo3 capture JSON
-- Captures DP $00-$1F PLUS individual FB sample bytes via multi-region hack:
-- we write a single JSON covering $0000-$00FF for DP, plus extra fields for
-- frame buffer samples (compare.py can only read one region, so we insert
-- the FB bytes into a DP-region capture at offsets that don't exist in DP,
-- using a wider region $0000-$FBFF is not practical). Instead, we write two
-- separate capture files:
--   p2_3a_coco3_dp.json      : $0000-$00FF  (DP)
--   p2_3a_coco3_fb_a.json    : $8000-$8000  (Frame A base sample, 1 byte)
--   p2_3a_coco3_fb_a_tail.json: $BBFF-$BBFF
--   p2_3a_coco3_fb_b.json    : $C000-$C000
--   p2_3a_coco3_fb_b_tail.json: $FBFF-$FBFF
local function write_capture(name, start_addr, end_addr, mem, frame)
    os.execute('mkdir "captures" 2>nul')
    local path = "captures/" .. name .. ".json"
    local f = io.open(path, "w")
    if not f then log("ERROR: cannot write " .. path); return end
    local bytes = {}
    for a = start_addr, end_addr do
        bytes[#bytes+1] = mem:read_u8(a)
    end
    f:write("{\n")
    f:write('  "platform": "coco3",\n')
    f:write(string.format('  "trigger": {"type": "write_tap", "value": %d},\n', GFX_INITIALIZED_DP))
    f:write(string.format('  "region": {"start": "0x%04X", "end": "0x%04X"},\n', start_addr, end_addr))
    f:write(string.format('  "frame": %d,\n', frame))
    f:write('  "bytes": [')
    for i, b in ipairs(bytes) do
        if i > 1 then f:write(", ") end
        f:write(string.format('"0x%02X"', b))
    end
    f:write("]\n}\n")
    f:close()
    log(string.format("  capture: %s  region=$%04X-$%04X  %d bytes", name, start_addr, end_addr, #bytes))
end

local state     = "waiting_basic"
local cpu       = manager.machine.devices[":maincpu"]
local mem       = cpu.spaces["program"]
local done      = false
local tap_frame = 0    -- frame when write-tap fired; reads deferred to frame+1

_G._gfxtest_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    -- Wait for BASIC-ready: frame >= 300 AND PC in ROM ($8000-$FFFF).
    -- Smoke test P1.1 confirmed CoCo3 reaches BASIC at frame 300.
    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "waiting_boot"
        log(string.format("frame=%d: BASIC-ready (PC=$%04X) -- loading binary", frame, pc))
    end

    if state == "waiting_boot" then
        log("frame=" .. frame .. ": loading " .. BIN_PATH)
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR: " .. tostring(err))
            local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: binary load\n"); f:close() end
            manager.machine:exit(); return
        end
        log(string.format("binary loaded; exec=$%04X", exec))
        cpu.state["PC"].value = exec
        state = "running"

        -- Install write-tap on gfx_initialized (DP $12) to fire when HAL_gfx_init completes.
        -- gfx_initialized is at CPU address $0012.
        local tap_ref = {}
        tap_ref[1] = mem:install_write_tap(0x0012, 0x0012, "gfx_init_done",
            function(offset, data, mask)
                -- MAME Lua write-tap fires BEFORE RAM commit (bus-intercept,
                -- not post-write notification). Reading $0012 here would return
                -- the pre-write value. Set tap_frame flag only; the frame
                -- notifier reads all state 1 frame later after commit.
                if done then return end
                done      = true
                tap_frame = screen:frame_number()
                log(string.format("write_tap fired: $0012 <- $%02X  frame=%d  (reads deferred +1 frame)",
                    data, tap_frame))
                pcall(function() tap_ref[1]:remove() end)
            end
        )
        log("write_tap installed on $0012 (gfx_initialized)")
    end

    -- Deferred capture: 1 frame after write-tap fired.
    -- At this point: $0012 write committed; post-init driver code has run
    -- (page_register=$20 written, HAL_gfx_clear completed, spin loop entered).
    if done and tap_frame > 0 and frame > tap_frame then
        tap_frame = -1   -- one-shot: prevent re-entry on subsequent frames
        local cap_frame = frame

        pcall(function() screen:snapshot() end)
        log("snapshot taken (deferred +1 frame, frame=" .. cap_frame .. ")")

        log("--- GIME register read-back probe ---")
        local gime_regs = {
            {0xFF90, "FF90 (INIT0)"},
            {0xFF98, "FF98 (VMODE)"},
            {0xFF99, "FF99 (VRES)"},
            {0xFF9C, "FF9C (VSCROL)"},
            {0xFF9D, "FF9D (VOFFSET_HI)"},
            {0xFF9E, "FF9E (VOFFSET_LO)"},
            {0xFF9F, "FF9F (HOFFSET)"},
            {0xFFB0, "FFB0 (PAL0)"},
            {0xFFB1, "FFB1 (PAL1)"},
            {0xFFB2, "FFB2 (PAL2)"},
            {0xFFB3, "FFB3 (PAL3)"},
            {0xFFD9, "FFD9 (SAM CLK)"},
            {0xFFDF, "FFDF (SAM RAM)"},
        }
        local exp = {}
        exp[0xFF90]=0x4C; exp[0xFF98]=0x80; exp[0xFF99]=0x15
        exp[0xFF9C]=0x00; exp[0xFF9D]=0xF8; exp[0xFF9E]=0x00; exp[0xFF9F]=0x00
        exp[0xFFB0]=0x00; exp[0xFFB1]=0x26; exp[0xFFB2]=0x1B; exp[0xFFB3]=0xFF
        exp[0xFFD9]=0x00; exp[0xFFDF]=0x00
        for _, r in ipairs(gime_regs) do
            local addr, rname = r[1], r[2]
            local val = mem:read_u8(addr)
            local e = exp[addr]
            local match = (val == e) and "MATCHES_WRITTEN" or
                          (val == 0xFF and "OPEN_BUS($FF)") or
                          (val == 0x00 and "READS_ZERO") or
                          string.format("READS_$%02X(unexpected)", val)
            log(string.format("  $%04X %-20s  wrote=$%02X  readback=$%02X  %s",
                addr, rname, e, val, match))
        end
        log("--- end probe ---")

        log("--- MMU task 0 registers (FFA0-FFA7) ---")
        for addr = 0xFFA0, 0xFFA7 do
            local slot = addr - 0xFFA0
            local val  = mem:read_u8(addr)
            log(string.format("  FFA%d ($%04X) = $%02X -> physical $%05X",
                slot, addr, val, val * 0x2000))
        end
        log(string.format("--- $FF91 (task select) = $%02X ---", mem:read_u8(0xFF91)))

        local gfx_init_val = mem:read_u8(0x0012)
        local page_reg_val = mem:read_u8(0x0050)
        local frame_hi     = mem:read_u8(0x0010)
        local frame_lo     = mem:read_u8(0x0011)
        log(string.format("DP$12 gfx_initialized = $%02X (expect $01)", gfx_init_val))
        log(string.format("DP$50 page_register   = $%02X (expect $20)", page_reg_val))
        log(string.format("DP$10/$11 frame_count = $%02X%02X (expect $0000)", frame_hi, frame_lo))

        local fa0    = mem:read_u8(FB_A_BASE)
        local fatail = mem:read_u8(FB_A_TAIL)
        local fb0    = mem:read_u8(FB_B_BASE)
        local fbtail = mem:read_u8(FB_B_TAIL)
        log(string.format("$8000 (Frame A base)  = $%02X (expect $00)", fa0))
        log(string.format("$BBFF (Frame A tail)  = $%02X (expect $00)", fatail))
        log(string.format("$C000 (Frame B base)  = $%02X (expect $00)", fb0))
        log(string.format("$FBFF (Frame B tail)  = $%02X (expect $00)", fbtail))

        write_capture("p2_3a_coco3_dp",         0x0000, 0x00FF, mem, cap_frame)
        write_capture("p2_3a_coco3_fb_a_base",  0x8000, 0x8000, mem, cap_frame)
        write_capture("p2_3a_coco3_fb_a_tail",  0xBBFF, 0xBBFF, mem, cap_frame)
        write_capture("p2_3a_coco3_fb_b_base",  0xC000, 0xC000, mem, cap_frame)
        write_capture("p2_3a_coco3_fb_b_tail",  0xFBFF, 0xFBFF, mem, cap_frame)

        local pass = (gfx_init_val == 0x01
            and page_reg_val == 0x20
            and fa0 == 0x00 and fatail == 0x00
            and fb0 == 0x00 and fbtail == 0x00)
        log("")
        if pass then
            log("RESULT: PASS")
            local pf = io.open(PASS_PATH, "w"); if pf then pf:write("PASS\n"); pf:close() end
        else
            log("RESULT: FAIL")
            local ff = io.open(FAIL_PATH, "w")
            if ff then
                ff:write(string.format(
                    "FAIL: gfx_init=$%02X page_reg=$%02X fa0=$%02X fatail=$%02X fb0=$%02X fbtail=$%02X\n",
                    gfx_init_val, page_reg_val, fa0, fatail, fb0, fbtail))
                ff:close()
            end
        end
        log_file:close()
        manager.machine:exit()
    end

    -- Safety exit (2000 frames: BASIC boot ~300f + binary execution time)
    if frame >= 2000 and not done then
        log("TIMEOUT at frame " .. frame)
        local ff = io.open(FAIL_PATH, "w"); if ff then ff:write("FAIL: timeout\n"); ff:close() end
        log_file:close()
        manager.machine:exit()
    end
end)

log("test harness active; waiting for BASIC-ready state (frame 300+ PC in ROM)...")
