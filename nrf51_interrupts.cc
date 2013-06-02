#include "nrf51.h"

// provided by the linker file
extern "C" unsigned long __stack_end__;

/*
 * This macro defines the names and order of the interrupt handlers for the
 * nRF51822. The macro is defined once and expanded twice. The first expansion
 * generates forward declarations for the interrupt entry points. The second
 * expansion fills the vector table.
 *
 * Note that the forward declarations are weakly bound to the Unused_Handler.
 * This allows the linker to use that function for any interrupt handler that
 * hasn't been defined. To implement an interrupt handler, simply define a
 * function of the correct name in another file (e.g., void Reset_Handler())
 */

#define NRF51_INTERRUPTS \
  PTR((void (*)(void)) &__stack_end__) \
  INT(Reset) \
  INT(NMI) \
  INT(HardFault) \
  INT(Reserved4) \
  INT(Reserved5) \
  INT(Reserved6) \
  INT(Reserved7) \
  INT(Reserved8) \
  INT(Reserved9) \
  INT(Reserved10) \
  INT(SVC) \
  INT(Reserved12) \
  INT(Reserved13) \
  INT(PendSV) \
  INT(SysTick) \
\
  INT(POWER_CLOCK) \
  INT(RADIO) \
  INT(UART0) \
  INT(SPI0_TWI0) \
  INT(SPI1_TWI1) \
  INT(Reserved21) \
  INT(GPIOTE) \
  INT(ADC) \
  INT(TIMER0) \
  INT(TIMER1) \
  INT(TIMER2) \
  INT(RTC0) \
  INT(TEMP) \
  INT(RNG) \
  INT(ECB) \
  INT(CCM_AAR) \
  INT(WDT) \
  INT(RTC1) \
  INT(QDEC) \
  INT(WUCOMP_COMP) \
  INT(SWI0) \
  INT(SWI1) \
  INT(SWI2) \
  INT(SWI3) \
  INT(SWI4) \
  INT(SWI5) \
  INT(Reserved42) \
  INT(Reserved43) \
  INT(Reserved44) \
  INT(Reserved45) \
  INT(Reserved46) \
  INT(Reserved47)

// To be called for an interrupt handler that isn't otherwise defined
// This is extern "C" because GCC's alias attribute can't deal with
// a mangled name. The other handlers are placed in the nrf51 namespace
// as C++ functions.
extern "C" void Unused_Handler(void) {}

namespace nrf51 {

  // Define PTR and INT to create forward declarations
#define PTR(value)
#define INT(name) void name ## _Handler(void) __attribute__ ((weak, alias("Unused_Handler")));
  NRF51_INTERRUPTS
#undef INT
#undef PTR

// Expand the interrupt defnitions a second time to fill out the vector table
  __attribute__ ((section(".vectors"), used))
  void (*const cortex_interrupt_vectors[])() = {
#define PTR(value) value,
#define INT(name) name ## _Handler,
    NRF51_INTERRUPTS
#undef INT
#undef PTR
  };
};
