---------------------------------------------------------------------------------
-- filename: alu.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
--use ieee.std_logic_unsigned.all;

use work.mips_pkg.all;
use work.casts.all;

entity alu is 
  port ( a, b      : in     STD_LOGIC_VECTOR(31 downto 0);
         aluctrl   : in     STD_LOGIC_VECTOR( 3 downto 0);
         shamt     : in     STD_LOGIC_VECTOR( 4 downto 0); 
         result    : out    STD_LOGIC_VECTOR(31 downto 0);
         zero      : buffer STD_LOGIC; 
         lez,
         ltz, gtz  : out    STD_LOGIC);
end;

architecture withBarrelshift of alu is
  
  signal   condinvb, 
           twosC_b   : SIGNED(31 downto 0);
  signal   aluresult,
           sllresult,
           srlresult,
           sraresult,
           prod, sum,
           res       : STD_LOGIC_VECTOR (31 downto 0) := ZERO32;
  signal   dir       : STD_LOGIC;         
  constant zeros31   : STD_LOGIC_VECTOR (30 downto 0) := (others => '0');
  constant zeros16   : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');

begin

  condinvb  <= signed(not b) when aluctrl(3)='1' else 
               signed(b);
  twosC_b   <= signed(condinvb) + signed(zeros31 & aluctrl(3));
  sum       <= to_slv(signed(a) + twosC_b); 
  prod      <= to_slv(signed(a(15 downto 0)) * signed(b(15 downto 0)));
  dir       <= '1' when aluctrl = ALU_srl else
               '0';
  barrelshifter: entity work.barrel port map(dir, b, shamt, res);
  
  --sllresult <= to_slv(shift_left (unsigned(b), to_i(shamt)));
  --srlresult <= to_slv(shift_right(unsigned(b), to_i(shamt)));
  
  sraresult <= to_slv(shift_right(  signed(b), to_i(shamt)));
  
              with aluctrl select
  aluresult <= a and b                  when ALU_and, 
               a or  b                  when ALU_or ,
               a xor b                  when ALU_xor,
               a nor b                  when ALU_nor,  
               sum                      when ALU_add, 
               sum                      when ALU_sub, 
               zeros31 & sum(31)        when ALU_slt, 
               --sllresult                when ALU_sll,
               --srlresult                when ALU_srl,
               res                      when ALU_sll | ALU_srl,
               sraresult                when ALU_sra, 
               prod                     when ALU_mul,
               b(15 downto 0) & zeros16 when ALU_lui, 
               a                        when others;
               
  zero   <= '1' when aluresult = X"00000000" else '0';
  lez    <=     zero or      aluresult(31);
  ltz    <= not zero and     aluresult(31);
  gtz    <= not zero and not aluresult(31);
               
  result <= aluresult; 
  
end;  

architecture withoutBarrelshift of alu is

  signal   condinvb, 
           twosC_b   : SIGNED(31 downto 0);
  signal   aluresult,
           sllresult,
           srlresult,
           sraresult,
           prod, sum : SIGNED (31 downto 0) := (others => '0');
  constant zeros31   : SIGNED (30 downto 0) := (others => '0');
  constant zeros16   : SIGNED (15 downto 0) := (others => '0');
  

begin
  
  condinvb  <= signed(not b) when aluctrl(3)='1' else 
               signed(b);
  twosC_b   <= signed(condinvb) + (zeros31 & aluctrl(3));
  sum       <= signed(a) + twosC_b; 
  prod      <= signed(a(15 downto 0)) * signed(b(15 downto 0));
  
               with aluctrl select
  aluresult <= signed(a and b)                  when ALU_and, 
               signed(a or  b)                  when ALU_or ,
               signed(a xor b)                  when ALU_xor,
               signed(a nor b)                  when ALU_nor,  
               sum                              when ALU_add, 
               sum                              when ALU_sub, 
               zeros31 & sum(31)                when ALU_slt, 
               signed(b(30 downto 0) & '0')     when ALU_sll, 
               --signed(b) sll to_i(shamt)        when ALU_sll,
               signed('0' & b(31 downto 1))     when ALU_srl,
               --signed(b) srl to_i(shamt)        when ALU_srl,
               signed(b(31) & b(31 downto 1))   when ALU_sra, 
               prod                             when ALU_mul,
               signed(b(15 downto 0)) & zeros16 when ALU_lui, 
               signed(a)                        when others;
               
  zero      <= '1' when aluresult = X"00000000" else '0';
  lez       <=     zero or      aluresult(31);
  ltz       <= not zero and     aluresult(31);
  gtz       <= not zero and not aluresult(31);
               
  result    <= to_slv(aluresult); --std_logic_vector(aluresult); 
  
end;  