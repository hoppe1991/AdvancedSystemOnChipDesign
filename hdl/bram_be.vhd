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

entity bram_be is
  generic ( ADDR     : integer  := 11;  
            --DATA     : integer  := 32; 
            EDGE     : EdgeType := RISING;
            FNAME    : string   := "isort"; 
            EXT      : string   := "dmem"
          );
          
  port ( clk    : STD_LOGIC;
         c      : in  ControlType;
         adr    : in  STD_LOGIC_VECTOR(ADDR+1 downto 0);
         din    : in  STD_LOGIC_VECTOR(31 downto 0);
         dout   : out STD_LOGIC_VECTOR(31 downto 0)
       );
end;

architecture synth of bram_be is
  
  signal we0, we1, 
         we2, we3    : STD_LOGIC := '0';
  signal b, b1se     : STD_LOGIC_VECTOR(     1 downto 0) := "00";
  signal bse         : STD_LOGIC_VECTOR(     2 downto 0) := "000";
  signal a           : STD_LOGIC_VECTOR(ADDR-1 downto 0) := (others => '0');
  signal do          : STD_LOGIC_VECTOR(    31 downto 0) := ZERO32;
  
begin

  b   <= adr(      1 downto 0); -- byte address
  a   <= adr( ADDR+1 downto 2); 
  
  we0 <= '1' when c.memwr = '1' and ((b    = "00" and c.bhw = Byte) or 
                                     (b(1) =  '0' and c.bhw = Half) or 
                                                      c.bhw = Word) else
         '0';                                             
  
  we1 <= '1' when c.memwr = '1' and ((b    = "01" and c.bhw = Byte) or 
                                     (b(1) =  '0' and c.bhw = Half) or 
                                                      c.bhw = Word) else
         '0';          
                                                                                               
  we2 <= '1' when c.memwr = '1' and ((b    = "10" and c.bhw = Byte) or 
                                     (b(1) =  '1' and c.bhw = Half) or 
                                                      c.bhw = Word) else
         '0';                                              
  
  we3 <= '1' when c.memwr = '1' and ((b    = "11" and c.bhw = Byte) or 
                                     (b(1) =  '1' and c.bhw = Half) or 
                                                      c.bhw = Word) else
         '0';
                                                                                                             
  byte0 : entity work.bram  
          generic map (ADDR=>ADDR, DATA=>8, EDGE=>EDGE, INIT=>FNAME&"0."&EXT)                      
          port    map (clk, we0, a, din( 7 downto  0), do( 7 downto  0)); 
  byte1 : entity work.bram  
          generic map (ADDR=>ADDR, DATA=>8, EDGE=>EDGE, INIT=>FNAME&"1."&EXT)                      
          port    map (clk, we1, a, din(15 downto  8), do(15 downto  8));         
  byte2 : entity work.bram  
          generic map (ADDR=>ADDR, DATA=>8, EDGE=>EDGE, INIT=>FNAME&"2."&EXT)                    
          port    map (clk, we2, a, din(23 downto 16), do(23 downto 16)); 
  byte3 : entity work.bram  
          generic map (ADDR=>ADDR, DATA=>8, EDGE=>EDGE, INIT=>FNAME&"3."&EXT)                       
          port    map (clk, we3, a, din(31 downto 24), do(31 downto 24));
         
  bse   <= b    & c.se;
  b1se  <= b(1) & c.se;
  
  -- data out with sign/zero extension
  
  dout  <= x"FFFFFF" & do( 7 downto  0) when c.bhw=Byte and bse="001" and do( 7)='1' else
           x"000000" & do( 7 downto  0) when c.bhw=Byte and bse="000" else
           x"FFFFFF" & do(15 downto  8) when c.bhw=Byte and bse="011" and do( 7)='1' else
           x"000000" & do(15 downto  8) when c.bhw=Byte and bse="010" else
           x"FFFFFF" & do(23 downto 16) when c.bhw=Byte and bse="101" and do( 7)='1' else
           x"000000" & do(23 downto 16) when c.bhw=Byte and bse="100" else
           x"FFFFFF" & do(31 downto 24) when c.bhw=Byte and bse="111" and do( 7)='1' else
           x"000000" & do(31 downto 24) when c.bhw=Byte and bse="110" else
           x"FFFF"   & do(15 downto  0) when c.bhw=Half and b1se="01" and do(15)='1' else
           x"0000"   & do(15 downto  0) when c.bhw=Half and b1se="00" else
           x"FFFF"   & do(31 downto 16) when c.bhw=Half and b1se="11" and do(15)='1' else
           x"0000"   & do(31 downto 16) when c.bhw=Half and b1se="10" else
                       do; --           when bhw=Word;          

end synth;