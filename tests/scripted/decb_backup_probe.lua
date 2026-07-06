-- decb_backup_probe.lua — drive DECB-under-MAME to DSKINI + BACKUP, for the
-- MAME-BACKUP escape-hatch verification. Feasibility mode first: post a command
-- sequence via natkeyboard, watch FDC command activity ($FF48) to detect when each
-- disk op finishes, then let MAME write the destination floppy (-flop2) back on exit.
-- Command script + timing come from env vars so one lua drives every variant:
--   DECB_CMDS  = "DSKINI 1\rBACKUP 0 TO 1\r"  (\r = ENTER; ; separates timed posts)
-- Posts are separated by "@@" and fired when the FDC has been idle a while (op done).
local LOG = os.getenv("DECB_LOG") or "C:/Projects/karateka_coco3/build/logs/unit/decb_backup_probe.log"
local CMDS = os.getenv("DECB_CMDS") or "DSKINI 1\r"
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local logf = io.open(LOG, "w")
local function log(s) logf:write(s.."\n"); logf:flush() end
local function emutime() local t=manager.machine.time; local ok,v=pcall(function() return t.seconds+t.attoseconds/1e18 end); return ok and v or 0 end

-- split the command script into timed posts on "@@"
local posts = {}
for p in (CMDS.."@@"):gmatch("(.-)@@") do if #p>0 then posts[#posts+1]=p end end
log("posts queued: "..#posts)

-- FDC command activity watch (idle-detect between disk ops)
_G._fdc_last = 0; _G._fdc_count = 0
pcall(function()
  _G._tap = mem:install_write_tap(0x0FF48,0x0FF48,"fdc",function(o,d,m)
    _G._fdc_last = _G._c or 0; _G._fdc_count = _G._fdc_count + 1 end)
end)

local kbd = manager.machine.natkeyboard
_G._c = 0; _G._pi = 1; _G._state = "boot"; _G._waituntil = 0
_G._n = emu.add_machine_frame_notifier(function()
  _G._c = _G._c + 1
  -- boot settle: wait to ~frame 240 (4s) for the DECB OK prompt
  if _G._state == "boot" then
    if _G._c >= 240 then _G._state = "ready"; log(string.format("[f%d] boot settled, posting first command", _G._c)) end
    return
  end
  if _G._state == "ready" then
    if _G._pi > #posts then
      -- all commands posted; let the last op finish then exit
      if _G._c - _G._fdc_last > 300 then
        log(string.format("[f%d] all posts done; FDC idle %d frames; total FDC cmds=%d; exiting (write-back)",
          _G._c, _G._c-_G._fdc_last, _G._fdc_count))
        logf:close(); manager.machine:exit()
      end
      return
    end
    -- fire next post once FDC has been idle >180 frames (prev op finished) or first post
    local idle = _G._c - _G._fdc_last
    if _G._pi == 1 or idle > 180 then
      if _G._c >= _G._waituntil then
        local cmd = posts[_G._pi]
        log(string.format("[f%d] POST #%d: %q (FDC idle %d, cmds so far %d)", _G._c, _G._pi, cmd, idle, _G._fdc_count))
        pcall(function() kbd:post(cmd) end)
        _G._pi = _G._pi + 1
        _G._waituntil = _G._c + 120   -- min gap before checking idle for the next
        _G._fdc_last = _G._c          -- assume the command will start FDC activity
      end
    end
    -- hard cap
    if _G._c > 40000 then log(string.format("[f%d] HARD CAP; FDC cmds=%d", _G._c, _G._fdc_count)); logf:close(); manager.machine:exit() end
  end
end)
