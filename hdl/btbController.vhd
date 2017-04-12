---------------------------------------------------------------------------------
-- filename: btbController.vhd
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
entity btbController is
	
  generic (
  	
  		-- The BTB is supposed to be a 2-way associative cache with 16 cache lines.
  		BTB_ENRTIES 	: INTEGER := 16;
  		
  		-- 
  		DATA_WIDTH       : INTEGER := 65;
 
 		-- Width of a memory address.       
		MEMORY_ADDRESS_WIDTH : INTEGER := 32;
		
		-- 
		ADDR_WIDTH		: INTEGER := 5
		
  );  
            
  port    (
  	
  		-- Clock signal.
  		clk 			: in STD_LOGIC;
  		
  		-- Signal to reset the BHT register file.
  		reset			: in STD_LOGIC;
  		
  		-- Current program counter given by CPU.
  		pc				: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- 
  		writeEnableID	: in STD_LOGIC;
  		
  		-- 
  		dataWriteID		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		writeEnableEX	: in STD_LOGIC;
  		
  		dataWriteEX		: in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		
  		-- Predicted program counter.
  		predictedPC		: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Signal indicates whether the predicted program counter is valid ('1') or not ('0').
  		predictedPCIsValid : out STD_LOGIC;
  		
  		-- Ports regarding first register file.
    	ra1 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	rd1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa1 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	wd1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we1 : out STD_LOGIC;
    
    	-- Ports regarding second register file.
    	ra2 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	rd2 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa2 : out STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    	wd2 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we2 : out STD_LOGIC 		
  );
end;

-- -------------------------------------------------------------------------------------
-- The BTB is supposed to be implemented as register files.
-- -------------------------------------------------------------------------------------
architecture behave of btbController is
	
	-- A BTB cache line contains a tag vector, target pc and a valid bit.
	type BTB_LINE is record
	
		-- +-----+-----------+-------------------------------------------------------------------------+
		-- |     |   INDEX	 |	TAG																	   |
		-- | 0 1 | 2 3 4 5 6 | 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 |
		-- +-----+-----------+-------------------------------------------------------------------------+
		-- Address width minus five bit index of BTB two bit skipped.
		tag    		: STD_LOGIC_VECTOR(25-1 downto 0);
		targetPC	: STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH - 1 downto 0);
		validBit	: STD_LOGIC;
	end record;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- This function returns a given STD_LOGIC_VECTOR to a correspondent BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function STD_LOGIC_VECTOR_TO_BTB_LINE( vector : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)) return BTB_LINE;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- This function returns a given BTB_LINE to a STD_LOGIC_VECTOR.
	-- ---------------------------------------------------------------------------------------------------------------
	function BTB_LINE_TO_STD_LOGIC_VECTOR( btbLine : in BTB_LINE ) return STD_LOGIC_VECTOR;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- Returns a new BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function CREATE_BTB_LINE( pcValue : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
		targetPCValue : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
		validBit : in STD_LOGIC
	) return BTB_LINE;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- Initializes a new BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function INIT_BTB_LINE return BTB_LINE;
	
	-- Read data word from register file 1 as BTB_LINE.
	signal rd1_btbLine 		: BTB_LINE := INIT_BTB_LINE;
	
	-- Read data word from register file 2 as BTB_LINE.
	signal rd2_btbLine 		: BTB_LINE := INIT_BTB_LINE;
	
	-- BTB line to be written into register file.
	signal wd_btbLine		: BTB_LINE := INIT_BTB_LINE;
	
	-- Selected register file index.
	signal selRegFileID    : INTEGER := 0;
	signal selRegFileID_ID : INTEGER := 0;
	signal selRegFileID_EX : INTEGER := 0;
	
	signal pc_ID		   : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	signal pc_EX		   : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	
	-- Tag value of given program counter.
	alias pcTag			   : STD_LOGIC_VECTOR(25-1 downto 0) is pc(MEMORY_ADDRESS_WIDTH-1 downto 7);
	
	-- Use bit signals which register file is used for current program counter.
	signal useBit : INTEGER := 1;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- This function returns a given STD_LOGIC_VECTOR to a correspondent BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function STD_LOGIC_VECTOR_TO_BTB_LINE( vector : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)) return BTB_LINE is
		variable b : BTB_LINE;
	begin
		b.tag 		:= vector( DATA_WIDTH-1 downto 33);
		b.targetPC 	:= vector( 32 downto 1);
		b.validBit 	:= vector( 0 );
			
		return b;
	end;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- This function returns a given BTB_LINE to a STD_LOGIC_VECTOR.
	-- ---------------------------------------------------------------------------------------------------------------
	function BTB_LINE_TO_STD_LOGIC_VECTOR( btbLine : in BTB_LINE ) return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR( DATA_WIDTH-1 downto 0) := (others=>'0');
	begin
		v(DATA_WIDTH-1 downto 33) 	:= btbLine.tag;
		v(32 downto 1)			  	:= btbLine.targetPC;
		v(0) 						:= btbLine.validBit;
		return v;
	end;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- Initializes a new BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function INIT_BTB_LINE return BTB_LINE is
		variable b : BTB_LINE;
	begin
		b.tag := (others=>'0');
		b.targetPC := (others=>'0');
		b.validBit := '0';
		return b;
	end;
	
	-- ---------------------------------------------------------------------------------------------------------------
	-- Returns a new BTB_LINE.
	-- ---------------------------------------------------------------------------------------------------------------
	function CREATE_BTB_LINE( pcValue : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
		targetPCValue : in STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
		validBit : in STD_LOGIC
	) return BTB_LINE is
		variable b : BTB_LINE;
	begin
		b.tag	   := pcValue(31 downto 7);
		b.targetPC := targetPCValue;
		b.validBit := validBit;
		return b;
	end;
	
begin
	
	-- TODO Add logic of the BTB controller here.
	
	-- Register the pc.
	pc_ID <= pc    when rising_edge(clk);
	pc_EX <= pc_ID when rising_edge(clk);
	
	-- Convert STD_LOGIC_VECTOR to BTB_LINE.
	rd1_btbLine	<= STD_LOGIC_VECTOR_TO_BTB_LINE( rd1 );
	rd2_btbLine	<= STD_LOGIC_VECTOR_TO_BTB_LINE( rd2 ); 
	
	useBit <= 1 when (rd1_btbLine.validBit='1' and rd1_btbLine.targetPC=pcTag and useBit=2) else
		   	  2 when (rd1_btbLine.validBit='1' and rd1_btbLine.targetPC=pcTag and useBit=1) else
		   	  1;
	
	-- TODO Is this signal logic is correct?
	selRegFileID <= 1 when (rd1_btbLine.validBit='1' and rd1_btbLine.targetPC=pcTag) else
					2 when (rd2_btbLine.validBit='1' and rd2_btbLine.targetPC=pcTag) else
					useBit;
					
	selRegFileID_ID <= selRegFileID    when rising_edge(clk);
	selRegFileID_EX <= selRegFileID_ID when rising_edge(clk);
							
	
	-- Determine whether the predicted program counter is valid ('1') or not ('0').
	predictedPCIsValid <= '1' when (rd1_btbLine.validBit='1' and rd1_btbLine.targetPC=pcTag) else
						  '1' when (rd2_btbLine.validBit='1' and rd2_btbLine.targetPC=pcTag) else
						  '0';
						  
	-- Predict the next program counter.
	predictedPC		   <= rd1_btbLine.targetPC when rd1_btbLine.validBit='1' else
						  rd2_btbLine.targetPC when rd2_btbLine.validBit='1' else
						  (others=>'0');
						  
	-- Determine the addresses of registers to be read.
	ra1 				<= pc(ADDR_WIDTH+1 downto 2);
	ra2					<= pc(ADDR_WIDTH+1 downto 2);
	
	
	-- If both the EX and ID stage are trying to write the table simultaneously, priority is given to the EX stage,
	-- since the branch instruction is ahead in the pipeline. Here, the writing of the BTB for the jump instruction
	-- is ignored which may result in minor performance degradation.
	wa1		  			<= pc_EX(ADDR_WIDTH+1 downto 2) when (writeEnableEX='1') else
						   pc_ID(ADDR_WIDTH+1 downto 2) when (writeEnableID='1') else
						   (others=>'0');
    wa2					<= pc_EX(ADDR_WIDTH+1 downto 2) when (writeEnableEX='1') else
						   pc_ID(ADDR_WIDTH+1 downto 2) when (writeEnableID='1') else
						   (others=>'0');
    
    
	we1 				<= '1' when (writeEnableEX='1' and selRegFileID_ID=1) else
						   '1' when (writeEnableID='1' and selRegFileID_EX=1) else
						   '0';
    we2 				<= '1' when (writeEnableEX='1' and selRegFileID_ID=2) else
						   '1' when (writeEnableID='1' and selRegFileID_EX=2) else
						   '0';
						   
	wd_btbLine			<= CREATE_BTB_LINE( pc_EX, dataWriteEX, '1' ) when (writeEnableEX='1') else
						   CREATE_BTB_LINE( pc_ID, dataWriteID, '1' ) when (writeEnableID='1');

    wd1 				<= BTB_LINE_TO_STD_LOGIC_VECTOR(wd_btbLine);
    wd2 				<= BTB_LINE_TO_STD_LOGIC_VECTOR(wd_btbLine);
    
	
end behave;