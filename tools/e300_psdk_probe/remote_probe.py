"""Receive private configuration on stdin; supervise a bounded core-only probe."""
import fcntl
import json
import os
import re
import selectors
from pathlib import Path
import signal
import subprocess
import sys
import termios
import time

root = Path(__file__).resolve().parents[2]
binary = root / "build" / "e300_psdk_probe"
request = json.load(sys.stdin)
mode = request["mode"]
if mode not in ("check", "run"):
    raise SystemExit("Invalid mode")
expected = {"PSDK_APP_NAME", "PSDK_APP_ID", "PSDK_APP_KEY", "PSDK_APP_LICENSE",
            "PSDK_DEVELOPER_ACCOUNT", "PSDK_BAUD_RATE"}
fields = request["fields"]
if set(fields) != expected or any(not isinstance(v, str) for v in fields.values()):
    raise SystemExit("Invalid configuration fields")
env = {k: v for k, v in os.environ.items() if not k.startswith("PSDK_")}
env.update(fields)
transport = request.get("transport", "legacy")
if transport not in ("legacy", "usb-ch340", "usb-cp210x"):
    raise SystemExit("Invalid transport")
env["PSDK_TRANSPORT"] = transport
device = "/dev/ttyS0" if transport == "legacy" else "/dev/ttyUSB0"
seen_uart = set()
repeated_uart = 0


def report(output):
    global repeated_uart
    # SDK library output is treated as private even when bypassing its log callback.
    for name, value in sorted(fields.items(), key=lambda x: len(x[1]), reverse=True):
        if name != "PSDK_BAUD_RATE" and value:
            output = output.replace(value, "[redacted]")
    output = re.sub(r"\b[\w.+-]+@[\w.-]+\b", "[redacted-account]", output)
    output = re.sub(r"(?i)\b(serial(?:\s+number)?|sn|appkey|applicense)\s*(?:[:=]|\bis\b)\s*\S+",
                    r"\1=[redacted]", output)
    output = re.sub(r"\b[A-Za-z0-9+/]{16,}={0,2}\b", "[redacted-token]", output)
    for line in output.splitlines():
        if line.startswith("uart_open baud="):
            if line in seen_uart:
                repeated_uart += 1
                continue
            seen_uart.add(line)
        print(line, flush=True)


result = subprocess.run([binary, "--check"], env=env, capture_output=True,
                        text=True, timeout=10)
report(result.stdout + result.stderr)
if result.returncode or mode == "check":
    raise SystemExit(result.returncode)
if os.geteuid() != 0:
    raise SystemExit("Run requires root for complete ownership preflight")
if transport == "legacy":
    getty = subprocess.run(["systemctl", "show", "serial-getty@ttyS0.service",
                            "-p", "LoadState", "-p", "ActiveState"],
                           capture_output=True, text=True, check=True)
    if "LoadState=masked\n" not in getty.stdout or "ActiveState=inactive\n" not in getty.stdout:
        raise SystemExit("Getty not masked and inactive")
    if not Path("/sys/module/psdk_uart_console").is_dir():
        raise SystemExit("Console helper missing")
else:
    vid, pid, driver = (("10c4", "ea60", "cp210x") if transport == "usb-cp210x"
                        else ("1a86", "7523", "ch341-uart"))
    sysdev = Path("/sys/class/tty/ttyUSB0/device").resolve(strict=True)
    usb = next((p for p in sysdev.parents if (p / "idVendor").exists()), None)
    if (usb is None or (usb / "idVendor").read_text().strip() != vid
            or (usb / "idProduct").read_text().strip() != pid
            or (sysdev / "driver").resolve(strict=True).name != driver):
        raise SystemExit("USB serial identity/driver preflight refused")
busy = subprocess.run(["fuser", device] + (["/dev/console"] if transport == "legacy" else []),
                      capture_output=True)
if busy.returncode != 1 or busy.stdout.strip() or busy.stderr.strip():
    raise SystemExit("UART ownership preflight refused")
print(f"preflight=passed transport={transport} selected_uart_not_console no_existing_holders", flush=True)
fd = os.open(device, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
saved = termios.tcgetattr(fd)
child = None
try:
    env["PSDK_SUPERVISED_LOG"] = "1"
    start_monotonic = time.monotonic()
    start_wall = time.time()
    child = subprocess.Popen([binary, "--run"], env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, start_new_session=True)
    # Redact complete lines as they arrive; do not lose all diagnostics on disconnect.
    pending = b""
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(child.stdout, selectors.EVENT_READ)
            while selector.get_map():
                remaining = 45 - (time.monotonic() - start_monotonic)
                if remaining <= 0:
                    raise subprocess.TimeoutExpired(binary, 45)
                for key, _ in selector.select(min(remaining, 0.5)):
                    chunk = os.read(key.fd, 4096)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    pending += chunk
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        report(line.decode("utf-8", errors="replace"))
                    if len(pending) > 65536:
                        # Abort rather than split a possible secret across reports.
                        raise RuntimeError("Oversized SDK log line; probe stopped")
        report(pending.decode("utf-8", errors="replace"))
        pending = b""
        code = child.wait(timeout=max(0.1, 45 - (time.monotonic() - start_monotonic)))
    except subprocess.TimeoutExpired:
        os.killpg(child.pid, signal.SIGTERM)
        try:
            output, _ = child.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            output, _ = child.communicate(timeout=5)
        code = 124
        report((pending + output).decode("utf-8", errors="replace"))
    print(f"probe_exit={code}", flush=True)
    if repeated_uart:
        print(f"repeated_uart_open_lines_omitted={repeated_uart}", flush=True)
    print(f"elapsed_monotonic_seconds={time.monotonic() - start_monotonic:.3f} "
          f"elapsed_wall_seconds={time.time() - start_wall:.3f}", flush=True)
finally:
    if child is not None and child.poll() is None:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait(timeout=5)
    termios.tcsetattr(fd, termios.TCSANOW, saved)
    fcntl.ioctl(fd, termios.TIOCNXCL)
    os.close(fd)
    print("supervisor_uart_settings_restored=true", flush=True)
raise SystemExit(code)
