---------------------------------------------------------------------------------
-- filename: mips.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.mips_pkg.all;
use work.casts.all;
use work.global_pkg.all;


entity mips is -- Pipelined MIPS processor
  generic ( DFileName 			: STRING := "../dmem/isort_pipe";
            IFileName 			: STRING := "../imem/isort_pipe";
	        TAG_FILENAME 		: STRING := "../imem/tagCache";
			DATA_FILENAME		: STRING := "../imem/dataCache";
			FILE_EXTENSION		: STRING := ".imem"
            );
  port ( clk, reset        : in  STD_LOGIC;
         writedata, dataadr: out STD_LOGIC_VECTOR(31 downto 0);
         memwrite          : out STD_LOGIC
       );
end;

architecture struct of mips is

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
	
	--
	signal pc : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	
	--
	signal IF_ir : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	
	
	-- Signals regarding main memory.
	signal readyMEM 	: STD_LOGIC := '0';
	signal addrMEM      : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');	
	signal rdMEM, wrMEM : STD_LOGIC := '0';
	signal dataMEM		: STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
	
begin
 
	  globalHitCounter <= hitCounter;

 
 
 
 
	-- ------------------------------------------------------------------------------------------
	-- Controller of mips.
	-- ------------------------------------------------------------------------------------------
	mipsContr: entity work.mipsController
		generic map(
			MEMORY_ADDRESS_WIDTH 	=> MEMORY_ADDRESS_WIDTH,
			DFileName     			=> DFileName
		)
		port map(
			clk            => clk,
			writedata      => writedata,
			dataadr        => dataadr,
			memwrite       => memwrite,
			hitCounter     => hitCounter,
			missCounter    => missCounter,
			stallFromCache => stallFromCache,
			IF_ir		   => IF_ir,
			pcToCache	   => pc
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
	-- Main memory unit.
	-- ------------------------------------------------------------------------------------------
	MMU : entity work.mainMemory
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
		
end;