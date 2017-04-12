---------------------------------------------------------------------------------
-- filename: regfileBHT.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.mips_pkg.all;
use work.casts.all;
use work.bht_pkg.all;

entity regfileBHT is
	generic(
			EDGE       : EDGETYPE := FALLING;
		    DATA_WIDTH : integer  := 32;
		    ADDR_WIDTH : integer  := 5;
		    IS_BHT	   : BOOLEAN  := FALSE
	);

	port(

		-- Clock signal.
		clk   : in  STD_LOGIC;

		-- Signal to reset the register file.
		reset : in  STD_LOGIC;

		-- Signal to control writing the register file.
		we    : in  STD_LOGIC;

		-- Address / index of register to be written.
		wa    : in  STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);

		-- Data word to be written into register.
		wd    : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

		-- Address / index of register to be read.
		ra    : in  STD_LOGIC_VECTOR(ADDR_WIDTH - 1 downto 0);

		-- Data word to be read from register.
		rd    : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
	);
end;

architecture behave of regfileBHT is
	
	-- Initial state of saturation counter.
	constant initialState : STATE_SATURATION_COUNTER := WEAKLY_TAKEN; 	--Standard is: WEAKLY_TAKEN; 
	
	-- Initializes the initial value of register.	
	function INIT_ZERO return STD_LOGIC_VECTOR;
	
	-- Initial value of register.
	constant ZERO : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := INIT_ZERO;
		
	-- Number of registers.
	constant ramIndex : INTEGER := 2**ADDR_WIDTH;
	
	-- Register file defined as array of vectors.
	type ramtype is array (ramIndex - 1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
	
	-- Register file containing the data vectors.
	signal reg : ramtype := (others => zero);
 
	-- Initializes the initial value of register.	
	function INIT_ZERO return STD_LOGIC_VECTOR is
		variable v : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0) := (others=>'0');
	begin
		if IS_BHT then
			v := TO_STD_LOGIC_VECTOR_STATE( initialState );
		else
			v := (others=>'0');
		end if;
		
		return v;
	end;

begin

	-- -----------------------------------------------------------
	-- This process controls the reset and write operations
	-- of the register file.
	-- -----------------------------------------------------------
	writeLogic: process(clk)
	begin
		if EDGE = FALLING then
			if falling_edge(clk) then
				if reset = '1' then
					reg <= (others => zero);
				elsif we = '1' then
					reg(to_i(wa)) <= wd;
				end if;
			end if;
		else
			if rising_edge(clk) then
				if reset = '1' then
					reg <= (others => zero);
				elsif we = '1' then
					reg(to_i(wa)) <= wd;
				end if;
			end if;
		end if;
	end process;

	-- Read the correspondent register.
	rd <= reg(to_i(ra));

end;