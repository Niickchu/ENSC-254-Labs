# ENSC-254-Assignments

## Note: These projects were developed for usage with a ZedBoard and the Xilinx Software Development Kit
### Note 2: Most of these assignments will not run without the necessary project folder. Nevertheless, I will keep this repo public as proof that I can write 32 bit ARM assembly

**Assignment 1: Big Add** \
An assembly subroutine that accurately adds two large numbers (larger than 32 bits) from memory and stores the sum back into memory. Includes all possible cases and has error handling.

**Assignment 2: Big Fib** \
C code which uses the Big Add subroutine to calculate fibonacci numbers.

**Assignment 3: ZedBoard GPIO** \
An assembly routine that implements a counter that can be incremented/decremented using the on board GPIO buttons. The counter was displayed in binary using the on board LED's

**Assignment 4: ZedBoard Fast Interrupt** \
An FIQ Handler that handles button interrupts and increments/decrements a counter using the on board buttons. The counter was displaed on the OLED display.

**Assignment 4: ZedBoard Fast Interrupt** \
An FIQ handler that button interrupts. These interrupts will increment/decrement a counter and display it to the OLED display as well as the LED's. The FPGA's Timer Counter was used to implement button debouncing.
