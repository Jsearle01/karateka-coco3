-- snap_imprison.lua — capture reference snapshots of the Apple II imprisonment
-- scene (the cast with correct colors) for the CoCo3 color gate. Snapshots at
-- several frames across the imprisonment window (~4200-6000).
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local function frame() local s=manager.machine.screens[":screen"]; return s and s:frame_number() or -1 end
local shots = {4000,4400,4800,5200,5600,6000}
local done = {}
_G._snap = emu.add_machine_frame_notifier(function()
    local f = frame()
    for _,sf in ipairs(shots) do
        if not done[sf] and f >= sf then
            done[sf] = true
            pcall(function() manager.machine.screens[":screen"]:snapshot() end)
            print(string.format("[snap] frame %d snapshot ($3D=$%02X)", f, mem:read_u8(0x3D)))
        end
    end
    if f >= 6100 then manager.machine:exit() end
end)
print("[snap] imprisonment reference capture armed")
