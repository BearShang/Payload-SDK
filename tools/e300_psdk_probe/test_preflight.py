"""Validate configuration gates without opening UART or initializing the SDK."""
import os
import subprocess
import sys

binary = sys.argv[1]
base = {k: v for k, v in os.environ.items() if not k.startswith("PSDK_")}
dummy = {
    "PSDK_APP_NAME": "shape-test-only",
    "PSDK_APP_ID": "1",
    "PSDK_APP_KEY": "x" * 32,
    "PSDK_APP_LICENSE": "x" * 512,
    "PSDK_DEVELOPER_ACCOUNT": "shape-test@example.invalid",
    "PSDK_BAUD_RATE": "921600",
    "PSDK_TRANSPORT": "usb-ch340",
}


def check(label, fields, expected):
    result = subprocess.run(
        [binary, "--check"], env={**base, **fields},
        capture_output=True, text=True, timeout=5,
    )
    assert result.returncode == expected, (label, result.returncode, result.stderr)
    assert "uart_open" not in result.stdout
    assert "Starting SDK core" not in result.stdout
    print(f"PASS {label}")


check("missing configuration", {}, 2)
check("valid shape, not authentication", dummy, 0)
check("USB CP210x with ttyS0 console preserved", {**dummy, "PSDK_TRANSPORT": "usb-cp210x"}, 0)
check("seven-digit baud", {**dummy, "PSDK_BAUD_RATE": "1000000"}, 0)
check("unsupported baud", {**dummy, "PSDK_BAUD_RATE": "123456"}, 2)
check("placeholder license", {**dummy, "PSDK_APP_LICENSE": "your_app_license"}, 2)
check("oversized key", {**dummy, "PSDK_APP_KEY": "x" * 33}, 2)
check("unterminated app name", {**dummy, "PSDK_APP_NAME": "x" * 32}, 2)
check("arbitrary transport rejected", {**dummy, "PSDK_TRANSPORT": "/dev/ttyS1"}, 2)
print("All checks used --check only; no UART access or authentication attempted.")
