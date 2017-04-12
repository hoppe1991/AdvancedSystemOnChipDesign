--------------------------------------------------------------------------------
-- filename : mips_arc_task4_instructioncache.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.mips_pkg.all;
use work.casts.all;
use work.global_pkg.all;

--------------------------------------------------------------------------------
-- Architecture of MIPS defines the pipelined MIPS (see task sheet 3) with
-- instruction cache (see task sheet 4), but without branch prediction.
--------------------------------------------------------------------------------
architecture mips_arc_task4_instructioncache of mips is
 
	-- Signals regarding instruction cache.
	constant MEMORY_ADDRESS_WIDTH	: INTEGER := 32;
	constant DATA_WIDTH 			: INTEGER := 32;
	constant BLOCKSIZE 				: INTEGER := 4;
	constant ADDRESSWIDTH         	: INTEGER := 256;
	constant OFFSET               	: INTEGER := 8;
	constant BRAM_ADDR_WIDTH		: INTEGER := 10; -- (11 downto 2) pc
	
	-- Signals count cache hits and cache misses.
	signal hitCounter, missCounter : INTEGER := 0;
	
	-- 
	signal stallFromCache : STD_LOGIC := '0';
	
	-- PC given by CPU.
	signal pc : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	
	--
	signal IF_ir : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	
	-- Signals regarding main memory.
	signal readyMEM 	: STD_LOGIC := '0';
	signal addrMEM      : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');	
	signal rdMEM, wrMEM : STD_LOGIC := '0';
	signal dataMEM		: STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
	
begin
	
	-- ------------------------------------------------------------------------------------------
	-- This entity controls the behavior of the MIPS.
	-- ------------------------------------------------------------------------------------------
	mipsContr: entity work.mips_controller_task4_imemcache
		generic map(
			DFileName            => DFileName,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH
		)
		port map(
			clk            => clk,
			writedata      => writedata,
			dataadr        => dataadr,
			memwrite       => memwrite,
			stallFromCache => stallFromCache,
			pcToCache      => pc,
			IF_ir          => IF_ir
		);
	
	-- ------------------------------------------------------------------------------------------
	-- Instruction cache.
	-- ------------------------------------------------------------------------------------------
	imemCache: entity work.cache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			reset       => reset,
			hitCounter  => hitCounter,
			missCounter => missCounter,
			stallCPU    => stallFromCache,
			rdCPU       => '1',
			wrCPU       => '0',
			addrCPU     => pc,
			dataCPU     => IF_ir,
			readyMEM    => readyMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			addrMEM     => addrMEM,
			dataMEM     => dataMEM
		);

	-- ------------------------------------------------------------------------------------------
	-- Create main memory.
	-- ------------------------------------------------------------------------------------------
	mainMemoryController : entity work.mainMemory
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			DATA_WIDTH           => DATA_WIDTH,
			BRAM_ADDR_WIDTH		 => BRAM_ADDR_WIDTH,
			DATA_FILENAME        => IFileName,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			readyMEM    => readyMEM,
			addrMEM     => addrMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			dataMEM  	=> dataMEM,
			reset       => reset
		);
	
end mips_arc_task4_instructioncache;