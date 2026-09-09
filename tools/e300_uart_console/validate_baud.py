"""Binary UART test. The selected UART bridge must connect to the PC, not aircraft."""
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

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--baud", type=int, choices=[115200, 460800, 921600], required=True)
parser.add_argument("--device", choices=["/dev/ttyS0", "/dev/ttyMT4"], default="/dev/ttyS0")
args = parser.parse_args()
if any(line.split()[0] == Path(args.device).name for line in Path("/proc/consoles").read_text().splitlines()):
    raise SystemExit("Refusing active kernel console")
if os.geteuid() != 0:
    raise SystemExit("Root required for complete ownership check")
devices = [args.device, "/dev/console"] if args.device == "/dev/ttyS0" else [args.device]
busy = subprocess.run(["fuser", *devices], capture_output=True)
if busy.returncode != 1 or busy.stdout.strip() or busy.stderr.strip():
    raise SystemExit("Refusing occupied UART")
expected = bytes(range(256)) * 16
response = bytes(x ^ 0xa5 for x in expected)
fd = os.open(args.device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
original = None
try:
    fcntl.ioctl(fd, termios.TIOCEXCL)
    original = termios.tcgetattr(fd)
    settings = termios.tcgetattr(fd)
    settings[0:4] = [0, 0, termios.CS8 | termios.CREAD | termios.CLOCAL, 0]
    settings[4] = settings[5] = getattr(termios, f"B{args.baud}")
    settings[6][termios.VMIN] = settings[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, settings)
    termios.tcflush(fd, termios.TCIOFLUSH)
    actual = termios.tcgetattr(fd)
    print(f"UART_TEST_READY baud={args.baud} termios_match={actual[4:6] == settings[4:6]}", flush=True)
    received = bytearray()
    deadline = time.monotonic() + 15
    while len(received) < len(expected) and time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], max(0, deadline - time.monotonic()))
        if ready:
            received.extend(os.read(fd, 8192))
    passed = received == expected
    sent = 0
    if passed:
        deadline = time.monotonic() + 10
        while sent < len(response) and time.monotonic() < deadline:
            _, ready, _ = select.select([], [fd], [], max(0, deadline - time.monotonic()))
            if ready:
                sent += os.write(fd, response[sent:])
    # Keep the test baud until the PC confirms the complete reverse transfer.
    ack = b""
    if sent == len(response):
        ready, _, _ = select.select([fd], [], [], 5)
        if ready:
            ack = os.read(fd, 32)
    print(json.dumps({"baud": args.baud, "pc_to_e300_exact": passed,
                      "rx_bytes": len(received), "tx_queued_bytes": sent,
                      "pc_acknowledged_reverse": ack == b"Z",
                      "rx_sha256": hashlib.sha256(received).hexdigest()}), flush=True)
finally:
    try:
        if original is not None:
            termios.tcsetattr(fd, termios.TCSANOW, original)
        fcntl.ioctl(fd, termios.TIOCNXCL)
    finally:
        os.close(fd)
print("UART_SETTINGS_RESTORED", flush=True)
raise SystemExit(0 if passed and sent == len(response) and ack == b"Z" else 1)
