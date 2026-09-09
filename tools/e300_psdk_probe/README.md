# E300 PSDK Core Probe

This ARM64 Linux tool reuses the repository's PSDK library and Linux OSAL.
It has no power-management, flight-control, camera, widget, upgrade, GPIO,
application-start, or automatic-startup calls. It does not change device permissions.

## Configuration

Supply these environment variables privately at runtime:

- `PSDK_APP_NAME`
- `PSDK_APP_ID`
- `PSDK_APP_KEY`
- `PSDK_APP_LICENSE`
- `PSDK_DEVELOPER_ACCOUNT`
- `PSDK_BAUD_RATE`

Use the user's own corresponding PSDK application information. Do not commit
credentials, include them in shell command arguments, or copy them into Wiki.
Supported baud values match the existing Linux UART sample: 115200, 230400,
460800, 921600, and 1000000. The actual aircraft baud must be confirmed.

## Build And Non-I/O Checks

From the repository root on E300:

```sh
cmake -S tools/e300_psdk_probe -B build/e300_psdk_probe
cmake --build build/e300_psdk_probe
ctest --test-dir build/e300_psdk_probe --output-on-failure
python3 tools/e300_psdk_probe/test_preflight.py build/e300_psdk_probe/e300_psdk_probe
```

The tests use dummy values exclusively with `--check`. This mode validates
field sizes, placeholders, baud selection, and the absence of the selected UART kernel
console. It never opens UART and does not authenticate credentials.

The CTest UART-status unit test calls the production callback without SDK startup
or descriptor operations. A query for the unused logical UART1 returns success
with `isConnect=false`, rather than an invalid-parameter error. UART0 reflects
local-open state only; null output pointers and out-of-range UART numbers fail.

## Communication Trial

Use `invoke_probe.ps1` with an application header path, SSH target, remote
deployment root, and mode `check` or `run`. Run mode takes a SecureString sudo
password in memory. It parses six simple literal macros without evaluating
the header, sends JSON over SSH stdin, and never creates a credential file.
Do not put passwords or keys into saved commands or scripts.

`-Transport usb-ch340` selects `/dev/ttyUSB0` and reports aircraft-facing
CH340 identity 1a86:7523, based on the user's confirmation that both adapters
are CH340. The supervisor additionally verifies the local USB VID/PID and
ch341-uart driver. This route does not require or detach ttyS0 console.
The default `legacy` route preserves the earlier ttyS0/CP210x behavior and
must not be used for the new wiring.

`-Transport usb-cp210x` selects `/dev/ttyUSB0` with CP210x identity 10c4:ea60
on both ends, as reported for the replacement wiring. Preflight requires the
local USB identity and cp210x driver to match. It preserves ttyS0 console and
uses the existing Linux cp210x module, not the added CH340 module.

Important: the double-CH340 trial on 2026-09-09 timed out during identification.
DJI's E-Port V2 guidance lists CP2102 and FT232, not CH340. Local Linux CH340
support does not establish aircraft support. Do not repeat this mode as a
supported aircraft configuration. After replacing the aircraft-side adapter,
separate its VID/PID selection from the local USB serial transport before use.

`remote_probe.py` checks configuration first. Before run it also requires root
and no selected-port holders. Only legacy mode additionally requires
masked/inactive getty, the console helper, and no /dev/console holders.
It supervises one core-only process for 45 seconds, then terminates it if needed
and restores terminal settings using its retained descriptor. Check console preparation
again after every reboot. Do not unload the console helper while connected
to the aircraft.

The probe opens only the selected fixed path, uses raw 8N1 without flow control,
reports the selected aircraft-facing adapter identity, initializes the SDK core, queries base information,
then deinitializes. UART status means local open status, not verified USB
enumeration by M400. Byte counts alone are not a successful SDK handshake.
Periodic diagnostics include the most recently configured local baud and hard
read/write error counters (excluding EAGAIN/EINTR). The USB-UART identity callback
logs when the SDK requests VID/PID; this is still reported configuration rather
than a readback from the aircraft USB host. The supervisor reports elapsed
monotonic and wall-clock time to expose clock jumps without changing OSAL behavior.
SDK diagnostic messages are captured in memory and redacted line by line by the supervisor before
display. Known application fields, email patterns, labelled identifiers, and
long token patterns are filtered. This is not a general-purpose privacy filter;
do not save or forward unreviewed output. Direct unsupervised `--run` is refused.
Oversized unterminated log lines abort the probe rather than bypass redaction.
The local SSH wrapper has keepalives and a 90-second outer deadline.

The SDK initialization and deinitialization are blocking. The supervisor supplies
the timeout and terminal restoration even if the child must be killed. Terminating
the supervisor itself or rebooting does not promise terminal restoration.
No kernel module, getty setting, or boot configuration is changed by this tool.

## Verification Boundary

Initialization now checks TCIFLUSH before applying termios, following the
official HAL's receive-queue reset order. Periodic per-baud RX counters and
zero/0xff counts expose receive patterns without retaining payload bytes.
These labels describe software baud selection, not measured wire baud or
valid DJI frames. A 2026-09-09 CP210x comparison with this change still timed
out during identification; the missing flush was not established as the cause.

On 2026-09-08, compilation/linking on E300 passed. The reused SDK OSAL emits
one existing unused `stackSize` warning. Preflight checks are separate from
aircraft handshake, authentication, and 24 V measurement.

The first real trial returned core error 0xec after TX 1406 / RX 1861 bytes.
A subsequent preflight refused execution after an intervening device reboot.
After reloading the previously verified console helper, a 45-second trial timed
out with zero RX at all periodic observations. No base information was obtained,
and no voltage request was issued. The reboot cause and changed receive behavior
are unresolved; do not conclude that the application credentials are invalid.
