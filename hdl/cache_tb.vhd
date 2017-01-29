--------------------------------------------------------------------------------
-- filename : cache_tb.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity cache_tb is
  generic ( DATAWIDTH     : integer := 32;  -- Length of instruction/data words.
            BLOCKSIZE     : integer := 4;  -- Number of words that a block contains.
            ADDRESSWIDTH  : integer := 256;   -- Number of cache blocks.
            OFFSET        : integer := 2    -- Number of bits that can be selected in the cache.
          );
end;


architecture test of cache_tb is

  signal writedata, dataadr   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
  signal clk, reset,  memwrite: STD_LOGIC := '0';

begin

  -- instantiate device to be tested
  dut: entity work.mips
       generic map(DFileName => DFileName, IFileName => IFileName)
       port map(clk, reset, writedata, dataadr, memwrite);

  -- Generate clock with 10 ns period
  process begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
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




end synth;
