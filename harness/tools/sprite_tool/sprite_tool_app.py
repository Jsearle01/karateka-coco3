#!/usr/bin/env python3
"""
sprite_tool_app.py — hand-authoring sprite tool, VIEWER stage (M1-M3 wired).

  python harness/tools/sprite_tool/sprite_tool_app.py [block frame_index]
  default: climb_crawl 0

Runs on Jay's machine (Tkinter + Pillow). Shows the assembled climb frame aspect-correct
(non-square 4x5 cells), integer zoom, nearest-neighbor, coord readout + cel owner, cel-
boundary overlay. Old (read-only) = the on-disk cels; New = the editable copy.

PAINTING (M4) + SAVE (M5) are intentionally NOT wired yet — they depend on the trans-vs-
opaque-black paint model (the `f` 4bpp question), pending Jay's decision. This stage proves
the load/assemble/aspect-correct-render/pixel-map path Jay can already run and eyeball.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from placement_table import Table
from frame_assembly import assemble_animation, assemble_static
from pixel_map import CELL_W, CELL_H, screen_to_sprite
from render import render_frame, RGB, TRANS_GRAY


class ViewerModel:
    """Headlessly-testable state: frame + zoom + a coord/owner lookup (no Tk)."""
    def __init__(self, table, block=None, frame_index=0, placement_id=None):
        self.table = table
        if placement_id:
            self.frame = assemble_static(table, placement_id)
        else:
            self.frame = assemble_animation(table, block or "climb_crawl", frame_index)
        self.zoom = 4

    def probe(self, screen_x, screen_y):
        """Screen click -> (sprite_px, sprite_py, [owner cel ids + value at that pixel])."""
        px, py = screen_to_sprite(screen_x, screen_y, self.zoom)
        cpx, cpy = self.frame.x0 + px, self.frame.y0 + py
        owners = []
        for pc in self.frame.owners(cpx, cpy):
            owners.append((pc.cel_id, pc.cel.pixels[cpy - pc.y][cpx - pc.x]))
        return px, py, owners


def main():
    args = sys.argv[1:]
    table = Table()
    if len(args) >= 2:
        model = ViewerModel(table, block=args[0], frame_index=int(args[1]))
    elif len(args) == 1:
        model = ViewerModel(table, placement_id=args[0])
    else:
        model = ViewerModel(table, "climb_crawl", 0)

    try:
        import tkinter as tk
        from PIL import ImageTk
    except Exception as e:
        print(f"GUI needs Tkinter + Pillow on a machine with a display: {e}")
        print(f"(headless: frame '{model.frame.label}' = {model.frame.W}x{model.frame.H}px, "
              f"{len(model.frame.placed)} cels — assembly works; run on your desktop for the UI.)")
        return

    root = tk.Tk()
    root.title(f"sprite tool — {model.frame.label} (VIEWER: paint/save pending model decision)")
    top = tk.Frame(root); top.pack(fill="x")
    coord = tk.Label(top, text="move over a pixel…", font=("Consolas", 11)); coord.pack(side="left", padx=8)
    zlbl = tk.Label(top, text=f"zoom {model.zoom}x  cell {CELL_W}x{CELL_H} (4:5 aspect)"); zlbl.pack(side="right", padx=8)
    canvas = tk.Canvas(root, width=760, height=560, bg="#282828"); canvas.pack(fill="both", expand=True)
    state = {"img": None}

    def redraw():
        pilimg = render_frame(model.frame, zoom=model.zoom, boundaries=True)
        state["img"] = ImageTk.PhotoImage(pilimg)
        canvas.delete("all")
        canvas.create_image(10, 10, anchor="nw", image=state["img"])
        zlbl.config(text=f"zoom {model.zoom}x  cell {CELL_W*model.zoom}x{CELL_H*model.zoom}px (4:5)")

    def on_move(e):
        px, py, owners = model.probe(e.x - 10, e.y - 10)
        if 0 <= px < model.frame.W and 0 <= py < model.frame.H and owners:
            own = " ".join(f"{cid}={val}" for cid, val in owners)
            note = "  [OVERLAP: routes to selected]" if len(owners) > 1 else ""
            coord.config(text=f"sprite ({px},{py})  owner: {own}{note}")
        else:
            coord.config(text=f"sprite ({px},{py})  (background)")

    def zoom_in(_=None):  model.zoom = min(12, model.zoom + 1); redraw()
    def zoom_out(_=None): model.zoom = max(1, model.zoom - 1); redraw()
    canvas.bind("<Motion>", on_move)
    root.bind("+", zoom_in); root.bind("-", zoom_out)
    tk.Button(top, text="+", command=zoom_in).pack(side="right")
    tk.Button(top, text="-", command=zoom_out).pack(side="right")
    redraw()
    root.mainloop()


if __name__ == "__main__":
    main()
