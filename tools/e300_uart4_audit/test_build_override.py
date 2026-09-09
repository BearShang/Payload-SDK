import unittest

from build_override import decode_length, encode_length, find_package, patch_table


class OverrideGuardTests(unittest.TestCase):
    def test_package_lengths_roundtrip(self):
        for width, values in ((1, (0, 1, 63)), (2, (64, 128, 4095)),
                              (3, (4096, 56043, 1048575)), (4, (1048576, 268435455))):
            for value in values:
                with self.subTest(width=width, value=value):
                    self.assertEqual(decode_length(encode_length(value, width), 0), (value, width))

    def test_width_expansion_refused(self):
        for value, width in ((64, 1), (4096, 2), (1048576, 3)):
            with self.assertRaises(ValueError):
                encode_length(value, width)

    def test_bad_width_refused(self):
        for width in (0, 5):
            with self.assertRaises(ValueError):
                encode_length(1, width)

    def test_negative_length_refused(self):
        with self.assertRaises(ValueError):
            encode_length(-1, 1)

    def test_find_method(self):
        data = b"\x14\x08_STA\x00\xa4\x00"
        self.assertEqual(find_package(data, b"\x14", b"_STA", 0, len(data)), (0, 1, 8, 1, 6, 9))

    def test_duplicate_or_missing_refused(self):
        data = b"\x14\x08_STA\x00\xa4\x00"
        for sample, name in ((data * 2, b"_STA"), (data, b"_INI")):
            with self.assertRaises(ValueError):
                find_package(sample, b"\x14", name, 0, len(sample))

    def test_different_table_refused(self):
        with self.assertRaisesRegex(ValueError, "re-audit"):
            patch_table(b"DSDT" + bytes(60))


if __name__ == "__main__":
    unittest.main()
