# Relatively Simple CPU in Verilog

A complete Verilog HDL implementation of John Carpinelli's **Relatively Simple CPU** architecture. This project includes the top-level CPU design, dedicated ALU module, and a comprehensive testbench covering all 16 supported opcodes.
> [!IMPORTANT]
> **Work in Progress (WIP):** This project is currently under active development.
---

## Architecture Overview

* **Data Width**: 8-bit accumulator-based datapath.
* **Address Width**: 16-bit address space ($64\text{ KB}$ addressable memory).
* **Core Registers**:
  * `AC` (Accumulator - 8-bit): Primary register for arithmetic, logic, and data transfers.
  * `R` (Register - 8-bit): Secondary general-purpose register used for ALU operations.
  * `PC` (Program Counter - 16-bit): Points to the next instruction byte.
  * `AR` (Address Register - 16-bit): Holds memory address during memory accesses.
  * `DR` (Data Register - 8-bit): Buffers data read from or written to memory.
  * `IR` (Instruction Register - 8-bit): Stores the active opcode during execution.
  * `TR` (Temporary Register - 8-bit): Holds high-byte addresses during multi-byte fetches.
  * `Z` (Zero Flag - 1-bit): Set to `1` when an ALU operation produces a result of `0x00`.
* **Execution Unit**: Finite State Machine (FSM) control unit managing multi-cycle instruction fetching and execution.
* **ALU Sub-Module**: Independent combinational module handling addition, subtraction, increment, clear, AND, OR, XOR, and NOT functions.

---

## Hardware Diagram
<img width="655" height="954" alt="image" src="https://github.com/user-attachments/assets/3f2bf6c9-e096-42c9-9d95-349dac6c5eb1" />

<sub>*Figure: Hardware block diagram screenshot from **Computer Systems Organization and Architecture** by John D. Carpinelli (Addison-Wesley / Pearson). Used under fair use for educational reference.*</sub>




## Instruction Set Architecture (ISA)

The processor supports 16 distinct opcodes grouped into Data Transfer, Control Flow, Arithmetic, and Logic operations.

| Opcode Name | Binary Code | Bytes | Micro-operation / Description |
| :--- | :---: | :---: | :--- |
| **`NOP`**  | `0000 0000` | 1 | No Operation |
| **`LDAC`** | `0000 0001` | 3 | Load Accumulator from memory: `AC <- M[addr16]` |
| **`STAC`** | `0000 0010` | 3 | Store Accumulator to memory: `M[addr16] <- AC` |
| **`MVAC`** | `0000 0011` | 1 | Move Accumulator to Register R: `R <- AC` |
| **`MOVR`** | `0000 0100` | 1 | Move Register R to Accumulator: `AC <- R` |
| **`JUMP`** | `0000 0101` | 3 | Unconditional Jump: `PC <- addr16` |
| **`JMPZ`** | `0000 0110` | 3 | Jump if Zero flag is set (`Z == 1`): `PC <- addr16` |
| **`JPNZ`** | `0000 0111` | 3 | Jump if Zero flag is clear (`Z == 0`): `PC <- addr16` |
| **`ADD`**  | `0000 1000` | 1 | Add R to Accumulator: `AC <- AC + R`, update `Z` |
| **`SUB`**  | `0000 1001` | 1 | Subtract R from Accumulator: `AC <- AC - R`, update `Z` |
| **`INAC`** | `0000 1010` | 1 | Increment Accumulator: `AC <- AC + 1`, update `Z` |
| **`CLAC`** | `0000 1011` | 1 | Clear Accumulator: `AC <- 0x00`, update `Z` |
| **`AND`**  | `0000 1100` | 1 | Bitwise AND: `AC <- AC & R`, update `Z` |
| **`OR`**   | `0000 1101` | 1 | Bitwise OR: `AC <- AC | R`, update `Z` |
| **`XOR`**  | `0000 1110` | 1 | Bitwise XOR: `AC <- AC ^ R`, update `Z` |
| **`NOT`**  | `0000 1111` | 1 | Bitwise NOT: `AC <- ~AC`, update `Z` |

---


## Simulation

### 1. Compile the Design & Testbench
Compile all Verilog modules into a simulation executable:
```bash
iverilog -o sim_cpu tb_cpu.v cpu.v alu.v
```

---

## 🧪 Testbench Verification

The testbench [`tb_cpu.v`](file:///home/sachin/Documents/Relatively-Simple-CPU/tb_cpu.v) initializes a 256-byte RAM model and exercises all 16 CPU instructions. Upon running the testbench, verified assertions output step-by-step progress and a final pass summary:

```text
============================================================
  RELATIVELY SIMPLE CPU -- COMPLETE ISA TEST SUITE
============================================================
  [PASS] Test  1: NOP
  [PASS] Test  2: CLAC
  [PASS] Test  3: INAC
  [PASS] Test  4: MVAC & MOVR
  [PASS] Test  5: ADD
  [PASS] Test  6: SUB
  [PASS] Test  7: AND
  [PASS] Test  8: OR
  [PASS] Test  9: XOR
  [PASS] Test 10: NOT
  [PASS] Test 11: LDAC & STAC
  [PASS] Test 12: JUMP
  [PASS] Test 13: JMPZ (Taken & Not Taken)
  [PASS] Test 14: JPNZ (Taken & Not Taken)
============================================================
  TEST SUMMARY: PASS=14  FAIL=0
  ALL TESTS PASSED SUCCESSFULLY!
============================================================
```

---
