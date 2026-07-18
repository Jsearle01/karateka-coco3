# Selecting RGB vs Composite in MAME (CoCo3) — via the config file

MAME has **no command-line switch** for the CoCo3's monitor type — RGB vs Composite is a *machine
configuration*, stored in a per-machine file named **`coco3.cfg`** inside MAME's config folder. This note
explains the three ways to set it, including how to **add it to a `coco3.cfg` you already have** without
losing your other settings.

*(Why it matters: the game's RGB colours look right only under **Monitor Type = RGB**; the CoCo3 emits RGB
and composite at once and the software can't sense which monitor you're on, so you pick it here.)*

---

## Presets in this folder
- **`rgb/coco3.cfg`** — Monitor Type = **RGB** (`value="1"`).
- **`composite/coco3.cfg`** — Monitor Type = **Composite** (`value="0"`, the MAME default).

---

## Option A — point MAME at the preset folder (easiest, non-destructive)
Add `-cfg_directory` to your launch command, pointing at the `rgb` (or `composite`) folder:

```
mame coco3 -rompath <your-roms> -flop1 <game.dsk> -cfg_directory "<path>/dist/mame-cfg/rgb"
```

MAME reads `coco3.cfg` from that folder at boot and comes up in RGB. This does **not** touch your normal
MAME config. *(MAME rewrites the file in that folder on exit — fine, it just re-saves the same setting.)*

## Option B — the in-MAME menu (no files at all)
Boot the game, press **Tab** → **Machine Configuration** → **Monitor Type** → **RGB**, then close the menu.
MAME saves it to your default `coco3.cfg` and it stays RGB for future runs until you change it back.

## Option C — ADD it to your EXISTING `coco3.cfg` (merge, don't replace)
Do this if you already have a `coco3.cfg` with your own key remaps/settings and don't want to lose them.

1. **Close MAME first** — it rewrites `coco3.cfg` on exit and would overwrite your hand-edit.
2. Find your config folder's **`coco3.cfg`** (default: a `cfg` folder next to MAME, or wherever your
   `mame.ini`'s `cfg_directory` points). If there is no `coco3.cfg`, just copy `rgb/coco3.cfg` there and
   you're done.
3. Open `coco3.cfg` in a plain-text editor. Inside the `<system name="coco3">` block, find the
   **`<input> … </input>`** section and add this **one line** inside it:

   ```xml
   <port tag=":screen_config" type="CONFIG" mask="1" defvalue="0" value="1" />
   ```

   So it looks like:
   ```xml
   <system name="coco3">
       <input>
           <!-- ...your existing key/port lines stay here... -->
           <port tag=":screen_config" type="CONFIG" mask="1" defvalue="0" value="1" />
       </input>
       <!-- ...other blocks stay as they are... -->
   </system>
   ```
4. Save. Next launch, coco3 boots in RGB and all your other settings are intact.

- **RGB = `value="1"`. Composite = `value="0"`** (or just remove the line — Composite is the default).

---

## Notes / gotchas
- The filename must be **`coco3.cfg`** (per-machine) and live in the config folder MAME actually uses.
- **`version="10"`** is this MAME's config-format version; a much older/newer MAME may use a different
  number, but the `<port …>` line itself is stable. If MAME ignores the file, check that its top
  `<mameconfig version="…">` matches what your MAME writes (set it once via Option B and copy the number).
- This sets the **emulator's monitor decode only.** Seeing the intended RGB palette also requires the
  booted program to load the RGB palette set — that lives in the game binary, not in this file.
