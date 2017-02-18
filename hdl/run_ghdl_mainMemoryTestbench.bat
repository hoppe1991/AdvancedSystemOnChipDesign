echo off
REM you have to specify the assembler text for the mips at the prompt!

IF "%~1"=="" (
echo usage: run_ghdl.bat path/asm-file-without-extension
GOTO :eof
)

REM echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
REM java -jar ./../../../Mars4_5.jar a dump .text HexText ../imem/%1.imem ../asm/%1.asm
REM java -jar ./../../../Mars4_5.jar a dump .data HexText ../dmem/%1.dmem ../asm/%1.asm
 
echo ++++++++++ Create files for cache BRAMs +++++++++++++++++++++++
echo.
ghdl -a -g -O3 --ieee=synopsys --workdir=work casts.vhd mips_pkg.vhd bram.vhd mainMemoryController.vhd mainMemory.vhd mainMemory_tb.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=work mainMemory_tb
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=work mainMemory_tb --stop-time=40us --wave=../sim/%1_mainMemory.ghw -gData_Filename="../imem/%1" -gFile_Extension=".imem"