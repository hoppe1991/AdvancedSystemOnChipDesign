#You have to specify the filename regarding the tag cache.


# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path
PATHTOGHDL="/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks ghdl path

echo usage: testCreatorCache.bat path/filename-without-extension path/filename-without-extension

if (( $# == 2)) 
then 


# Remove the work directory if it already exists.
echo "++++++++++ Create work folder +++++++++++++++++++++++++++++++++"

echo "Remove work directory."
#rm -rf work
mkdir work



echo .
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=work cache_pkg.vhd  creatorOfCacheFiles.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=work creatorOfCacheFiles
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=work creatorOfCacheFiles -gTag_Filename="../imem/$1" -gData_Filename="../imem/$2"


fi