# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path
PATHTOGHDL="/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks ghdl path

# you have to specify the assembler text for the mips at the prompt!

if (( $# == 1)) 
then 
echo usage: run_ghdl.bat path/asm-file-without-extension

# Remove the work directory if it already exists.
echo "++++++++++ Create work folder +++++++++++++++++++++++++++++++++"

echo "Remove work directory."

#rm -rf workB
mkdir workB






# echo ++++++++++ assemble the MIPS program (imem and dmem) ++++++++++
# java -jar ./../../../Mars4_5.jar a dump .text HexText ../imem/%1.imem ../asm/%1.asm
# java -jar ./../../../Mars4_5.jar a dump .data HexText ../dmem/%1.dmem ../asm/%1.asm
 
echo "++++++++++ Create files for cache BRAMs +++++++++++++++++++++++"
echo .
$PATHTOGHDL -a -g -O3 --ieee=synopsys --workdir=work casts.vhd mips_pkg.vhd bram.vhd mainMemoryController.vhd mainMemory.vhd mainMemory_tb.vhd
echo .
echo ++++++++++ create an executable for the testbench ++++++++++
$PATHTOGHDL -e -g -O3 --ieee=synopsys --workdir=work mainMemory_tb
echo .
echo ++++++++++ run the executable ++++++++++
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=work mainMemory_tb --stop-time=40us --wave=../sim/%1_mainMemory.ghw -gData_Filename="../imem/%1" -gFile_Extension=".imem"
fi