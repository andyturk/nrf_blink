# override root locations in local_vars.mk
-include local_vars.mk

# The following variables ending in _ROOT are directories where external
# things are installed. The location of these may change depending on
# how the host machine is configured. Override the definitions here in
# the optional local_vars.mk
NRF_ROOT                ?= /Users/andy/code/nRF51822
NRF_SOFTDEVICE_ROOT     ?= $(NRF_ROOT)/$(NRF_SOFTDEVICE_VERSION)
BINUTILS_ROOT           ?= /usr/local/arm/gcc-arm-none-eabi-4_7-2013q1
JLINK_ROOT              ?= /usr/local/jlink
KEXT_ROOT               ?= /System/Library/Extensions/IOUSBFamily.kext/Contents/PlugIns

NRF_SOFTDEVICE_VERSION  ?= s110_nrf51822_5.1.0
NRF_SDK                 := $(NRF_ROOT)/sdk
NRF_SOFTDEVICE_HEX      := $(NRF_SOFTDEVICE_ROOT)/$(NRF_SOFTDEVICE_VERSION)_softdevice.hex
NRF_SOURCE              := $(NRF_SDK)/Source

# Toolchain configuration
TARGET                  := arm-none-eabi
CC                      := $(BINUTILS_ROOT)/bin/$(TARGET)-gcc
CXX                     := $(BINUTILS_ROOT)/bin/$(TARGET)-g++
AS                      := $(BINUTILS_ROOT)/bin/$(TARGET)-as
OBJCOPY					:= $(BINUTILS_ROOT)/bin/$(TARGET)-objcopy
JLINKEXE                := $(JLINK_ROOT)/bin/JLinkExe
JLINKGDBSERVER          := $(JLINK_ROOT)/bin/JLinkGDBServer

DYLD_LIBRARY_PATH        = $(JLINK_ROOT)/lib:/usr/local/lib:/opt/local/lib

export DYLD_LIBRARY_PATH

# Where build products go
BUILD                   := build
OBJ                      = $(BUILD)/obj

# Source files
C_SRC                   += nrf51_interrupts.c
C_SRC                   += $(wildcard $(NRF_SOURCE)/nrf_delay/*.c)

CXX_SRC                 += main.cc

# Object files
OBJECTS                  = $(addprefix $(OBJ)/, $(C_SRC:.c=.o) $(CXX_SRC:.cc=.o))

CFLAGS                  += -DNRF51
CFLAGS                  += -DBOARD_PCA10001
CFLAGS                  += -I$(NRF_SDK)/Include/gcc
CFLAGS                  += -I$(NRF_SDK)/Include
CFLAGS                  += -I$(NRF_SOFTDEVICE_ROOT)/$(NRF_SOFTDEVICE_VERSION)_API/include
CFLAGS                  += -g
CFLAGS                  += -Wall
CFLAGS                  += -mcpu=cortex-m0
CFLAGS                  += -mthumb
CFLAGS                  += -ffunction-sections
CFLAGS                  += -Wa,-alh=$(@:.o=.lst)
CFLAGS                  += -fdata-sections

CXXFLAGS                += $(CFLAGS)
CXXFLAGS                += -fno-rtti
CXXFLAGS                += -fno-exceptions
CXXFLAGS                += -fms-extensions
CXXFLAGS                += -Wno-pmf-conversions
CXXFLAGS                += -Wno-unused-parameter
CXXFLAGS                += -Wno-psabi
CXXFLAGS                += -std=gnu++0x

LDFLAGS                 += -mcpu=cortex-m0
LDFLAGS                 += -mthumb
LDFLAGS                 += -nostartfiles

DIRS                    += $(BUILD)
DIRS                    += $(sort $(dir $(OBJECTS)))

help :
	@echo "The following targets are available:"
	@echo "  make blink             -- compiles and links"
	@echo "  make cdc               -- check status of OS X CDC drivers"
	@echo "  make disable_cdc       -- disables OS X CDC drivers"
	@echo "  make enable_cdc        -- enables OS X CDC drivers"
	@echo "  make flash_softdevice  -- erases everything and programs nRF soft device code"
	@echo "  make flash_app         -- flashes application code without erasing"
	@echo "  make flash_bare        -- erases everything and flashes app code w/o soft device"
	@echo "  make gdb_server        -- spawns a gdb server on port 2331"
	@echo "  make clean             -- nukes build products"
	@echo "  make info              -- stuff for debugging the Makefile"

clean :
	@rm -rf $(BUILD) JLink.log

info :
	@echo NRF_SOURCE: '$(NRF_SOURCE)'
	@echo USER: $(USER)
	@echo OBJECTS: $(OBJECTS)
	@echo C_SRC: $(C_SRC)
	@echo CXX_SRC: $(CXX_SRC)

disable_cdc :
ifeq ($(USER),root)
	-@kextunload $(KEXT_ROOT)/AppleUSBCDCACMData.kext >/dev/null 2>&1
	-@kextunload $(KEXT_ROOT)/AppleUSBCDCECMData.kext >/dev/null 2>&1
	-@kextunload $(KEXT_ROOT)/AppleUSBCDCACMControl.kext >/dev/null 2>&1
	-@kextunload $(KEXT_ROOT)/AppleUSBCDC.kext >/dev/null 2>&1
	@echo "Verify with 'make cdc'"
	@echo "Then unplug and re-plug your J-Link devices."
else
	@echo "You must be root to do this. 'sudo make disable_cdc'"
endif

enable_cdc :
ifeq ($(USER),root)
	-@kextload $(KEXT_ROOT)/AppleUSBCDC.kext
	-@kextload $(KEXT_ROOT)/AppleUSBCDCACMControl.kext
	-@kextload $(KEXT_ROOT)/AppleUSBCDCACMData.kext
	-@kextload $(KEXT_ROOT)/AppleUSBCDCECMData.kext
else
	@echo "You must be root to do this. 'sudo make enable_cdc'"
endif

softdevice : $(BUILD)/softdevice_main.bin $(BUILD)/softdevice_uicr.bin

$(DIRS) :
	@echo Creating $(@)
	@mkdir -p $(@)

blink : $(BUILD)/blink.elf

$(BUILD)/blink_bare.elf : $(OBJECTS) $(MAKEFILE_LIST) | $(BUILD)
	@echo Linking $(@)
	@$(CC) \
		-Xlinker -Map=$(patsubst %.elf,%.map,$(@)) \
		$(LDFLAGS) \
		-Tnrf51_bare.ld \
		-o $(@) $(OBJECTS)

$(BUILD)/blink.elf : $(OBJECTS) $(MAKEFILE_LIST) | $(BUILD)
	@echo Linking $(@)
	@$(CC) \
		-Xlinker -Map=$(patsubst %.elf,%.map,$(@)) \
		$(LDFLAGS) \
		-Tnrf51_softdevice.ld \
		-o $(@) $(OBJECTS)

%.bin : %.elf
	@echo Converting $(<) to $(@)
	@$(OBJCOPY) -O binary $(<) $(@)

%.bin : %.hex
	@echo Converting $(X) to $(@)
	@$(OBJCOPY) -O ihex $(<) $(@)

$(OBJECTS) : $(DIRS)

$(OBJ)/%.o : %.c
	@echo Compiling $(<F)
	@$(CC) $(CFLAGS) -c $< -o $(@)

$(OBJ)/%.o : %.cc
	@echo Compiling $(<F)
	@$(CXX) $(CXXFLAGS) -c $< -o $(@)

$(OBJ)/%.E : %.c
	@$(CC) $(CFLAGS) -E -c $< -o $(@)

$(OBJ)/%.E : %.cc
	@$(CXX) $(CXXFLAGS) -E -c $< -o $(@)

$(OBJ)/%.o : %.s
	@echo Assembling $(<F)
	@$(AS) $(ASFLAGS) $< -o $(@)


$(BUILD)/softdevice_main.bin : $(NRF_SOFTDEVICE_HEX) | $(BUILD)
	@echo Extracting $(@F)
	@$(OBJCOPY) -Iihex -Obinary --remove-section .sec3 $(^) $(@)

$(BUILD)/softdevice_uicr.bin : $(NRF_SOFTDEVICE_HEX) | $(BUILD)
	@echo Extracting $(@F)
	@$(OBJCOPY) -Iihex -Obinary --only-section .sec3 $(^) $(@)

########################
define SEGGER_FLASH_SOFTDEVICE_CMD
device nrf51822
speed 1000
w4 4001e504 2 // enable erase
w4 4001e50c 1 // erase all
w4 4001e514 1 // erase uicr
r
w4 4001e504 1 // enable write
loadbin $(BUILD)/softdevice_uicr.bin 0x10001000
loadbin $(BUILD)/softdevice_main.bin 0x00000000
r
g
exit
endef
########################
export SEGGER_FLASH_SOFTDEVICE_CMD

########################
define SEGGER_FLASH_APP_CMD
device nrf51822
speed 1000
w4 4001e504 1
loadbin $(BUILD)/blink.bin 0x00014000
r
g
exit
endef
#########################
export SEGGER_FLASH_APP_CMD

########################
define SEGGER_FLASH_BARE_CMD
device nrf51822
speed 1000
w4 4001e504 2 // enable erase
w4 4001e50c 1 // erase all
w4 4001e514 1 // erase uicr
r
w4 4001e504 1 // enable write
loadbin $(BUILD)/blink.bin 0x00000000
r
g
exit
endef
#########################
export SEGGER_FLASH_BARE_CMD

INSTALLED_CDC_KEXT_COUNT := $(word 1,$(shell kextstat | grep USBCDC | wc))

ifeq ($(INSTALLED_CDC_KEXT_COUNT),0)
cdc :
	@echo No CDC drivers are installed.

jlink :
	@$(JLINKEXE)

flash_app : $(BUILD)/blink.bin
	@echo "$$SEGGER_FLASH_APP_CMD" | $(JLINKEXE)

flash_bare : $(BUILD)/blink.bin
	@echo "$$SEGGER_FLASH_BARE_CMD" | $(JLINKEXE)

flash_softdevice : $(BUILD)/softdevice_uicr.bin $(BUILD)/softdevice_main.bin
	@echo "$$SEGGER_FLASH_SOFTDEVICE_CMD" | $(JLINKEXE)

gdb_server :
	$(JLINKGDBSERVER) -if SWD -device nRF51822 -speed 4000

else
jlink flash_softdevice flash_app flash_bare gdb_server:
	@echo "Please disable the CDC drivers first. 'sudo make disable_cdc'"

cdc :
	@echo $(INSTALLED_CDC_KEXT_COUNT) CDC drivers are currently installed.
	@echo "Please 'sudo make disable_cdc' before using J-Link"
endif

.PHONY : softdevice disable_cdc enable_cdc clean info default cdc flashit flash_softdevice blink


