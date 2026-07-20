#!/usr/bin/env python3
"""
sprite_tool_app.py — hand-authoring sprite tool (M1-M5 wired).

  python harness/tools/sprite_tool/sprite_tool_app.py [block frame_index | placement_id]
  default: climb_crawl 0

Load/assemble a frame from the §2F table (sub-byte), aspect-correct render (non-square 4x5
cells, integer zoom, nearest), paint colour + opacity (white/blue/orange/black-opaque/trans),
undo/redo, changed-pixel highlight, cel selector for overlap routing, coord+owner readout,
and SAVE (converted.s byte-identical for opacity-only + opacity sidecar + registry state,
derive-and-verify, .bak). FIXED dims — painting never changes a cel's size/origin.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from placement_table import Table
from frame_assembly import assemble_animation, assemble_static
from pixel_map import CELL_W, CELL_H, screen_to_sprite
from render import render_frame
from edit_model import FrameEdit, PALETTE
import opacity as O
from save import save_cel, SaveIOError

SWATCH_RGB = {"white": "#FFFFFF", "blue": "#00AAFF", "orange": "#FF5500",
              "black": "#000000", "trans": "#808080"}
ARM = "#FFE400"      # armed-swatch highlight border

MARGIN = 10

def build_frame(table, args):
    if len(args) >= 2:
        return assemble_animation(table, args[0], int(args[1])), (args[0], int(args[1]))
    if len(args) == 1:
        return assemble_static(table, args[0]), (args[0],)
    return assemble_animation(table, "climb_crawl", 0), ("climb_crawl", 0)

def main():
    table = Table()
    frame, ident = build_frame(table, sys.argv[1:])
    edit = FrameEdit(table, frame)

    try:
        import tkinter as tk
        from PIL import ImageTk
    except Exception as e:
        print(f"GUI needs Tkinter + Pillow on a machine with a display: {e}")
        print(f"(headless: frame '{frame.label}' {frame.W}x{frame.H}px, cels {list(edit.cels)} — "
              f"assembly/edit model work; run on your desktop for the UI.)")
        return

    root = tk.Tk()
    root.title(f"sprite tool — {frame.label}")
    state = {"zoom": 4, "entry": "black", "img": None, "painting": False}

    bar = tk.Frame(root); bar.pack(fill="x")
    # FIXED width (monospace) + left-anchored so the readout's changing text never resizes the
    # label and shoves the palette/controls to its right.
    coord = tk.Label(bar, text="move over a pixel…", font=("Consolas", 10), width=46, anchor="w")
    coord.pack(side="left", padx=6)
    # palette — each swatch shows its colour; the ARMED one gets a bright highlight border
    swatches = {}
    def arm(n):
        state["entry"] = n
        for nm, fr in swatches.items():
            fr.config(bg=ARM if nm == n else bar.cget("bg"),
                      highlightbackground=ARM if nm == n else bar.cget("bg"))
    for name in ("white", "blue", "orange", "black", "trans"):
        fr = tk.Frame(bar, bg=bar.cget("bg"), bd=0, padx=3, pady=3); fr.pack(side="left")
        tk.Button(fr, text=name, bg=SWATCH_RGB[name],
                  fg="#000000" if name in ("white", "orange", "trans") else "#FFFFFF",
                  activebackground=SWATCH_RGB[name], width=6,
                  command=lambda n=name: (arm(n))).pack()
        swatches[name] = fr
    # FRAME selector (primary): every animation frame + every static placement.
    frame_specs = []
    for block, frames in table.anim.items():
        for i, fr in enumerate(frames):
            frame_specs.append((f"{block} {fr.fid}", ("anim", block, i)))
    for pid in table.placement:
        frame_specs.append((f"static: {pid}", ("static", pid, None)))
    spec_by_label = dict(frame_specs)
    if len(ident) >= 2:
        init_label = f"{ident[0]} {table.anim[ident[0]][ident[1]].fid}"
    else:
        init_label = f"static: {ident[0]}"
    prev_label = [init_label]
    tk.Label(bar, text="frame:").pack(side="left")
    framevar = tk.StringVar(value=init_label)
    tk.OptionMenu(bar, framevar, *[l for l, _ in frame_specs],
                  command=lambda l: select_frame(l)).pack(side="left")
    # cel selector (secondary — overlap routing only)
    tk.Label(bar, text="paint cel:").pack(side="left", padx=(8, 0))
    celvar = tk.StringVar(value=edit.selected)
    def on_cel(*_): edit.selected = celvar.get()
    celmenu = tk.OptionMenu(bar, celvar, *edit.cels.keys(), command=on_cel)
    celmenu.pack(side="left")

    canvas = tk.Canvas(root, width=1040, height=640, bg="#282828"); canvas.pack(fill="both", expand=True)
    # prominent SAVE banner (bottom): only save writes it, so redraw() can't clobber the result.
    savebar = tk.Label(root, text="ready — paint, then Save (Ctrl-S)", anchor="w",
                       font=("Consolas", 12, "bold"), fg="white", bg="#444",
                       padx=10, pady=8, justify="left", wraplength=1100)
    savebar.pack(side="bottom", fill="x")
    status = tk.Label(root, text="", anchor="w", font=("Consolas", 9))
    status.pack(side="bottom", fill="x")

    def opac_map():  return {cid: ce.opacity for cid, ce in edit.cels.items()}
    def chg_map():   return {cid: ce.changed() for cid, ce in edit.cels.items()}

    LABEL_H = 18
    def redraw():
        z = state["zoom"]
        old = render_frame(frame, zoom=z, boundaries=True,
                           pixels_by_cel={cid: ce.orig_pixels for cid, ce in edit.cels.items()},
                           opacity_by_cel={cid: ce.orig_opacity for cid, ce in edit.cels.items()})
        new = render_frame(frame, zoom=z, boundaries=True,
                           opacity_by_cel=opac_map(), changed_by_cel=chg_map())
        state["old_img"] = ImageTk.PhotoImage(old)
        state["new_img"] = ImageTk.PhotoImage(new)
        canvas.delete("all")
        # OLD (read-only, left) | NEW (editable, right)
        canvas.create_text(MARGIN, 2, anchor="nw", text="OLD  (read-only)", fill="#bbbbbb",
                           font=("Consolas", 10, "bold"))
        canvas.create_image(MARGIN, LABEL_H, anchor="nw", image=state["old_img"])
        nx = MARGIN + old.width + 36
        state["new_x0"], state["new_y0"] = nx, LABEL_H
        canvas.create_text(nx, 2, anchor="nw", text="NEW  (paint here — yellow = changed)",
                           fill="#ffe400", font=("Consolas", 10, "bold"))
        canvas.create_image(nx, LABEL_H, anchor="nw", image=state["new_img"])
        canvas.config(scrollregion=(0, 0, nx + new.width + MARGIN, LABEL_H + new.height + MARGIN))
        status.config(text=f"zoom {z}x  cell {CELL_W*z}x{CELL_H*z}px (4:5)  "
                           f"active={edit.selected}  edited={[c.cel_id for c in edit.edited_cels()]}")

    def select_frame(label):
        nonlocal frame, edit
        if label == prev_label[0]:
            return
        if edit.edited_cels():                       # discard-guard for unsaved edits
            import tkinter.messagebox as mb
            if not mb.askyesno("Discard edits?",
                               f"Unsaved edits on {[c.cel_id for c in edit.edited_cels()]} will be "
                               f"LOST switching frames. Switch anyway?"):
                framevar.set(prev_label[0]); return   # revert the dropdown
        kind, a, b = spec_by_label[label]
        frame = assemble_animation(table, a, b) if kind == "anim" else assemble_static(table, a)
        edit = FrameEdit(table, frame)
        prev_label[0] = label
        m = celmenu["menu"]; m.delete(0, "end")       # rebuild the cel selector for the new frame
        for cid in edit.cels:
            m.add_command(label=cid, command=lambda c=cid: (celvar.set(c), on_cel()))
        celvar.set(edit.selected)
        root.title(f"sprite tool — {frame.label}")
        redraw()

    def canvas_to_frame(e):
        return screen_to_sprite(e.x - state.get("new_x0", MARGIN), e.y - state.get("new_y0", MARGIN), state["zoom"])

    def on_move(e):
        fx, fy = canvas_to_frame(e)
        cpx, cpy = frame.x0 + fx, frame.y0 + fy
        owners = [(p.cel_id, p.cel.pixels[cpy - p.y][cpx - p.x]) for p in frame.placed if p.covers(cpx, cpy)]
        if 0 <= fx < frame.W and 0 <= fy < frame.H and owners:
            note = "  [OVERLAP -> active]" if len(owners) > 1 else ""
            coord.config(text=f"({fx},{fy}) " + " ".join(f"{c}={v}" for c, v in owners) + note)
        else:
            coord.config(text=f"({fx},{fy}) background")

    def on_press(e):
        for ce in edit.cels.values(): ce.begin_stroke()   # snapshot all for a coherent undo step
        state["painting"] = True
        on_drag(e)
    def on_drag(e):
        if not state["painting"]: return
        fx, fy = canvas_to_frame(e)
        if 0 <= fx < frame.W and 0 <= fy < frame.H:
            edit.paint_canvas(fx, fy, state["entry"]); redraw()
    def on_release(e): state["painting"] = False

    def do_undo(_=None):
        for ce in edit.cels.values(): ce.undo_stroke()
        redraw()
    def do_redo(_=None):
        for ce in edit.cels.values(): ce.redo_stroke()
        redraw()
    def zoom_in(_=None): state["zoom"] = min(12, state["zoom"]+1); redraw()
    def zoom_out(_=None): state["zoom"] = max(1, state["zoom"]-1); redraw()

    def do_save(_=None):
        import tkinter.messagebox as mb
        edited = edit.edited_cels()
        if not edited:
            savebar.config(text="nothing edited — nothing to save", fg="white", bg="#666"); return
        ok_msgs, stop_msgs = [], []
        for ce in edited:
            try:
                r = save_cel(ce.cel, ce.cel_dir, ce.label, ce.opacity, ce.sprite_id, table.path)
                conv = "converted.s byte-identical" if r["byte_identical"] else "converted.s colour-changed"
                sc = f"opacity.s ({r['kind']}) written" if r["state"] == "authored" else "no sidecar (none)"
                note = "  [stencil: authored; build-render wiring is a follow-up]" if r["kind"] == "stencil" else ""
                ok_msgs.append(f"Saved {ce.cel_id} — {conv}, {sc}, registry→{r['state']}{note}")
                ce.orig_pixels = [row[:] for row in ce.cel.pixels]
                ce.orig_opacity = [row[:] for row in ce.opacity]
            except O.CannotEncode as ex:
                stop_msgs.append(f"NOT SAVED — {ce.cel_id}: marking needs per-pixel (row-varying) "
                                 f"opacity; mixed/masked can't encode it → stencil_punch path. [{ex}]")
            except AssertionError as ex:
                stop_msgs.append(f"NOT SAVED — {ce.cel_id}: {ex}")
            except SaveIOError as ex:                     # hard error → modal popup + rolled back
                mb.showerror("Save failed (rolled back)",
                             f"{ce.cel_id}: {ex}\nThe pre-save state was restored (no half-written files).")
                stop_msgs.append(f"SAVE FAILED (rolled back) — {ce.cel_id}: {ex}")
        if stop_msgs:
            savebar.config(text="  ||  ".join(stop_msgs + ok_msgs), fg="white", bg="#b02020")
        else:
            savebar.config(text="  |  ".join(ok_msgs), fg="white", bg="#1b7f1b")
        redraw()   # updates the info line only; the save banner above is untouched

    tk.Button(bar, text="undo", command=do_undo).pack(side="right")
    tk.Button(bar, text="redo", command=do_redo).pack(side="right")
    tk.Button(bar, text="SAVE", command=do_save).pack(side="right", padx=6)
    tk.Button(bar, text="+", command=zoom_in).pack(side="right")
    tk.Button(bar, text="-", command=zoom_out).pack(side="right")
    canvas.bind("<Motion>", on_move)
    canvas.bind("<ButtonPress-1>", on_press)
    canvas.bind("<B1-Motion>", on_drag)
    canvas.bind("<ButtonRelease-1>", on_release)
    root.bind("<Control-z>", do_undo); root.bind("<Control-y>", do_redo)
    root.bind("<Control-s>", do_save); root.bind("+", zoom_in); root.bind("-", zoom_out)
    arm(state["entry"])          # show the initially-armed swatch
    redraw()
    root.mainloop()

if __name__ == "__main__":
    main()
