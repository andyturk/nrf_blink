SECTIONS {
 .text : {
    . = 0;
    PROVIDE (__text_start__ = .);
    __Vectors = .;
    KEEP(*(.vectors))
      *(.startup*)
      . = 0x400;
    *(.text*)
      *(.gnu.linkonce.t*)
      *(.rodata* .gnu.linkonce.r.*)
      . = ALIGN(4);
    KEEP(*(.init))
      *(.ARM.extab* .gnu.linkonce.armextab.*)
      *(.gcc_except_table)
      . = ALIGN(4);
    __preinit_array_start = .;
    KEEP (*(.preinit_array))
      __preinit_array_end = .;
    __init_array_start = .;
    KEEP (*(SORT(.init_array.*)))
      KEEP (*(.init_array))
      __init_array_end = .;
		
  } > FLASH = 0xFF

  .ARM.exidx : {
    __exidx_start = .;
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    __exidx_end = .;
  } > FLASH
	
  .eh_frame : {
    *(.eh_frame);
  } > FLASH
	
  _etext = .;
  PROVIDE (__text_end__ = .);

  .data : AT (_etext) {
    . = ALIGN(4);
    _sdata = .; 
    PROVIDE (__data_start__ = .);
    *(.data* .gnu.linkonce.d.*)
      . = ALIGN(4);
    _edata = .; 
    PROVIDE (__data_end__ = .);
  } > RAM

  .noinit (NOLOAD) : {
    *(.noinit*)
  } > RAM

  .bss : {
    . = ALIGN(4);
    _sbss = .; 
    PROVIDE (__bss_start__ = _sbss);
    *(.shbss)
      *(.bss* .gnu.linkonce.b.*)
      *(COMMON)
      *(.ram.b .bss.ram)
      . = ALIGN(4);
    _ebss = .;   
    PROVIDE (__bss_end__ = .);
  } > RAM
  end = .;
  _end = .;
  __end = .;
  PROVIDE (__end__ = end);

  _estack = ORIGIN(RAM) + LENGTH(RAM);
  PROVIDE (__stack_end__ = _estack);
}

