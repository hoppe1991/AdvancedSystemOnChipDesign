@echo off
REM You have to specify the filename regarding the tag cache.

IF "%~2"=="" (
	echo usage: testCreatorCache.bat path/filename-without-extension path/filename-without-extension
	GOTO :eof
)

echo.
echo ++++++++++ check syntax of the vhdl file gates.vhd ++++++++++
ghdl -a -g -O3 --ieee=synopsys --workdir=work cache_pkg.vhd  creatorOfCacheFiles.vhd
echo.
echo ++++++++++ create an executable for the testbench ++++++++++
ghdl -e -g -O3 --ieee=synopsys --workdir=work creatorOfCacheFiles
echo.
echo ++++++++++ run the executable ++++++++++
ghdl -r -g -O3 --ieee=synopsys --workdir=work creatorOfCacheFiles -gTag_Filename="../imem/%1" -gData_Filename="../imem/%2"
