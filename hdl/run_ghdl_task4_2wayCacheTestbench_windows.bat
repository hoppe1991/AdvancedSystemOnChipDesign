@echo off
REM you have to specify the assembler text for the mips at the prompt!

IF "%~1"=="" (
echo usage: run_ghdl.bat path/asm-file-without-extension
GOTO :eof
)

REM Folder name of work directory.
SET location="workC"

REM Set generic variables for 2-way associative cache.
SET replacementStrategy=LRU_t
SET mainMemoryFilename="../imem/%1"
SET dataFilenameCache1="../imem/data%1_cache1"
SET dataFilenameCache2="../imem/data%1_cache2"
SET tagFilenameCache1="../imem/tag%1_cache1"
SET tagFilenameCache2="../imem/tag%1_cache2"
SET fileExtension=".imem"

REM Remove the work directory if it already exists.
echo ++++++++++ Create work folder +++++++++++++++++++++++++++++++++
if exist %location% (
	echo "Remove work directory."
	rmdir /s /q %location%
)

REM Create new work folder if it does not exist.
if not exist %location% (
	echo "Create work directory."
	mkdir %location%
 )

echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
java -jar ./../../../Mars4_5.jar a dump .text HexText ../imem/%1.imem ../asm/%1.asm
java -jar ./../../../Mars4_5.jar a dump .data HexText ../dmem/%1.dmem ../asm/%1.asm
echo.
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
ghdl -a -g -O3 --ieee=synopsys --workdir=%location% convertMemFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=%location% convertMemFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%location% convertMemFiles -gDFileName="../dmem/%1" -gIFileName="../imem/%1"
echo.
echo ++++++++++ Create files for cache BRAMs +++++++++++++++++++++++
echo.
ghdl -a -g -O3 --ieee=synopsys --workdir=%location% cache_pkg.vhd creatorOfTwoWayCacheFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=%location% creatorOfTwoWayCacheFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%location% creatorOfTwoWayCacheFiles -gDATA_FILENAME_CACHE2=%dataFilenameCache2% -gDATA_FILENAME_CACHE1=%dataFilenameCache1% -gTAG_FILENAME_CACHE1=%tagFilenameCache1% -gTAG_FILENAME_CACHE2=%tagFilenameCache2% -gFILE_EXTENSION=%fileExtension% -gFILE_EXTENSION=%fileExtension%

@echo off
echo.
echo ++++++++++ add files in the work design library ++++++++++
ghdl -i -g -O3 --ieee=synopsys --workdir=%location% mips_pkg.vhd casts.vhd cache_pkg.vhd bram.vhd directMappedCacheController.vhd mainMemoryController.vhd mainMemory.vhd directMappedCache.vhd cacheController.vhd twoWayAssociativeCacheController.vhd twoWayAssociativeCache.vhd twoWayAssociativeCache_tb.vhd
echo.
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
ghdl -m -g -O3 --ieee=synopsys --workdir=%location% twoWayAssociativeCache_tb
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=%location% twoWayAssociativeCache_tb --stop-time=300000ns  --wave=../sim/cacheTestbench.ghw -gREPLACEMENT_STRATEGY=%replacementStrategy% -gDATA_FILENAME_CACHE2=%dataFilenameCache2% -gDATA_FILENAME_CACHE1=%dataFilenameCache1% -gTAG_FILENAME_CACHE1=%tagFilenameCache1% -gTAG_FILENAME_CACHE2=%tagFilenameCache2% -gFILE_EXTENSION=%fileExtension%
