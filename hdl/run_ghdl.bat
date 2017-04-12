@echo off
REM you have to specify the assembler text for the mips at the prompt!

IF "%~1"=="" (
echo usage: run_ghdl.bat path/asm-file-without-extension
GOTO :eof
)

echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
java -jar ./../../../Mars4_5.jar a dump .text HexText ../imem/%1.imem ../asm/%1.asm
java -jar ./../../../Mars4_5.jar a dump .data HexText ../dmem/%1.dmem ../asm/%1.asm

echo.
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
ghdl -a -g -O3 --ieee=synopsys --workdir=work convertMemFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=work convertMemFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=work convertMemFiles -gDFileName="../dmem/%1" -gIFileName="../imem/%1"


echo.
echo ++++++++++ add files in the work design library ++++++++++
ghdl -i -g -O3 --ieee=synopsys --workdir=work *.vhd
echo.
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
ghdl -m -g -O3 --ieee=synopsys --workdir=work mips_testbench
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=work mips_testbench --stop-time=40us  --wave=../sim/%1.ghw -gDFileName="../dmem/%1" -gIFileName="../imem/%1"
