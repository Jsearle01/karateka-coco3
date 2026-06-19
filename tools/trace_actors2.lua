-- trace_actors2.lua — per-FRAME actor signature. Accumulate each frame's drawn
-- sprites per actor group; at frame end, if a group's signature changed, log
-- frame/$3B/$39 + the signature. Reveals animation over time + cadence + $3B coupling.
local mem = manager.machine.devices[":maincpu"].spaces["program"]
local scr = manager.machine.screens[":screen"]
local logf = io.open("C:/karateka-capture/actors2.log","w")
local function log(s) logf:write(s.."\n"); logf:flush() end
-- group a src -> "akuma" / "eagle" / "guard" / nil
local function grp(hi, src)
  if src==0x9FC4 or src==0x9FD8 then return "eagle" end
  if hi==0x98 or hi==0x99 or hi==0x9F then return "akuma" end
  if hi==0x8F or hi==0x89 or hi==0x8A then return "guard" end
  return nil
end
local acc = {akuma={}, eagle={}, guard={}}   -- this frame's src sets
local last = {akuma="", eagle="", guard=""}
log("# per-frame actor signature: f 3B 39 | group=sorted srcs (logged on change)")
_G._tap = mem:install_write_tap(0x04, 0x04, "t", function(off,data)
  if mem:read_u8(0x3d) ~= 1 then return end
  local src = data*256 + mem:read_u8(0x03)
  local g = grp(data, src)
  if g then acc[g][string.format("%04X",src)] = true end
end)
local prevf = -1
_G._a = emu.add_machine_frame_notifier(function()
  local f = scr:frame_number()
  if f ~= prevf then
    -- end of prevf: emit changed signatures
    for _,g in ipairs({"akuma","eagle","guard"}) do
      local keys={}; for k in pairs(acc[g]) do keys[#keys+1]=k end
      table.sort(keys); local sig=table.concat(keys,",")
      if sig~="" and sig~=last[g] then
        log(string.format("f=%-6d 3B=%02X 39=%02X | %-5s= %s",
            prevf, mem:read_u8(0x3b), mem:read_u8(0x39), g, sig))
        last[g]=sig
      end
      acc[g]={}
    end
    prevf=f
  end
  if f>=6000 then log("[done]"); logf:close(); manager.machine:exit() end
end)
