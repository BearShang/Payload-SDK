#include <dji_aircraft_info.h>
#include <dji_core.h>
#include <dji_logger.h>
#include <osal.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <termios.h>
#include <unistd.h>

#define OK DJI_ERROR_SYSTEM_MODULE_CODE_SUCCESS
#define FAIL DJI_ERROR_SYSTEM_MODULE_CODE_SYSTEM_ERROR
#define INVALID DJI_ERROR_SYSTEM_MODULE_CODE_INVALID_PARAMETER

static int uart_fd = -1;
static const char *uart_device = "/dev/ttyS0";
static int usb_ch340;
static struct termios saved_termios;
static int have_saved_termios;
static atomic_ulong tx_bytes, rx_bytes;
static atomic_ulong tx_errors, rx_errors;
static atomic_uint active_baud;
static atomic_ulong status_queries[2];
static const unsigned baud_values[] = {115200, 230400, 460800, 921600, 1000000};
static atomic_ulong rx_by_baud[5], rx_zero_bytes, rx_ff_bytes;

static void record_rx(const uint8_t *buf, uint32_t length)
{
    unsigned baud = atomic_load(&active_baud);
    unsigned long zeros = 0, ones = 0;
    for (size_t i = 0; i < sizeof(baud_values) / sizeof(baud_values[0]); ++i) {
        if (baud_values[i] == baud) {
            atomic_fetch_add(&rx_by_baud[i], length);
            break;
        }
    }
    for (uint32_t i = 0; i < length; ++i) {
        zeros += buf[i] == 0;
        ones += buf[i] == 0xff;
    }
    atomic_fetch_add(&rx_zero_bytes, zeros);
    atomic_fetch_add(&rx_ff_bytes, ones);
}

static void *progress(void *unused)
{
    (void)unused;
    for (;;) {
        sleep(5);
        printf("uart_progress baud=%u tx_bytes=%lu rx_bytes=%lu tx_errors=%lu rx_errors=%lu\n",
               atomic_load(&active_baud), atomic_load(&tx_bytes), atomic_load(&rx_bytes),
               atomic_load(&tx_errors), atomic_load(&rx_errors));
        printf("uart_rx_by_baud b115200=%lu b230400=%lu b460800=%lu b921600=%lu b1000000=%lu zero=%lu ff=%lu\n",
               atomic_load(&rx_by_baud[0]), atomic_load(&rx_by_baud[1]),
               atomic_load(&rx_by_baud[2]), atomic_load(&rx_by_baud[3]),
               atomic_load(&rx_by_baud[4]), atomic_load(&rx_zero_bytes), atomic_load(&rx_ff_bytes));
    }
    return NULL;
}

static T_DjiReturnCode diagnostic_sdk_log(const uint8_t *data, uint16_t length)
{
    /* The supervisor captures and redacts this stream; never run it with a log tee. */
    fputs("sdk_log ", stdout);
    fwrite(data, 1, length, stdout);
    return OK;
}

static void close_uart(void)
{
    if (uart_fd < 0)
        return;
    if (have_saved_termios)
        tcsetattr(uart_fd, TCSANOW, &saved_termios);
    ioctl(uart_fd, TIOCNXCL);
    close(uart_fd);
    uart_fd = -1;
    have_saved_termios = 0;
}

static int console_released(void)
{
    char line[256];
    FILE *f = fopen("/proc/consoles", "r");
    if (!f)
        return 0;
    while (fgets(line, sizeof(line), f)) {
        char name[64];
        if (sscanf(line, "%63s", name) == 1 && !strcmp(name, uart_device + 5)) {
            fclose(f);
            return 0;
        }
    }
    int valid = !ferror(f);
    fclose(f);
    return valid;
}

static T_DjiReturnCode uart_init(E_DjiHalUartNum num, uint32_t baud, T_DjiUartHandle *handle)
{
    speed_t speed;
    struct termios options;
    struct flock lock = {.l_type = F_WRLCK, .l_whence = SEEK_SET};
    if (num != DJI_HAL_UART_NUM_0 || !handle || uart_fd >= 0 || !console_released())
        return INVALID;
    switch (baud) {
        case 115200: speed = B115200; break;
        case 230400: speed = B230400; break;
        case 460800: speed = B460800; break;
        case 921600: speed = B921600; break;
        case 1000000: speed = B1000000; break;
        default: return INVALID;
    }
    uart_fd = open(uart_device, O_RDWR | O_NOCTTY | O_NONBLOCK | O_CLOEXEC);
    if (uart_fd < 0)
        return FAIL;
    if (fcntl(uart_fd, F_SETLK, &lock) < 0 || ioctl(uart_fd, TIOCEXCL) < 0 ||
        tcgetattr(uart_fd, &saved_termios) < 0) {
        close_uart();
        return FAIL;
    }
    have_saved_termios = 1;
    options = saved_termios;
    cfmakeraw(&options);
    options.c_cflag &= ~(CRTSCTS | CSTOPB | PARENB | CSIZE);
    options.c_cflag |= CLOCAL | CREAD | CS8;
    options.c_cc[VMIN] = 0;
    options.c_cc[VTIME] = 0;
    if (cfsetispeed(&options, speed) < 0 || cfsetospeed(&options, speed) < 0 ||
        tcflush(uart_fd, TCIFLUSH) < 0 || tcsetattr(uart_fd, TCSANOW, &options) < 0) {
        close_uart();
        return FAIL;
    }
    *handle = &uart_fd;
    atomic_store(&active_baud, baud);
    printf("uart_open baud=%u (local port, not aircraft enumeration proof)\n", baud);
    return OK;
}

static T_DjiReturnCode uart_deinit(T_DjiUartHandle handle)
{
    if (handle != &uart_fd)
        return INVALID;
    close_uart();
    return OK;
}

static T_DjiReturnCode uart_write(T_DjiUartHandle handle, const uint8_t *buf,
                                  uint32_t len, uint32_t *actual)
{
    if (handle != &uart_fd || uart_fd < 0 || !buf || !actual)
        return INVALID;
    *actual = 0;
    ssize_t n = write(uart_fd, buf, len);
    if (n < 0) {
        if (errno == EAGAIN || errno == EINTR)
            return OK;
        atomic_fetch_add(&tx_errors, 1);
        return FAIL;
    }
    *actual = (uint32_t)n;
    atomic_fetch_add(&tx_bytes, (unsigned long)n);
    return OK;
}

static T_DjiReturnCode uart_read(T_DjiUartHandle handle, uint8_t *buf,
                                 uint32_t len, uint32_t *actual)
{
    if (handle != &uart_fd || uart_fd < 0 || !buf || !actual)
        return INVALID;
    *actual = 0;
    ssize_t n = read(uart_fd, buf, len);
    if (n < 0) {
        if (errno == EAGAIN || errno == EINTR)
            return OK;
        atomic_fetch_add(&rx_errors, 1);
        return FAIL;
    }
    *actual = (uint32_t)n;
    atomic_fetch_add(&rx_bytes, (unsigned long)n);
    record_rx(buf, (uint32_t)n);
    return OK;
}

static T_DjiReturnCode uart_status(E_DjiHalUartNum num, T_DjiUartStatus *status)
{
    if (!status || (num != DJI_HAL_UART_NUM_0 && num != DJI_HAL_UART_NUM_1))
        return INVALID;
    /* UART1 is a valid SDK query, but this board exposes only UART0. */
    status->isConnect = num == DJI_HAL_UART_NUM_0 && uart_fd >= 0;
    if (atomic_fetch_add(&status_queries[num], 1) == 0)
        printf("sdk_uart_status_query logical_port=%d connected=%d result=0 (local status only)\n",
               num, status->isConnect);
    return OK;
}

static T_DjiReturnCode uart_info(T_DjiHalUartDeviceInfo *info)
{
    if (!info)
        return INVALID;
    info->vid = usb_ch340 ? 0x1a86 : 0x10c4;
    info->pid = usb_ch340 ? 0x7523 : 0xea60;
    printf("sdk_requested_usb_uart_identity vid=%04x pid=%04x (reported identity, not host readback)\n",
           info->vid, info->pid);
    return OK;
}

static int field(char *dest, size_t capacity, const char *name, int terminated)
{
    const char *value = getenv(name);
    if (!value || !*value || !strncmp(value, "your_", 5) ||
        strlen(value) > capacity - (size_t)terminated) {
        fprintf(stderr, "Missing, placeholder or oversized field: %s\n", name);
        return 0;
    }
    memcpy(dest, value, strlen(value));
    return 1;
}

int main(int argc, char **argv)
{
    struct rlimit no_core = {0, 0};
    T_DjiUserInfo user = {0};
    T_DjiAircraftInfoBaseInfo info = {0};
    T_DjiOsalHandler osal = {
        .TaskCreate = Osal_TaskCreate, .TaskDestroy = Osal_TaskDestroy,
        .TaskSleepMs = Osal_TaskSleepMs, .MutexCreate = Osal_MutexCreate,
        .MutexDestroy = Osal_MutexDestroy, .MutexLock = Osal_MutexLock,
        .MutexUnlock = Osal_MutexUnlock, .SemaphoreCreate = Osal_SemaphoreCreate,
        .SemaphoreDestroy = Osal_SemaphoreDestroy, .SemaphoreWait = Osal_SemaphoreWait,
        .SemaphoreTimedWait = Osal_SemaphoreTimedWait, .SemaphorePost = Osal_SemaphorePost,
        .Malloc = Osal_Malloc, .Free = Osal_Free, .GetRandomNum = Osal_GetRandomNum,
        .GetTimeMs = Osal_GetTimeMs, .GetTimeUs = Osal_GetTimeUs,
    };
    T_DjiHalUartHandler uart = {
        .UartInit = uart_init, .UartDeInit = uart_deinit,
        .UartWriteData = uart_write, .UartReadData = uart_read,
        .UartGetStatus = uart_status, .UartGetDeviceInfo = uart_info,
    };
    setvbuf(stdout, NULL, _IOLBF, 0);
    if (setrlimit(RLIMIT_CORE, &no_core) != 0)
        return 1;
    if (argc != 2 || (strcmp(argv[1], "--check") && strcmp(argv[1], "--run"))) {
        fprintf(stderr, "Usage: e300_psdk_probe --check|--run\n");
        return 2;
    }
    const char *transport = getenv("PSDK_TRANSPORT");
    if (transport && strcmp(transport, "legacy") && strcmp(transport, "usb-ch340") &&
        strcmp(transport, "usb-cp210x")) {
        fputs("Unsupported transport\n", stderr);
        return 2;
    }
    usb_ch340 = transport && !strcmp(transport, "usb-ch340");
    uart_device = transport && strcmp(transport, "legacy") ? "/dev/ttyUSB0" : "/dev/ttyS0";
    int valid = field(user.appName, sizeof(user.appName), "PSDK_APP_NAME", 1);
    valid &= field(user.appId, sizeof(user.appId), "PSDK_APP_ID", 0);
    valid &= field(user.appKey, sizeof(user.appKey), "PSDK_APP_KEY", 0);
    valid &= field(user.appLicense, sizeof(user.appLicense), "PSDK_APP_LICENSE", 0);
    valid &= field(user.developerAccount, sizeof(user.developerAccount), "PSDK_DEVELOPER_ACCOUNT", 1);
    valid &= field(user.baudRate, sizeof(user.baudRate), "PSDK_BAUD_RATE", 0);
    if (!valid)
        return 2;
    const char *rates[] = {"115200", "230400", "460800", "921600", "1000000"};
    valid = 0;
    for (size_t i = 0; i < sizeof(rates) / sizeof(rates[0]); ++i)
        valid |= !strcmp(getenv("PSDK_BAUD_RATE"), rates[i]);
    if (!valid || !console_released()) {
        fprintf(stderr, "Unsupported baud or selected UART is a kernel console\n");
        return 2;
    }
    if (!strcmp(argv[1], "--check")) {
        puts("Configuration shape and console check passed; UART not opened; credentials not authenticated");
        return 0;
    }
    if (!getenv("PSDK_SUPERVISED_LOG") || strcmp(getenv("PSDK_SUPERVISED_LOG"), "1")) {
        fputs("Use the private remote supervisor for --run\n", stderr);
        return 2;
    }
    /* SDK messages must pass through the private supervisor redaction. */
    atexit(close_uart);
    T_DjiReturnCode rc = DjiPlatform_RegOsalHandler(&osal);
    T_DjiLoggerConsole logger = {
        .func = diagnostic_sdk_log, .consoleLevel = DJI_LOGGER_CONSOLE_LOG_LEVEL_INFO,
        .isSupportColor = false,
    };
    if (rc == OK)
        rc = DjiLogger_AddConsole(&logger);
    if (rc == OK)
        rc = DjiPlatform_RegHalUartHandler(&uart);
    if (rc != OK) {
        printf("platform_registration_rc=0x%llx\n", (unsigned long long)rc);
        return 1;
    }
    puts("Starting SDK core only; no application modules or voltage request");
    pthread_t progress_thread;
    if (pthread_create(&progress_thread, NULL, progress, NULL) != 0)
        return 1;
    rc = DjiCore_Init(&user);
    explicit_bzero(&user, sizeof(user));
    printf("core_init_rc=0x%llx tx_bytes=%lu rx_bytes=%lu\n", (unsigned long long)rc,
           atomic_load(&tx_bytes), atomic_load(&rx_bytes));
    printf("uart_io_errors tx=%lu rx=%lu\n", atomic_load(&tx_errors), atomic_load(&rx_errors));
    if (rc != OK)
        return 1;
    rc = DjiAircraftInfo_GetBaseInfo(&info);
    printf("base_info_rc=0x%llx\n", (unsigned long long)rc);
    if (rc == OK)
        printf("aircraft_type=%d adapter_type=%d mount_position=%d\n",
               info.aircraftType, info.djiAdapterType, info.mountPosition);
    T_DjiReturnCode end = DjiCore_DeInit();
    printf("core_deinit_rc=0x%llx\n", (unsigned long long)end);
    return rc == OK && end == OK ? 0 : 1;
}
