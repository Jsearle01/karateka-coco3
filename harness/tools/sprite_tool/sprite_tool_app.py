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
    state = {"zoom": 5, "entry": "black", "img": None, "painting": False}

    bar = tk.Frame(root); bar.pack(fill="x")
    coord = tk.Label(bar, text="move over a pixel…", font=("Consolas", 10)); coord.pack(side="left", padx=6)
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
    # cel selector (overlap routing)
    celvar = tk.StringVar(value=edit.selected)
    def on_cel(*_): edit.selected = celvar.get()
    tk.OptionMenu(bar, celvar, *edit.cels.keys(), command=on_cel).pack(side="left", padx=6)
    tk.Label(bar, text="(active cel)").pack(side="left")

    canvas = tk.Canvas(root, width=820, height=600, bg="#282828"); canvas.pack(fill="both", expand=True)
    status = tk.Label(root, text="", anchor="w", font=("Consolas", 9)); status.pack(fill="x")

    def opac_map():  return {cid: ce.opacity for cid, ce in edit.cels.items()}
    def chg_map():   return {cid: ce.changed() for cid, ce in edit.cels.items()}

    def redraw():
        img = render_frame(frame, zoom=state["zoom"], boundaries=True,
                           opacity_by_cel=opac_map(), changed_by_cel=chg_map())
        state["img"] = ImageTk.PhotoImage(img)
        canvas.delete("all")
        canvas.create_image(MARGIN, MARGIN, anchor="nw", image=state["img"])
        status.config(text=f"zoom {state['zoom']}x  cell {CELL_W*state['zoom']}x{CELL_H*state['zoom']}px (4:5)  "
                           f"active={edit.selected}  edited={[c.cel_id for c in edit.edited_cels()]}")

    def canvas_to_frame(e):
        return screen_to_sprite(e.x - MARGIN, e.y - MARGIN, state["zoom"])

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
            status.config(text="nothing edited — nothing to save", fg="#bbbbbb"); return
        ok_msgs, stop_msgs = [], []
        for ce in edited:
            try:
                r = save_cel(ce.cel, ce.cel_dir, ce.label, ce.opacity, ce.sprite_id, table.path)
                conv = "converted.s byte-identical" if r["byte_identical"] else "converted.s colour-changed"
                sc = f"opacity.s ({r['kind']}) written" if r["state"] == "authored" else "no sidecar (none)"
                ok_msgs.append(f"Saved {ce.cel_id} — {conv}, {sc}, registry→{r['state']}")
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
            status.config(text="  ||  ".join(stop_msgs + ok_msgs), fg="#ff5555")
        else:
            status.config(text="  |  ".join(ok_msgs), fg="#55ff55")
        redraw()

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
