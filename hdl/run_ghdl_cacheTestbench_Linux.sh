# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path
PATHTOGHDL="/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks ghdl path


if (( $# == 1)) 
then 


# Remove the work directory if it already exists.
echo ++++++++++ Create work folder +++++++++++++++++++++++++++++++++

echo "Remove work directory."
rm -rf workB
mkdir workB

# Create new work folder if it does not exist.
 
#echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
java -jar $PATHTOMARS a dump .text HexText ../imem/$1.imem ../asm/$1.asm
java -jar $PATHTOMARS a dump .data HexText ../dmem/$1.dmem ../asm/$1.asm
echo .
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=workB convertMemFiles.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=workB convertMemFiles
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=workB convertMemFiles -gDFileName="../dmem/$1" -gIFileName="../imem/$1"
echo .
echo ++++++++++ Create files for cache BRAMs +++++++++++++++++++++++
echo .
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=workB cache_pkg.vhd creatorOfCacheFiles.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=workB creatorOfCacheFiles
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=workB creatorOfCacheFiles -gTag_Filename="../imem/tag$1" -gData_Filename="../imem/data$1" -gFILE_EXTENSION=".imem"

#@echo off
echo .
echo ++++++++++ add files in the work design library ++++++++++
$PATHTOGHDL -i -g -O3 --ieee=synopsys --workdir=workB mips_pkg.vhd casts.vhd cache_pkg.vhd bram.vhd directMappedCacheController.vhd mainMemoryController.vhd mainMemory.vhd directMappedCache.vhd cacheController.vhd cache.vhd cache_tb.vhd 
echo .
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
$PATHTOGHDL -m -g -O3 --ieee=synopsys --workdir=workB cache_tb
echo .
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=workB cache_tb --stop-time=300000ns  --wave=../sim/cacheTestbench.ghw -gMAIN_MEMORY_FILENAME="../imem/$1" -gData_Filename="../imem/data$1" -gTag_Filename="../imem/tag$1" -gFILE_EXTENSION=".imem"




fi