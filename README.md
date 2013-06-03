nrf_blink
=========

OS X Blink example for the nRF51 PCA10001 board

Prerequisites:
+ An ARM toolchain
+ J-Link 4.62a
+ nRF51822 SDK
+ nRF51822 soft device

Modify the _ROOT variables at the top of the Makefile to match your system. Even better, put your definitions in a file called `local_vars.mk`

If you haven't installed the soft device on the nRF51 yet, start with:
```
make flash_softdevice
```

After that, to compile, build and flash the application code:
```
make flash_app
```
