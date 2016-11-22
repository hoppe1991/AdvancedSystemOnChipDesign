---------------------------------------------------------------------------------
-- filename: ram.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

use work.mips_pkg.all;
use work.casts.all;

entity bram is
  generic ( ADDR     : integer  := 10;  
            DATA     : integer  := 32; 
            EDGE     : EdgeType := RISING;
            MODE     : MODEType := NO_CHANGE;
            INIT     : string   := "DMEM.hex" 
          );
          
  port ( clk, we: in  STD_LOGIC;
         adr    : in  STD_LOGIC_VECTOR(ADDR-1 downto 0);
         din    : in  STD_LOGIC_VECTOR(DATA-1 downto 0);
         dout   : out STD_LOGIC_VECTOR(DATA-1 downto 0)
       );
end;

architecture synth of bram is

  type MemType is array(0 to (2**ADDR-1)) of STD_LOGIC_VECTOR(DATA-1 downto 0);
       
  impure function InitRamFromFile (RamFileName : in string) return MemType is
    file RamFile         : text is in RamFileName;
    variable RamFileLine : line;
    variable RAM         : MemType;
  begin
    for I in MemType'range loop
      readline (RamFile, RamFileLine);
      hread (RamFileLine, RAM(I));
    end loop;
    return RAM;
  end function;     
       
  signal mem: MemType := InitRamFromFile(INIT);
  
  signal do : STD_LOGIC_VECTOR(DATA-1 downto 0) := (others => '0');
  
begin  

  process (clk)
  begin
    if EDGE = RISING then
      case MODE is
        when READ_FIRST => if rising_edge(clk) then
                             --do <= mem(to_i(adr));
                             if we = '1' then
                               mem(to_i(adr)) <= din;  
                             end if;
                           end if;
        when WRITE_FIRST=> if rising_edge(clk) then
                             if we = '1' then
                               mem(to_i(adr)) <= din;  
                               --do <= din;        
                             --else 
                               --do <= mem(to_i(adr)); 
                            end if;
                          end if;
       when NO_CHANGE  => if rising_edge(clk) then
                             if we = '1' then
                               mem(to_i(adr)) <= din; 
                             --else 
                               --do <= mem(to_i(adr)); 
                            end if;
                          end if;                          
      end case;          
    else
      case MODE is
        when READ_FIRST => if falling_edge(clk) then
                             --do <= mem(to_i(adr));
                             if we = '1' then
                               mem(to_i(adr)) <= din;  
                             end if;
                           end if;
        when WRITE_FIRST=> if falling_edge(clk) then
                             if we = '1' then
                               mem(to_i(adr)) <= din;  
                               --do <= din;        
                             --else 
                               --do <= mem(to_i(adr)); 
                            end if;
                          end if;
       when NO_CHANGE  => if falling_edge(clk) then
                             if we = '1' then
                               mem(to_i(adr)) <= din; 
                             else 
                               --do <= mem(to_i(adr)); 
                            end if;
                          end if;                          
      end case;      
    end if;
  end process;
  
  do <= mem(to_i(adr));
  dout <= do;
  
end synth;