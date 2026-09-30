GDSReady-RV
32-bit 5-Stage Pipelined RISC-V Processor
RTL-to-GDSII ASIC Implementation

Repository
https://github.com/Tharun-Reddy777/GDSReady-RV

Technology
- SKY130 HD
- LibreLane
- Yosys
- OpenROAD
- Magic
- KLayout
- Netgen

Architecture
IF → ID → EX → MEM → WB

Verification
- ALU + forwarding: PASS
- Load/store + load-use: PASS
- BEQ/BNE: PASS
- JAL: PASS

Physical Implementation
- GDSII generated
- DRC: PASS
- LVS: PASS
- Antenna: PASS
- Hold timing: PASS
- Setup timing: limitation at the 10 ns target

Main RTL
rtl/riscv_core.s

ASIC RTL
rtl/riscv_core_asic.s

Final GDS
final/gds/riscv_core_asic_final.gds
