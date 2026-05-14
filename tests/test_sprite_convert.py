import sys
import os
import unittest

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


class TestConvertSprite(unittest.TestCase):
    def test_all_on_single_byte(self):
        # 1 row, 1 Apple II byte (7 pixels), all ON (bits 0-6 set)
        result, coco3_width = convert_sprite_to_coco3([0x7F], 1, 1)
        # 7 pixels → ceil(7/4) = 2 CoCo3 bytes
        # byte 0: pixels 0-3 all ON → 01_01_01_01 = 0x55
        # byte 1: pixels 4-6 ON + pad → 01_01_01_00 = 0x54
        self.assertEqual(coco3_width, 2)
        self.assertEqual(list(result), [0x55, 0x54])

    def test_all_off(self):
        result, coco3_width = convert_sprite_to_coco3([0x80], 1, 1)
        # bit 7 = color-set selector, ignored; all pixels off
        self.assertEqual(list(result), [0x00, 0x00])

    def test_high_bit_ignored(self):
        # $FF vs $7F should give same result (bit 7 ignored)
        r1, _ = convert_sprite_to_coco3([0xFF], 1, 1)
        r2, _ = convert_sprite_to_coco3([0x7F], 1, 1)
        self.assertEqual(list(r1), list(r2))

    def test_output_size(self):
        # 3 rows × 2 Apple II bytes/row → coco3_width = ceil(14/4) = 4
        apple_bytes = [0x00] * (3 * 2)
        result, coco3_width = convert_sprite_to_coco3(apple_bytes, 3, 2)
        self.assertEqual(coco3_width, 4)
        self.assertEqual(len(result), 3 * 4)


if __name__ == '__main__':
    unittest.main()
