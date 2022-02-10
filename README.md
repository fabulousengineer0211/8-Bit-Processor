# 8-Bit-Processor
Its a VHDL code for 8-bit processor. which has a Memory, ALU and a driver (which is synchronising memory and alu). 
The processor is capable of performing signed and unsigned operations and storing the output in a 16 bit register.
The complete action occurs at a rising edge of the clock with respect to the input read and write signals.
The code has compiled perfectly, but improvements are yet going.
# Improvements :-
1. Currently, the division is working absolutely fine for integral results,  for fraction numbers improvement is going.
2. Due to software simulation limitations, individually ALU and Memory are working fine, but the Driver i.e. synchronisation of both, is yet to be confirmed.
