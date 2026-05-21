-- tests/scripted/prod_boot_loader_minimal.lua
-- Minimal one-shot binary loader for visual verification runs.
-- NO frame-notifier callbacks after the binary is loaded.
-- NO screenshots. NO reads. NO logging. MAME runs uninterrupted.
--
-- Used by run_prod_boot_visual.sh (normal throttle, visual-gate runs).

local BIN_PATH = "tests/karateka.bin"
local loaded   = false

local function load_decb(path, mem)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local data = f:read("*a"); f:close()
    local pos = 1; local exec_addr = nil
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

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

_G._minimal_notifier = emu.add_machine_frame_notifier(function()
    if loaded then return end  -- one-shot: immediate no-op after load
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value
    if frame >= 300 and pc >= 0x8000 then
        local exec, err = load_decb(BIN_PATH, mem)
        if exec then
            cpu.state["PC"].value = exec
            print(string.format("[visual] frame=%d karateka.bin loaded exec=$%04X", frame, exec))
        else
            print("[visual] ERROR: " .. tostring(err))
        end
        loaded = true  -- suppress all future firings
    end
end)

print("[visual] waiting for BASIC-ready (frame 300+)...")
