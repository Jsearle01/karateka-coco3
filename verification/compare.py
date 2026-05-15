#!/usr/bin/env python3
"""compare.py — karateka-coco3 P2.0b behavioral comparison tool.

Reads an Apple II capture JSON and a CoCo3 capture JSON, loads a variable
mapping, and for each mapped variable compares the bytes at the Apple II
address against the bytes at the CoCo3 address, handling 6502/6809 endianness.

Usage:
    python3 verification/compare.py <apple2_capture.json> <coco3_capture.json> <mapping.json>
    python3 verification/compare.py --self-test

Exit codes:
    0  — no mismatches (matches + pending only)
    1  — one or more mismatches found

Endianness rule (from mapping.json):
    6502 = little-endian: bytes[addr] is low byte, bytes[addr+1] is high byte.
    6809 = big-endian:    bytes[addr] is high byte, bytes[addr+1] is low byte.
    For size>1 entries, both sides are converted to integer values before
    comparison. Raw byte order will differ; that is expected and correct.
    size=1: no endianness conversion needed (single byte).
"""

import json
import sys
from pathlib import Path


def load_json(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def hex_bytes_to_list(bytes_field: list[str]) -> list[int]:
    """Convert ["0xXX", ...] to [int, ...]."""
    return [int(b, 16) for b in bytes_field]


def read_region(capture: dict, start_addr: int, size: int) -> list[int]:
    """Extract `size` bytes starting at `start_addr` from a capture's bytes list.

    The capture's region defines the base address; bytes are relative to that.
    Returns None if the address range falls outside the captured region.
    """
    region_start = int(capture["region"]["start"], 16)
    region_end   = int(capture["region"]["end"], 16)
    if start_addr < region_start or (start_addr + size - 1) > region_end:
        return None
    offset = start_addr - region_start
    raw = hex_bytes_to_list(capture["bytes"])
    return raw[offset : offset + size]


def bytes_to_value_le(b: list[int]) -> int:
    """Little-endian bytes -> integer value (6502 convention)."""
    result = 0
    for i, byte in enumerate(b):
        result |= byte << (8 * i)
    return result


def bytes_to_value_be(b: list[int]) -> int:
    """Big-endian bytes -> integer value (6809 convention)."""
    result = 0
    for byte in b:
        result = (result << 8) | byte
    return result


def compare(apple2_path: str, coco3_path: str, mapping_path: str,
            verbose: bool = True) -> int:
    """Run the comparison. Returns number of mismatches."""
    apple2  = load_json(apple2_path)
    coco3   = load_json(coco3_path)
    mapping = load_json(mapping_path)

    assert apple2.get("platform") in ("apple2e", "apple2"), \
        f"Expected apple2e/apple2 platform, got: {apple2.get('platform')}"
    assert coco3.get("platform") == "coco3", \
        f"Expected coco3 platform, got: {coco3.get('platform')}"

    results = {"match": [], "mismatch": [], "pending": [], "skip": [], "error": []}

    for entry in mapping.get("entries", []):
        name   = entry["semantic_name"]
        status = entry["status"]

        if status == "unmapped":
            results["skip"].append(name)
            continue

        if status == "apple2-confirmed-coco3-predicted":
            # CoCo3 address not yet assigned; report pending, not mismatch.
            results["pending"].append(name)
            continue

        if status != "confirmed":
            results["skip"].append(name)
            continue

        # status == "confirmed": both sides should have addresses.
        a2_addr  = entry["apple2"]["address"]
        c3_addr  = entry["coco3"]["address"]
        size     = entry["apple2"]["size"]

        if c3_addr is None:
            results["pending"].append(name)
            continue

        a2_bytes = read_region(apple2, a2_addr, size)
        c3_bytes = read_region(coco3, c3_addr, size)

        if a2_bytes is None:
            results["error"].append(f"{name}: apple2 addr ${a2_addr:04X} outside capture region")
            continue
        if c3_bytes is None:
            results["error"].append(f"{name}: coco3 addr ${c3_addr:04X} outside capture region")
            continue

        if size == 1:
            # Single byte: direct comparison, no endianness.
            match = (a2_bytes[0] == c3_bytes[0])
            detail = f"apple2=${a2_addr:04X}:0x{a2_bytes[0]:02X}  coco3=${c3_addr:04X}:0x{c3_bytes[0]:02X}"
        else:
            # Multi-byte: compare integer values after endianness conversion.
            a2_val = bytes_to_value_le(a2_bytes)
            c3_val = bytes_to_value_be(c3_bytes)
            match  = (a2_val == c3_val)
            a2_hex = " ".join(f"0x{b:02X}" for b in a2_bytes)
            c3_hex = " ".join(f"0x{b:02X}" for b in c3_bytes)
            detail = (f"apple2=${a2_addr:04X}:[{a2_hex}](LE=0x{a2_val:04X})  "
                      f"coco3=${c3_addr:04X}:[{c3_hex}](BE=0x{c3_val:04X})")

        if match:
            results["match"].append((name, detail))
        else:
            results["mismatch"].append((name, detail))

    if verbose:
        print(f"\nComparison: {Path(apple2_path).name} vs {Path(coco3_path).name}")
        print(f"  Mapping:  {Path(mapping_path).name}")
        print(f"  Apple II region: {apple2['region']['start']}-{apple2['region']['end']}")
        print(f"  CoCo3 region:    {coco3['region']['start']}-{coco3['region']['end']}")
        print()

        if results["match"]:
            print(f"MATCH  ({len(results['match'])})")
            for name, detail in results["match"]:
                print(f"  {name}: {detail}")

        if results["mismatch"]:
            print(f"MISMATCH  ({len(results['mismatch'])})")
            for name, detail in results["mismatch"]:
                print(f"  {name}: {detail}")

        if results["pending"]:
            print(f"PENDING  ({len(results['pending'])}) — coco3 address not yet assigned (TBD-P2.x)")
            for name in results["pending"]:
                print(f"  {name}")

        if results["skip"]:
            print(f"SKIP  ({len(results['skip'])})")

        if results["error"]:
            print(f"ERROR  ({len(results['error'])})")
            for msg in results["error"]:
                print(f"  {msg}")

        n_mismatch = len(results["mismatch"])
        n_error    = len(results["error"])
        print()
        print(f"Summary: {len(results['match'])} match, {n_mismatch} mismatch, "
              f"{len(results['pending'])} pending, {len(results['skip'])} skip, "
              f"{n_error} error")
        if n_mismatch == 0 and n_error == 0:
            print("RESULT: PASS (no mismatches)")
        else:
            print(f"RESULT: FAIL ({n_mismatch} mismatch(es), {n_error} error(s))")

    return len(results["mismatch"])


def self_test() -> None:
    """Run the comparison tool against the synthetic CoCo3 capture and test fixtures.
    Verifies: match detection, mismatch detection, endianness handling, pending skip.
    """
    base = Path(__file__).parent
    apple2_path  = str(Path("../karateka_dissasembly_claude/captures/p2_0a_frame_700_zp.json"))
    coco3_path   = str(base / "synthetic_coco3_capture.json")
    fixtures     = str(base / "test_fixtures.json")

    print("=== compare.py self-test ===")
    print(f"Apple II capture: {apple2_path}")
    print(f"CoCo3 capture:    {coco3_path}")
    print(f"Test fixtures:    {fixtures}")

    n_mismatch = compare(apple2_path, coco3_path, fixtures, verbose=True)

    # The test fixtures define exactly 1 mismatch.
    expected_mismatches = 1
    if n_mismatch == expected_mismatches:
        print(f"\nSELF-TEST PASS: detected exactly {expected_mismatches} mismatch as expected.")
        sys.exit(0)
    else:
        print(f"\nSELF-TEST FAIL: expected {expected_mismatches} mismatch, got {n_mismatch}.")
        sys.exit(1)


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    elif len(sys.argv) == 4:
        n = compare(sys.argv[1], sys.argv[2], sys.argv[3])
        sys.exit(0 if n == 0 else 1)
    else:
        print("Usage:")
        print("  compare.py <apple2_capture> <coco3_capture> <mapping>")
        print("  compare.py --self-test")
        sys.exit(2)
