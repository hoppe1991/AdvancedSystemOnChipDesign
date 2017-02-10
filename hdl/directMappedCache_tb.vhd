--------------------------------------------------------------------------------
-- filename : directMappedCache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity directMappedCache_tb is
  generic (
  	TagFileName  : string := "../imem/tagCache";
  	DataFileName : string := "../imem/dataCache";
  	
  	MEMADDRESSWIDTH : integer := 32;
  	ADDRESSWIDTH : integer := 256;
  	BLOCKSIZE    : integer := 4;
  	DATAWIDTH    : integer := 32;
  	OFFSET       : integer := 8);
end;

architecture test of directMappedCache_tb is

signal reset   : STD_LOGIC := '0';
signal addrCPU : STD_LOGIC_VECTOR( MEMADDRESSWIDTH-1 downto 0) := (others => '0');
signal dataCPU_in  : STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0)    := (others => '0');
signal dataCPU_out  : STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0)    := (others => '0');
signal clk     : STD_LOGIC := '0';
signal rd      : STD_LOGIC := '0';
signal wr      : STD_LOGIC := '0';
signal valid   : STD_LOGIC := '0';
signal dirty   : STD_LOGIC := '0';
signal hit     : STD_LOGIC := '0';
signal dataMem : STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0 ) := (others => '0' );
signal wrCacheBlockLine : STD_LOGIC := '0';
signal setValid : STD_LOGIC := '0';
signal setDirty : STD_LOGIC := '0';

begin

-- -----------------------------------------------------------------------------
-- Instantiate device to be tested.
-- -----------------------------------------------------------------------------
cache : entity work.directMappedCache
	generic map (
		MEMORY_ADDRESS_WIDTH => MEMADDRESSWIDTH,
		DATA_WIDTH => DATAWIDTH,
		BLOCKSIZE => BLOCKSIZE,
		ADDRESSWIDTH => ADDRESSWIDTH,
		OFFSET => OFFSET,
		TAGFILENAME => TagFileName,
		DATAFILENAME => DataFileName
		)
        port map( clk => clk,
        		  reset => reset,
                  dataCPU_in => dataCPU_in,
                  dataCPU_out => dataCPU_out,
                  addrCPU => addrCPU,
                  dataMem => dataMem,
                  rd => rd,
                  wr => wr,
                  valid => valid,
                  dirty => dirty,
                  setValid => setValid,
                  setDirty => setDirty,
                  hit => hit,
                  wrCacheBlockLine => wrCacheBlockLine
                  );

        -- Generate clock with 10 ns period
        process begin
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
      end process;
      
      process begin
      	wr <= '0';
      	rd <= '0';
      	wrCacheBlockLine <= '0'; 
      	dataCPU_in <= "11111111111111111111111111111111";
      	wait for 5 us;
      	wr <= '1';
      	rd <= '0';
      	wait for 20 us;
      	wr <= '0';
      	rd <= '1';
      	wait for 30 us;
      	wr <= '1';
      	rd <= '0';
      	wrCacheBlockLine <= '0';
      	addrCPU(0) <= '1';
      	dataCPU_in <= "11111111111111111111111111111111";
      	wait for 5 us;
      	wr <= '0';
      	rd <= '1';
      	wait for 50 us;
      	end process;

        -- Generate reset for first two clock cycles
        process begin
          reset <= '0';
          wait for 2 ns;
          reset <= '0';
          wait for 20 ns;
          reset <= '0';
          wait;
        end process;
end;
