/* Test the exact production callback without opening UART or initializing SDK. */
#define main probe_application_main
#include "main.c"
#undef main

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "Failed at line %d\n", __LINE__); return 1; } } while (0)

int main(void)
{
    T_DjiUartStatus status = {0};
    uart_fd = -1;
    CHECK(uart_status(DJI_HAL_UART_NUM_0, &status) == OK && !status.isConnect);
    CHECK(uart_status(DJI_HAL_UART_NUM_1, &status) == OK && !status.isConnect);
    uart_fd = 42; /* Simulated local-open state; no descriptor operations. */
    CHECK(uart_status(DJI_HAL_UART_NUM_0, &status) == OK && status.isConnect);
    CHECK(uart_status(DJI_HAL_UART_NUM_1, &status) == OK && !status.isConnect);
    CHECK(uart_status(DJI_HAL_UART_NUM_0, NULL) == INVALID);
    CHECK(uart_status((E_DjiHalUartNum)2, &status) == INVALID);
    CHECK(uart_status((E_DjiHalUartNum)-1, &status) == INVALID);
    uart_fd = -1;
    T_DjiHalUartDeviceInfo info = {0};
    usb_ch340 = 1;
    CHECK(uart_info(&info) == OK && info.vid == 0x1a86 && info.pid == 0x7523);
    usb_ch340 = 0;
    CHECK(uart_info(&info) == OK && info.vid == 0x10c4 && info.pid == 0xea60);
    CHECK(uart_info(NULL) == INVALID);
    const uint8_t sample[] = {0, 0, 0xff, 0x55};
    atomic_store(&active_baud, 460800);
    record_rx(sample, sizeof(sample));
    CHECK(atomic_load(&rx_by_baud[2]) == 4);
    CHECK(atomic_load(&rx_by_baud[0]) == 0);
    CHECK(atomic_load(&rx_zero_bytes) == 2 && atomic_load(&rx_ff_bytes) == 1);
    record_rx(NULL, 0);
    CHECK(atomic_load(&rx_by_baud[2]) == 4);
    puts("PASS UART status, adapter identity and RX statistics; no UART I/O or SDK initialization");
    return 0;
}
