# Jack → VM → Hack Compiler (Zig)

A multi-stage compiler for the [Nand2Tetris](https://www.nand2tetris.org/) project, written in [Zig](https://ziglang.org/). This toolchain translates high-level Jack programs down to low-level Hack assembly code through a cleanly modular pipeline.

> **Stages:** `Jack (.jack)` → `VM (.vm)` → `Hack Assembly (.asm)`

---

## 🧠 Project Overview

This project implements a **Jack-to-Hack compiler** from scratch using the Zig programming language. It mirrors the compilation stages taught in the Nand2Tetris course:

1. **Jack Parser:** Parses `.jack` source files and generates an Abstract Syntax Tree (AST).
2. **VM Translator:** Converts the AST to virtual machine code in `.vm` format.
3. **VM-to-Hack Compiler:** Translates `.vm` instructions to Hack assembly (`.asm`) using stack-based logic.

Each stage is decoupled and testable independently.

---

## 🛠️ Tech Stack

- **Language:** Zig
- **Paradigm:** Systems-level, type-safe
- **Build System:** `build.zig`
- **Tests:** Custom unit tests for parsers and translators

---

## 🚀 Features

- ✅ Full Jack language parser and tokenizer
- ✅ Generates valid VM code with correct control flow, memory, and function handling
- ✅ Handles multiple `.vm` files for full project translation
- ✅ Outputs clean Hack assembly code compatible with the Nand2Tetris CPU emulator
- ✅ Modular and extensible Zig codebase

---

## 📁 Project Structure

```bash
zig-compiler-project/
├── src/
│   ├── jack/          # Tokenizer & parser for Jack language
│   ├── vm/            # VM code generator
│   ├── hack/          # Hack code generator
│   └── main.zig       # Entry point
├── tests/             # Unit tests for parser and translator
├── build.zig          # Build configuration
└── README.md
````

---

## 📚 Background

This compiler is part of the [Nand2Tetris](https://www.nand2tetris.org/) course, a renowned computer science curriculum that teaches the full stack — from logic gates to high-level languages.

Implementing the compiler in **Zig** gave me hands-on experience with:

* Manual memory management
* Compile-time execution
* AST construction
* System-level program design

---

## 🧑‍💻 Author

**Effie Mincer**
Computer Science @ JCT | Systems Programming Enthusiast
[effiemincer.dev](https://www.effiemincer.dev)

**Rachamim Seltzer**
Computer Science @ JCT

---

## 🪪 License

MIT — See [`LICENSE`](./LICENSE)
---
