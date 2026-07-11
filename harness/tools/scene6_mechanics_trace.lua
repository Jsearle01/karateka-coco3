-- scene6_mechanics_trace.lua — FIGHT MECHANICS: execution-confirm the distance->state->action chain.
-- Static read (HYP, to confirm): update_range_flag computes $33 = $72 - $62 (a distance) when in
-- range, else $FF; fight_ai_a000 ($A000) reads $33 (ldx $33 @ $A03D), and if $33 >= $0C treats it
-- as out-of-range; the prob-tables $A087-$A096 are indexed by X=$33; selected action -> $29 -> the
-- $6540 dispatch. Because save_combatant_a/b copy the active context $20-$2F into $60-$6F (A) /
-- $70-$7F (B), $62/$72 are A's/B's position byte ($22); $33 = $72-$62 = inter-combatant distance.
-- This tool logs, per AI decision (bp @ $A03D) and per dispatch (bp @ $6540), the state bytes so the
-- chain is OBSERVED, not read from labels. Watches bytes as DATA (6502 read-taps false-0). Read-only.
--
-- Env: MT_TR (trace), MT_FSTART/MT_FEND (window), MT_SEEDPOKE/MT_POKEF, MT_STATEFORCE (force $33 @
--      $A03D to reach out-of-range / suppressed rows the demo never hits).
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local dbg = manager.machine.debugger
pcall(function() if dbg then dbg.execution_state = "run" end end)
local TR     = os.getenv("MT_TR") or "C:/Projects/karateka_dissasembly_claude/build/logs/mech.tr"
local FSTART = tonumber(os.getenv("MT_FSTART")) or 7240
local FEND   = tonumber(os.getenv("MT_FEND"))   or 8200
local SEEDPOKE   = tonumber(os.getenv("MT_SEEDPOKE"))
local POKEF      = tonumber(os.getenv("MT_POKEF")) or 6484
local STATEFORCE = tonumber(os.getenv("MT_STATEFORCE"))
_G._f = 0; _G._armed = false
_G._n = emu.add_machine_frame_notifier(function()
  _G._f = _G._f + 1
  if _G._f == FSTART and not _G._armed then
    _G._armed = true
    pcall(function() dbg:command("trace "..TR..",0") end)
    -- AI decision point ($A03D = ldx $33): log the selection inputs; optionally FORCE $33 first.
    -- distance $33, positions $62/$72/$22, gates $2F/$5E/$70, threshold $DB, anim $20.
    local force = STATEFORCE and string.format("pb@0x33=0x%X; ", STATEFORCE) or ""
    pcall(function() cpu.debug:bpset(0xA03D, nil,
      force..'tracelog "<<<AI 33=%02X 62=%02X 72=%02X 22=%02X 2F=%02X 5E=%02X 70=%02X DB=%02X 20=%02X>>>",b@0x33,b@0x62,b@0x72,b@0x22,b@0x2f,b@0x5e,b@0x70,b@0xdb,b@0x20; go') end)
    -- dispatch ($6540): the SELECTED action code A/$29 + gate + anim
    pcall(function() cpu.debug:bpset(0x6540, nil,
      'tracelog "<<<ACT 29=%02X 2F=%02X 20=%02X>>>",a,b@0x2f,b@0x20; go') end)
  end
  if SEEDPOKE and _G._f == POKEF then mem:write_u8(0x59, SEEDPOKE) end
  if _G._f > FEND then pcall(function() dbg:command("trace off") end); manager.machine:exit() end
end)
