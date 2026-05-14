import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from tools.sound_convert import convert_pcm_samples, convert_tone_records


class TestSoundConvert(unittest.TestCase):
    def test_pcm_8bit_to_6bit(self):
        result = convert_pcm_samples([255, 128, 0])
        self.assertEqual(list(result), [63, 32, 0])

    def test_pcm_range(self):
        result = convert_pcm_samples(list(range(256)))
        self.assertTrue(all(0 <= b <= 63 for b in result))

    def test_tone_passthrough(self):
        original = bytes([0x01, 0xFF, 0x10, 0x20])
        self.assertEqual(convert_tone_records(original), original)

    def test_tone_passthrough_full(self):
        original = bytes(range(256))
        self.assertEqual(convert_tone_records(original), original)


if __name__ == '__main__':
    unittest.main()
