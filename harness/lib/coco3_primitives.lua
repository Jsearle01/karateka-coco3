-- harness/lib/coco3_primitives.lua
-- Reusable instrumentation primitives for CoCo3 MAME tests.
-- MAME v0.281; CoCo3 driver; 6809 CPU at :maincpu.

local M = {}

local function cpu() return manager.machine.devices[":maincpu"] end
local function mem() return cpu().spaces["program"] end

function M.peek8(addr)  return mem():read_u8(addr)  end
function M.peek16(addr) return mem():read_u16(addr) end
function M.poke8(addr, val) mem():write_u8(addr, val) end

function M.regs()
    local c = cpu()
    return {
        pc = c.state["PC"].value,
        a  = c.state["A"].value,
        b  = c.state["B"].value,
        x  = c.state["X"].value,
        y  = c.state["Y"].value,
        u  = c.state["U"].value,
        s  = c.state["S"].value,
        cc = c.state["CC"].value,
        dp = c.state["DP"].value,
    }
end

function M.snapshot()
    pcall(function() manager.machine.screens[":screen"]:snapshot() end)
end

-- Returns current frame number.
function M.frame()
    local s = manager.machine.screens[":screen"]
    return s and s:frame_number() or 0
end

-- Register a per-frame notifier. callback(frame, pc) called each frame.
-- Returns the notifier handle (keep alive with _G to prevent GC).
function M.add_frame_notifier(callback)
    return emu.add_machine_frame_notifier(function()
        local s = manager.machine.screens[":screen"]
        if not s then return end
        local frame = s:frame_number()
        local pc = cpu().state["PC"].value
        callback(frame, pc)
    end)
end

return M
