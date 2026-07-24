## Recon Report — Scroll-layer decomposition (what actually has to move?)

**Class:** PURE RECON (inventory + measure). NO build. `wip`. Prod `88eba89…` untouched.
Supersedes the started-then-stopped full-band sub-byte build.

### §0  Receipt / status
t0=`2026-07-24T13:10:24-04:00` (HEAD `533474b`, `wip`). commit-time=`<this commit>`.
git status: clean tree; only pre-existing untracked `docs/ground-truth/*.pdf`, `oracle_arch_*.lua`, `nvram/`.
Prod `build/karateka.bin` sha1 `88eba89b15cd…` (untouched).

---

### §1  Layer decomposition — measured from the actual snapshot bytes
Dumped `scroll_save` (`$050F`, the clean gated band = 81 rows × 80 bytes) after init and classified every
row. The strip already treats **bytes 0–4** (left border, cleared), **bytes 5–24** (cliff-face striations,
copied *aligned* — never shifted → already static), **bytes 75–79** (right border, cleared). The only part
that *slides* is the **block, bytes 25–74**. Its per-row content:

| Block rows (screen y) | Bytes 25–74 content | Verdict |
|---|---|---|
| 100 | uniform `$AA` (one blue line) | **scroll-invariant → SKIP** |
| **101–104, 108–111** (9 rows) | STRUCTURED (`03 0A 2A AA AB C0 EA F0`…) = wall-top posts + rail | **must-scroll** (but see below — already sprite-handled) |
| 105–107 (3 rows) | `$00` black gap | **invariant → SKIP** |
| 112–152 (41 rows) | `$00` — **uniform black, zero structure** | **invariant → SKIP** |
| 153–180 (28 rows, floor) | each row a **single** byte — `$AA` (odd) / `$55` (even) | **horizontally uniform → any shift is a NO-OP → SKIP** |

**Wall (§1.1):** confirmed **uniformly black** — every byte `$00` across rows 105–107 and 112–152 (44 rows).
No non-black byte found. Scroll-invariant.
**Floor (§1.2):** each floor row is a **single repeated byte** (`$AA` = blue, or `$55` = orange, alternating
by row). Horizontal period = 1 pixel (constant color per row) → **grid-aligned to the byte trivially →
scrolling it is a visual no-op.** Not even a wrap is needed — skip entirely.
**Wall-top (§1.3):** rows 101–111 are the only horizontally-varying block content — the posts/rail.
**Arch (§1.4):** already a separate `$52`-relative sprite composite (`draw_arch`, sub-byte via `arch_subv`);
not part of the band copy. Confirmed.
**Actors (§1.5):** player/guard are per-frame sprite blits (`draw_player_run`/`draw_guard_parked`), not
band-copy. Confirmed.

**Key structural finding:** the wall-top RMW data (`wt_rmw`/`wt_bytes` in `scene6_cliff_walltop.s`) covers
rows **101–111 byte-for-byte**, and `draw_posts_over_fuji` **already re-asserts that whole wall-top scrolled
by `scroll_shift` every frame** (`subb scroll_shift`). So the band-copy of the wall-top is **redundant with
the sprite RMW path** — the sprites are the authoritative scroller for the only must-scroll band content.

---

### §2  Oracle cross-check (fidelity)
The oracle composes phase-1 every frame from two write paths (`render_frame_0a00.s`, verified per-frame):
a **fill path** (`$0A00`/`$0A03`, solid/patterned rectangles) and a **cel path** (`$1903–$190C`, structured
sprites). From the oracle fill trace at the requested mid-scroll point ($52=$24→$23, f8580–8960):

- The oracle **re-blits** the black wall (`$80` fill, rows ~112–117) and the floor (`$D5` fill, row ~153+)
  **every scroll step**, into both alternating buffers (floor row = 142 fills, wall row = 102 fills over the
  window). At the *code* level it skips nothing.
- **BUT** both are **horizontally-uniform constant-value fills** — `render_pass_*` writes one repeated value
  across the whole span. **Re-emitting a uniform fill at a shifted column produces a pixel-identical frame.**
  Only the structured cliff/wall **edge** (drawn by the *cel* path, not the flat fill) visibly translates.

**Verdict: skipping the black wall and the flat floor in the port is VISUALLY FAITHFUL** — the oracle's
per-frame re-fill of those layers is redundant work, not a visible effect (indistinguishable output). What
must still translate with shifted content is exactly the cel-path structure: wall-top / arch / cliff-edge /
figures. This matches our port layer-for-layer (uniform black wall, uniform floor, structured wall-top).
*Caveat:* the cross-check rests on the oracle's fill **values** + render-engine semantics + port framebuffer
corroboration, not a fresh oracle `$2000` pixel grid; the uniform-fill conclusion is well-supported by all
three, and the re-blit cadence is from the definitive engine source.

---

### §3  Re-cost with the dead layers removed
- **Actually-must-scroll band content:** ≤ **9 rows** (101–111 minus the 2 black gap rows) × 50 bytes =
  **~450 bytes/step**, vs the current whole-band copy of ~6,480 bytes/step (the dispatch's ~2,400 B was the
  block-only estimate; the strip actually re-copies striations too). And those 9 rows are **already scrolled
  by the sprite RMW path** — so the band copy of them is **eliminable**, taking the must-scroll band copy to
  **~0 bytes/step** (draw the band once, wall-top region left black, sprites carry the motion).
- **Sub-byte smoothing affordability:** the storage crisis **dissolves** — no 12,393 B pre-shift band. The
  moving elements (wall-top RMW, generated posts, arch, actors) are sprite blits; three of four are already
  sub-byte (`dpg_phase`, `arch_subv`). Pre-shift storage needed = **0**. Better: eliminating the strip frees
  the **81.2%-busy strip phase itself** — the tightest phase becomes nearly empty, so frequent small-step
  (fine sub-byte) updates now have ample budget where the full-band version was the worry.
- **Floor-coupling dividend:** the floor is **horizontally uniform (one color per row) AND static (no-op to
  scroll)** → there is **no floor texture and no floor motion under the feet to skate against** → **feet are
  grounded for free.** The previous recon's foot-skate risk and its floor-split (option 1) fallback are
  **both moot** — confirmed, not merely mitigated.

---

### §4  Deliverable summary + recommendation
- **Per-layer verdict:** wall = SKIP (uniform black); floor = SKIP (horizontally uniform, no-op); wall-top =
  must-scroll but **already sprite-handled** (RMW path); arch/actors = already separate sub-byte sprites.
- **Floor:** single repeated byte per row (period 1px), grid-trivially aligned → skip case, not wrap.
- **Oracle:** re-blits everything, but the uniform layers are pixel-invariant under scroll → **skipping them
  is faithful**; only the cel-path structure translates.
- **Re-cost:** must-scroll band copy → ~0; sub-byte pre-shift storage → 0; the 81.2% strip phase is freed;
  fine smoothing becomes affordable; feet grounded for free.

**Recommendation — REWRITE the sub-byte build around a static band + sprite-only motion (do NOT do the
full-band pre-shift):**
1. Draw the band **once** (both buffers): striations (already static) + black wall + uniform floor, with the
   wall-top region left black. **Delete the per-step strip band-copy** (`strip_chunk`/`strip_one_row`).
2. Let the **existing sprite paths** carry all motion — wall-top RMW (`draw_posts_over_fuji`), generated posts,
   arch, actors — driven from a common sub-byte scroll position. Three are already sub-byte; the wall-top RMW
   needs the same sub-byte adaptation the generated-posts path already demonstrates (`dpg_phase`) — ~11 rows ×
   50 bytes, cheap.
3. This is **cheaper than today** (no strip), makes sub-byte smoothing trivially affordable, and grounds the
   feet without a floor-split.

**One flagged build consideration (not a blocker):** the current strip doubles as the **actor eraser** (it
rebuilds the band each step, wiping last frame's player/guard for free). A static band removes that, so the
rewrite must add a per-actor clean-restore (the climb_controller `cl_restore` pattern) or redraw the static
band under each actor's bbox per frame. Its cost is small (actor bboxes only) and should be measured in the
build, not assumed.

### §5  Out of scope / untouched
No build. The sub-byte build is re-scoped per §4 as a separate dispatch. B3, transition, in-game fight,
Stage C — untouched. Prod `88eba89…` byte-identical.

### §6  Uncertainty flags
- Oracle pixel-grid not freshly captured (see §2 caveat); conclusion rests on fill values + engine semantics +
  port corroboration — strong but not a direct oracle byte-grid.
- The "eliminate the strip" recommendation assumes the sprite RMW fully reproduces the wall-top at all scroll
  positions (it draws the same rows 101–111 data); the rewrite must verify no ghost/ gap where the baked
  wall-top used to scroll, and add the actor-erase (§4 flag). Both are build-time verifications, not assumed.

### §7  Candidate(s) captured
None this task (pure recon). Candidate-worthy insight for later: *"a layer that is uniform along the scroll
axis is scroll-invariant — re-emitting it shifted is a no-op; decompose the moving region by CONTENT
(horizontal variance), not by bounding box, before paying to move it."* (turned a 12 KB / tight-budget /
foot-skate build into eliminate-the-strip.)
