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

## 🧪 Running & Testing

### Build the compiler:

```bash
zig build
```

### Run the compiler on a Jack source directory:

```bash
zig build run -- /path/to/JackProject
```

This will recursively compile all `.jack` files into `.asm` output in the target directory.

### Run tests:

```bash
zig build test
```

---

## 📚 Background

This compiler is part of the [Nand2Tetris](https://www.nand2tetris.org/) course, a renowned computer science curriculum that teaches the full stack — from logic gates to high-level languages.

Implementing the compiler in **Zig** gave me hands-on experience with:

* Manual memory management
* Compile-time execution
* AST construction
* System-level program design

---

## 🧵 Future Work

* Add symbol table and support for class-level scoping
* Implement Jack standard library
* Add CLI options for individual compilation stages
* Improve error handling and diagnostics

---

## 📸 Demo

<p align="center">
  <img src="https://raw.githubusercontent.com/effiemincer/zig-compiler-project/main/assets/compilation-pipeline.png" alt="Jack to VM to Hack Compilation Pipeline" width="500">
</p>

---

## 🧑‍💻 Author

**Effie Mincer**
Computer Science @ JCT | Systems Programming Enthusiast
[effiemincer.dev](https://www.effiemincer.dev)

---

## 🪪 License

MIT — See [`LICENSE`](./LICENSE)
---
