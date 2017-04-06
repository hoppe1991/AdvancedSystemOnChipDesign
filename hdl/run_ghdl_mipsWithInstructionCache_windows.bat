@echo off
REM you have to specify the assembler text for the mips at the prompt!

IF "%~1"=="" (
echo usage: run_ghdl.bat path/asm-file-without-extension
GOTO :eof
)

REM Directories regarding Mars.
SET mars="./../../../Mars4_5.jar"

REM Set generic variables for 2-way associative cache.
SET tagFilename="../imem/tag%1"
SET dataFilename="../imem/data%1"
SET fileExtension=".imem"
SET ghwFilename="mipsWithInstructionCache"
SET workDirectory="work"
SET DFileName=""../dmem/%1""
SET IFileName=""../imem/%1""

echo.
echo ++++++++++ Create work folder +++++++++++++++++++++++++++++++++
REM Remove the work directory if it already exists.
if exist %workDirectory% ( 
	echo Remove work directory %workDirectory%.
	rmdir /s /q "%workDirectory%"
)
REM Create new work folder if it does not exist.
if not exist %workDirectory% (
	echo Create work directory %workDirectory%.
	mkdir "%workDirectory%"
 )

echo.
echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
java -jar %mars% a dump .text HexText ../imem/%1.imem ../asm/%1.asm
java -jar %mars% a dump .data HexText ../dmem/%1.dmem ../asm/%1.asm

echo.
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
ghdl -a -g -O3 --ieee=synopsys --workdir=%workDirectory% convertMemFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=%workDirectory% convertMemFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%workDirectory% convertMemFiles -gDFileName=%DFileName% -gIFileName=%IFileName%

echo.
echo ++++++++++ Create files for cache BRAMs +++++++++++++++++++++++
echo.
ghdl -a -g -O3 --ieee=synopsys --workdir=%workDirectory% cache_pkg.vhd creatorOfCacheFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=%workDirectory% creatorOfCacheFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%workDirectory% creatorOfCacheFiles -gTag_Filename=%tagFilename% -gData_Filename=%dataFilename% -gFILE_EXTENSION=%fileExtension%


echo.
echo ++++++++++ add files in the work design library ++++++++++
ghdl -i -g -O3 --ieee=synopsys --workdir=%workDirectory% *.vhd
echo.
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
ghdl -m -g -O3 --ieee=synopsys --workdir=%workDirectory% mips_with_instructionCache_tb
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%workDirectory% mips_with_instructionCache_tb --stop-time=40us  --wave=../sim/%1.ghw -gDFileName=%DFileName% -gIFileName=%IFileName% -gTAG_FILENAME=%tagFilename% -gDATA_FILENAME=%dataFilename% -gFILE_EXTENSION=%fileExtension%
