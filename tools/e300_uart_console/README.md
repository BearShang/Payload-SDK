# E300 UART Console Helper

Experimental, board-specific helper for the observed ARM64 Linux 6.6.10 system.
This is not a general-purpose kernel module or a DJI SDK component.

On the inspected device, dry-run, last-console refusal, detach, unload/restore,
reload, bidirectional 115200-baud marker transfer, and a controlled kernel-log
isolation check passed on 2026-09-08. This does not validate aircraft enumeration
or PSDK communication. The compiler was GCC 11.4.0 versus kernel GCC 11.2.0;
successful tests do not establish compatibility with other vendor images.

It uses exported console APIs to unregister only the built-in `ttyS0` console.
It does not unload the UART driver, alter ACPI tables, flash firmware, or change
the kernel image. Unloading the helper registers the original console again.
Kernel messages remain in the kernel log, but the detached console cannot print
them. Detaching the last console also removes that `/dev/console` destination.
Existing processes holding a console TTY must be checked separately.

## Preconditions

- Keep J10 connected to the maintenance computer, not the aircraft, for testing
  and rollback. Restoring the console may replay kernel messages over UART7.
- Verify the running image, matching headers/configuration, exported APIs, and
  built-in 8250 driver. A matching release string alone does not prove ABI safety.
- Keep SSH available and mask the `serial-getty@ttyS0` instance first.
- Check root-owned processes holding `/dev/ttyS0` and `/dev/console`.
- The helper refuses callbacks other than the inspected built-in 8250 setup,
  write, and exit functions. It leaves hardware cleanup to their standard APIs.
- Do not run PSDK or another serial process during load/unload.
- Loading an external module sets the out-of-tree kernel taint flag; unloading
  does not clear it. This helper does not force-load modules.

## Build And Validate On The Device

```sh
make KDIR=/lib/modules/6.6.10/build
sudo insmod ./psdk_uart_console.ko
sudo dmesg | tail -n 10
cat /proc/consoles
sudo rmmod psdk_uart_console
```

The default is read-only `dry_run=1`. To detach after preflight:

```sh
sudo insmod ./psdk_uart_console.ko dry_run=0 allow_last_console=1
cat /proc/consoles
sudo fuser -v /dev/ttyS0 /dev/console
```

Omit `allow_last_console=1` to refuse removal of the last enabled console.
Before claiming UART readiness, verify no enabled ttyS0 console, no conflicting
TTY owners, bidirectional marker transfer, and that a kernel log marker does not
arrive on the UART.

`validate_uart.py` performs a bounded 115200-baud marker exchange while refusing
an active ttyS0 console. It requires the PC peer to send exactly
`PSDK_PC_TO_E300_CHECK\n` and returns its own `PSDK_E300_TO_PC_CHECK\n` marker.
It restores termios and releases its exclusive-open flag when done. Never run
this marker test with J10 connected to the aircraft.

## Rollback

Disconnect the aircraft and stop any serial application before restoring:

```sh
sudo rmmod psdk_uart_console
cat /proc/consoles
```

If registration fails, reboot with the unchanged original firmware environment.
Restore the login service separately only when wanted:

```sh
sudo systemctl unmask serial-getty@ttyS0.service
sudo systemctl start serial-getty@ttyS0.service
```

No automatic loading or startup service is installed. Reboot restores the kernel
console, while the previously masked getty remains masked. This helper only
addresses the running Linux console; early firmware/boot logs still use UART7.
