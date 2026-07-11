-- scene6_pose_timing.lua — FIGHT TIMING: measure VBLs-per-pose ($20 dwell vs the VBL timebase).
-- The VBL timebase is the game's vbl_sync ($779A: lda $C019 / bmi spin on RDVBL bit7); one pass =
-- one VBL boundary. This tool (a) counts vbl_sync ENTRIES ($779A) via a debugger bp to validate
-- MAME-frame == VBL (HS-2), and (b) taps the four sprite draw entries ($1903/$1906/$1909/$190C —
-- the PROVEN-firing tap from scene6_full_descriptor) and, at each COMBATANT-bank cel draw ($8xxx/
-- $9xxx), records the MAME frame + entry + cel ptr + $20 (WNDLFT, the anim-frame index L6811 reads)
-- + X. Dwell per $20 per combatant (separated by head-norm-half $8E9B player / $8ECB guard, HS-7)
-- is computed offline from the CSV. $20 is watched as DATA at the draw (HS-1/HS-5), not a code
-- read-tap. Read-only.
--
-- Env: PT_CSV (draw CSV), PT_VBL (vbl_sync mark trace), PT_FSTART/PT_FEND (window),
--      PT_SEEDPOKE/PT_POKEF (seed axis), PT_STATEFORCE (force AI row $33 at $A03D — cover moves a
--      single seed misses, HS-3).
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local dbg = manager.machine.debugger
pcall(function() if dbg then dbg.execution_state = "run" end end)   -- unpause headless -debug (idiom)
local CSV    = os.getenv("PT_CSV") or "C:/Projects/karateka_dissasembly_claude/build/logs/pose_timing.csv"
local VBLTR  = os.getenv("PT_VBL") or "C:/Projects/karateka_dissasembly_claude/build/logs/pose_vbl.tr"
local FSTART = tonumber(os.getenv("PT_FSTART")) or 7240
local FEND   = tonumber(os.getenv("PT_FEND"))   or 8200
local SEEDPOKE  = tonumber(os.getenv("PT_SEEDPOKE"))
local POKEF     = tonumber(os.getenv("PT_POKEF")) or 6484
local STATEFORCE= tonumber(os.getenv("PT_STATEFORCE"))
local csvf = io.open(CSV,"w"); csvf:write("frame,ent,ptr,a20,x,y\n")
local function rd(a) return mem:read_u8(a) end
local ENT = {[0x1903]="A",[0x1906]="Ay",[0x1909]="B",[0x190C]="By"}
_G._f = 0
local function handle(tag)
  return function(o,d,m)
    if _G._f < FSTART or _G._f > FEND then return end
    local src = rd(0x04)*256 + rd(0x03)
    if src < 0x8000 or src >= 0xA000 then return end   -- combatant/fx banks $8xxx/$9xxx only; skip $A4xx scroll
    local a20 = rd(0x20)                    -- WNDLFT = $20 = anim-frame index, at the draw (HS-1)
    local x   = rd(0x05)*7 + rd(0x10)
    local y   = rd(0x06)
    csvf:write(string.format("%d,%s,%04X,%02X,%d,%d\n", _G._f, tag, src, a20, x, y))
  end
end
pcall(function() for a,t in pairs(ENT) do _G["_t"..a] = mem:install_read_tap(a,a,t,handle(t)) end end)
-- VBL validation: bp at vbl_sync entry $779A tracelogs one mark per VBL wait; count vs frame span.
pcall(function() dbg:command("trace "..VBLTR..",0") end)
pcall(function() cpu.debug:bpset(0x779A, nil, 'tracelog "V%d\\n",0; go') end)
-- Optional state-force to reach moves a single seed never plays (HS-3).
if STATEFORCE then pcall(function() cpu.debug:bpset(0xA03D, nil, string.format("pb@0x33=0x%X; go", STATEFORCE)) end) end
_G._n = emu.add_machine_frame_notifier(function()   -- keep referenced (GC idiom); MAME frame = VBL tick
  _G._f = _G._f + 1
  if SEEDPOKE and _G._f == POKEF then mem:write_u8(0x59, SEEDPOKE) end
  if _G._f > FEND then
    pcall(function() dbg:command("trace off") end)
    csvf:close(); manager.machine:exit()
  end
end)
