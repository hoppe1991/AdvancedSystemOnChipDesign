# you have to specify the assembler text for the mips at the prompt!
PATHTOMARS="/home/hendrik/Downloads/Mars4_5.jar" # Hendriks path
PATHTOGHDL="/home/hendrik/Downloads/ghdl-033/bin/ghdl" # Hendriks ghdl path


if (( $# == 1)) 
then 
mkdir workA



echo .
echo "++++++++++ add files in the work design library ++++++++++"
$PATHTOGHDL -i -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb.vhd directMappedCache.vhd directMappedCacheController.vhd bram.vhd mips_pkg.vhd casts.vhd cache_pkg.vhd
echo .
echo "++++++++++ analyze automatically outdated files and create an executable ++++++++++"
$PATHTOGHDL -m -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb
echo .
echo "++++++++++ run the executable for 15us and save all waveforms ++++++++++"
$PATHTOGHDL -r -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb --stop-time=500us  --wave=../sim/directMappedCacheTestbench.ghw


fi