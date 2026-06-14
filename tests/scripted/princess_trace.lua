-- princess_trace.lua — RECON/verify: load the princess controller sandbox,
-- poll pr_leg ($43) + pr_x ($44) + page_register ($50) each frame; log leg
-- cadence + position steps; snapshot to confirm she renders. Memory reads are
-- reliable under -nothrottle; motion fidelity is Jay's live gate (AC-5).
local LOG_PATH = "princess_trace.log"
local BIN_PATH = "tests/sprite_engine_princess.bin"
local PR_LEG, PR_X, PR_CAD, PAGE = 0x43, 0x44, 0x45, 0x50
local OBSERVE = 520
local SHOT1, SHOT2 = 160, 380

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local log_file = io.open(LOG_PATH, "w")
local function log(m) log_file:write(m.."\n"); log_file:flush(); print("[princess] "..m) end
log("# princess_trace " .. os.date())

local function load_decb(path)
    local f = io.open(path, "rb"); if not f then return nil,"open "..path end
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

local state, lf, llg, lx, shot1, shot2 = "wait", 0, -1, -1, false, false
_G._pn = emu.add_machine_frame_notifier(function()
    local scr = manager.machine.screens[":screen"]; if not scr then return end
    local fr = scr:frame_number(); local pc = cpu.state["PC"].value
    if state=="wait" and fr>=300 and pc>=0x8000 then state="load" end
    if state=="load" then
        local ex,err = load_decb(BIN_PATH)
        if not ex then log("ERR "..tostring(err)); log_file:close(); manager.machine:exit(); return end
        cpu.state["PC"].value = ex; lf = fr; state="run"
        log(string.format("loaded exec=$%04X; observing %d frames", ex, OBSERVE))
        log("leg/x transitions (elapsed, pr_leg, pr_x, page):")
    end
    if state=="run" then
        local el = fr-lf
        local leg, x, pg = mem:read_u8(PR_LEG), mem:read_u8(PR_X), mem:read_u8(PAGE)
        if leg~=llg or x~=lx then
            log(string.format("  el=%3d pr_leg=%d pr_x=%d page=$%02X", el, leg, x, pg))
            llg, lx = leg, x
        end
        if not shot1 and el>=SHOT1 then shot1=true; pcall(function() scr:snapshot() end); log("SNAP1 el="..el.." pr_x="..x) end
        if not shot2 and el>=SHOT2 then shot2=true; pcall(function() scr:snapshot() end); log("SNAP2 el="..el.." pr_x="..x) end
        if el>=OBSERVE then log("DONE"); log_file:close(); manager.machine:exit() end
    end
end)
log("active; waiting for BASIC-ready")
