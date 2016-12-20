# you have to specify the assembler text for the mips at the prompt!
if (( $# == 1)) 
then
# assemble the MIPS program (imem and dmem)
java -jar /home/leonard/Documents/Mars.jar a dump .text HexText ../imem/$1.imem ../asm/$1.asm
java -jar /home/leonard/Documents/Mars.jar a dump .data HexText ../dmem/$1.dmem ../asm/$1.asm

# check syntax of the vhdl file gates.vhd
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -a -g -O3 --ieee=synopsys --workdir=work convertMemFiles.vhd
# creates an executable for the testbench
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -e -g -O3 --ieee=synopsys --workdir=work convertMemFiles
# runs the executable
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -r -g -O3 --ieee=synopsys --workdir=work convertMemFiles -gDFileName="../dmem/$1" -gIFileName="../imem/$1"

# add files in the work design library
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -i -g -O3 --ieee=synopsys --workdir=work *.vhd
# analyze automatically outdated files and creates an executable
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -m -g -O3 --ieee=synopsys --workdir=work mips_testbench
# runs the executable for 15us and saves all waveforms
/home/leonard/Documents/ghdl-0.33-x86_64-linux/bin/ghdl -r -g -O3 --ieee=synopsys --workdir=work mips_testbench --stop-time=15us  --wave=../sim/$1.ghw -gDFileName="../dmem/$1" -gIFileName="../imem/$1"
else echo "usage: ghdl.sh path/asm-file-without-extension"
fi
