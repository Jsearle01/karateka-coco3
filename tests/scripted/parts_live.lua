-- parts_live.lua — AC-5/AC-6 LIVE GATE (Jay): load the princess controller
-- sandbox and let it run at real 60fps (throttled). No poll, no exit — watch
-- the walk-in (motion smoothness, no smear) + colors at the game-parity column.
local BIN_PATH = "tests/sprite_engine_parts.bin"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

local function load_decb(path)
    local f = io.open(path, "rb"); if not f then return nil end
    local d = f:read("*a"); f:close(); local p = 1; local exec
    while p <= #d do
        local t = string.byte(d,p)
        if t == 0x00 then
            local len = string.byte(d,p+1)*256+string.byte(d,p+2)
            local ad  = string.byte(d,p+3)*256+string.byte(d,p+4)
            for i=0,len-1 do mem:write_u8(ad+i, string.byte(d,p+5+i)) end
            p = p+5+len
        elseif t == 0xFF then exec = string.byte(d,p+3)*256+string.byte(d,p+4); break
        else break end
    end
    return exec
end

local state = "wait"
_G._pl = emu.add_machine_frame_notifier(function()
    local scr = manager.machine.screens[":screen"]; if not scr then return end
    if state=="wait" and scr:frame_number()>=300 and cpu.state["PC"].value>=0x8000 then
        local ex = load_decb(BIN_PATH)
        if ex then cpu.state["PC"].value = ex end
        state = "run"
        print("[parts_live] loaded; running at real speed — inspect the parts")
    end
end)
