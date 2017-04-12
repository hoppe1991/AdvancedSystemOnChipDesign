@echo off
REM you have to specify the assembler text for the mips at the prompt!

REM Define the configuration
IF "%~1"=="" (
SET config=cgcd3
) ELSE (
SET config=%1
)
echo "Use configuration " %config%

REM Directories regarding Mars.
SET mars="./../../../Mars4_5.jar"

REM Set the assembler name.
SET asmFilename=gcd

REM Define the working directory.
SET workDirectory="work"

REM Set generic variables for 2-way associative cache.
SET tagFilename="../imem/tag%asmFilename%"
SET dataFilename="../imem/data%asmFilename%"
SET fileExtension=".imem"
SET ghwFilename="mipsWithInstructionCache"
SET DFileName=""../dmem/%asmFilename%""
SET IFileName=""../imem/%asmFilename%""

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
java -jar %mars% a dump .text HexText ../imem/%asmFilename%.imem ../asm/%asmFilename%.asm
java -jar %mars% a dump .data HexText ../dmem/%asmFilename%.dmem ../asm/%asmFilename%.asm

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
echo ++++++++++ add files in the work design library ++++++++++
ghdl -m -g -O3 --ieee=synopsys --workdir=%workDirectory% %config% mips_gcd_tb
echo. 
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=%workDirectory% %config% mips_gcd_tb
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%workDirectory% %config% mips_gcd_tb --stop-time=40us --wave=../sim/%asmFilename%.ghw -gDFileName=%DFileName% -gIFileName=%IFileName% -gTAG_FILENAME=%tagFilename% -gDATA_FILENAME=%dataFilename% -gFILE_EXTENSION=%fileExtension%
