-- tests/scripted/r_boot_debugtrace.lua
-- Minimal DECB loader for instruction-level trace run.
-- Trace itself driven by boot_trace_bpset.dbg via -debugscript.
-- Does not install frame analysis — just loads binary and sets PC.

local BIN_PATH = "tests/karateka.bin"
local loaded   = false

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

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

_G._debugtrace_notifier = emu.add_machine_frame_notifier(function()
    if loaded then return end
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value
    if frame >= 300 and pc >= 0x8000 then
        local exec, err = load_decb(BIN_PATH, mem)
        if exec then
            cpu.state["PC"].value = exec
            print(string.format("[debugtrace] frame=%d binary loaded exec=$%04X", frame, exec))
        else
            print("[debugtrace] ERROR: " .. tostring(err))
        end
        loaded = true
    end
end)

print("[debugtrace] waiting for BASIC-ready (frame 300+)...")
