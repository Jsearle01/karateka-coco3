-- scrollA_measure.lua — MEASURE the Stage-A per-step composite cost + OBSERVED mid-ground cols.
-- Boots coco3 to BASIC, loads scene6_walk_scrollA_driver.bin (S_BIN), sets PC=exec, then:
--  (1) read-taps restore_band ($0277) [step start] + HAL_gfx_present ($0B51) [step end] and records
--      machine.time delta = the per-step composite cost (restore band + re-blit mid-ground), in ms.
--  (2) at cur52=$28 and $1B, dumps back-buffer row 105 (bytes 0-79) = OBSERVED mid-ground positions
--      (non-$AA bytes = posts vs $AA blue sky). Read-only; coco3 read-taps fire on execution (§idioms).
-- Env: S_BIN, S_OUT (report path). Headless: -video none -seconds_to_run ~25.
local BIN = os.getenv("S_BIN")
local OUT = os.getenv("S_OUT") or "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/scroll/scrollA_measure.txt"
local cpu = manager.machine.devices[":maincpu"]; local mem = cpu.spaces["program"]
local scr = manager.machine.screens:at(1)
local function now() return manager.machine.time:as_double() end
local function rd(a) return mem:read_u8(a) end
local log = io.open(OUT, "w")

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

local st="wait"; local t0=nil; local nstep=0; local dumped={}
local dmin=1e9; local dmax=0; local dsum=0; local dn=0

local function dump_row(tag, s52)
  local base = (rd(0x50)==0x20) and 0x8000 or 0xC000
  local off = base + 105*80
  local s = string.format("# OBSERVED back-buffer row 105 @ $52=%02X (base=%04X):\n#  ", s52, base)
  for c=0,79 do s = s .. string.format("%02X", rd(off+c)); if (c%16)==15 then s=s.."\n#  " end end
  log:write(s.."\n")
  -- identify post cols: runs of non-$AA (sky) content bytes 5..74
  local cols={}
  for c=5,74 do local v=rd(off+c); if v~=0xAA and v~=0x00 then cols[#cols+1]=c end end
  log:write(string.format("#  non-sky content byte-cols at $52=%02X: %s\n", s52, table.concat(cols,",")))
end

local function on_restore() t0 = now() end
local function on_present()
  if t0 then
    local dt = (now()-t0)*1000.0    -- ms
    local s52 = rd(0x02E2); local sh = rd(0x02E3)
    nstep = nstep+1
    if nstep>2 then  -- skip first couple (boot/settling)
      dsum=dsum+dt; dn=dn+1; if dt<dmin then dmin=dt end; if dt>dmax then dmax=dt end
    end
    if nstep<=40 then log:write(string.format("step %2d  $52=%02X shift=%02X  composite=%.3f ms\n", nstep, s52, sh, dt)) end
    if (s52==0x28 or s52==0x1B) and not dumped[s52] then dumped[s52]=true; dump_row("d", s52) end
    t0=nil
  end
end

_G._n = emu.add_machine_frame_notifier(function()
  if st=="wait" and scr:frame_number()>=300 and cpu.state["PC"].value>=0x8000 then
    local ex = load(BIN)
    if ex then
      cpu.state["PC"].value = ex; st="run"
      _G._t1 = mem:install_read_tap(0x0277,0x0277,"restore",on_restore)
      _G._t2 = mem:install_read_tap(0x0782,0x0782,"present",on_present)
      log:write(string.format("# loaded, PC=%04X, taps armed f%d\n", ex, scr:frame_number()))
    end
  end
  if st=="run" and nstep>=35 then
    log:write(string.format("\n# === per-step composite cost (n=%d, steps 3..): min=%.3f max=%.3f avg=%.3f ms ===\n",
      dn, dmin, dmax, dsum/math.max(dn,1)))
    log:write(string.format("# VBL budget = 16.68 ms (60 Hz). Worst-case %.3f ms => %s\n",
      dmax, (dmax<16.68) and "FITS within one VBL" or "EXCEEDS VBL"))
    log:close(); manager.machine:exit()
  end
end)
