-- prod_boot_snap.lua — load karateka.bin and snapshot scenes 1-4 at fixed
-- elapsed frames, for the opaque-blit regression A/B (HEAD vs pre-opaque).
-- Deterministic prod boot -> same frames are directly comparable.
local BIN_PATH = "tests/karateka.bin"
local SHOTS = {120, 360, 640, 920, 1180}   -- broderbund / presents / title / scroll
local DONE = 1320
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open("C:/karateka-capture/prod_boot_snap.txt","w")
local function log(s) print(s); logf:write(s.."\n"); logf:flush() end

local function load_decb(path)
    local f=io.open(path,"rb"); if not f then return nil end
    local d=f:read("*a"); f:close(); local p=1; local ex
    while p<=#d do
        local t=string.byte(d,p)
        if t==0x00 then
            local len=string.byte(d,p+1)*256+string.byte(d,p+2)
            local ad=string.byte(d,p+3)*256+string.byte(d,p+4)
            for i=0,len-1 do mem:write_u8(ad+i,string.byte(d,p+5+i)) end
            p=p+5+len
        elseif t==0xFF then ex=string.byte(d,p+3)*256+string.byte(d,p+4); break
        else break end
    end
    return ex
end

local state, lf, si = "wait", 0, 1
_G._pbs = emu.add_machine_frame_notifier(function()
    local scr=manager.machine.screens[":screen"]; if not scr then return end
    local f=scr:frame_number()
    if state=="wait" and f>=300 and cpu.state["PC"].value>=0x8000 then
        local ex=load_decb(BIN_PATH); if ex then cpu.state["PC"].value=ex end
        lf=f; state="run"; log("loaded exec=$"..string.format("%04X",ex or 0).." at f="..f)
    elseif state=="run" then
        local el=f-lf
        if si<=#SHOTS and el>=SHOTS[si] then
            pcall(function() scr:snapshot() end); log("SNAP "..si.." el="..el); si=si+1
        end
        if el>=DONE then log("done"); logf:close(); manager.machine:exit() end
    end
end)
