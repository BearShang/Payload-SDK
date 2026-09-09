"""Bounded UART marker test, for J10 connected to a maintenance PC only."""

import argparse
import fcntl
import json
import os
import select
import termios
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=20)
    args = parser.parse_args()
    if not 1 <= args.timeout <= 60:
        parser.error("timeout must be between 1 and 60 seconds")
    if any(line.split()[0] == "ttyS0"
           for line in Path("/proc/consoles").read_text().splitlines() if line.split()):
        raise RuntimeError("ttyS0 is still registered as a console")

    expected = b"PSDK_PC_TO_E300_CHECK\n"
    sent = b"PSDK_E300_TO_PC_CHECK\n"
    fd = os.open("/dev/ttyS0", os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    original = None
    received = bytearray()
    try:
        fcntl.ioctl(fd, termios.TIOCEXCL)
        original = termios.tcgetattr(fd)
        settings = termios.tcgetattr(fd)
        settings[0] = 0
        settings[1] = 0
        settings[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
        settings[3] = 0
        settings[4] = termios.B115200
        settings[5] = termios.B115200
        settings[6][termios.VMIN] = 0
        settings[6][termios.VTIME] = 0
        termios.tcsetattr(fd, termios.TCSANOW, settings)
        termios.tcflush(fd, termios.TCIOFLUSH)
        if os.write(fd, sent) != len(sent):
            raise RuntimeError("short marker write")
        termios.tcdrain(fd)
        print("UART_TEST_READY", flush=True)
        deadline = time.monotonic() + args.timeout
        while time.monotonic() < deadline and len(received) < len(expected):
            ready, _, _ = select.select([fd], [], [], max(0, deadline - time.monotonic()))
            if ready:
                received.extend(os.read(fd, 256))
        passed = bytes(received) == expected
        print(json.dumps({"passed": passed, "baud": 115200,
                          "sent_hex": sent.hex(), "received_hex": received.hex()}), flush=True)
        return 0 if passed else 1
    finally:
        try:
            if original is not None:
                termios.tcsetattr(fd, termios.TCSANOW, original)
            fcntl.ioctl(fd, termios.TIOCNXCL)
        finally:
            os.close(fd)


if __name__ == "__main__":
    raise SystemExit(main())
