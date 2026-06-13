-- tests/scripted/r_p24_input_break.lua
-- R-p24 AC-8 trace: inject a keypress mid-hold via a $FF00 (PIA0 PDRA)
-- read tap, confirm HAL_input_poll detects it through the DATA register,
-- early-breaks the hold, and sets the game-start flags ($60/$61 = $01).
--
-- Injection: from elapsed>=60, force the $FF00 read to pull row 0 low
-- (data & 0xFE) — simulating a pressed key/button in the matrix scan.
-- Expect: polls stop far below 240; intro_input_flag/$aux = $01; halt.

local LOG_PATH = "tools/r_p24_input_break.log"
local BIN_PATH = "tests/karateka.bin"
local OBSERVE  = 400
local INJECT_AT = 60

local log_file = io.open(LOG_PATH, "w")
local function log(m) log_file:write(m.."\n"); log_file:flush(); print("[r_p24_inp] "..m) end
log("# r_p24_input_break.lua -- "..os.date())

local function load_decb(path, mem)
    local f = io.open(path, "rb"); if not f then return nil, "open fail "..path end
    local data = f:read("*a"); f:close()
    local pos = 1; local exec = nil
    while pos <= #data do
        local bt = string.byte(data, pos)
        if bt == 0x00 then
            local len  = string.byte(data,pos+1)*256 + string.byte(data,pos+2)
            local addr = string.byte(data,pos+3)*256 + string.byte(data,pos+4)
            for i=0,len-1 do mem:write_u8(addr+i, string.byte(data,pos+5+i)) end
            pos = pos + 5 + len
        elseif bt == 0xFF then
            exec = string.byte(data,pos+3)*256 + string.byte(data,pos+4); break
        else break end
    end
    return exec
end

local cpu   = manager.machine.devices[":maincpu"]
local mem   = cpu.spaces["program"]
local state = "waiting_basic"
local load_frame = 0
local poll_count = 0
local inject = false
local taps_done = false
local detected_logged = false

_G._rp24i_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]; if not screen then return end
    local frame = screen:frame_number()
    local pc = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then state = "loading" end
    if state == "loading" then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then log("ERR "..tostring(err)); log_file:close(); manager.machine:exit(); return end
        if not taps_done then
            -- poll counter
            mem:install_read_tap(0x0A86, 0x0A86, "rp24i_poll",
                function() poll_count = poll_count + 1 end)
            -- keypress injector on PIA0 PDRA ($FF00): pull row 0 low when armed
            mem:install_read_tap(0xFF00, 0xFF00, "rp24i_kbd",
                function(offset, data, mask)
                    if inject then return data & 0xFE end
                end)
            taps_done = true
        end
        load_frame = frame; cpu.state["PC"].value = exec; state = "running"
        log(string.format("frame=%d: loaded exec=$%04X; taps armed (inject at elapsed %d)", frame, exec, INJECT_AT))
    end

    if state == "running" then
        local elapsed = frame - load_frame
        if not inject and elapsed >= INJECT_AT then
            inject = true
            log(string.format("elapsed=%d: INJECT armed ($FF00 row0 forced low), polls so far=%d", elapsed, poll_count))
        end
        if inject and not detected_logged then
            local f86 = mem:read_u8(0x0060)
            local f4f = mem:read_u8(0x0061)
            if f86 == 0x01 and f4f == 0x01 then
                detected_logged = true
                log(string.format("DETECTED at elapsed=%d: intro_input_flag($60)=$%02X intro_inputaux($61)=$%02X polls=%d PC=$%04X",
                    elapsed, f86, f4f, poll_count, cpu.state["PC"].value))
                if poll_count < 200 then
                    log("AC-8: PASS (press detected via $FF00 data read; flags set; hold early-broke before 240)")
                else
                    log("AC-8: REVIEW (flags set but poll_count high — early break unclear)")
                end
            end
        end
        if elapsed >= OBSERVE then
            if not detected_logged then
                log(string.format("AC-8: FAIL — no detection. flags $60=$%02X $61=$%02X polls=%d PC=$%04X",
                    mem:read_u8(0x0060), mem:read_u8(0x0061), poll_count, cpu.state["PC"].value))
            end
            log_file:close(); manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready (frame 300+)...")
