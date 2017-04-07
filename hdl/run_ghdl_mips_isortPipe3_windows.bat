@echo off
REM you have to specify the assembler text for the mips at the prompt!
 
REM Directories regarding Mars.
SET mars="./../../../Mars4_5.jar"

REM Set the assembler name.
SET assemblerName=isort_pipe3


REM Set generic variables for 2-way associative cache.
SET tagFilename="../imem/tag%assemblerName%"
SET dataFilename="../imem/data%assemblerName%"
SET fileExtension=".imem"
SET ghwFilename="mipsWithInstructionCache"
SET workDirectory="work"
SET DFileName=""../dmem/%assemblerName%""
SET IFileName=""../imem/%assemblerName%""

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
java -jar %mars% a dump .text HexText ../imem/%assemblerName%.imem ../asm/%assemblerName%.asm
java -jar %mars% a dump .data HexText ../dmem/%assemblerName%.dmem ../asm/%assemblerName%.asm

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
ghdl -m -g -O3 --ieee=synopsys --workdir=%workDirectory% mips_isortPipe3_tb
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%workDirectory% mips_isortPipe3_tb --stop-time=40us  --wave=../sim/%assemblerName%.ghw -gDFileName=%DFileName% -gIFileName=%IFileName% -gTAG_FILENAME=%tagFilename% -gDATA_FILENAME=%dataFilename% -gFILE_EXTENSION=%fileExtension%
