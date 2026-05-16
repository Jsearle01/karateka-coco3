"""
Tests for sprite_render_apple2.py — 4-category color model.

Rule (TASK 4 gate, 2026-05-16; validated against MAME snap 0083):
  - Isolated ON + bit7=1 + even screen col -> Blue   (screen-col parity)
  - Isolated ON + bit7=1 + odd  screen col -> Orange (screen-col parity)
  - Leading of adjacent run + gap_before==1 -> Blue/Orange per screen-col parity
  - Leading of adjacent run + gap_before>=2 -> White (no NTSC carrier buildup)
  - Interior / trailing of adjacent run -> White
  - OFF -> Black

gap_before threshold: 113/113 gap=1 chroma; 120/120 gap>=2 White (snap 0083).
[ref: C:\karateka-capture\snap\apple2e\0083.png]
"""
import sys, os, tempfile, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    from tools.sprite_render_apple2 import (render, COLOR_BLACK, COLOR_ORANGE,
                                             COLOR_BLUE, COLOR_WHITE,
                                             COLOR_GREEN, COLOR_VIOLET)
    from PIL import Image
    HAVE_PIL = True
except ImportError:
    HAVE_PIL = False


@unittest.skipUnless(HAVE_PIL, "PIL/Pillow not available")
class TestAppleIIColor(unittest.TestCase):
    SCALE = 1

    def _render_1row(self, apple_bytes, width_bytes, start_col=0):
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
            path = tmp.name
        render(1, width_bytes, apple_bytes, path, scale=self.SCALE, start_col=start_col)
        img = Image.open(path)
        px = img.load()
        row = [px[x, 0] for x in range(width_bytes * 7)]
        os.unlink(path)
        return row

    # --- Basic rules (start_col=0) ---

    def test_off_pixel_is_black(self):
        row = self._render_1row([0x80], 1)
        self.assertTrue(all(c == COLOR_BLACK for c in row))

    def test_all_on_is_all_white(self):
        row = self._render_1row([0x7F], 1)
        self.assertTrue(all(c == COLOR_WHITE for c in row))

    # --- Isolated pixels: always colored, screen-col parity ---

    def test_isolated_even_screen_col_is_blue(self):
        # start_col=0, local 0 -> screen 0 (even) -> Blue
        row = self._render_1row([0x81], 1, start_col=0)
        self.assertEqual(row[0], COLOR_BLUE)

    def test_isolated_odd_screen_col_is_orange(self):
        # start_col=0, local 1 -> screen 1 (odd) -> Orange
        row = self._render_1row([0x82], 1, start_col=0)
        self.assertEqual(row[1], COLOR_ORANGE)

    # --- Adjacent runs: trailing and interior always White ---

    def test_trailing_pixel_is_white(self):
        # 2-pixel run at cols 0-1; col 1 (trailing) -> White
        row = self._render_1row([0x83], 1, start_col=0)
        self.assertEqual(row[1], COLOR_WHITE)

    def test_interior_pixel_is_white(self):
        # 3-pixel run cols 0-2; col 1 (interior) -> White
        row = self._render_1row([0x87], 1, start_col=0)
        self.assertEqual(row[1], COLOR_WHITE)

    # --- Leading-edge: gap==1 -> chroma; gap>=2 -> White ---

    def test_leading_gap1_even_screen_col_is_blue(self):
        # 0xEF = 11101111: run1=[0-3], lc4 OFF (gap=1), run2=[5-6]
        # Chroma attributed to ON lc=5 (sc=1+5=6 even->Blue); painted at lc=4 (-1 offset).
        # [ref: Option 2 — ON pixel drives chroma, -1 sub-pixel render offset]
        row = self._render_1row([0xEF], 1, start_col=1)
        self.assertEqual(row[4], COLOR_BLUE,
                         f"gap=1 chroma at lc=4 (from ON lc=5, sc=6 even)->Blue; got {row[4]}")
        self.assertEqual(row[5], COLOR_WHITE,
                         f"leading ON lc=5 is White (chroma painted at lc-1); got {row[5]}")

    def test_leading_gap1_odd_screen_col_is_orange(self):
        # start_col=0: ON lc=5 -> sc=5 (odd)->Orange; painted at lc=4 (-1 offset)
        row = self._render_1row([0xEF], 1, start_col=0)
        self.assertEqual(row[4], COLOR_ORANGE,
                         f"gap=1 chroma at lc=4 (from ON lc=5, sc=5 odd)->Orange; got {row[4]}")
        self.assertEqual(row[5], COLOR_WHITE,
                         f"leading ON lc=5 is White; got {row[5]}")

    def test_leading_gap2_is_white(self):
        # 0xE7 = 11100111: lc0-2 ON (run1=[0-2]), lc3-4 OFF (gap=2), lc5-6 ON (run2=[5-6])
        # Leading of run2 at lc=5: gap=2 -> White regardless of parity
        row = self._render_1row([0xE7], 1, start_col=0)
        self.assertEqual(row[5], COLOR_WHITE,
                         f"leading gap=2 -> White; got {row[5]}")

    def test_leading_gap_from_row_start_is_white(self):
        # First run in row after long gap from position 0
        # byte0: all OFF ($80); byte1: bit 0 ON, rest OFF ($81) -> lc=7 leads
        # gap_before = 7 (positions 0-6 all OFF) -> White
        row = self._render_1row([0x80, 0x83], 2, start_col=0)
        # lc=7 leading, gap=7 from row start -> White
        self.assertEqual(row[7], COLOR_WHITE,
                         f"leading from row start (gap=7) -> White; got {row[7]}")

    # --- Screen-col parity: Logo 1 and Logo 2 regression ---

    def test_logo1_isolated_local_odd_is_blue(self):
        # Logo 1, start_col=119, local 9 (odd) -> screen 128 (even) -> Blue
        row = self._render_1row([0x80, 0x84], 2, start_col=119)
        self.assertEqual(row[9], COLOR_BLUE)

    def test_logo1_isolated_local_even_is_orange(self):
        # Logo 1, start_col=119, local 16 (even) -> screen 135 (odd) -> Orange
        row = self._render_1row([0x80, 0x80, 0x84], 3, start_col=119)
        self.assertEqual(row[16], COLOR_ORANGE)

    def test_logo2_isolated_local_even_is_blue(self):
        # Logo 2, start_col=84, local 14 (even) -> screen 98 (even) -> Blue
        row = self._render_1row([0x80, 0x80, 0x81], 3, start_col=84)
        self.assertEqual(row[14], COLOR_BLUE)

    def test_logo2_isolated_not_orange(self):
        # Regression: Logo 2 local even must NOT be Orange (old local-col rule)
        row = self._render_1row([0x80, 0x80, 0x81], 3, start_col=84)
        self.assertNotEqual(row[14], COLOR_ORANGE)

    # --- bit7=0 (predicted) ---

    def test_isolated_bit7_0_even_screen_col_is_green(self):
        row = self._render_1row([0x01], 1, start_col=0)
        self.assertEqual(row[0], COLOR_GREEN)

    def test_isolated_bit7_0_odd_screen_col_is_violet(self):
        row = self._render_1row([0x02], 1, start_col=0)
        self.assertEqual(row[1], COLOR_VIOLET)


if __name__ == '__main__':
    unittest.main()
