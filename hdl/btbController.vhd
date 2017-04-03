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
  		predictedPCIsValid : out STD_LOGIC;
  		
  		-- Ports regarding first register file.
    	ra1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	rd1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wd1 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we1 : out STD_LOGIC;
    
    	-- Ports regarding second register file.
    	ra2 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	rd2 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wa2 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	wd2 : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    	we2 : out STD_LOGIC 		
  );
end;

-- -------------------------------------------------------------------------------------
-- The BTB is supposed to be implemented as register files.
-- -------------------------------------------------------------------------------------
architecture behave of btbController is
	   
begin
	
	-- TODO Add logic of the BTB controller here.
	
end behave;