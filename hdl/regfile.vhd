---------------------------------------------------------------------------------
-- filename: regfile.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.mips_pkg.all;
use work.casts.all;

entity regfile is
  generic ( EDGE       : EDGETYPE:= FALLING;
            DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer :=  5
          );  
            
  port    ( clk, we3       : in  STD_LOGIC;
            ra1, ra2, wa3  : in  STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
            wd3            : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
            rd1, rd2       : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
          );
end;

architecture behave of regfile is

  type ramtype is array (2**ADDR_WIDTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
  signal reg: ramtype := (others => ZERO32);
  
begin
  
  process(clk) begin
    if EDGE=FALLING then
      if falling_edge(clk) then
--      if reset = '1' then
--        for regaddr in 0 to 2**(ADDR_WIDTH-1) loop
--          reg(to_i(regaddr)) <= ZERO32;
--        end loop;   
        if we3 = '1' then 
          reg(to_i(wa3)) <= wd3;        
        end if;
      end if;
    else 
      if rising_edge(clk) then
--      if reset = '1' then
--        for regaddr in 0 to 2**(ADDR_WIDTH-1) loop
--          reg(to_i(regaddr)) <= ZERO32;
--        end loop;   
        if we3 = '1' then 
          reg(to_i(wa3)) <= wd3;        
        end if;
      end if;
    end if;  
  end process;
  
  rd1 <= ZERO32        when to_i(ra1) = 0 else 
         reg(to_i(ra1));                   
  rd2 <= ZERO32        when to_i(ra2) = 0 else 
         reg(to_i(ra2));

         
end;