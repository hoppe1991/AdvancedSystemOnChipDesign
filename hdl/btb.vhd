---------------------------------------------------------------------------------
-- filename: btb.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 03/04/17 
---------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;

-- -------------------------------------------------------------------------------------
-- The BTB is supposed to be implemented as register files.
-- -------------------------------------------------------------------------------------
entity btb is
	
  generic (
  	
  		-- The BTB is supposed to be a 2-way associative cache with 16 cache lines.
  		BTB_ENRTIES 	: INTEGER := 16;
  		
  		-- 
  		EDGE       		: EDGETYPE:= FALLING;
 
 		-- Width of a memory address.       
		MEMORY_ADDRESS_WIDTH : INTEGER := 32
  );  
            
  port    (
  	
  		-- Clock signal.
  		clk 			: in STD_LOGIC;
  		
  		-- Signal to reset the BHT register file.
  		reset			: in STD_LOGIC;
  		
  		-- Current program counter given by CPU.
  		pc				: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		--
  		addressWriteID	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- 
  		writeEnableID	: in STD_LOGIC;
  		
  		-- 
  		dataWriteID		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		
  		addressWriteEX	: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		writeEnableEX	: in STD_LOGIC;
  		
  		dataWriteEX		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		
  		-- Predicted program counter.
  		predictedPC		: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Signal indicates whether the predicted program counter is valid ('1') or not ('0').
  		predictedPCIsValid : out STD_LOGIC
  );
end;

-- -------------------------------------------------------------------------------------
-- BTB is supposed to be a 2-way associative cache.
-- -------------------------------------------------------------------------------------
architecture behave of btb is
	
	-- Number of cache lines.
  	constant BTB_INDEXSIZE 	: INTEGER := INTEGER(CEIL(LOG2(REAL(BTB_ENRTIES))));
  	
  	-- Width of data word stored in register file. A data word contains
  	-- tag (32 bits), target PC (32 bits) and valid bit (1 bit).
  	constant DATA_WIDTH 	: INTEGER := 2*MEMORY_ADDRESS_WIDTH + 1;
  	
  	-- Width of address vector regarding the register files.
    constant ADDR_WIDTH 	: integer := BTB_INDEXSIZE;
    
    -- Signals regarding first register file.
    signal ra1 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) 	:= (others=>'0');
    signal rd1 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) 	:= (others=>'0');
    signal wa1 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) 	:= (others=>'0');
    signal wd1 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) 	:= (others=>'0');
    signal we1 : STD_LOGIC 									:= '0';
    
    -- Signals regarding second register file.
    signal ra2 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) 	:= (others=>'0');
    signal rd2 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) 	:= (others=>'0');
    signal wa2 : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) 	:= (others=>'0');
    signal wd2 : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) 	:= (others=>'0');
    signal we2 : STD_LOGIC 									:= '0';
    
begin

	-- ---------------------------------------------------------------
	-- This entity controls the behavior of the BTB.
	-- ---------------------------------------------------------------
	btbContr : entity work.btbController
		generic map(
			BTB_ENRTIES          => BTB_ENRTIES,
			DATA_WIDTH           => DATA_WIDTH,
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			ADDR_WIDTH			 => ADDR_WIDTH
		)
		port map(
			clk              => clk,
			reset            => reset,
			pc               => pc,
			addressWriteID   => addressWriteID,
			writeEnableID    => writeEnableID,
			dataWriteID      => dataWriteID,
			addressWriteEX   => addressWriteEX,
			writeEnableEX    => writeEnableEX,
			dataWriteEX      => dataWriteEX,
			predictedPC      => predictedPC,
			predictedPCIsValid => predictedPCIsValid,
			ra1              => ra1,
			rd1              => rd1,
			wa1              => wa1,
			wd1              => wd1,
			we1              => we1,
			ra2              => ra2,
			rd2              => rd2,
			wa2              => wa2,
			wd2              => wd2,
			we2              => we2
		);	

	
	-- ---------------------------------------------------------------
	-- Register file stores target PC of branch instructions.
	-- ---------------------------------------------------------------
	regFileBHT1 : entity work.regfileBHT
		generic map(
			EDGE       => EDGE,
			DATA_WIDTH => DATA_WIDTH,
			ADDR_WIDTH => ADDR_WIDTH
		)
		port map(
			reset => reset,
			clk   => clk,
			ra    => ra1,
			rd    => rd1,
			wa    => wa1,
			we    => we1,
			wd    => wd1
		); 
		
		
	-- ---------------------------------------------------------------
	-- Register file stores target PC of branch instructions.
	-- ---------------------------------------------------------------
	regFileBHT2 : entity work.regfileBHT
		generic map(
			EDGE       => EDGE,
			DATA_WIDTH => DATA_WIDTH,
			ADDR_WIDTH => ADDR_WIDTH
		)
		port map(
			reset => reset,
			clk   => clk,
			ra    => ra2,
			rd    => rd2,
			wa    => wa2,
			we    => we2,
			wd    => wd2
		); 
end behave;