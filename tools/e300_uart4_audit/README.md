# E300 UART4 ACPI Audit

The builder performs offline preparation only. It does not automatically change
boot configuration, load tables, access UART, or reboot.

One explicitly authorized temporary boot on 2026-09-08 loaded the exact minimal
candidate through the existing EFI stub and changed UART4 status to 15. Driver
probe then failed with `Unable to set dma mask` and error `-5`; no ttyMT node was
created. Do not treat the status-only candidate as a working UART configuration.
No UART4 payload or PSDK was sent in that trial. The temporary environment was
not saved; restoration uses the original saved boot path.

The audited live DSDT declares UART4 as `\\_SB.COM1`, `MCOM0001`, `serial_id=4`,
MMIO `0x0071B000`, with `_STA` returning zero. The running driver is built in,
but this disabled device has no ttyMT instance. Pinmux, clock behavior, and UART
communication are still unverified. The user reports an external level shifter
and confirmed 1.8 V TX/RX. COM6 is the external bridge; J10/COM5 remains the
independent UART7 recovery console. Never detach UART7 for this experiment.

## Candidate Construction

`build_override.py` accepts only the SHA-256-pinned original live DSDT. It uses
a narrow AML package-length decoder for the audited `_SB_`, `COM1`, and `_STA`
nodes. It changes `Return(Zero)` to `Return(0x0F)`, updates the three enclosing
package lengths, table length, OEM revision, and checksum. An inverse check
proves that every other byte is unchanged.

An independent ACPICA disassembly must match a manually reviewed ASL source
body before a cpio artifact is generated. This is not a general AML editor.
The initial full-table recompile changed unrelated AML bytes and must NOT be
used; its `uart4-test.aml` is a rejected candidate. Only `minimal/uart4-minimal.aml`
passed the byte-preservation check. The reviewed `uart4-test.dsl` remains the
expected source used for verification, not the binary to deploy.

The cpio contains only `kernel/firmware/acpi/uart4.aml`. Build artifacts stay
in the remote audit directory, not Wiki. No secrets are required by the builder.
Root is needed only when reading the protected live table.

## Checks

```sh
python3 tools/e300_uart4_audit/test_build_override.py
```

The builder additionally validates the real table hash, original and candidate
checksums, inverse patch equality, independent disassembly, and archive listing.
Passing these checks is not proof that the firmware clock or pinmux works.

## Proposed Boot Boundary

The existing machine boots its NVMe first-partition `Image` through U-Boot
`bootefi`; `/boot/vmlinuz-6.6.10` is not the same image. Do not overwrite either.
Linux EFI stub `initrd=` plus ACPI table upgrade was observed working in the
temporary boot. Keep the original ACPI and UART7 console,
use only a separate test artifact and RAM-only boot arguments, and never save
the test U-Boot environment. Confirm explicit reboot approval and COM5 recovery
before any boot trial. A failed temporary boot is recovered through the original
saved boot path, not by repeatedly loading the console-detachment module.

This U-Boot's command parser did not handle double-quoted `setenv bootargs` as
assumed, and variable expansion lost a backslash. Readback caught this before
booting. A single-quoted complete argument value preserved the EFI absolute path.
Always read back the full current parameters before booting; never reuse a saved
ACPI RSDP address from an earlier boot.
