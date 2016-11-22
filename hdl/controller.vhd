---------------------------------------------------------------------------------
-- filename: controller.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all;

use work.mips_pkg.all;

entity control is -- single cycle control decoder
  port ( i       : in  InstructionType;
         c       : out ControlType 
       );
end;

architecture struct of control is
 
  signal aluop        : STD_LOGIC_VECTOR(2 downto 0) := "000";
  signal controls     : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');   
  
begin

 
  (c.regwr, c.link, c.regdst, c.memwr, c.mem2reg, c.jump, c.alusrc, c.jr) <= controls;
  -- Control Signals
  
              --rlrmmjaj  
                          with i.Mnem select
  controls  <= "10100000" when ADD   | ADDU  | ANDop | ORop  | NORop | SLLop | 
                               SRAop | SRLop | SUB   | SUBU  | XORop | SLT   | 
                               SLTU  | MUL   , -- R-type     
               "10000010" when ADDI  | ADDIU | SLTI  | SLTIU | LUI   | ANDI  | 
                               ORI   | XORI  , -- I-type 
               "00000100" when J     ,  
               "11000100" when JAL   ,  
               "00100001" when JR    ,
               "10001010" when LW    | LH    | LHU   | LB    | LBU   ,                 
               "00010010" when SW    | SH    | SB    ,  
               "00000000" when others;   

  -- ALU Control Signals 
                          with i.Mnem select
  c.aluctrl <= ALU_add    when ADD   | ADDU | ADDI  | ADDIU | LW |  LH  |  LHU | 
                               LB    | LBU  | SW    | SH    | SB ,          
               ALU_slt    when SLT   | SLTU | SLTIU | SLTI  ,  
               ALU_sub    when SUB   | SUBU | BEQ   | BNE   | BLEZ | BLTZ | BGTZ,  
               ALU_and    when ANDop | ANDI ,   
               ALU_or     when ORop  | ORI  , 
               ALU_nor    when NORop ,            
               ALU_xor    when XORop | XORI ,  
               ALU_lui    when LUI   ,                
               ALU_sll    when SLLop , 
               ALU_srl    when SRLop , 
               ALU_sra    when SRAop ,  
               ALU_mul    when MUL   , 
               "0000"     when others;
                
                          with i.Mnem select
  c.bhw     <= Byte       when LB | SB | LBU, 
               Half       when LH | SH | LHU,           
               Word       when others; -- i.Mnem = LW or i.Mnem = SW;             
                          
             
                          with i.Mnem select 
  c.se      <= '0'        when LHU | LBU,   
               '1'        when others; 
               
                          with i.Mnem select
  c.signext <= '1'        when ADDIU | ADDI | SLTI | SLTIU,
               '0'        when others; 
                           
                          -- instructions that uses rs 
                          with i.Mnem select   
  c.rs      <= '1'        when  ADD   | ADDU  | ADDI | ADDIU | ANDop | ANDI  | 
                                MUL   | NORop | ORop | ORI   | SUB   | SUBU  |
                                XORop | XORI  | SLT  | SLTI  | SLTIU | BEQ   | 
                                BNE   | BLEZ  | BGTZ | BLTZ  | JR    | 
                                LW    | LB    | LBU  |  LH   | LHU   | 
                                SW    | SH    | SB    ,
               '0'        when others;
              
                          -- instructions that uses rt
                          with i.Mnem select   
  c.rt      <= '1'        when  ADD   | ADDU  | ANDop | MUL  | NORop | ORop  |
                                SLLop | SRAop | SRLop | SUB  | SUBU  | XORop | 
                                SLT   | BEQ   | BNE   | BLEZ | BGTZ  | BLTZ  | 
                                SW    | SH    | SB    ,
               '0'        when others;              
                           

end;