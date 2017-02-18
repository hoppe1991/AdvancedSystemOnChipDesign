@echo off
echo.
echo ++++++++++ add files in the work design library ++++++++++
ghdl -i -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb.vhd directMappedCache.vhd directMappedCacheController.vhd bram.vhd mips_pkg.vhd casts.vhd cache_pkg.vhd
echo.
echo ++++++++++ analyze automatically outdated files and create an executable ++++++++++
ghdl -m -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb
echo.
echo ++++++++++ run the executable for 15us and save all waveforms ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=workA directMappedCache_tb --stop-time=200us  --wave=../sim/directMappedCacheTestbench.ghw
