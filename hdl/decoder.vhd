---------------------------------------------------------------------------------
-- filename: decoder.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.mips_pkg.all;
use work.casts.all;

entity decoder is
  port ( instructionWord: in  STD_LOGIC_vector(31 downto 0);
         instruction    : out InstructionType
         
  );
end decoder;

architecture behavior of decoder is

  signal i : InstructionType;

begin

  i.Opc       <= instructionWord (31 downto 26);
  i.Rs        <= instructionWord (25 downto 21);
  i.Rt        <= instructionWord (20 downto 16);
  i.Rd        <= instructionWord (15 downto 11);
  i.shamt     <= instructionWord (10 downto  6);
  i.Funct     <= instructionWord ( 5 downto  0);    
  i.Imm       <= instructionWord (15 downto  0);
  i.BrTarget  <= instructionWord (25 downto  0);   
  
  instruction <= I; 

  i.Mnem   <= ADD    when i.Opc   = I_ADD.Opc     and i.Funct = I_ADD.Funct   else 
              ADDU   when i.Opc   = I_ADDU.Opc    and i.Funct = I_ADDU.Funct  else 
              ADDI   when i.Opc   = I_ADDI.Opc                                else
              ADDIU  when i.Opc   = I_ADDIU.Opc                               else
              ANDop  when i.Opc   = I_AND.Opc     and i.Funct = I_AND.Funct   else 
              ANDI   when i.Opc   = I_ANDI.Opc                                else
--              CLO    when i.Opc   = I_CLO.Opc     and i.Funct = I_CLO.Funct   else    
--              CLZ    when i.Opc   = I_CLZ.Opc     and i.Funct = I_CLZ.Funct   else 
--              DIV    when i.Rd    = I_DIV.Rd      and i.Funct = I_DIV.Funct   else 
--              DIVU   when i.Rd    = I_DIVU.Rd     and i.Funct = I_DIVU.Funct  else 
--              MULT   when i.Opc   = I_MULT.Opc    and i.Funct = I_MULT.Funct  else   
--              MULTU  when i.Opc   = I_MULTU.Opc   and i.Funct = I_MULTU.Funct else 
              MUL    when i.Opc   = I_MUL.Opc     and i.Funct = I_MUL.Funct   else    
--              MADD   when i.Opc   = I_MADD.Opc    and i.Funct = I_MADD.Funct  else  
--              MADDU  when i.Opc   = I_MADDU.Opc   and i.Funct = I_MADDU.Funct else  
--              MSUB   when i.Opc   = I_MSUB.Opc    and i.Funct = I_MSUB.Funct  else  
--              MSUBU  when i.Opc   = I_MSUBU.Opc   and i.Funct = I_MSUBU.Funct else  
              NORop  when i.Opc   = I_NOR.Opc     and i.Funct = I_NOR.Funct   else 
              ORop   when i.Opc   = I_OR.Opc      and i.Funct = I_OR.Funct    else  
              ORI    when i.Opc   = I_ORI.Opc                                 else
              SLLop  when i.Opc   = I_SLL.Opc     and i.Shamt /= "00000"      --I_SLL.Shamt 
                                                  and i.Funct = I_SLL.Funct   else 
--              SLLV   when i.Opc   = I_SLLV.Opc    and i.Funct = I_SLLV.Funct  else 
              SRAop  when i.Opc   = I_SRA.Opc     and i.Funct = I_SRA.Funct   else 
--              SRAV   when i.Opc   = I_SRAV.Opc    and i.Funct = I_SRAV.Funct  else 
              SRLop  when i.Opc   = I_SRL.Opc     and i.Funct = I_SRL.Funct   else
--              SRLV   when i.Opc   = I_SRLV.Opc    and i.Funct = I_SRLV.Funct  else
              SUB    when i.Opc   = I_SUB.Opc     and i.Funct = I_SUB.Funct   else
              SUBU   when i.Opc   = I_SUBU.Opc    and i.Funct = I_SUBU.Funct  else
              XORop  when i.Opc   = I_XOR.Opc     and i.Funct = I_XOR.Funct   else
              XORI   when i.Opc   = I_XORI.Opc                                else
              LUI    when i.Opc   = I_LUI.Opc                                 else
              SLT    when i.Opc   = I_SLT.Opc     and i.Funct = I_SLT.Funct   else
              SLTU   when i.Opc   = I_SLTU.Opc    and i.Funct = I_SLTU.Funct  else
              SLTI   when i.Opc   = I_SLTI.Opc                                else
              SLTIU  when i.Opc   = I_SLTIU.Opc                               else
--              BCLF   when i.Opc   = I_BCLF.Opc    and i.Rt    = I_BCLF.Rt     else
--              BCLT   when i.Opc   = I_BCLT.Opc    and i.Rt    = I_BCLT.Rt     else
              BEQ    when i.Opc   = I_BEQ.Opc                                 else
--              BGEZ   when i.Opc   = I_BGEZ.Opc    and i.Rt    = I_BGEZ.Rt     else
--              BGEZAL when i.Opc   = I_BGEZAL.Opc  and i.Rt    = I_BGEZAL.Rt   else
              BGTZ   when i.Opc   = I_BGTZ.Opc    and i.Rt    = I_BGTZ.Rt     else
              BLEZ   when i.Opc   = I_BLEZ.Opc    and i.Rt    = I_BLEZ.Rt     else
--              BLTZAL when i.Opc   = I_BLTZAL.Opc  and i.Rt    = I_BLTZAL.Rt   else
              BLTZ   when i.Opc   = I_BLTZ.Opc    and i.Rt    = I_BLTZ.Rt     else
              BNE    when i.Opc   = I_BNE.Opc                                 else
              J      when i.Opc   = I_J.Opc                                   else
              JAL    when i.Opc   = I_JAL.Opc                                 else
--              JALR   when i.Opc   = I_JALR.Opc    and i.Funct = I_JALR.Funct  else
              JR     when i.Opc   = I_JR.Opc     and i.Funct = I_JR.Funct     else
--              TEQ    when i.Opc   = I_TEQ.Opc     and i.Funct = I_TEQ.Funct   else
--              TEQI   when i.Opc   = I_TEQI.Opc    and i.Rt    = I_TEQI.Rt     else
--              TNE    when i.Opc   = I_TNE.Opc     and i.Funct = I_TNE.Funct   else
--              TNEQI  when i.Opc   = I_TNEQI.Opc   and i.Rt    = I_TNEQI.Rt    else
--              TGE    when i.Opc   = I_TGE.Opc     and i.Funct = I_TGE.Funct   else
--              TGEU   when i.Opc   = I_TGEU.Opc    and i.Funct = I_TGEU.Funct  else
--              TGEQI  when i.Opc   = I_TGEQI.Opc   and i.Rt    = I_TGEQI.Rt    else
--              TGEQIU when i.Opc   = I_TGEQIU.Opc  and i.Rt    = I_TGEQIU.Rt   else
--              TLT    when i.Opc   = I_TLT.Opc     and i.Funct = I_TLT.Funct   else
--              TLTI   when i.Opc   = I_TLTI.Opc    and i.Rt    = I_TLTI.Rt     else
--              TLTIU  when i.Opc   = I_TLTIU.Opc   and i.Rt    = I_TLTIU.Rt    else
              LB     when i.Opc   = I_LB.Opc                                  else
              LBU    when i.Opc   = I_LBU.Opc                                 else
              LH     when i.Opc   = I_LH.Opc                                  else
              LHU    when i.Opc   = I_LHU.Opc                                 else
              LW     when i.Opc   = I_LW.Opc                                  else
--              LWCL   when i.Opc   = I_LWCL.Opc                                else
--              LWL    when i.Opc   = I_LWL.Opc                                 else
--              LWR    when i.Opc   = I_LWR.Opc                                 else
--              LL     when i.Opc   = I_LL.Opc                                  else
--              SC     when i.Opc   = I_SC.Opc                                  else
              SB     when i.Opc   = I_SB.Opc                                  else
              SH     when i.Opc   = I_SH.Opc                                  else
              SW     when i.Opc   = I_SW.Opc                                  else
--              SWCL   when i.Opc   = I_SWCL.Opc                                else
--              SDCL   when i.Opc   = I_SDCL.Opc                                else
--              SWL    when i.Opc   = I_SWL.Opc                                 else
--              SWR    when i.Opc   = I_SWR.Opc                                 else
--              MFHI   when i.Opc   = I_MFHI.Opc    and i.Funct = I_MFHI.Funct  else
--              MFLO   when i.Opc   = I_MFLO.Opc    and i.Funct = I_MFLO.Funct  else
--              MTHI   when i.Opc   = I_MTHI.Opc    and i.Funct = I_MTHI.Funct  else
--              MTLO   when i.Opc   = I_MTLO.Opc    and i.Funct = I_MTLO.Funct  else
--              MFC0   when i.Funct = I_MFC0.Funct and i.Rs     = I_MFC0.Rs     else                              
--              MFC1   when i.Funct = I_MFC1.Funct and i.Rs     = I_MFC1.Rs     else
--              MTC0   when i.Funct = I_MTC0.Funct and i.Rs     = I_MTC0.Rs     else
--              MTC1   when i.Funct = I_MTC1.Funct and i.Rs     = I_MTC1.Rs     else
--              MOVN   when i.Opc   = I_MOVN.Opc    and i.Funct = I_MOVN.Funct  else
--              MOVZ   when i.Opc   = I_MOVZ.Opc    and i.Funct = I_MOVZ.Funct  else
--              MOVF   when i.Funct = I_MOVF.Funct and i.Rt     = I_MOVF.Rt     else
--              MOVT   when i.Funct = I_MOVT.Funct and i.Rt     = I_MOVT.Rt     else
--              ERET   when i.Opc   = I_ERET.Opc   and i.Funct  = I_ERET.Funct  else
--              SYSCAL when i.Opc   = I_SYSCAL.Opc and i.Funct = I_SYSCAL.Funct else 
--              BREAK  when i.Opc   = I_BREAK.Opc  and i.Funct = I_BREAK.Funct  else
              NOP    when i.Opc   = I_NOP.Opc    and i.Funct = I_NOP.Funct 
                                                 and i.Shamt = I_NOP.Shamt      else
              UNKNOWN;
end;             
