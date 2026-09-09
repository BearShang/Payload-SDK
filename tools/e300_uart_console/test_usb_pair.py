"""Test two crossed CP2102 adapters on E300; neither USB end may be on aircraft."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import select
import subprocess
import termios
import time


PORTS = (("/dev/ttyUSB0", "1-3"), ("/dev/ttyUSB1", "1-2"))
RATES = (115200, 230400, 460800, 921600, 1000000)
FORWARD = bytes(range(256)) * 16
REVERSE = bytes(x ^ 0xa5 for x in FORWARD)


def transfer(sender, receiver, payload, timeout=3):
    sent = 0
    received = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready_r, ready_w, _ = select.select(
            [receiver], [sender] if sent < len(payload) else [], [],
            max(0, deadline - time.monotonic()),
        )
        if ready_w:
            try:
                sent += os.write(sender, payload[sent:sent + 256])
            except BlockingIOError:
                pass
        if ready_r:
            try:
                chunk = os.read(receiver, 8192)
            except BlockingIOError:
                continue
            if not chunk:
                raise RuntimeError("Receiver closed during transfer")
            received.extend(chunk)
        if sent == len(payload) and len(received) >= len(payload):
            # Include unexpected trailing bytes rather than accepting only a prefix.
            quiet_end = time.monotonic() + 0.1
            while time.monotonic() < quiet_end:
                ready, _, _ = select.select([receiver], [], [], max(0, quiet_end - time.monotonic()))
                if not ready:
                    break
                extra = os.read(receiver, 8192)
                if not extra:
                    raise RuntimeError("Receiver closed during trailing-byte check")
                received.extend(extra)
            break
    mismatch = next((i for i, (a, b) in enumerate(zip(payload, received)) if a != b), None)
    if mismatch is None and len(received) != len(payload):
        mismatch = min(len(received), len(payload))
    return {
        "tx_queued_bytes": sent, "rx_bytes": len(received),
        "exact": sent == len(payload) and received == payload,
        "first_mismatch_offset": mismatch,
        "rx_sha256": hashlib.sha256(received).hexdigest(),
        "expected_sha256": hashlib.sha256(payload).hexdigest(),
    }


def preflight():
    if os.geteuid() != 0:
        raise RuntimeError("Root required for complete ownership check")
    consoles = {line.split()[0] for line in Path("/proc/consoles").read_text().splitlines()}
    for device, expected_path in PORTS:
        if Path(device).name in consoles:
            raise RuntimeError("Refusing kernel console")
        sysdev = (Path("/sys/class/tty") / Path(device).name / "device").resolve(strict=True)
        usb = next(p for p in sysdev.parents if (p / "idVendor").exists())
        if (usb.name != expected_path or (usb / "idVendor").read_text().strip() != "10c4"
                or (usb / "idProduct").read_text().strip() != "ea60"
                or (sysdev / "driver").resolve(strict=True).name != "cp210x"):
            raise RuntimeError("USB identity/path changed; inspect before testing")
    busy = subprocess.run(["fuser", *(device for device, _ in PORTS)], capture_output=True, timeout=5)
    if busy.returncode != 1 or busy.stdout.strip() or busy.stderr.strip():
        raise RuntimeError("Refusing occupied ports or failed ownership check")


def configure(fd, rate):
    settings = termios.tcgetattr(fd)
    settings[0:4] = [0, 0, termios.CS8 | termios.CREAD | termios.CLOCAL, 0]
    settings[4] = settings[5] = getattr(termios, f"B{rate}")
    settings[6][termios.VMIN] = settings[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, settings)
    actual = termios.tcgetattr(fd)
    framing_mask = termios.CSIZE | termios.CSTOPB | termios.PARENB | termios.CRTSCTS | termios.CLOCAL | termios.CREAD
    if (actual[0:2] != [0, 0] or actual[3] != 0 or actual[4:6] != settings[4:6]
            or actual[2] & framing_mask != settings[2] & framing_mask):
        raise RuntimeError("Termios readback mismatch")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", action="store_true", help="Send fixed test bytes on both isolated adapters")
    args = parser.parse_args()
    preflight()
    print("pair_preflight=passed", flush=True)
    if not args.run:
        return 0
    opened = []
    all_passed = True
    cleanup_errors = []
    try:
        for device, _ in PORTS:
            fd = os.open(device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK | os.O_CLOEXEC)
            opened.append([fd, None])
            fcntl.ioctl(fd, termios.TIOCEXCL)
            opened[-1][1] = termios.tcgetattr(fd)
        for rate in RATES:
            for fd, _ in opened:
                configure(fd, rate)
            time.sleep(0.1)
            for sender, receiver, payload, direction in (
                (opened[0][0], opened[1][0], FORWARD, "J3_to_J1"),
                (opened[1][0], opened[0][0], REVERSE, "J1_to_J3"),
            ):
                for fd, _ in opened:
                    termios.tcflush(fd, termios.TCIOFLUSH)
                result = transfer(sender, receiver, payload)
                all_passed &= result["exact"]
                print(json.dumps({"baud": rate, "direction": direction, **result}), flush=True)
    finally:
        for fd, original in reversed(opened):
            try:
                if original is not None:
                    termios.tcsetattr(fd, termios.TCSANOW, original)
                    if termios.tcgetattr(fd) != original:
                        raise RuntimeError("Restoration readback mismatch")
            except Exception as exc:
                cleanup_errors.append(str(exc))
            finally:
                try:
                    fcntl.ioctl(fd, termios.TIOCNXCL)
                except OSError as exc:
                    cleanup_errors.append(str(exc))
                finally:
                    os.close(fd)
        print(json.dumps({"settings_restored_and_ports_closed": not cleanup_errors,
                          "cleanup_errors": cleanup_errors}), flush=True)
    return 0 if all_passed and not cleanup_errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
