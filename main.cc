extern "C" {
#include "nrf_delay.h"
#include "nrf_gpio.h"
#include "boards.h"
};

extern "C" int main(void)
{
  uint8_t output_state = 0;

  // Configure LED-pins as outputs
  nrf_gpio_range_cfg_output(LED_START, LED_STOP);

  for(;;) {
    nrf_gpio_port_write(LED_PORT, 1 << (output_state + LED_OFFSET));
    output_state = (output_state + 1) & BLINKY_STATE_MASK;
    nrf_delay_ms(100);
  }
}

// This function is generated by the linker
extern "C" void __libc_init_array();

// This function is called by the generated __libc_init_array()
extern "C" void _init() {
}

// These locations are provided by the linker file
extern "C" unsigned long __text_end__;
extern "C" unsigned long __data_start__;
extern "C" unsigned long __data_end__;
extern "C" unsigned long __bss_start__;
extern "C" unsigned long __bss_end__;

namespace nrf51 {
  __attribute__ ((section(".startup")))
  void Reset_Handler(void) {
    // ensure that both RAM banks are turned on
    NRF_POWER->RAMON = POWER_RAMON_ONRAM0_Msk | POWER_RAMON_ONRAM1_Msk;

    // Enable Peripherals.  See PAN_028_v1.4.pdf "25. System: Manual setup is required to enable use of peripherals"
    *(uint32_t *)0x40000504 = 0xC007FFDF;
    *(uint32_t *)0x40006C18 = 0x00008000;

    // Use 16MHz from external crystal
    NRF_CLOCK->EVENTS_HFCLKSTARTED = 0;
    NRF_CLOCK->TASKS_HFCLKSTART    = 1;

    // wait for clock to start
    while (NRF_CLOCK->EVENTS_HFCLKSTARTED == 0);

    NRF_CLOCK->LFCLKSRC = (CLOCK_LFCLKSRC_SRC_Xtal << CLOCK_LFCLKSRC_SRC_Pos);
    NRF_CLOCK->EVENTS_LFCLKSTARTED = 0;
    NRF_CLOCK->TASKS_LFCLKSTART = 1;

    // wait for clock to start
    while (NRF_CLOCK->EVENTS_LFCLKSTARTED == 0);
    NRF_CLOCK->EVENTS_LFCLKSTARTED = 0;

    // enable constant latency mode.
    NRF_POWER->TASKS_CONSTLAT = 1;

    uint32_t *src = &__text_end__;
    uint32_t *dest = &__data_start__;
    uint32_t *limit = &__data_end__;

    // initialize .data
    while (dest < limit) *dest++ = *src++;

    dest = &__bss_start__;
    limit = &__bss_end__;

    // initialize .bss
    while (dest < limit) *dest++ = 0;

    __libc_init_array();

    main();
    while (1);
  }
};
