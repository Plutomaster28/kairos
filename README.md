# Kairos Programming Language

A scripting language interpreter written in x86 Assembly, combining the best of Bash, Lua, and Python.

## Features (Planned)
- Dynamic typing
- Shell-like command execution capabilities
- Lua-inspired table structures
- Python-like syntax clarity
- Built from scratch in x86 Assembly

## Build Requirements
- UCRT64 toolchain
- NASM (Netwide Assembler)
- MinGW-w64

## Project Structure
```
kairos/
├── src/
│   ├── main.asm          # Entry point
│   ├── lexer.asm         # Tokenization
│   ├── parser.asm        # Parse tree generation
│   ├── interpreter.asm   # Core interpreter logic
│   ├── memory.asm        # Memory management
│   ├── builtins.asm      # Built-in functions
│   └── utils.asm         # Utility functions
├── include/
│   └── kairos.inc        # Main include file with constants and macros
├── tests/
│   └── *.kr              # Kairos test files
├── examples/
│   └── *.kr              # Example Kairos programs
├── build/                # Build output
└── Makefile              # Build configuration
```

## Building
```bash
make clean
make
```

## Running
```bash
./build/kairos script.kr
```
