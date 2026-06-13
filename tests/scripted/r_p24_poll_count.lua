-- tests/scripted/r_p24_poll_count.lua
-- R-p24 AC-7 / AC-9 trace: count HAL_input_poll executions across the
-- scene-1 holds (no input) and confirm once-per-frame + 160+80 total.
--
-- Method: read-tap on $0A86 (HAL_input_poll opcode fetch) counts every
-- call (instruction-level — per-frame Lua cannot observe sub-frame).
-- Expect: ~1 poll/frame during the holds; total ~240 (=160+80) at halt.
--
-- Symbols (from lwasm listing, production karateka.bin):
--   HAL_input_poll = $0A86   scene1_hold_poll = $024B   boot_halt = $0249
--   intro_input_flag = $60   intro_inputaux_flag = $61   hal_frame_lo = $11

local LOG_PATH = "tools/r_p24_poll_count.log"
local BIN_PATH = "tests/karateka.bin"
local OBSERVE  = 400

local log_file = io.open(LOG_PATH, "w")
local function log(m) log_file:write(m.."\n"); log_file:flush(); print("[r_p24_poll] "..m) end
log("# r_p24_poll_count.lua -- "..os.date())

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
local load_frame, run_frame = 0, 0
local poll_count = 0
local first_poll_frame = nil
local tap_installed = false
local halt_logged = false

_G._rp24_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]; if not screen then return end
    local frame = screen:frame_number()
    local pc = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        state = "loading"
    end
    if state == "loading" then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then log("ERR "..tostring(err)); log_file:close(); manager.machine:exit(); return end
        -- install poll counter tap once the binary is in place
        if not tap_installed then
            mem:install_read_tap(0x0A86, 0x0A86, "rp24_pollcount",
                function(offset, data, mask)
                    poll_count = poll_count + 1
                    if first_poll_frame == nil then first_poll_frame = "pending" end
                end)
            tap_installed = true
        end
        load_frame = frame; cpu.state["PC"].value = exec; state = "running"
        log(string.format("frame=%d: karateka.bin loaded exec=$%04X; tap@$0A86 armed", frame, exec))
    end

    if state == "running" then
        local elapsed = frame - load_frame
        -- record the frame at which polling first begins
        if first_poll_frame == "pending" then first_poll_frame = elapsed end
        -- per-checkpoint poll snapshot
        if elapsed == 40 or elapsed == 80 or elapsed == 120 or elapsed == 160
           or elapsed == 200 or elapsed == 240 or elapsed == 280 then
            log(string.format("elapsed=%3d  polls=%3d  PC=$%04X  page=$%02X  frame_lo=$%02X",
                elapsed, poll_count, cpu.state["PC"].value, mem:read_u8(0x0050), mem:read_u8(0x0011)))
        end
        -- halt detection: PC parked at boot_halt ($0249)
        if not halt_logged and cpu.state["PC"].value == 0x0249 and elapsed > 5 then
            halt_logged = true
            local span = elapsed - (first_poll_frame or elapsed)
            log(string.format("HALT at elapsed=%d: total polls=%d, poll-span=%d frames",
                elapsed, poll_count, span))
            log(string.format("  flags: intro_input_flag($60)=$%02X intro_inputaux($61)=$%02X (expect $00/$00, no input)",
                mem:read_u8(0x0060), mem:read_u8(0x0061)))
            local ratio = (span > 0) and (poll_count / span) or 0
            log(string.format("AC-7 poll/frame ratio = %.3f (expect ~1.0)", ratio))
            if poll_count >= 232 and poll_count <= 248 then
                log("AC-7/AC-9: PASS (total polls ~240 = 160-hold + 80-blank, ~1/frame)")
            else
                log(string.format("AC-7/AC-9: REVIEW (total polls=%d, expected ~240)", poll_count))
            end
        end
        if elapsed >= OBSERVE then
            if not halt_logged then
                log(string.format("END elapsed=%d (no halt seen): polls=%d PC=$%04X", elapsed, poll_count, cpu.state["PC"].value))
            end
            log_file:close(); manager.machine:exit()
        end
    end
end)
log("waiting for BASIC-ready (frame 300+)...")
