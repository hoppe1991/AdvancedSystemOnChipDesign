
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;

use work.casts.all;

entity barrel is 
  port ( --clk, 
         dir     : in  STD_LOGIC;
         b       : in  STD_LOGIC_VECTOR(31 downto 0);
         shamt   : in  STD_LOGIC_VECTOR( 4 downto 0);
         result  : out STD_LOGIC_VECTOR(31 downto 0)
       );
end;

architecture structural of barrel is
  signal br, --dir, 
         temp1, temp2, 
         temp3, temp4  : STD_LOGIC_VECTOR(31 downto 0);
  --signal shamt        : STD_LOGIC_VECTOR( 4 downto 0);
  signal res           : STD_LOGIC_VECTOR(31 downto 0);
  signal ctrl0, ctrl1, 
         ctrl2, ctrl3, 
         ctrl4         : STD_LOGIC_VECTOR(1 downto 0);
begin
    
  br     <= b; --     when rising_edge(clk);
 
  ctrl0 <= shamt(0) & dir; --when rising_edge(clk);    
  ctrl1 <= shamt(1) & dir; --when rising_edge(clk);
  ctrl2 <= shamt(2) & dir; --when rising_edge(clk);
  ctrl3 <= shamt(3) & dir; --when rising_edge(clk);
  ctrl4 <= shamt(4) & dir; --when rising_edge(clk);    
  --
  -- sll and srl
           with ctrl0 select
  temp1 <= br                            when "00" | "01",
           br(30 downto 0) & '0'         when "10",
           '0' & br(31 downto 1)         when others;
           
           with ctrl1 select   
  temp2 <= temp1                         when "00" | "01",
           temp1(29 downto 0) & "00"     when "10",
           "00" & temp1(31 downto 2)     when others;         

           with ctrl2 select    
  temp3 <= temp2                         when "00" | "01",
           temp2(27 downto 0) & x"0"     when "10",
           x"0" & temp2(31 downto 4)     when others; 
           
           with ctrl3 select   
  temp4 <= temp3                         when "00" | "01",
           temp3(23 downto 0) & x"00"    when "10",
           x"00" & temp3(31 downto 8)    when others;
           
           with ctrl4 select   
  res   <= temp4                         when "00" | "01",
           temp4(15 downto 0) & x"0000"  when "10",
           x"0000" & temp4(31 downto 16) when others;    
           

           
  result <= res; -- when rising_edge(clk);            
  
  
end;  

  --
--  ctrl0 <= shamt(0) & dir;    
--  ctrl1 <= shamt(1) & dir;
--  ctrl2 <= shamt(2) & dir;
--  ctrl3 <= shamt(3) & dir;
--  ctrl4 <= shamt(4) & dir;    
  
--  -- rol and ror
--           with ctrl0 select
--  temp1 <= br                                       when "00" | "01",
--           br(30 downto 0) & br(31)                 when "10",
--           br(0) & br(31 downto 1)                  when others;
           
--           with ctrl1 select   
--  temp2 <= temp1                                    when "00" | "01",
--           temp1(29 downto 0) & temp1(31 downto 30) when "10",
--           temp1( 1 downto 0) & temp1(31 downto  2) when others;         

--           with ctrl2 select    
--  temp3 <= temp2                                    when "00" | "01",
--           temp2(27 downto 0) & temp2(31 downto 28) when "10",
--           temp2( 3 downto 0) & temp2(31 downto  4) when others; 
           
--           with ctrl3 select   
--  temp4 <= temp3                                    when "00" | "01",
--           temp3(23 downto 0) & temp3(31 downto 24) when "10",
--           temp3( 7 downto 0) & temp1(31 downto 8)  when others;
           
--           with ctrl4 select   
--  res   <= temp4                                    when "00" | "01",
--           temp4(15 downto 0) & temp4(31 downto 16) when others;

--  -- sll
--  temp1 <= br                       when shamtr(0)='0' else
--           br(30 downto 0) & '0'; 
--  temp2 <= temp1                    when shamtr(1)='0' else
--           temp1(29 downto 0) & "00"; 
--  temp3 <= temp2                    when shamtr(2)='0' else
--           temp2(27 downto 0) & x"0";   
--  temp4 <= temp3                    when shamtr(3)='0' else
--           temp3(23 downto 0) & x"00";     
--  res   <= temp4                    when shamtr(4)='0' else
--           temp4(15 downto 0) & x"0000";   

  --result <= to_slv(shift_left (unsigned(br), to_i(shamtr))) when rising_edge(clk);
  
--  with shamtr(4 downto 0) select   --- cases for left shift
--            res <=  br when "00000",
--                    br(30 downto 0) & '0' when "00001",
--                    br(29 downto 0) & "00" when "00010",
--                    br(28 downto 0) & "000" when "00011",
--                    br(27 downto 0) & "0000" when "00100",
--                    br(26 downto 0) & "00000" when "00101",
--                    br(25 downto 0) & "000000" when "00110",
--                    br(24 downto 0) & "0000000" when "00111",
--                    br(23 downto 0) & "00000000" when "01000",
--                    br(22 downto 0) & "000000000" when "01001",
--                    br(21 downto 0) & "0000000000" when "01010",
--                    br(20 downto 0) & "00000000000" when "01011",
--                    br(19 downto 0) & "000000000000" when "01100",
--                    br(18 downto 0) & "0000000000000" when "01101",
--                    br(17 downto 0) & "00000000000000" when "01110",
--                    br(16 downto 0) & "000000000000000" when "01111",
--                    br(15 downto 0) & "0000000000000000" when "10000",
--                    br(14 downto 0) & "00000000000000000" when "10001",
--                    br(13 downto 0) & "000000000000000000" when "10010",
--                    br(12 downto 0) & "0000000000000000000" when "10011",
--                    br(11 downto 0) & "00000000000000000000" when "10100",
--                    br(10 downto 0) & "000000000000000000000" when "10101",
--                    br(9 downto 0)  & "0000000000000000000000" when "10110",
--                    br(8 downto 0)  & "00000000000000000000000" when "10111",
--                    br(7 downto 0)  & "000000000000000000000000" when "11000",
--                    br(6 downto 0)  & "0000000000000000000000000" when "11001",
--                    br(5 downto 0)  & "00000000000000000000000000" when "11010",
--                    br(4 downto 0)  & "000000000000000000000000000" when "11011",
--                    br(3 downto 0)  & "0000000000000000000000000000" when "11100",
--                    br(2 downto 0)  & "00000000000000000000000000000" when "11101",
--                    br(1 downto 0)  & "000000000000000000000000000000" when "11110",
--                    br(0 downto 0)  & "0000000000000000000000000000000" when "11111",
--                    br when others;

--    result <= res when rising_edge(clk);                
  
--  PROCESS (br, shamtr)
--  VARIABLE temp1, temp2, temp3, temp4: STD_LOGIC_VECTOR (31 DOWNTO 0);
--  
--  BEGIN
--   ---- 1st shifter -----
--   
--  IF (shamtr(0)='0') THEN
--  temp1 := br;
--  ELSE
--  temp1(31 downto 0) := br(30 downto 0) & '0'; 
-- --  temp1(0) := '0';
-- --  FOR i IN 1 TO shamt'HIGH LOOP
-- --  temp1(i) := br(i-1);
-- --  END LOOP;
--  END IF;
--  ---- 2nd shifter -----
--  IF (shamtr(1)='0') THEN
--  temp2 := temp1;
--  ELSE
--  temp2(31 downto 0) := temp1(29 downto 0) & "00"; 
-- --  FOR i IN 0 TO 1 LOOP
-- --  temp2(i) := '0';
-- --  END LOOP;
-- --  FOR i IN 2 TO br'HIGH LOOP
-- --  temp2(i) := temp1(i-2);
-- --  END LOOP;
--  END IF;
--  ---- 3rd shifter -----
--  IF (shamtr(2)='0') THEN
--  temp3 := temp2;
--  ELSE
--  temp3(31 downto 0) := temp2(27 downto 0) & x"0"; 
-- --  FOR i IN 0 TO 3 LOOP
-- --  temp3(i) := '0';
-- --  END LOOP;
-- --  FOR i IN 4 TO br'HIGH LOOP
-- --  temp3(i) := temp2(i-4);
-- --  END LOOP;
--  END IF;
--  ---- 4rd shifter -----
--  IF (shamtr(3)='0') THEN
--  temp4 := temp3;
--  ELSE
--  temp4(31 downto 0) := temp3(23 downto 0) & x"00"; 
--  
-- --  FOR i IN 0 TO 7 LOOP
-- --  temp4(i) := '0';
-- --  END LOOP;
-- --  FOR i IN 8 TO br'HIGH LOOP
-- --  temp4(i) := temp3(i-8);
-- --  END LOOP;
--  END IF;
--   ---- 5rd shifter -----
--  IF (shamtr(4)='0') THEN
--  res <= temp4;
--  ELSE
--    res(31 downto 0) <= temp4(15 downto 0) & x"0000"; 
-- --  FOR i IN 0 TO 15 LOOP
-- --  res(i) <= '0';
-- --  END LOOP;
-- --  FOR i IN 16 TO br'HIGH LOOP
-- --  res(i) <= temp4(i-16);
-- --  END LOOP;
--  END IF;
--  END PROCESS;