-- scene6_dispatch_trace.lua — CLOSE 1.2: observe the $6540 action dispatcher EXECUTING.
-- Puts a DEBUGGER BREAKPOINT at $6540 (opcode-fetch level — read-taps false-0 on 6502 fetch) and,
-- per fire, tracelogs the action code (A), the $2F gate selector, and $20 (anim frame) into a bounded
-- instruction trace. Because the full instruction stream is traced in [FSTART,FEND], the executed
-- branch path (which cmp passes, which jmp is TAKEN to a handler $65F4-$6717, or the no-match
-- fall-through) is directly visible after each mark — the branch TAKEN is OBSERVED, not re-read.
-- Read-only: `trace` writes its own file; no game memory is modified unless DT_FORCEA is set.
--
-- Env:
--   DT_TR      trace output path (required)
--   DT_FSTART  window start frame (default 7240)   DT_FEND  window end frame (default 7440)
--   DT_SECONDS informational only (set -seconds_to_run on the cmdline)
--   DT_FORCEA  hex: force A:=this at $6540 entry, to OBSERVE that action code's jmp for codes the
--              natural fight never reaches (HS-3 bp-force, applied to the action code).
--   DT_FORCE2F hex: force $2F:=this at $6540 entry (default 0x00 when FORCEA set). The dispatch is
--              $2F-GATED: $2F==0 checks D1/D7/C5/C6/9B; $2F!=0 skips D1/D7/C5 and (via the $6567
--              tail) is the ONLY route that reaches the cmp #$C2 at $656B -> jmp $66FE. So to observe
--              C2->$66FE you MUST force $2F!=0 (e.g. 0x01). The natural demo holds $2F==0 at dispatch.
--   DT_STATEFORCE hex: force prob-table row $33 at the AI read $A03D (surfaces codes via state, not A).
--   DT_LINE20  "1": append " ;20=%02X 2F=%02X" to EVERY traced line (see $20 evolve through a handler).
--   DT_HANDLERS "1": also bp the 6 handler entries ($65F4/$6618/$667E/$6717/$66C3/$66FE) + log $20,
--              making action->handler->$20 explicit and grep-cheap (the branch target, observed AT it).
local cpu = manager.machine.devices[":maincpu"]
local dbg = manager.machine.debugger
pcall(function() dbg.execution_state = "run" end)   -- unpause the -debug startup (else CPU idles)
local TR      = os.getenv("DT_TR") or "C:/Projects/karateka_dissasembly_claude/build/logs/dispatch.tr"
local FSTART  = tonumber(os.getenv("DT_FSTART")) or 7240
local FEND    = tonumber(os.getenv("DT_FEND"))   or 7440
local FORCEA  = tonumber(os.getenv("DT_FORCEA"))
local FORCE2F = tonumber(os.getenv("DT_FORCE2F")) or 0x00
local STATEF  = tonumber(os.getenv("DT_STATEFORCE"))
local LINE20  = os.getenv("DT_LINE20") == "1"
local HANDLERS= os.getenv("DT_HANDLERS") == "1"
local diag = io.open((os.getenv("DT_TR") or TR)..".diag.log","w")
local function D(s) diag:write(s.."\n"); diag:flush() end
local HMAP = {[0x65F4]="65F4",[0x6618]="6618",[0x667E]="667E",[0x6717]="6717",[0x66C3]="66C3",[0x66FE]="66FE"}
_G._c = 0; _G._armed = false
_G._n = emu.add_machine_frame_notifier(function()
  _G._c = _G._c + 1
  if _G._c == FSTART and not _G._armed then
    _G._armed = true
    if LINE20 then
      pcall(function() dbg:command('trace '..TR..',0,,{tracelog " ;20=%02X 2F=%02X",b@0x20,b@0x2f}') end)
    else
      pcall(function() dbg:command('trace '..TR..',0') end)
    end
    -- $6540 dispatch breakpoint. If forcing, set A and clear the $2F gate so the full cmp chain runs.
    local act
    if FORCEA then
      act = string.format('a=0x%X; b@0x2f=0x%X; tracelog "<<<D6540 A=%%02X 2F=%%02X 20=%%02X FORCED>>>",a,b@0x2f,b@0x20; go', FORCEA, FORCE2F)
    else
      act = 'tracelog "<<<D6540 A=%02X 2F=%02X 20=%02X>>>",a,b@0x2f,b@0x20; go'
    end
    pcall(function() cpu.debug:bpset(0x6540, nil, act) end)
    if HANDLERS then
      for addr,name in pairs(HMAP) do
        pcall(function() cpu.debug:bpset(addr, nil, string.format('tracelog "<<<H%s A=%%02X 20=%%02X>>>",a,b@0x20; go', name)) end)
      end
    end
    if STATEF then
      pcall(function() cpu.debug:bpset(0xA03D, nil, string.format("pb@0x33=0x%X; go", STATEF)) end)
    end
    D(string.format("armed f%d FORCEA=%s STATEF=%s LINE20=%s HANDLERS=%s", FSTART, tostring(FORCEA), tostring(STATEF), tostring(LINE20), tostring(HANDLERS)))
  end
  if _G._c > FEND then
    pcall(function() dbg:command("trace off") end)
    D("done f".._G._c); diag:close(); manager.machine:exit()
  end
end)
