@echo off
REM Build script for Kairos Programming Language
REM Requires UCRT64 environment (MSYS2)

echo Building Kairos Programming Language Interpreter...

REM Check if we're in MSYS2/UCRT64 environment
if not defined MSYSTEM (
    echo Error: This script must be run in MSYS2/UCRT64 environment
    echo Please open UCRT64 terminal and run this script
    exit /b 1
)

REM Create build directories
if not exist "build" mkdir build
if not exist "build\obj" mkdir build\obj

REM Set assembly and linking flags for 64-bit Windows
set ASFLAGS=-f win64 -g -F dwarf -Iinclude/
set LDFLAGS=-m i386pep

echo.
echo Assembling source files...

REM Assemble each source file
nasm %ASFLAGS% -o build\obj\main.o src\main.asm
if errorlevel 1 goto error

nasm %ASFLAGS% -o build\obj\utils.o src\utils.asm
if errorlevel 1 goto error

nasm %ASFLAGS% -o build\obj\lexer.o src\lexer.asm
if errorlevel 1 goto error

nasm %ASFLAGS% -o build\obj\parser.o src\parser.asm
if errorlevel 1 goto error

nasm %ASFLAGS% -o build\obj\interpreter.o src\interpreter.asm
if errorlevel 1 goto error

echo.
echo Linking executable with GCC...

REM Link the final executable with C runtime
gcc -o build\kairos.exe build\obj\main.o build\obj\utils.o build\obj\lexer.o build\obj\parser.o build\obj\interpreter.o build\obj\memory.o build\obj\builtins.o
if errorlevel 1 goto error

echo.
echo Build successful! Executable created at: build\kairos.exe
echo.
echo To test the interpreter, run:
echo   build\kairos.exe examples\hello.kr
echo.
goto end

:error
echo.
echo Build failed! Check the error messages above.
exit /b 1

:end
echo Done.
