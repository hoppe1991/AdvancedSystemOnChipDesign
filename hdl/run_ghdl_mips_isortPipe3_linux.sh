# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="$MYMARS"    #/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path 
ghdl="ghdl"   			#/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks old ghdl path 


# Define the configuration
if [[ $# -eq 0 ]] ; then
config="cisort3"
else
config=$1
fi
echo "Use configuration " $config

# Directories regarding Mars.
mars="$PATHTOMARS"

# Set the assembler name.
asmFilename=isort_pipe3

# Define the working directory.
workDirectory="work"

# Set generic variables for 2-way associative cache.
tagFilename="../imem/tag$asmFilename"
dataFilename="../imem/data$asmFilename"
fileExtension=".imem"
DFileName="../dmem/$asmFilename"
IFileName="../imem/$asmFilename"

echo "."
# Remove the work directory if it already exists.
echo "++++++++++ Create work folder +++++++++++++++++++++++++++++++++"
echo "Remove work directory."
rm -rf $workDirectory
mkdir $workDirectory
echo "."
echo "++++++++++ assemble the MIPS program (imem and dmem) ++++++++++"
java -jar $mars a dump .text HexText ../imem/$asmFilename.imem ../asm/$asmFilename.asm
java -jar $mars a dump .data HexText ../dmem/$asmFilename.dmem ../asm/$asmFilename.asm

echo "."
echo "++++++++++ check syntax of the vhdl file gates.vhd ++++++++++"
$ghdl -a -g -O3 --ieee=synopsys --workdir=$workDirectory convertMemFiles.vhd
echo "."
echo "++++++++++ create an executable for the testbench ++++++++++"
$ghdl -e -g -O3 --ieee=synopsys --workdir=$workDirectory convertMemFiles
echo "."
echo "++++++++++ run the executable ++++++++++"
$ghdl -r -g -O3 --ieee=synopsys --workdir=$workDirectory convertMemFiles -gDFileName=$DFileName -gIFileName=$IFileName

echo "."
echo "++++++++++ Create files for cache BRAMs +++++++++++++++++++++++"
echo "."
$ghdl -a -g -O3 --ieee=synopsys --workdir=$workDirectory cache_pkg.vhd creatorOfCacheFiles.vhd
echo "."
echo "++++++++++ create an executable for the testbench ++++++++++"
$ghdl -e -g -O3 --ieee=synopsys --workdir=$workDirectory creatorOfCacheFiles
echo "."
echo "++++++++++ run the executable ++++++++++"
$ghdl -r -g -O3 --ieee=synopsys --workdir=$workDirectory creatorOfCacheFiles -gTag_Filename=$tagFilename -gData_Filename=$dataFilename -gFILE_EXTENSION=$fileExtension

echo "."
echo "++++++++++ add files in the work design library ++++++++++"
$ghdl -i -g -O3 --ieee=synopsys --workdir=$workDirectory *.vhd

echo "."
echo "++++++++++ analyze automatically outdated files and create an executable ++++++++++"
$ghdl -m -g -O3 --ieee=synopsys --workdir=$workDirectory $config mips_isortPipe3_tb
echo "."

echo "++++++++++ run the executable for 15us and save all waveforms ++++++++++"
echo $tagFilename 
$ghdl -r -g -O3 --ieee=synopsys --workdir=$workDirectory $config mips_isortPipe3_tb  --stop-time=40us --wave=../sim/$asmFilename.ghw -gDFileName=$DFileName -gIFileName=$IFileName -gTAG_FILENAME=$tagFilename -gDATA_FILENAME=$dataFilename -gFILE_EXTENSION=$fileExtension
