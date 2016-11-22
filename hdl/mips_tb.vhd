---------------------------------------------------------------------------------
-- filename: mips_tb.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;

entity mips_testbench is
  generic (DFileName : string := "../dmem/isort_pipe";
           IFileName : string := "../imem/isort_pipe");
end;

architecture test of mips_testbench is
  
  signal writedata, dataadr   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
  signal clk, reset,  memwrite: STD_LOGIC := '0';
  --signal t                 :  STD_LOGIC_VECTOR(1 downto 0):="10";

begin

--   generate_initfiles: entity work.convertMemFiles; --  generic map(
--   DFileName => "/home/wolfgang/Projekte/Xilinx/FCE/Test/VHDL/MIPS_P/asm/isort",
--   IFileName => "/home/wolfgang/Projekte/Xilinx/FCE/Test/VHDL/MIPS_P/asm/isort_pipe2");
  
  --t <= not t when rising_edge(clk);

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

  -- check that 7 gets written to address 84 at end of program
--  process (clk) begin
--    if (clk'event and clk = '0' and memwrite = '1') then
--      if (to_integer(dataadr) = 84 and to_integer(writedata) = 7) then 
--        report "NO ERRORS: Simulation succeeded" severity failure;
--      --elsif (dataadr = x"50") then 
--      --  report "Simulation failed" severity failure;
--      end if;
--    end if;
--  end process;
end;
