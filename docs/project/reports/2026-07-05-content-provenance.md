# Track content/ + provenance manifest — exec history (2026-07-05)

Cleanup found `content/` partially untracked while the committed scene-5 build
depends on it, and some sprites were hand-modified during scene-5 tuning
(irreplaceable). Decision (Jay): TRACK content/ + build a mechanical
hand-tuned-vs-generated manifest.

## What was done
1. **Tracked content/** (commit `1e5c602`, pushed FIRST per Jay): staged the 38
   untracked `converted.s` by explicit path (content/ only). All 108 converted.s
   are now tracked → clean clone builds scene 5. No content EDIT (byte-unchanged).
2. **Provenance manifest** (`docs/project/content-provenance.md`): mechanical diff
   of every `content/**/converted.s` against a FRESH `harness/tools/sprite_convert.py`
   run (to /tmp, never over content/ — HS-3), header args × {default, --flip-parity}.
   - **46 CLEAN-GENERATED** (exact fcb match → safe to regenerate).
   - **25 DIFFERS-FROM-CONVERTER** (protect; incl. the known 9EB8 blue-line tune).
   - **37 BINARY-DUMP** (ORIGIN `dump05*`, not a `.s` → out of this converter's
     scope; protect).
3. **Regen doc + WARNING**: the converter command + "only regenerate CLEAN-GENERATED;
   convert-to-temp-and-diff for the rest."

## Method note (why it works)
The converter is deterministic: a known-generated file (akuma_frame_5) reproduced
byte-identically with `--flip-parity` + the header start_col. So EXACT match =
generated; differ = protect. The `--flip-parity` need is because these were
generated before the 2026-06-14 parity fix.

## Cross-check vs Jay's memory (HS-4)
- 9EB8 blue-line removal — caught (DIFFERS) ✓.
- Princess X-offset tuning — lives in `src/engine/princess_controller.s` (CODE),
  not content/. Discrepancy surfaced: that tuning is code, not sprite content;
  the princess content is all binary-dump (unverifiable via this converter).

## Caveat (HS-2 best-effort)
The 25 DIFFERS are a candidate set — "differs" ⊇ "hand-tuned" (also captures minor
converter-version-drift / start_col-parity reconstruction limits). For the
protection goal all 62 non-exact files are treated identically: do not
blind-regenerate. The 46 CLEAN-GENERATED are definitive (exact byte match).

## Files
- content/ (38 .s tracked, commit 1e5c602) ; docs/project/content-provenance.md (manifest).
