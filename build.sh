#!/bin/bash
# Build script for Kairos Programming Language (Windows UCRT64)

echo "Building Kairos Programming Language Interpreter..."

# Create build directories
mkdir -p build/obj

# Set assembly and linking flags for Windows 64-bit
ASFLAGS="-f win64 -g -Iinclude/"

echo
echo "Assembling source files..."

# Assemble each source file to object format
nasm $ASFLAGS -o build/obj/main.obj src/main.asm || exit 1
nasm $ASFLAGS -o build/obj/utils.obj src/utils.asm || exit 1
nasm $ASFLAGS -o build/obj/lexer.obj src/lexer.asm || exit 1
nasm $ASFLAGS -o build/obj/parser.obj src/parser.asm || exit 1
nasm $ASFLAGS -o build/obj/interpreter.obj src/interpreter.asm || exit 1
nasm $ASFLAGS -o build/obj/memory.obj src/memory.asm || exit 1
nasm $ASFLAGS -o build/obj/builtins.obj src/builtins.asm || exit 1

echo
echo "Linking executable with GCC..."

# Use GCC to link (no -m32 flag for 64-bit)
gcc -o build/kairos.exe build/obj/main.obj build/obj/utils.obj build/obj/lexer.obj build/obj/parser.obj build/obj/interpreter.obj build/obj/memory.obj build/obj/builtins.obj || exit 1

echo
echo "Build successful! Executable created at: build/kairos"
echo
echo "To test the interpreter, run:"
echo "  ./build/kairos examples/hello.kr"
echo
