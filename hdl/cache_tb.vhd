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
  generic (TagFileName  : string := "../imem/tagCache";
           DataFileName : string := "../imem/dataCache";

           ADDRESSWIDTH : integer := 256;
           BLOCKSIZE    : integer := 4;
           DATAWIDTH    : integer := 32;
           OFFSET       : integer := 8
      );

end;


architecture tests of cache_tb is

  signal clk, reset, memwrite: STD_LOGIC := '0';

  signal stallCPU : STD_LOGIC := '0';
  signal rdCPU : STD_LOGIC := '0';
  signal wrCPU : STD_LOGIC := '0';
  signal addrCPU : STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0 );
  signal dataCPU : STD_LOGIC_VECTOR( OFFSET-1 downto 0 );
  signal readyMEM : STD_LOGIC := '0';
  signal rdMEM : STD_LOGIC := '0';
  signal wrMEM : STD_LOGIC := '0';
  signal addrMEM : STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0 );
  signal dataMEM : STD_LOGIC_VECTOR( OFFSET-1 downto 0 );

begin

cache : entity work.cacheController
        generic map (
            DATAWIDTH => DATAWIDTH,
            BLOCKSIZE => BLOCKSIZE,
            ADDRESSWIDTH => ADDRESSWIDTH,
            OFFSET => OFFSET,
            TagFileName => TagFileName,
            DataFileName => DataFileName
        )
        port map( clk => clk,
                  reset => reset,
                  stallCPU => stallCPU,
                  dataCPU => dataCPU,
                  addrCPU => addrCPU,
                  readyMEM => readyMEM,
                  dataMEM => dataMEM,
                  rdCPU => rdCPU,
                  wrCPU => wrCPU
                  );




  -- Generate clock with 10 ns period
  process begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    rdCPU <= '1' after 10 ns;
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

end tests;
