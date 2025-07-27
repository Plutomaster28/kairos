# Makefile for Kairos Programming Language Interpreter
# Built with NASM and MinGW-w64 for Windows

# Compiler and assembler settings
AS = nasm
LD = ld
CC = gcc
ASFLAGS = -f elf32 -g -F dwarf
LDFLAGS = -m i386pe -e _start
CFLAGS = -m32

# Directories
SRCDIR = src
INCDIR = include
BUILDDIR = build
OBJDIR = $(BUILDDIR)/obj

# Source files
ASM_SOURCES = $(wildcard $(SRCDIR)/*.asm)
OBJECTS = $(ASM_SOURCES:$(SRCDIR)/%.asm=$(OBJDIR)/%.o)

# Target executable
TARGET = $(BUILDDIR)/kairos.exe

# Default target
all: directories $(TARGET)

# Create directories
directories:
	@if not exist "$(BUILDDIR)" mkdir "$(BUILDDIR)"
	@if not exist "$(OBJDIR)" mkdir "$(OBJDIR)"

# Link the final executable
$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

# Compile assembly files
$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	$(AS) $(ASFLAGS) -I$(INCDIR)/ -o $@ $<

# Clean build files
clean:
	@if exist "$(BUILDDIR)" rmdir /s /q "$(BUILDDIR)"

# Install NASM and MinGW-w64 (if using MSYS2/UCRT64)
install-deps:
	pacman -S mingw-w64-ucrt-x86_64-gcc nasm

# Run the interpreter
run: $(TARGET)
	$(TARGET) examples/hello.kr

# Debug build
debug: ASFLAGS += -F dwarf
debug: all

# Test target
test: $(TARGET)
	@echo "Running tests..."
	@for %%f in (tests\*.kr) do $(TARGET) %%f

.PHONY: all clean directories install-deps run debug test

# Help target
help:
	@echo "Kairos Programming Language Makefile"
	@echo "Available targets:"
	@echo "  all        - Build the interpreter (default)"
	@echo "  clean      - Remove build files"
	@echo "  run        - Build and run with hello.kr"
	@echo "  test       - Run all tests"
	@echo "  debug      - Build with debug symbols"
	@echo "  help       - Show this help message"
