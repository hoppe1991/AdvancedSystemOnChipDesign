--------------------------------------------------------------------------------
-- filename : mips_arc_task5_btb.vhd
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
-- instruction cache (see task sheet 4) and BTB (see task sheet 5).
--------------------------------------------------------------------------------
architecture mips_arc_task5_btb of mips is

	-- Number of entries in BTB.
	constant BTB_ENRTIES 			: INTEGER 	:= 16;
	
	-- Edge type of register files in BTB.
	constant BTB_EDGE    			: EDGETYPE := FALLING; -- FALLING or RAISING
	
	-- Width of memory address.
	constant MEMORY_ADDRESS_WIDTH 	: INTEGER := 32;
	
	-- Number of entries in BHT.
	constant BHT_ENTRIES 			: INTEGER := 32;
	
	-- Signals regarding instruction cache.
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
	
	-- Branch prediction calculated from BHT.
    signal predictionFromBHT : STD_LOGIC := '0';
    
    -- Signal indicates whether the branch is taken or not.
    signal branchTaken : STD_LOGIC := '0';
    
    -- Signal indicates whether the BHT should be rewritten.
    signal writeEnableBHT : STD_LOGIC := '0';
    
    
    -- New program counter predicted by BTB.
    signal predictedPC : STD_LOGIC_VECTOR(MEMORY_ADDRESs_WIDTH-1 downto 0) := (others=>'0');

  	-- Data word (from ID stage) to be written into BTB.
	signal dataWriteID	: STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
 	
 	-- Data word (from EX stage) to be written into BTB.
 	signal dataWriteEX    : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
  	
  	-- Control signal (from ID stage) indicates whether to write into BTB.
  	signal writeEnableID  :  STD_LOGIC := '0';
  	
  	-- Control signal (from EX stage) indicates whether to write into BTB.
  	signal writeEnableEX  : STD_LOGIC := '0';
  	
  	-- Signal indicates whether the predicted program counter by BTB is valid ('1') or not ('0').
  	signal predictedPCIsValid : STD_LOGIC := '0';
    
     
begin
	
	-- ------------------------------------------------------------------------------------------
	-- Entity controls the behavior of the MIPS.
	-- ------------------------------------------------------------------------------------------
	mipsContr: entity work.mips_controller_task5_btb
		generic map(
			DFileName            => DFileName,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH
		)
		port map(
			clk                       => clk,
			reset                     => reset,
			writedata                 => writedata,
			dataadr                   => dataadr,
			memwrite                  => memwrite,
			stallFromCache            => stallFromCache,
			pcToCache                 => pc,
			IF_ir                     => IF_ir,
			predictionFromBHT         => predictionFromBHT,
			branchTaken               => branchTaken,
			writeEnableBHT            => writeEnableBHT,
			predictedPCFromBTB        => predictedPC,
			predictedPCIsValidFromBTB => predictedPCIsValid,
			dataWriteID               => dataWriteID,
			dataWriteEX               => dataWriteEX,
			writeEnableID             => writeEnableID,
			writeEnableEX             => writeEnableEX
		);
	
	-- ----------------------------------------------------------------------
	-- Branch Target Buffer (BTB).
	-- ----------------------------------------------------------------------
	branchTargetBuffer: entity work.btb
		generic map(
			BTB_ENRTIES          => BTB_ENRTIES,
			EDGE                 => BTB_EDGE,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH
		)
		port map(
			clk              	=> clk,
			reset            	=> reset,
			pc               	=> pc,
			
			-- TODO Connect the ports with the correct signals.
			writeEnableID    	=> writeEnableID,
			dataWriteID      	=> dataWriteID,
			writeEnableEX    	=> writeEnableEX,
			dataWriteEX      	=> dataWriteEX,
			predictedPC      	=> predictedPC,
			predictedPCIsValid	=> predictedPCIsValid
		);


	-- ----------------------------------------------------------------------
	-- Branch History Table (BHT) predicts whether a branch instruction
	-- will be TAKEN or NOT TAKEN.
	-- ----------------------------------------------------------------------
	branchHistoryTable: entity work.BHT
		generic map(
			BHT_ENTRIES          => BHT_ENTRIES,
			EDGE                 => FALLING,				-- RAISING
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH
		)
		port map(
			clk				=> clk,
			reset           => reset,
			instructionPC	=> pc,
			prediction		=> predictionFromBHT,
			branchTaken		=> branchTaken,
			writeEnable		=> writeEnableBHT
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
end mips_arc_task5_btb;