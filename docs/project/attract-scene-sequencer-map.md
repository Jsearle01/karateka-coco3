# Attract Scene Sequencer Map — execution-confirmed (2026-07-13)

**Type:** READ-ONLY investigation. **Recipe:** CLEAN throughout — `-video none
-keyboardprovider none` (no key can boot the actual game). **Prod ROM:**
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched. Frames are my-boot (boot-relative,
provenance only); scenes are content-anchored. Oracle: `karateka_dissasembly_claude` src.

## Result: the attract sequencer is PURE CONTROL FLOW — NO scene-index, NO dispatch table
The null hypothesis holds. Every scene boundary is a **static `jmp`** or **continuous
fall-through**; no boundary reads a byte to select its destination (HS-1). The only byte-indexed
dispatches in the region are unrelated: `$6540` is the **fight-action** dispatch (6-way, `$2F`-gated),
and `jmptable_ad00` ($AD00, 8-entry) is a **render sub-dispatch** called by gameplay code — neither
sequences scenes. `$B0`/`$B1` is set by a hardcoded `lda #$0E` (recon `d14a937`) and is a carried
level/opponent counter, **not** read to dispatch (HS-2 resolved).

## The cycle (execution-confirmed firing order: `B895→B400→B5D7→B895→B400`)
```
[boot: exactly ONE disk load — disk_load_trigger $0300 fires 0× across the whole cycle, HS-5]
intro  (title/Broderbund + scenes 1-4)          entry $B77C (loop re-entry) / boot
   └─ intro end → routine_b895:  jmp $B400       [mechanism 3: static jmp]
scene-5  (princess imprisonment)                 entry $B400  [scene5_entry_b400]
   │  content: $1CC4 princess-shadow + $1Dxx/$1DD7 princess figure
   └─ NO transfer — the same demo continues per-frame (scene-local loop)  [mechanism 2: continuous]
scene-6  (climb → walk → guard-fight)            NO separate entry (continuous beat)
   │  content: $8ACB climb figure (held y124); walk/guard-entry $B29D cmp #$0f on $62
   └─ attract-end gate $B5D3-$B5D7 (PRGEND $AF-armed) → jmp $b766   [mechanism 3: GATED static jmp]
$b766 (jmptable_b760 slot 2) → $B769 prelude → $B77C intro entry → intro scenes 1-4 → jmp $B400 [LOOP]
```

## D4 map — beat → transition → mechanism → verified entry
| Beat | Entry address | Reached via | Mechanism (HS-1) | Content anchor | Run-from (HS-3) |
|---|---|---|---|---|---|
| intro (title + 1-4) | **$B77C** (loop) / boot-loader | `$b766→$B769→$B77C` chain | 3 static jmp | — | chain fires (B5D7→…→B895) [E] |
| scene-5 princess | **$B400** | `$B895: jmp $B400` | 3 static jmp | `$1CC4`/`$1DD7` | **PASS** — cold PC:=$B400 boots scene-5 [E] |
| scene-6 climb/walk/fight | **none (continuous)** | scene-5 demo continues | 2 continuous, no transfer | `$8ACB`; `$B29D`/`$62` | n/a — `$B400` never re-fires [E] |
| attract-end → loop | **$B5D7** (`jmp $b766`) | PRGEND `$AF`-armed gate | 3 gated static jmp | — | fires; cycle closes (2nd `$B400`) [E] |

## Execution evidence [E]
- Full-cycle bp trace (13000 frames): `B895→B400→B5D7→B895→B400` — the cycle closes via the loop-back.
- `disk_load_trigger` `$0300` = **0** hits across the full cycle → single-boot-load premise HELD (HS-5).
- `$B400` **run-from-verified**: from a clean attract-loop point, cold-set PC:=$B400 (readback=`B400`,
  SP=`01F4`) → scene-5 boots (`$1CC4` princess-shadow + `$1DD7` figure draw). [HS-3 PASS]
- `$B400` does **not** re-fire at the princess→climb boundary → scene-6 is a continuous beat, not a
  separately-entered scene. `$B584`/`$B5D7` (Q012 loop-back machinery) are attract-END code, not the
  per-frame demo driver (0 hits during the scene-5/6 demo window).

## Entry-state contract (HS-4)
`$B400` boots scene-5 cleanly from a **stable post-boot-load attract-execution state** (display/
soft-switches/SP already live). Cold-jumping DURING the boot disk-protection phase (`$03xx`) instead
diverts to `$0301 brk` — so the contract is "post-load, IRQ+display state live," which the one-load
premise guarantees (boot → single load → all scene code resident → entries valid to run from).

## Port consequence (Stage-4)
Replicate **pure control flow** — intro → `jmp` scene-5 → continuous demo → gated loop-back; **no
scene-index or dispatch table is needed or authentic.** The stable content/address anchors
(`$B400`=scene-5, `$1CC4`=princess, `$8ACB`=climb, `$B29D`/`$62`=guard-entry) **retire the
boot-relative-frame problem** — anchor Stage-4 sequencing to these, not to frame numbers.
