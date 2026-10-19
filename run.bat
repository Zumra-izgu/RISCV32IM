@echo off
setlocal
cd /d "%~dp0"

if exist "rtl\defines.vh" (
    cd rtl
) else (
    echo [ERROR] defines.vh not found in . or rtl\
    pause
    exit /b 1
)

set TB=..\tb\riscv_tb.v
if not exist "%TB%" set TB=tb\riscv_tb.v
if not exist "%TB%" (
    echo [ERROR] Testbench not found.
    pause
    exit /b 1
)

echo ========================================
echo   RISC-V Pipeline Simulation
echo ========================================
echo.

echo [1/4] Compiling RTL and Testbench...
iverilog -g2012 -s riscv_tb -o riscv_tb.vvp ^
    defines.vh ^
    alu_control.v ^
    alu.v ^
    control_unit.v ^
    data_mem.v ^
    ex_stage.v ^
    forwarding_unit.v ^
    hazard_unit.v ^
    id_stage.v ^
    if_stage.v ^
    instr_mem.v ^
    mem_stage.v ^
    pc.v ^
    register_file.v ^
    riscv_pipeline.v ^
    wb_stage.v ^
    %TB%

if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed!
    pause
    exit /b 1
)

echo [2/4] Compilation successful.
echo.

echo [3/4] Running simulation...
vvp riscv_tb.vvp
if %errorlevel% neq 0 (
    echo [ERROR] Simulation failed!
    pause
    exit /b 1
)

echo.
echo [4/4] Simulation finished. VCD file generated: riscv.vcd
echo.

echo Opening GTKWave...
start gtkwave riscv.vcd
exit /b 0