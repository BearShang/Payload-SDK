# E300 external CH340 adapter

This route uses a USB host port (J3) and an external USB-UART adapter. It does
not enable UART4, detach the ttyS0 console, or change the kernel Image.

## Source and build

- Upstream: https://raw.githubusercontent.com/gregkh/linux/v6.6.10/drivers/usb/serial/ch341.c
- Source SHA-256: b286d49dd1f2a3a8f96188888b4df7869f65c4d9bead51d5291d50150b235951
- Remote build directory: /home/dev/psdk-usb-uart-20260909
- Build: `make -C /lib/modules/6.6.10/build M=/home/dev/psdk-usb-uart-20260909 modules`
- Observed module SHA-256: 662282d5daa7d27a4a7b225e97721dd8de064a153f553149d1ee49655802ec0a
- Vermagic: `6.6.10 SMP preempt mod_unload aarch64`

The kernel reports GCC 11.2.0; the available compiler is GCC 11.4.0. Kbuild
warned about this difference but completed compilation and MODPOST. Matching
vermagic alone does not establish complete runtime compatibility.

## Initial status, 2026-09-09

The original configuration has USB_SERIAL=m but USB_SERIAL_CH341 disabled.
The adapter enumerates as 1a86:7523. The existing usbserial module and the
new ch341 module were loaded temporarily; the boot identifier did not change.
ttyS0 remains a console and the old console-detachment module is not loaded.

No ttyUSB node appeared. The CH340 interface remains without a driver symlink.
Its authorization and USB bus autoprobe are enabled. A guarded explicit bind
returned EBUSY (16); fuser found no process holding the USB device node. The
cause is not established. Do not equate module registration with a working
UART, or persist the module before resolving this and testing communication.

No module was copied into /lib/modules, no autoload configuration was added,
and no initramfs or boot configuration was changed. No serial payload, PSDK
initialization, or power request was sent through this adapter.

After resolving attachment, verify the aircraft-side adapter identity before
reusing the old probe: its serial path and console guard are hardcoded to
ttyS0, and its reported aircraft-facing adapter identity is CP210x. The local
CH340 identity does not establish the aircraft-side adapter identity.

## Resolved attachment, 2026-09-09

After physical replug, dmesg showed ttyUSB0 attach followed by brltty claiming
the device and disconnecting the serial driver. brltty-udev.service (not the
separately queried brltty.service) was active. The installed vendor rule
matches 1a86:7523 as a braille display.

Installed `99-psdk-ch340.rules` in /etc/udev/rules.d. It is restricted to
observed USB path 1-3, VID/PID 1a86:7523, and a sole brltty systemd dependency.
The rule clears that device event's braille properties and dependency. Other
USB devices and vendor rules were left unchanged. Rule simulation succeeded;
after a targeted change event, the dependency was absent. Stopping the current
brltty-udev service and rebinding the interface produced /dev/ttyUSB0.
No service was masked or disabled.

Installed the hash-verified module at:
`/lib/modules/6.6.10/extra/psdk-ch341/ch341.ko`
After depmod, the adapter modalias resolves to ch341. No modules-load file,
initramfs rebuild or kernel replacement is needed for this ordinary hotplug
autoload route. A reboot persistence test has NOT been performed.

Exclusive open and software termios readback at 460800, 8N1, no flow control
succeeded. No UART payload was sent. Original termios was restored and the
descriptor closed. ttyS0 console was preserved and no reboot was performed.

Rollback, with SDK stopped and the adapter unused: remove only the installed
rule above and reload udev rules; unload ch341, remove only the installed module
above and run depmod for 6.6.10. Inspect paths/hashes before removal. Do not
remove the vendor brltty rule, usbserial module, or other services. Replugging
after removing the exception will allow original brltty matching again.

The exclusion assumes the observed USB path. Review it if moving USB ports or
changing firmware/kernel enumeration. Rebuild the module after kernel changes.
