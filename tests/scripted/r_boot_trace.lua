-- tests/scripted/r_boot_trace.lua
-- Execution trace for R-boot production binary investigation.
-- Samples PC, CC, memory state at MAME frame boundaries.
-- Key diagnostic targets:
--   $0A00 = hal_vbl_spin (real-VBL path, CC.I=0)
--   $0A07 = hal_vbl_synthetic (N3-beta path, CC.I=1, masked)
--   $010C = dispatch slot ($7E=JMP patched, $3B=RTI stub unpatched)
--   FA_logo1 = Frame A framebuffer at Logo1 anchor (non-zero = blit ran)

dofile("tools/lib/framebuffer_dump.lua")

local LOG_PATH = "tools/rboot_trace.log"
local BIN_PATH = "tests/karateka.bin"

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[trace] " .. msg)
end
log("# r_boot_trace.lua -- " .. os.date())

-- Probe physical RAM region for framebuffer reads
-- (cpu.spaces["program"] reads at $8000+ return ROM, not GIME RAM)
local ram_region = nil
local function probe_regions()
    log("--- Memory region probe ---")
    local ok, regions = pcall(function() return manager.machine.memory.regions end)
    if ok and regions then
        for name, region in pairs(regions) do
            log(string.format("  %-32s size=0x%X", name, region.size))
        end
    end
    -- Try common CoCo3 RAM region names
    for _, try_name in ipairs({":ram", ":maincpu:ram", "ram"}) do
        local r = manager.machine.memory.regions[try_name]
        if r then
            ram_region = r
            log("  RAM region for FB reads: " .. try_name)
            break
        end
    end
    if not ram_region then log("  WARNING: no RAM region found; FA_logo1=n/a") end
    log("--- end probe ---")
end

-- Frame A physical base ($3C page * $2000 = $78000)
-- Logo1 anchor: row=72, col=35 -> offset=5795=$16A3 -> phys=$796A3
local FA_PHYS_BASE = 0x78000
local LOGO1_OFFSET = 72 * 80 + 35  -- = 5795

local function read_fa_logo1()
    if not ram_region then return "n/a" end
    local ok, v = pcall(function()
        return ram_region:read_u8(FA_PHYS_BASE + LOGO1_OFFSET)
    end)
    return ok and string.format("$%02X", v) or "err"
end

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a"); f:close()
    local pos = 1; local exec_addr = nil
    while pos <= #data do
        local bt = string.byte(data, pos)
        if bt == 0x00 then
            local len  = string.byte(data, pos+1) * 256 + string.byte(data, pos+2)
            local addr = string.byte(data, pos+3) * 256 + string.byte(data, pos+4)
            for i = 0, len-1 do
                mem:write_u8(addr + i, string.byte(data, pos+5+i))
            end
            pos = pos + 5 + len
        elseif bt == 0xFF then
            exec_addr = string.byte(data, pos+3) * 256 + string.byte(data, pos+4)
            break
        else break end
    end
    return exec_addr
end

-- C1 applied: HAL_gfx_init upper bound $0736 (not $0754); HAL_gfx_clear $0737-$0754
local function pc_region(pc)
    if pc == 0x0239 then return "BOOT_HALT"
    elseif pc >= 0x0200 and pc <= 0x0238 then return string.format("boot.s:$%04X", pc)
    elseif pc == 0x06CD then return "SYS_PANIC(!)"
    elseif pc >= 0x0697 and pc <= 0x06CC then return string.format("HAL_sys_init:$%04X", pc)
    elseif pc >= 0x06CF and pc <= 0x06DC then return string.format("hal_vbl_handler:$%04X", pc)
    elseif pc >= 0x06DD and pc <= 0x0736 then return string.format("HAL_gfx_init:$%04X", pc)   -- C1 fix
    elseif pc >= 0x0755 and pc <= 0x076C then return string.format("HAL_gfx_present:$%04X", pc)
    elseif pc >= 0x0737 and pc <= 0x0754 then return string.format("HAL_gfx_clear:$%04X", pc)
    elseif pc >= 0x09D8 and pc <= 0x09F7 then return string.format("HAL_time_init:$%04X", pc)
    elseif pc == 0x0A00 then return "hal_vbl_SPIN($0A00)"
    elseif pc >= 0x09F8 and pc <= 0x0A06 then return string.format("HAL_time_vbl_wait:$%04X", pc)
    elseif pc == 0x0A07 then return "hal_vbl_SYNTHETIC($0A07)"
    elseif pc >= 0x0A08 and pc <= 0x0A1A then return string.format("HAL_time_vbl_wait:$%04X", pc)
    elseif pc >= 0x0A1B and pc <= 0x0A27 then return string.format("HAL_time_delay:$%04X", pc)
    elseif pc >= 0x03D1 and pc <= 0x045C then return string.format("broderbund_scene:$%04X", pc)
    else return string.format("$%04X", pc) end
end

local cpu       = manager.machine.devices[":maincpu"]
local mem       = cpu.spaces["program"]

local function log_state(tag, elapsed, pc)
    local cc   = cpu.state["CC"].value
    local flo  = mem:read_u8(0x0011)
    local pg   = mem:read_u8(0x0050)
    local ff9d = mem:read_u8(0xFF9D)
    local d010c= mem:read_u8(0x010C)
    local fa   = read_fa_logo1()
    log(string.format(
        "[%s] e=%3d %s | CC=$%02X I=%d | flo=$%02X pg=$%02X FF9D=$%02X $010C=$%02X FA=%s",
        tag, elapsed, pc_region(pc),
        cc, (cc >> 4) & 1,
        flo, pg, ff9d, d010c, fa))
end

local state      = "waiting_basic"
local load_frame = 0
local prev_region = nil

local vqr_captured_e1  = false
local vqr_captured_e50 = false

local function log_vector_chain(tag, elapsed)
    local function rb(a) return string.format("$%02X", mem:read_u8(a)) end
    local function rb2(a)
        return string.format("$%02X $%02X", mem:read_u8(a), mem:read_u8(a+1))
    end
    log(string.format("--- VECTOR_CHAIN @ e=%d (%s) ---", elapsed, tag))
    log(string.format("  $010C-$010F : %s %s %s %s",
        rb(0x010C), rb(0x010D), rb(0x010E), rb(0x010F)))
    log(string.format("  $FFF8-$FFF9 : %s", rb2(0xFFF8)))
    log(string.format("  $FEF5-$FEF9 : %s %s %s %s %s",
        rb(0xFEF5), rb(0xFEF6), rb(0xFEF7), rb(0xFEF8), rb(0xFEF9)))
    log(string.format(
        "  $06CF-$06DE : %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s",
        rb(0x06CF), rb(0x06D0), rb(0x06D1), rb(0x06D2),
        rb(0x06D3), rb(0x06D4), rb(0x06D5), rb(0x06D6),
        rb(0x06D7), rb(0x06D8), rb(0x06D9), rb(0x06DA),
        rb(0x06DB), rb(0x06DC), rb(0x06DD), rb(0x06DE)))
    -- R-boot sequence bytes: $0220-$023A (27 bytes)
    local rboot = {}
    for i = 0, 26 do rboot[i+1] = rb(0x0220 + i) end
    log("  $0220-$023A : " .. table.concat(rboot, " "))
    -- broderbund_scene entry bytes: $03D1-$03E0 (16 bytes)
    local bscene = {}
    for i = 0, 15 do bscene[i+1] = rb(0x03D1 + i) end
    log("  $03D1-$03E0 : " .. table.concat(bscene, " "))
    log("--- end VECTOR_CHAIN ---")
end

local SAMPLE_AT = {1, 2, 3, 5, 10, 20, 40, 80, 120, 160, 170, 200, 250, 260}
local sampled   = {}

_G._trace_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "loading"
        log(string.format("frame=%d BASIC-ready PC=$%04X", frame, pc))
        probe_regions()
    end

    if state == "loading" then
        local exec, err = load_decb(BIN_PATH, mem)
        if exec then
            load_frame = frame
            cpu.state["PC"].value = exec
            state = "running"
            log(string.format("frame=%d binary loaded exec=$%04X", frame, exec))
        else
            log("ERROR: " .. tostring(err))
            log_file:close(); manager.machine:exit(); return
        end
    end

    if state ~= "running" then return end

    local elapsed = frame - load_frame

    -- One-shot vector chain reads
    if elapsed == 1 and not vqr_captured_e1 then
        log_vector_chain("post-load e=1", elapsed)
        vqr_captured_e1 = true
    end
    if elapsed == 50 and not vqr_captured_e50 then
        log_vector_chain("anomaly-window e=50", elapsed)
        vqr_captured_e50 = true
    end

    -- Log region transitions
    local cur_region = pc_region(pc)
    if cur_region ~= prev_region then
        log_state("TRANSITION", elapsed, pc)
        prev_region = cur_region
    end

    -- Periodic sample points
    if not sampled[elapsed] then
        for _, ep in ipairs(SAMPLE_AT) do
            if elapsed == ep then
                log_state("SAMPLE", elapsed, pc)
                if elapsed == 5 then
                    if pc >= 0x0A00 and pc <= 0x0A06 then
                        log("  *** REAL-VBL spin path (CC.I=0, waiting for interrupt) ***")
                    elseif pc >= 0x0A07 and pc <= 0x0A0F then
                        log("  *** N3-BETA synthetic path (CC.I=1, masked fallback) ***")
                    elseif pc >= 0x06DD and pc <= 0x0736 then
                        log("  *** still in HAL_gfx_init at elapsed=5 ***")
                    end
                end
                sampled[elapsed] = true
                break
            end
        end
    end

    -- Terminal: boot_halt
    if pc == 0x0239 and elapsed >= 3 and not sampled["halt"] then
        sampled["halt"] = true
        log_state("BOOT_HALT", elapsed, pc)
        log("Trace complete: boot_halt reached at elapsed=" .. elapsed)
        log_file:close(); manager.machine:exit()
        state = "done"
    end

    -- Panic detector
    if pc == 0x06CD then
        log_state("SYS_PANIC", elapsed, pc)
    end

    -- Safety exit
    if elapsed >= 310 then
        log_state("SAFETY_EXIT", elapsed, pc)
        log_file:close(); manager.machine:exit()
        state = "done"
    end
end)

log("waiting for BASIC-ready (frame 300+)...")
