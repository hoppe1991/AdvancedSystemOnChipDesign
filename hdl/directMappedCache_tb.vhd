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
  generic (TagFileName  : string := "../imem/tagCache";
           DataFileName : string := "../imem/dataCache";

           ADDRESSWIDTH : integer := 256;
           BLOCKSIZE    : integer := 4;
           DATAWIDTH    : integer := 32;
           OFFSET       : integer := 8);
end;

architecture test of directMappedCache_tb is

signal reset   : STD_LOGIC := '0';
signal addrCPU : STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0) := (others => '0');
signal dataCPUIn  : STD_LOGIC_VECTOR( OFFSET-1 downto 0)    := (others => '0');
signal dataCPUOut : sTD_LOGIC_VECTOR( OFFSET-1 downto 0)    := (others => '0');
signal clk     : STD_LOGIC := '0';
signal rd      : STD_LOGIC := '0';
signal wr      : STD_LOGIC := '0';
signal valid   : STD_LOGIC := '0';
signal dirty   : STD_LOGIC := '0';
signal hit     : STD_LOGIC := '0';
signal dataMemIn : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0' );
signal dataMemOut : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0' );
signal wrCacheBlockLine : STD_LOGIC := '0';

begin

-- -----------------------------------------------------------------------------
-- Instantiate device to be tested.
-- -----------------------------------------------------------------------------
cache : entity work.directMappedCache
        generic map (
            DATA_WIDTH => DATAWIDTH,
            BLOCKSIZE => BLOCKSIZE,
            ADDRESSWIDTH => ADDRESSWIDTH,
            OFFSET => OFFSET,
            TagFileName => TagFileName,
            DataFileName => DataFileName
        )
        port map( clk => clk,
                  dataCPUIn => dataCPUIn,
                  addrCPU => addrCPU,
                  dataCPUOut => dataCPUOut,
                  dataMEMIn => dataMemIn,
                  dataMEMOut => dataMemOut,
                  rd => rd,
                  wr => wr,
                  valid => valid,
                  dirty => dirty,
                  hit => hit,
                  wrCacheBlockLine => wrCacheBlockLine
                  );

        -- Generate clock with 10 ns period
        process begin
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          dataCPUIn <= "11111111" after 5 ns;
          wr <= '1' after 7 ns;
        end process;

        -- Generate reset for first two clock cycles
        process begin
          reset <= '0';
          wait for 2 ns;
          reset <= '1';
          wait for 20 ns;
          reset <= '0';
          wait;
        end process;
end;
