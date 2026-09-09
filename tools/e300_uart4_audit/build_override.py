"""Build and independently disassemble an exact-image UART4 DSDT candidate.

This tool writes audit artifacts only. It does not load ACPI tables, mount a boot
partition, alter firmware variables, change pinmux, open UART, or reboot.
"""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile


EXPECTED_SHA256 = "ff78c38fdaa33ad52e88f5e5283e789db42dc7b3a1605b8c4ac35aa1b3d785c2"


def decode_length(data, pos):
    first = data[pos]
    extra = first >> 6
    value = first & (0x0F if extra else 0x3F)
    for i in range(extra):
        value |= data[pos + 1 + i] << (4 + 8 * i)
    return value, extra + 1


def encode_length(value, width):
    if not 1 <= width <= 4:
        raise ValueError("Invalid AML package-length width")
    capacity = 64 if width == 1 else 1 << (4 + 8 * (width - 1))
    if not 0 <= value < capacity:
        raise ValueError("Refusing package-length width change")
    if width == 1:
        return bytes([value])
    return bytes([((width - 1) << 6) | (value & 15)]) + bytes(
        (value >> (4 + 8 * i)) & 255 for i in range(width - 1)
    )


def find_package(data, opcode, name, start, end):
    # Narrow decoder for three audited nodes in one SHA-pinned image, not an AML parser.
    found = []
    for pos in range(start, end - len(opcode) - 5):
        if data[pos:pos + len(opcode)] != opcode:
            continue
        length_pos = pos + len(opcode)
        length, width = decode_length(data, length_pos)
        name_pos = length_pos + width
        stop = length_pos + length
        if data[name_pos:name_pos + 4] == name and name_pos + 4 <= stop <= end:
            found.append((pos, length_pos, length, width, name_pos + 4, stop))
    if len(found) != 1:
        raise ValueError(f"Expected one audited {name!r} package; got {len(found)}")
    return found[0]


def patch_table(original):
    if hashlib.sha256(original).hexdigest() != EXPECTED_SHA256:
        raise ValueError("Live DSDT changed; re-audit required")
    if original[:4] != b"DSDT" or sum(original) % 256:
        raise ValueError("Invalid original ACPI table")
    if struct.unpack_from("<I", original, 4)[0] != len(original):
        raise ValueError("Original table length mismatch")
    scope = find_package(original, b"\x10", b"_SB_", 36, len(original))
    device = find_package(original, b"\x5b\x82", b"COM1", scope[4], scope[5])
    method = find_package(original, b"\x14", b"_STA", device[4], device[5])
    if original[method[4]:method[5]] != b"\x00\xa4\x00":
        raise ValueError("Expected zero-argument _STA returning Zero")
    device_bytes = original[device[4]:device[5]]
    if b"MCOM0001\x00" not in device_bytes or b"serial_id\x00\x0a\x04" not in device_bytes:
        raise ValueError("Expected MCOM0001 serial_id 4")
    result = bytearray(original)
    for package in (scope, device, method):
        _, pos, length, width, _, _ = package
        result[pos:pos + width] = encode_length(length + 1, width)
    insert_pos = method[5] - 1
    result[insert_pos:insert_pos + 1] = b"\x0a\x0f"
    struct.pack_into("<I", result, 4, len(result))
    struct.pack_into("<I", result, 24, 0x201)
    result[9] = 0
    result[9] = (-sum(result)) & 255

    # Reverse precisely the permitted modifications, proving every other byte survived.
    reverse = bytearray(result)
    reverse[insert_pos:insert_pos + 2] = b"\x00"
    for package in (scope, device, method):
        _, pos, _, width, _, _ = package
        reverse[pos:pos + width] = original[pos:pos + width]
    for start, end in ((4, 8), (9, 10), (24, 28)):
        reverse[start:end] = original[start:end]
    if reverse != original or sum(result) % 256:
        raise ValueError("Unrelated bytes changed or bad output checksum")
    return bytes(result), {"scope_offset": scope[0], "device_offset": device[0],
                           "method_offset": method[0], "integer_offset": insert_pos}


def source_body(path):
    text = Path(path).read_text()
    start = text.index("DefinitionBlock (")
    return "\n".join(line.rstrip() for line in text[start:].splitlines()).rstrip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--iasl", required=True, type=Path)
    parser.add_argument("--approved-source", required=True, type=Path)
    args = parser.parse_args()
    root = args.output_root.resolve()
    root.mkdir(parents=True, exist_ok=True)
    candidate = root / "uart4-minimal.aml"
    if candidate.resolve() == args.input.resolve():
        raise ValueError("Refusing input overwrite")
    original = args.input.read_bytes()
    result, offsets = patch_table(original)
    candidate.write_bytes(result)
    decoded_prefix = root / "uart4-minimal-decoded"
    command = subprocess.run([str(args.iasl), "-p", str(decoded_prefix), "-d", str(candidate)],
                             capture_output=True, text=True)
    if command.returncode:
        raise ValueError("Independent disassembly failed; candidate must not be used")
    actual = source_body(decoded_prefix.with_suffix(".dsl"))
    approved = source_body(args.approved_source)
    if actual != approved:
        diff = "\n".join(difflib.unified_diff(approved.splitlines(), actual.splitlines()))
        raise ValueError("Candidate differs from reviewed source:\n" + diff[:4000])

    with tempfile.TemporaryDirectory(prefix="uart4-cpio-", dir=root) as temporary:
        stage = Path(temporary)
        target = stage / "kernel/firmware/acpi/uart4.aml"
        target.parent.mkdir(parents=True)
        target.write_bytes(result)
        names = "kernel\nkernel/firmware\nkernel/firmware/acpi\nkernel/firmware/acpi/uart4.aml\n"
        archive = subprocess.run(["cpio", "--create", "--format=newc", "--reproducible"],
                                 input=names.encode(), cwd=stage, capture_output=True, check=True)
    cpio = root / "uart4-minimal.cpio"
    cpio.write_bytes(archive.stdout)
    listing = subprocess.run(["cpio", "-it"], input=archive.stdout,
                             capture_output=True, check=True).stdout.decode().splitlines()
    if listing != names.splitlines():
        raise ValueError("Unexpected archive contents")
    report = {"original_sha256": EXPECTED_SHA256, "candidate_sha256": hashlib.sha256(result).hexdigest(),
              "candidate_bytes": len(result), "cpio_sha256": hashlib.sha256(archive.stdout).hexdigest(),
              "cpio_bytes": len(archive.stdout), "checksum_ok": True,
              "reverse_patch_identical": True, "independent_disassembly_matches_approved_source": True,
              "offsets": offsets, "boot_files_changed": False, "table_loaded": False}
    (root / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
