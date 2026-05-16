"""
Tests for sprite_convert.py — 4-category color model.

Rule (TASK 4 gate, 2026-05-16):
  - Isolated ON + bit7=1 + even screen col -> palette 2 (Blue)
  - Isolated ON + bit7=1 + odd  screen col -> palette 1 (Orange)
  - Leading of adjacent run + gap==1 -> palette 2/1 per screen-col parity
  - Leading of adjacent run + gap>=2 -> palette 3 (White)
  - Interior / trailing -> palette 3 (White)
  - OFF -> palette 0 (Black)

[ref: MAME snap 0083; 113/113 gap=1, 120/120 gap>=2]
"""
import sys, os, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from tools.sprite_convert import convert_sprite_to_coco3, parse_byte_directive


class TestParseByteDirective(unittest.TestCase):
    def test_hex(self):
        self.assertEqual(parse_byte_directive('.byte $00, $FF, $A5'), [0, 255, 165])

    def test_decimal(self):
        self.assertEqual(parse_byte_directive('.byte 0, 128, 255'), [0, 128, 255])

    def test_comment_stripped(self):
        self.assertEqual(parse_byte_directive('.byte $FF ; sentinel'), [255])

    def test_no_match(self):
        self.assertEqual(parse_byte_directive('; comment only'), [])

    def test_binary(self):
        self.assertEqual(parse_byte_directive('.byte %11110000'), [0xF0])


class TestConvertSpriteColorModel(unittest.TestCase):

    def _decode(self, coco3_bytes, coco3_width):
        indices = []
        for byte_val in coco3_bytes:
            for pix in range(4):
                indices.append((byte_val >> (6 - pix * 2)) & 0b11)
        return indices

    def test_all_off_byte(self):
        result, cw = convert_sprite_to_coco3([0x80], 1, 1)
        idx = self._decode(result, cw)[:7]
        self.assertTrue(all(i == 0 for i in idx))

    def test_all_on_single_byte_gives_white(self):
        result, cw = convert_sprite_to_coco3([0x7F], 1, 1)
        self.assertEqual(cw, 2)
        self.assertEqual(list(result), [0xFF, 0xFC])

    def test_output_values_in_range(self):
        apple = [0x80, 0xAA, 0xD5, 0xCE, 0x9C] * 3
        result, cw = convert_sprite_to_coco3(apple, 3, 5)
        for b in result:
            for pix in range(4):
                self.assertIn((b >> (6 - pix*2)) & 0b11, {0, 1, 2, 3})

    # --- Isolated pixels: screen-col parity ---

    def test_isolated_even_screen_col_is_blue(self):
        # lc=0, sc=0 (even) -> Blue (2)
        result, cw = convert_sprite_to_coco3([0x81], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[0], 2)

    def test_isolated_odd_screen_col_is_orange(self):
        # lc=1, sc=1 (odd) -> Orange (1)
        result, cw = convert_sprite_to_coco3([0x82], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[1], 1)

    # --- Adjacent runs: trailing and interior always White ---

    def test_trailing_pixel_is_white(self):
        result, cw = convert_sprite_to_coco3([0x83], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[1], 3)

    def test_interior_pixel_is_white(self):
        result, cw = convert_sprite_to_coco3([0x87], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[1], 3)

    # --- Leading-edge: gap==1 -> chroma; gap>=2 -> White ---

    def test_leading_gap1_even_screen_col_is_blue(self):
        # 0xEF: run1=[0-3], lc4 OFF (gap=1), run2=[5-6]
        # ON lc=5 (sc=1+5=6 even) drives chroma; painted at lc=4 (-1 sub-pixel offset)
        result, cw = convert_sprite_to_coco3([0xEF], 1, 1, start_col=1)
        self.assertEqual(self._decode(result, cw)[4], 2,
                         "gap=1 chroma at lc=4 (ON lc=5, sc=6 even)->Blue (2)")
        self.assertEqual(self._decode(result, cw)[5], 3,
                         "leading ON lc=5 is White (3)")

    def test_leading_gap1_odd_screen_col_is_orange(self):
        # ON lc=5 -> sc=5 (odd)->Orange; painted at lc=4
        result, cw = convert_sprite_to_coco3([0xEF], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[4], 1,
                         "gap=1 chroma at lc=4 (ON lc=5, sc=5 odd)->Orange (1)")
        self.assertEqual(self._decode(result, cw)[5], 3,
                         "leading ON lc=5 is White (3)")

    def test_leading_gap2_is_white(self):
        # 0xE7 = 11100111: lc0-2 ON (run1=[0-2]), lc3-4 OFF (gap=2), lc5-6 ON (run2=[5-6])
        # Leading of run2 at lc=5: gap=2 -> White (3)
        result, cw = convert_sprite_to_coco3([0xE7], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[5], 3,
                         "leading gap=2 -> White (3)")

    def test_leading_from_row_start_is_white(self):
        # First run in row: gap = run_start = 7 -> White
        # byte0 all off ($80), byte1 bit0 ON -> lc=7 leading, gap=7
        result, cw = convert_sprite_to_coco3([0x80, 0x83], 1, 2, start_col=0)
        self.assertEqual(self._decode(result, cw)[7], 3,
                         "leading from row start (gap=7) -> White (3)")

    # --- Logo regression tests ---

    def test_logo1_isolated_odd_local_is_blue(self):
        # Logo 1, start_col=119, local 9 (odd) -> screen 128 (even) -> Blue (2)
        result, cw = convert_sprite_to_coco3([0x80, 0x84], 1, 2, start_col=119)
        self.assertEqual(self._decode(result, cw)[9], 2)

    def test_logo2_isolated_even_local_is_blue(self):
        # Logo 2, start_col=84, local 14 (even) -> screen 98 (even) -> Blue (2)
        result, cw = convert_sprite_to_coco3([0x80, 0x80, 0x81], 1, 3, start_col=84)
        self.assertEqual(self._decode(result, cw)[14], 2)

    def test_logo2_isolated_not_orange(self):
        result, cw = convert_sprite_to_coco3([0x80, 0x80, 0x81], 1, 3, start_col=84)
        self.assertNotEqual(self._decode(result, cw)[14], 1)

    # --- Structural tests ---

    def test_cross_byte_adjacency(self):
        # lc=6 (byte0 bit6) and lc=7 (byte1 bit0) adjacent -> both White (3)
        result, cw = convert_sprite_to_coco3([0x40, 0x01], 1, 2)
        idx = self._decode(result, cw)
        self.assertEqual(idx[6], 3)
        self.assertEqual(idx[7], 3)

    def test_output_size(self):
        result, cw = convert_sprite_to_coco3([0x00] * 6, 3, 2)
        self.assertEqual(cw, 4)
        self.assertEqual(len(result), 12)

    def test_isolated_bit7_0_quantizes_to_blue(self):
        result, cw = convert_sprite_to_coco3([0x01], 1, 1, start_col=0)
        self.assertEqual(self._decode(result, cw)[0], 2)


if __name__ == '__main__':
    unittest.main()
