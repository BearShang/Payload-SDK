// SPDX-License-Identifier: GPL-2.0-only
#include <linux/console.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/string.h>
#include <linux/utsname.h>
#include <linux/version.h>

#if !defined(CONFIG_ARM64) || !IS_BUILTIN(CONFIG_SERIAL_8250)
#error "This helper requires the E300 ARM64 built-in 8250 driver"
#endif
#if LINUX_VERSION_CODE != KERNEL_VERSION(6, 6, 10)
#error "Re-audit the console ABI before building for another kernel"
#endif

static bool dry_run = true;
module_param(dry_run, bool, 0400);
MODULE_PARM_DESC(dry_run, "Inspect only; explicitly use dry_run=0 to detach ttyS0");

static bool allow_last_console;
module_param(allow_last_console, bool, 0400);
MODULE_PARM_DESC(allow_last_console, "Allow detaching the last enabled console");

/* The built-in 8250 console has static lifetime, including while detached. */
static struct console *detached_console;

static bool expected_callbacks(struct console *con)
{
    char symbol[96];

    snprintf(symbol, sizeof(symbol), "%ps", con->exit);
    if (strcmp(symbol, "univ8250_console_exit"))
        return false;
    snprintf(symbol, sizeof(symbol), "%ps", con->setup);
    if (strcmp(symbol, "univ8250_console_setup"))
        return false;
    snprintf(symbol, sizeof(symbol), "%ps", con->write);
    return !strcmp(symbol, "univ8250_console_write");
}

static int __init psdk_uart_console_init(void)
{
    struct console *con;
    struct console *target = NULL;
    unsigned int matches = 0;
    unsigned int enabled = 0;
    int ret = 0;

    if (strcmp(utsname()->release, "6.6.10"))
        return -ENODEV;

    console_list_lock();
    for_each_console(con) {
        if (con->flags & CON_ENABLED)
            enabled++;
        if (strncmp(con->name, "ttyS", sizeof(con->name)) || con->index != 0)
            continue;
        matches++;
        target = con;
    }

    if (target)
        pr_info("psdk_uart_console: ttyS0 flags=0x%x write=%ps device=%ps setup=%ps exit=%ps\n",
                (unsigned short)target->flags, target->write, target->device,
                target->setup, target->exit);

    if (matches != 1 || !target) {
        ret = -ENODEV;
    } else if (!(target->flags & CON_ENABLED) ||
               (target->flags & (CON_BOOT | CON_BRL | CON_SUSPENDED)) ||
               !target->device || !expected_callbacks(target)) {
        ret = -EOPNOTSUPP;
    } else if (!dry_run && enabled == 1 && !allow_last_console) {
        ret = -EBUSY;
    }
    console_list_unlock();

    if (ret) {
        pr_err("psdk_uart_console: preflight refused (%d), matches=%u enabled=%u\n",
               ret, matches, enabled);
        return ret;
    }
    if (dry_run) {
        pr_info("psdk_uart_console: dry-run OK, ttyS0 found, enabled=%u; no change\n",
                enabled);
        return 0;
    }

    /* unregister_console() takes the list mutex itself and drains SRCU readers. */
    ret = unregister_console(target);
    if (ret) {
        /* An exit callback can fail after removal; do not strand the console. */
        if (!console_is_registered(target))
            register_console(target);
        pr_err("psdk_uart_console: unregister failed (%d)\n", ret);
        return ret;
    }
    detached_console = target;
    pr_info("psdk_uart_console: ttyS0 detached; UART driver remains loaded\n");
    return 0;
}

static void __exit psdk_uart_console_exit(void)
{
    if (!detached_console)
        return;

    register_console(detached_console);
    if (!console_is_registered(detached_console))
        pr_err("psdk_uart_console: console restore failed; reboot to restore\n");
    else
        pr_info("psdk_uart_console: ttyS0 console restored\n");
}

module_init(psdk_uart_console_init);
module_exit(psdk_uart_console_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Reversible E300 6.6.10 ttyS0 console detachment for UART testing");
