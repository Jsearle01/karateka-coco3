# Scene-6 recon — reconciliation of the consolidation vs the live repo `[2026-07-11]`

**Verification layer** for `scene6-recon-consolidated.md` (Orchestrator-authored from the verdict
record). Ground-truthed against the live oracle code (`karateka_dissasembly_claude/src`) + the live
`docs/project/scene6-recon.md`. **Verdict: the consolidation MATCHES the live repo** — every
load-bearing address/label is repo-confirmed; no finding-level drift. Two minor items flagged for
Jay (cosmetic stale tags in the live doc's superseded block) + additive gap-fills.

## §2  Per-section reconciliation (matches / drifted / needs-address)

| Section | Load-bearing items | Status | Live-repo evidence |
|---|---|---|---|
| §1 Cast | `$A3C5-$A649` climb, `$8E9B`/`$8ECB` heads, `$8244`/`$891B`/`$8D0A`/`$8654` combat, `$8000`/`$9043`/`$8EA5`/`$8EB3` win-suppressed, `$0B12` arrow | **MATCHES** | `sprite_data_8300.s` bank `$8000-$8C66` (`sprite_8000`…); climb chain confirmed in prior pass |
| §2 Draw model | `$1903`/`$1906`/`$1909`/`$190C`, X=`$05·7+$10` | **MATCHES** | jmptable_1900 (verified all-entry pass) |
| §3 Background | `$A948` Fuji stack, `$0A00` fill, `$AA11` floor, `$A684` scroll | **MATCHES** | scene6-recon.md three-layer + X-scoped overpaint |
| §4 Selection | `$59` LCG, `$A000` fight_ai, `$A087`/`$A08C`/`$A091`/`$A096`, `$6540` (6-way, `$2F`-gated `$C2`) | **MATCHES** | `fight_engine.s` `fight_ai_a000`; `$6540` observed-executing (1.2 pass) |
| §5 Timing | `$20` writers `$7081`/`$709D`/`$645B`/`$6493`; no table | **MATCHES** | `$20`-writer watchpoint; F3 no-table (timing pass) |
| §6 Mechanics | `hit_detection_7366`, `check_position_a/b`, `combat_round_manager $7207`, `$B584`, `$33=$72-$62`, `$2F` gate, start `$62≈$0F`/`$72=$30` | **MATCHES** | `gameplay_7000.s:499/182/200/346` (all confirmed in code) |
| §7 Health | `$B6`/`$B7`, `$0B0C`, `$0B35`, `$0B12`, `$0BC1`/`$0BD2`, `$5B`/`$5C`, `$B8`/`$B9`, `$0C1E` | **MATCHES** | `gameplay_7000.s:44` `L0B0C`; `gameplay_state_0b00.s` documents `handler_0bd2` |
| §7a Sound | `$1000`/`$0D00`/`handler_tail $101C`, gate `($4F AND $86)`, `$C030`/`$0C40`/`$0C55-$0CB0`, records `$118C`/`$110B` | **MATCHES** | `timer_dispatch.s:218` `handler_tail`, `:66` `dispatch_slot_6`; `kernel_dispatch_handlers.s` SPKR handlers |
| §8 Port summary | (derived from §1-§7a) | **MATCHES** | consistent with the above |

**No address/label drift found** — the consolidation is address-accurate against the live oracle.

## §3  Superseded ledger (§9) — both-direction check
- **Current version confirmed** for all 16 entries (each current finding is what the doc states).
- **Dead version absent-as-fact** — all major dead findings appear in the live doc **only as
  marked corrections/refutations** (not as current fact): #1 "each handler sets `$20`" → line 229
  "CORRECTION"; #3 timing-table → "NO timing table"; #4 direct-write → "C4 REFINED, NOT a direct
  write"; #5 zero-row → "UNREACHED-STATE, not zero-row"; #11 collision-[I] → "CLOSED"; #12/#13
  always-wins → multi-layer/authored. ✓
- **⚠ FLAG (F2, minor — for Jay):** the live `scene6-recon.md` **superseded-original sound block**
  (lines 551-572, under a "[Superseded original]" header) still contains the DEAD #14 and #16
  findings with **live tags**: line 551 "THE FIGHT IS SILENT-BY-NO-TRIGGER **[C]** (F2)"; lines
  562/572 "one shared interface `HAL_sound_trigger`"; lines 567-570 "fight-event sites =
  DESIGN-FROM-EVENTS, real-play-only **[I]**, record IDs unknown" (now false — the SPKR path was
  found). The block **is** marked superseded (so not an *unmarked* stale finding), but the retained
  `[C]`/`[I]` tags could mislead a skim-reader. **Recommend:** strike those superseded bullets or
  remove their tags. *(Not silently edited — finding-cleanup gates to Jay per the audit rule.)*

## §4  Inferred [I] status (§10a) — still open?
- **C1 residual transition edges** — **STILL OPEN** [I] (mechanics-close pass marked F-C1 partial;
  residual not force-reached). ✓
- **Low-health blink** threshold+cadence — **STILL OPEN** [I] (never traced). ✓
- **Health guard-side arrow draw + mirror** — **STILL OPEN** [I] (read-tap missed; needs bp re-run). ✓
- **Collision→hit-state feed** — correctly **CLOSED** (not [I]) — the range/reach `hit_detection_7366`
  test (collision pass). ✓ (Consolidation §9-11 states this correctly.)

## §5  Gap-fills (additive specifics — not corrections)
- **`hit_detection_7366` inputs:** reads **`$5E`** (enable gate), **`$32`** (action class, indexes
  `tbl_range_0`/`tbl_range_1`), **`$33`** (distance), `$A3`, `$DB`; returns the event/hit code
  (`$03` on connect). Reach-vs-distance compare (`cmp $33`).
- **`$C030` SPKR handler → event correlations:** `$0C55`↔`$40`≠0 (player hit), `$0C64`/`$0C74`↔
  `$41`≠0 (guard hit), `$0C84`↔every hit (common impact), `$0CB0`↔no-hit (footstep, `$20`=24).
- **Placement-table `$20` frames:** hit = order marker(`$93AB`)→sound→decrement; footstep `$20`=24;
  cliff `$20`=07 (f6114, +9 after climb f6105); victory `$20`=06 (~f8416, mid-pose).
- **Health damage detail:** the guard-damage routine clears **`$5C` AND `$5E`** on zero (not only the
  regen timer) — per `gameplay_state_0b00.s` (`handler_0bd2`). Additive to §7's "reset regen timer."

## §6  Drift flagged for Jay (F1/F2/F4)
- **F1 (address/label drift): NONE** — the consolidation is address-accurate.
- **F2 (dead lingering as fact): 1, minor** — the live doc's superseded-sound-block retains dead
  #14/#16 findings with live `[C]`/`[I]` tags (block-marked superseded; recommend striking bullets).
  → Jay's ruling.
- **F4 (references not in repo): NONE** — every consolidation address exists in the live oracle.

**Net: the consolidation is REPO-VERIFIED build-ready.** No finding-level drift; the one flag is a
cosmetic cleanup of already-superseded text in the live doc (for Jay). Gap-fills added the implicit
specifics. After Jay rules on the F2 tidy, scene 6 is build-ready.
