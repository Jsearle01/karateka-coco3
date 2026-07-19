-- scrollA_fbdump.lua — render-neutral gate: dump BOTH framebuffers ($8000-$FBFF)
-- at a FIXED frame after exec, for byte-identical before/after comparison.
-- Env: S_BIN (driver .bin), S_OUT (raw dump path). Deterministic boot -> same frame = same anim state.
local BIN = os.getenv("S_BIN")
local OUT = os.getenv("S_OUT")
local DUMP_AFTER = tonumber(os.getenv("S_AFTER") or "180")  -- frames after exec to snapshot
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)

local function load(p)
  local f = io.open(p, "rb"); if not f then return end
  local d = f:read("*a"); f:close(); local i = 1; local ex
  while i <= #d do local t = string.byte(d, i)
    if t == 0 then local n = string.byte(d,i+1)*256+string.byte(d,i+2)
      local a = string.byte(d,i+3)*256+string.byte(d,i+4)
      for j=0,n-1 do mem:write_u8(a+j, string.byte(d,i+5+j)) end
      i = i+5+n
    elseif t == 0xFF then ex = string.byte(d,i+3)*256+string.byte(d,i+4); break
    else break end
  end
  return ex
end

local st="wait"; local exf=0
_G._n = emu.add_machine_frame_notifier(function()
  if st=="wait" and scr:frame_number()>=300 and cpu.state["PC"].value>=0x8000 then
    local ex = load(BIN)
    if ex then cpu.state["PC"].value = ex; st="run"; exf=scr:frame_number() end
  elseif st=="run" and scr:frame_number() >= exf+DUMP_AFTER then
    local out = io.open(OUT, "wb")
    for a=0x8000,0xFBFF do out:write(string.char(mem:read_u8(a))) end
    out:close()
    st="done"; manager.machine:exit()
  end
end)
