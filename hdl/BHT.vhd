---------------------------------------------------------------------------------
-- filename: BHT.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.log2;
use IEEE.math_real.ceil;
use work.mips_pkg.all;
use work.casts.all;
use work.bht_pkg.all;

-- -------------------------------------------------------------------------------------
-- BHT takes for each branch instruction a separation counter.
-- The current states of each separation counter are stored in a register file.
-- Thus, the BHT predicts for a given PC whether the instruction should be TAKEN or
-- NOT TAKEN. Also, the BHT updates its register files in execution stage.
-- -------------------------------------------------------------------------------------
entity BHT is
	
  generic (
  	
  		-- Number of BHT entries.
  		BHT_ENTRIES 	: INTEGER := 32;
  		
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
  		
  		-- Instruction (PC) given by CPU.
  		instructionPC : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Prediction of the current instruction.
  		-- 1, if TAKEN. 0, if NOT TAKEN.
  		prediction					 : out STD_LOGIC;
  		
  		-- Execution stage determines whether the branch instruction has been '1' TAKEN or '0' NOT TAKEN.
  		branchTaken					: in STD_LOGIC;
  		
  		-- Signal controls whether the register file should be written or not.
  		writeEnable 					: in STD_LOGIC
  );
end;

-- -------------------------------------------------------------------------------------
-- BHT takes for each branch instruction a separation counter.
-- The current states of each separation counter are stored in a register file.
-- Thus, the BHT predicts for a given PC whether the instruction should be TAKEN or
-- NOT TAKEN. Also, the BHT updates its register files in execution stage.
-- -------------------------------------------------------------------------------------
architecture behave of BHT is
	
  	constant BHT_INDEXSIZE 	: INTEGER := INTEGER(CEIL(LOG2(REAL(BHT_ENTRIES))));
  	constant DATA_WIDTH 	: INTEGER := 2;
    constant ADDR_WIDTH 	: integer := BHT_INDEXSIZE;
    
	-- Initial state of saturation counter.
	constant initialState : STATE_SATURATION_COUNTER := WEAKLY_TAKEN;
    
    signal rd : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal ra : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
    
    signal wd : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal wa : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
begin
	
	-- ---------------------------------------------------------------
	-- This entity controls the behavior of the BHT.
	-- ---------------------------------------------------------------
	bhtController : entity work.BHTController
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BHT_INDEXSIZE        => BHT_INDEXSIZE,
			DATA_WIDTH           => DATA_WIDTH
		)
		port map(
			clk           => clk,
			ra            => ra,
			wd            => wd,
			wa            => wa,
			rd            => rd,
			branchTaken   => branchTaken,
			prediction    => prediction,
			instructionPC => instructionPC
		);
	
	-- ---------------------------------------------------------------
	-- Register file stores the current states of 
	-- each separation counters.
	-- ---------------------------------------------------------------
	regFileBHT : entity work.regfileBHT
		generic map(
			EDGE       => EDGE,
			DATA_WIDTH => DATA_WIDTH,
			ADDR_WIDTH => ADDR_WIDTH,	
		    ZERO 	   => TO_STD_LOGIC_VECTOR( initialState )
		 )
		port map(
			reset => reset,
			clk   => clk,
			ra    => ra,
			rd    => rd,
			wa    => wa,
			we    => writeEnable,
			wd    => wd
		); 
end behave;