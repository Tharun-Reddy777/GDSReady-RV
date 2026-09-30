# GDSReady-RV

## RTL-to-GDSII Implementation of a 32-bit 5-Stage Pipelined RISC-V Processor

GDSReady-RV is a complete academic RTL-to-GDSII implementation of a
32-bit five-stage pipelined RISC-V-style processor.

### Pipeline

IF -> ID -> EX -> MEM -> WB

### Major Features

- 32-bit datapath
- 32 × 32-bit register file
- x0 hard-wired to zero
- ALU operations:
  ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA
- Immediate generation
- Instruction decoding
- Control unit
- Branch handling
- JAL
- EX/MEM and MEM/WB forwarding
- Load-use hazard detection
- Pipeline registers
- ASIC-facing instruction/data memory interfaces

## RTL Verification

Final directed regression:

- ALU + forwarding: PASS
- Load/store + load-use: PASS
- BEQ/BNE: PASS
- JAL: PASS

Result:

ALL RTL REGRESSION TESTS PASSED

## ASIC Flow

The ASIC-facing design was processed through:

RTL
-> Yosys synthesis
-> OpenROAD floorplan
-> placement
-> CTS
-> routing
-> post-route STA
-> antenna checking
-> Magic DRC
-> KLayout DRC
-> Netgen LVS
-> GDSII

Technology:

SKY130 HD standard-cell flow

## Final Implementation

Primary run:

RISCV_ASIC_PNR_01

Clock target:

10 ns / 100 MHz

Physical verification:

- DRC: PASS
- LVS: PASS
- Antenna: PASS

Timing:

The implementation is not setup-timing-clean at the 10 ns target
under the slow-corner analysis. The worst post-P&R nominal slow-corner
setup WNS is approximately -6.861 ns. Hold timing is clean.

## Final Deliverables

- final/gds/riscv_core_asic_final.gds
- final/layout/riscv_core_asic.lef
- final/layout/riscv_core_asic.def
- final/netlist/riscv_core_asic.nl.v
- final/rtl/
- final/reports/
- docs/GDSReady_RV_Final_Project_Report.docx

## Project Report

See:

docs/GDSReady_RV_Final_Project_Report.docx
