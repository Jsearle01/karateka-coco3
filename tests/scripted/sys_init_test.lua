-- tests/scripted/sys_init_test.lua
-- P2.3a.0 HAL_sys_init behavioral test.
--
-- Loads sys_init_driver.bin into CoCo3 RAM after BASIC-ready state
-- (frame 300+ PC in ROM; P2.3a.2 boot-context discipline).
-- Installs write-tap on sys_init_cc_mask (DP $13 = CPU $0013).
-- After tap fires, deferred-frame read (+1 frame) captures:
--   DP $00-$1F  (includes sys_init_cc_mask at $13, mmu_pre at $14-$1B)
--   $FFA0-$FFA7 (MMU task 0 post-init values)
--   $0100-$010F (dispatch block RTI stubs)
-- Pass: CC mask = $50 AND all MMU slots = $38-$3F AND RTI stubs = $3B

local LOG_PATH  = "tools/sysinittest.log"
local PASS_PATH = "tools/sysinittest_PASS"
local FAIL_PATH = "tools/sysinittest_FAIL"
local BIN_PATH  = "tests/sys_init_driver.bin"

local CC_MASK_ADDR = 0x0013     -- sys_init_cc_mask (DP $13)

local log_file = io.open(LOG_PATH, "w")
local function log(msg)
    log_file:write(msg .. "\n")
    log_file:flush()
    print("[sysinittest] " .. msg)
end
log("# sys_init_test.lua -- " .. os.date())

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

local state     = "waiting_basic"
local cpu       = manager.machine.devices[":maincpu"]
local mem       = cpu.spaces["program"]
local done      = false
local tap_frame = 0

_G._sysinittest_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "waiting_boot"
        log(string.format("frame=%d: BASIC-ready (PC=$%04X) -- loading binary", frame, pc))
    end

    if state == "waiting_boot" then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            log("ERROR: " .. tostring(err))
            local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: load\n"); f:close() end
            manager.machine:exit(); return
        end
        log(string.format("binary loaded; exec=$%04X", exec))
        cpu.state["PC"].value = exec
        state = "running"

        local tap_ref = {}
        tap_ref[1] = mem:install_write_tap(CC_MASK_ADDR, CC_MASK_ADDR, "sys_init_done",
            function(offset, data, mask)
                if done then return end
                done      = true
                tap_frame = screen:frame_number()
                log(string.format("write_tap fired: $%04X <- $%02X  frame=%d  (reads deferred +1 frame)",
                    CC_MASK_ADDR, data, tap_frame))
                pcall(function() tap_ref[1]:remove() end)
            end
        )
        log("write_tap installed on $0013 (sys_init_cc_mask)")
    end

    -- Deferred capture: 1 frame after tap fired
    if done and tap_frame > 0 and frame > tap_frame then
        tap_frame = -1
        local cap_frame = frame

        pcall(function() screen:snapshot() end)
        log("snapshot taken (frame=" .. cap_frame .. ")")

        -- CC mask state
        local cc_mask = mem:read_u8(0x0013)
        log(string.format("DP$13 sys_init_cc_mask = $%02X (expect $50; bits I=1,F=1)", cc_mask))

        -- MMU pre-state (BASIC's values at $14-$1B)
        log("--- MMU pre-state (BASIC values, DP$14-$1B) ---")
        for i = 0, 7 do
            log(string.format("  DP$%02X mmu_pre_%d = $%02X", 0x14+i, i, mem:read_u8(0x14+i)))
        end

        -- MMU post-state ($FFA0-$FFA7)
        log("--- MMU post-state ($FFA0-$FFA7) ---")
        local mmu_expected = {0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,0x3F}
        local mmu_pass = true
        for i = 0, 7 do
            local addr = 0xFFA0 + i
            local val  = mem:read_u8(addr)
            local exp  = mmu_expected[i+1]
            local ok   = (val == exp) and "OK" or string.format("FAIL(expect $%02X)", exp)
            log(string.format("  $%04X FFA%d = $%02X  %s", addr, i, val, ok))
            if val ~= exp then mmu_pass = false end
        end

        -- Dispatch block RTI stubs ($0100-$010F, every 3rd byte)
        log("--- Dispatch block RTI stubs ---")
        local slots = {
            {0x0100,"swi3"},{0x0103,"swi2"},{0x0106,"swi"},
            {0x0109,"nmi"},{0x010C,"irq"},{0x010F,"firq"}
        }
        local dispatch_pass = true
        for _, s in ipairs(slots) do
            local val = mem:read_u8(s[1])
            local ok  = (val == 0x3B) and "OK(RTI)" or string.format("FAIL(got $%02X,expect $3B)", val)
            log(string.format("  $%04X %s_handler = $%02X  %s", s[1], s[2], val, ok))
            if val ~= 0x3B then dispatch_pass = false end
        end

        -- Pass/fail: check F and I bits set (bits 6 and 4); E bit (bit 7)
        -- may be set from BASIC interrupt handling — not controlled by ORCC #$50
        local cc_pass = ((cc_mask & 0x50) == 0x50)
        local pass = cc_pass and mmu_pass and dispatch_pass
        log("")
        if pass then
            log("RESULT: PASS")
            local pf = io.open(PASS_PATH, "w"); if pf then pf:write("PASS\n"); pf:close() end
        else
            log("RESULT: FAIL")
            local ff = io.open(FAIL_PATH, "w")
            if ff then
                ff:write(string.format("FAIL: cc_mask=$%02X mmu=%s dispatch=%s\n",
                    cc_mask, mmu_pass and "OK" or "FAIL", dispatch_pass and "OK" or "FAIL"))
                ff:close()
            end
        end
        log_file:close()
        manager.machine:exit()
    end

    if frame >= 2000 and not done then
        log("TIMEOUT at frame " .. frame)
        local f = io.open(FAIL_PATH, "w"); if f then f:write("FAIL: timeout\n"); f:close() end
        log_file:close()
        manager.machine:exit()
    end
end)

log("test harness active; waiting for BASIC-ready state (frame 300+ PC in ROM)...")
