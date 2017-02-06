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
  generic (TagFileName  : string := "../imem/jumpTest2";
           DataFileName : string := "../imem/jumpTest2";

           ADDRESSWIDTH : integer := 256;
           BLOCKSIZE    : integer := 32;
           DATAWIDTH    : integer := 32;
           OFFSET       : integer := 2);
end;

architecture test of directMappedCache_tb is

signal reset   : STD_LOGIC := '0';
signal addrCPU : STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0) := (others => '0');
signal dataIn  : STD_LOGIC_VECTOR(DATAWIDTH-1 downto 0)    := (others => '0');
signal dataOut : sTD_LOGIC_VECTOR(DATAWIDTH-1 downto 0)    := (others => '0');
signal clk     : STD_LOGIC := '0';
signal rw      : STD_LOGIC := '0';
signal wr      : STD_LOGIC := '0';
signal valid   : STD_LOGIC := '0';
signal dirty   : STD_LOGIC := '0';
signal hit     : STD_LOGIC := '0';
signal miss    : STD_LOGIC := '0';

begin

-- -----------------------------------------------------------------------------
-- Instantiate device to be tested.
-- -----------------------------------------------------------------------------
cache : entity work.directMappedCache
        generic map (
            DATAWIDTH => DATAWIDTH,
            BLOCKSIZE => BLOCKSIZE,
            ADDRESSWIDTH => ADDRESSWIDTH,
            OFFSET => OFFSET,
            IFilename => TagFileName
        )
        port map( clk => clk,
                  dataIn => dataIn,
                  addrCPU => addrCPU,
                  dataOut => dataOut,
                  rw => rw,
                  wr => wr,
                  valid => valid,
                  dirty => dirty,
                  hit => hit,
                  miss => miss );

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
end;
