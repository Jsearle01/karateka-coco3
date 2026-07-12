-- scene6_stage1_confirm.lua — headless PC-confirm for the Stage-1 Fuji backdrop.
-- Loads scene6_stage1_driver.bin after boot, sets PC=entry, runs, reports final PC.
-- SUCCESS = PC settles at the hold loop $021B (init+draw+present ran, no crash).
-- This confirms CODE RAN, NOT what it looks like (§11 — the visual is Jay's gate).
local BIN = os.getenv("S1_BIN") or "C:/Projects/karateka_coco3/tests/scripted/scene6_stage1_driver.bin"
local LOG = os.getenv("S1_LOG") or "C:/Projects/karateka_coco3/build/logs/scene6_stage1_confirm.log"
local HOLD = 0x021B
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local logf = io.open(LOG, "w")
local function log(s) logf:write(s .. "\n"); logf:flush() end

local function load(p)
  local f = io.open(p, "rb"); if not f then return end
  local d = f:read("*a"); f:close(); local i = 1; local ex
  while i <= #d do local t = string.byte(d, i)
    if t == 0 then
      local n = string.byte(d, i+1)*256 + string.byte(d, i+2)
      local a = string.byte(d, i+3)*256 + string.byte(d, i+4)
      for j = 0, n-1 do mem:write_u8(a+j, string.byte(d, i+5+j)) end
      i = i + 5 + n
    elseif t == 0xFF then ex = string.byte(d, i+3)*256 + string.byte(d, i+4); break
    else break end
  end
  return ex
end

local st = "wait"; local loaded_ex = nil; local samples = {}
_G._s1 = emu.add_machine_frame_notifier(function()
  local fn = scr:frame_number()
  if st == "wait" and fn >= 300 and cpu.state["PC"].value >= 0x8000 then
    loaded_ex = load(BIN)
    if loaded_ex then cpu.state["PC"].value = loaded_ex; st = "run"
      log(string.format("loaded .bin, exec=$%04X, PC set at f%d", loaded_ex, fn)) end
  elseif st == "run" then
    if fn % 20 == 0 then samples[#samples+1] = cpu.state["PC"].value end
    if fn >= 480 then
      local pc = cpu.state["PC"].value
      -- also read a few framebuffer bytes to confirm the blit wrote pixels (non-zero)
      local nz = 0
      for r = 80, 130 do for c = 0, 79 do
        if mem:read_u8(0x8000 + r*80 + c) ~= 0 then nz = nz + 1 end
      end end
      log(string.format("final PC=$%04X  (HOLD=$%04X -> %s)", pc, HOLD,
          (pc >= 0x021B and pc <= 0x021D) and "REACHED HOLD (init+draw+present ran, no crash)" or "NOT at hold"))
      log(string.format("PC samples: %s", table.concat((function() local t={} for _,v in ipairs(samples) do t[#t+1]=string.format("%04X",v) end return t end)(), " ")))
      log(string.format("framebuffer non-zero bytes in rows 80-130: %d (blit wrote pixels = %s)", nz, nz > 0 and "YES" or "NO"))
      logf:close(); manager.machine:exit()
    end
  end
end)
