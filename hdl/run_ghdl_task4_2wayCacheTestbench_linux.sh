# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path
PATHTOGHDL="/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks ghdl path


# you have to specify the assembler text for the mips at the prompt!



if (( $# == 1)) 
then 


# Folder name of work directory.
location="workC"

# Set generic variables for 2-way associative cache.
replacementStrategy=LRU_t
mainMemoryFilename="../imem/$1"
dataFilenameCache1="../imem/data$1_cache1"
dataFilenameCache2="../imem/data$1_cache2"
tagFilenameCache1="../imem/tag$1_cache1"
tagFilenameCache2="../imem/tag$1_cache2"
fileExtension=".imem"
ghwFilename="twoWayCacheTestbench"


# Remove the work directory if it already exists.
echo "++++++++++ Create work folder +++++++++++++++++++++++++++++++++"

echo "Remove work directory."
rm -rf "$location"
mkdir "$location"


echo "++++++++++ assemble the MIPS program (imem and dmem) ++++++++++"
java -jar $PATHTOMARS a dump .text HexText ../imem/$1.imem ../asm/$1.asm
java -jar $PATHTOMARS a dump .data HexText ../dmem/$1.dmem ../asm/$1.asm
echo .
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=$location convertMemFiles.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=$location convertMemFiles
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=$location convertMemFiles -gDFileName="../dmem/$1" -gIFileName="../imem/$1"
echo .
echo ++++++++++ Create files for cache BRAMs +++++++++++++++++++++++
echo .
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=$location cache_pkg.vhd creatorOfTwoWayCacheFiles.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=$location creatorOfTwoWayCacheFiles
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=$location creatorOfTwoWayCacheFiles -gDATA_FILENAME_CACHE2=$dataFilenameCache2 -gDATA_FILENAME_CACHE1=$dataFilenameCache1 -gTAG_FILENAME_CACHE1=$tagFilenameCache1 -gTAG_FILENAME_CACHE2=$tagFilenameCache2 -gFILE_EXTENSION=$fileExtension -gFILE_EXTENSION=$fileExtension

# @echo off
echo .
echo ++++++++++ add files in the work design library ++++++++++
$PATHTOGHDL -i -g -O3 --ieee=synopsys --workdir=$location mips_pkg.vhd casts.vhd cache_pkg.vhd bram.vhd directMappedCacheController.vhd mainMemoryController.vhd mainMemory.vhd directMappedCache.vhd cacheController.vhd twoWayAssociativeCacheController.vhd twoWayAssociativeCache.vhd twoWayAssociativeCache_tb.vhd
echo .
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
$PATHTOGHDL -m -g -O3 --ieee=synopsys --workdir=$location twoWayAssociativeCache_tb
echo .
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=$location twoWayAssociativeCache_tb --stop-time=300000ns --wave=../sim/$ghwFilename.ghw -gMAIN_MEMORY_FILENAME=$mainMemoryFilename -gREPLACEMENT_STRATEGY=$replacementStrategy -gDATA_FILENAME_CACHE2=$dataFilenameCache2 -gDATA_FILENAME_CACHE1=$dataFilenameCache1 -gTAG_FILENAME_CACHE1=$tagFilenameCache1 -gTAG_FILENAME_CACHE2=$tagFilenameCache2 -gFILE_EXTENSION=$fileExtension



fi