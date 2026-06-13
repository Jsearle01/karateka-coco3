-- tests/scripted/sprite_engine_sandbox_live.lua
-- R-engine sandbox — LIVE P4 gate harness (Jay, real-time).
-- Loads sprite_engine_sandbox.bin after BASIC-ready and hands control to it
-- INDEFINITELY (no frame cap, no snapshots). Run WITHOUT -nothrottle so the
-- animation plays at true 60 fps; close the MAME window when done.
--
--   cd /d C:\karateka-capture
--   C:\mame\mame.exe coco3 -rompath C:\mame\roms -window \
--       -autoboot_script tools\sprite_engine_sandbox_live.lua
--
-- Controls: free-run by default; tap any key to single-step one frame.
-- [ref: tests/scripted/sprite_engine_sandbox.lua — automated P2/P3 trace variant]

local BIN_PATH = "tests/sprite_engine_sandbox.bin"

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

local state = "waiting_basic"
local cpu   = manager.machine.devices[":maincpu"]
local mem   = cpu.spaces["program"]

_G._engsandbox_live_notifier = emu.add_machine_frame_notifier(function()
    local screen = manager.machine.screens[":screen"]
    if not screen then return end
    local frame = screen:frame_number()
    local pc    = cpu.state["PC"].value

    if state == "waiting_basic" and frame >= 300 and pc >= 0x8000 then
        local exec, err = load_decb(BIN_PATH, mem)
        if not exec then
            print("[engsandbox-live] ERROR: " .. tostring(err))
            manager.machine:exit(); return
        end
        cpu.state["PC"].value = exec
        state = "running"
        print(string.format("[engsandbox-live] loaded; exec=$%04X — animation running (close window to end)", exec))
    end
end)

print("[engsandbox-live] harness active; waiting for BASIC-ready...")
