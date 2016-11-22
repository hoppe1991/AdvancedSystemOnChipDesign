---------------------------------------------------------------------------------
-- filename: mips_pkg.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package mips_pkg is

  constant IADDR_WIDTH   : integer :=  9;   -- address width of instruction memory 
  constant DADDR_WIDTH   : integer :=  9;   -- address width of data memory
  constant RADDR_WIDTH   : integer :=  5;   -- address width of registers
  constant DATA_WIDTH    : integer := 32;   -- data width
  constant OPCODE_WIDTH  : integer :=  6;   -- opcode width
  constant FUNCT_WIDTH   : integer :=  6;   -- function field width
  constant SHAMT_WIDTH   : integer :=  5;   -- shift field width
  constant IMM_WIDTH     : integer := 16;   -- immediate width
  constant BRTARGET_WIDTH: integer := 26;   -- branch address width
  
  constant ALU_add  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
  constant ALU_and  : STD_LOGIC_VECTOR(3 downto 0) := "0001";
  constant ALU_or   : STD_LOGIC_VECTOR(3 downto 0) := "0010";
  constant ALU_xor  : STD_LOGIC_VECTOR(3 downto 0) := "0011";
  constant ALU_sll  : STD_LOGIC_VECTOR(3 downto 0) := "0100";
  constant ALU_srl  : STD_LOGIC_VECTOR(3 downto 0) := "0101";
  constant ALU_sra  : STD_LOGIC_VECTOR(3 downto 0) := "0110";
  constant ALU_mul  : STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 32-bit result
  constant ALU_sub  : STD_LOGIC_VECTOR(3 downto 0) := "1000";     
  constant ALU_slt  : STD_LOGIC_VECTOR(3 downto 0) := "1001";
  constant ALU_lui  : STD_LOGIC_VECTOR(3 downto 0) := "1010";
  constant ALU_nor  : STD_LOGIC_VECTOR(3 downto 0) := "1100";
  


  -- Encoding of the MIPS instructions
  
  type EncType is record
         Opc        : STD_LOGIC_VECTOR (  OPCODE_WIDTH-1 downto 0); 
         Shamt      : STD_LOGIC_VECTOR (   SHAMT_WIDTH-1 downto 0);
         Funct      : STD_LOGIC_VECTOR (   FUNCT_WIDTH-1 downto 0);   
         Rs, Rt, Rd : STD_LOGIC_VECTOR (   RADDR_WIDTH-1 downto 0);      
  end record;
                                -- Opc       Shamt    Funct     Rs       Rt       Rd          Op Fc Rs Rt Rd
  constant  I_ADD   : EncType := ("000000", "00000", "100000", "11111", "11111", "11111"); --    20
  constant  I_ADDU  : EncType := ("000000", "00000", "100001", "11111", "11111", "11111"); --    21
  constant  I_ADDI  : EncType := ("001000", "11111", "111111", "11111", "11111", "11111"); -- 08
  constant  I_ADDIU : EncType := ("001001", "11111", "111111", "11111", "11111", "11111"); -- 09 
  constant  I_AND   : EncType := ("000000", "00000", "100100", "11111", "11111", "11111"); --    24
  constant  I_ANDI  : EncType := ("001100", "11111", "111111", "11111", "11111", "11111"); -- 0C
  constant  I_CLO   : EncType := ("011100", "00000", "100001", "11111", "00000", "11111"); -- 1C 11
  constant  I_CLZ   : EncType := ("011100", "00000", "100000", "11111", "00000", "11111"); -- 1C 10
  constant  I_DIV   : EncType := ("000000", "00000", "011010", "11111", "11111", "00000"); --    1A
  constant  I_DIVU  : EncType := ("000000", "00000", "011011", "11111", "11111", "00000"); --    1B
  constant  I_MULT  : EncType := ("000000", "00000", "011000", "11111", "11111", "00000"); --    18
  constant  I_MULTU : EncType := ("000000", "00000", "011001", "11111", "11111", "00000"); --    19
  constant  I_MUL   : EncType := ("011100", "00000", "000010", "11111", "11111", "11111"); -- 1C 02   
  constant  I_MADD  : EncType := ("011100", "00000", "000000", "11111", "11111", "00000"); -- 1C 00
  constant  I_MADDU : EncType := ("011100", "00000", "000001", "11111", "11111", "00000"); -- 1C 01
  constant  I_MSUB  : EncType := ("011100", "00000", "000100", "11111", "11111", "00000"); -- 1C 04
  constant  I_MSUBU : EncType := ("011100", "00000", "000101", "11111", "11111", "00000"); -- 1C 05
  constant  I_NOR   : EncType := ("000000", "00000", "100111", "11111", "11111", "11111"); --    17
  constant  I_OR    : EncType := ("000000", "00000", "100101", "11111", "11111", "11111"); --    15
  constant  I_ORI   : EncType := ("001101", "11111", "111111", "11111", "11111", "11111"); -- 0D
  constant  I_SLL   : EncType := ("000000", "11111", "000000", "11111", "11111", "11111"); -- 00 00
  constant  I_SLLV  : EncType := ("000000", "00000", "000100", "11111", "11111", "11111"); -- 00 04
  constant  I_SRA   : EncType := ("000000", "11111", "000011", "11111", "11111", "11111"); --    03
  constant  I_SRAV  : EncType := ("000000", "00000", "000111", "11111", "11111", "11111"); --    07
  constant  I_SRL   : EncType := ("000000", "11111", "000010", "11111", "11111", "11111"); --    02
  constant  I_SRLV  : EncType := ("000000", "00000", "000110", "11111", "11111", "11111"); --    06
  constant  I_SUB   : EncType := ("000000", "00000", "100010", "11111", "11111", "11111"); --    22
  constant  I_SUBU  : EncType := ("000000", "00000", "100011", "11111", "11111", "11111"); --    23
  constant  I_XOR   : EncType := ("000000", "00000", "100110", "11111", "11111", "11111"); --    26 
  constant  I_XORI  : EncType := ("001110", "11111", "111111", "11111", "11111", "11111"); --    0E
  constant  I_LUI   : EncType := ("001111", "11111", "111111", "00000", "11111", "11111"); --    0F
  constant  I_SLT   : EncType := ("000000", "00000", "101010", "11111", "11111", "11111"); --    2A
  constant  I_SLTU  : EncType := ("000000", "00000", "101011", "11111", "11111", "11111"); --    2B
  constant  I_SLTI  : EncType := ("001010", "11111", "111111", "11111", "11111", "11111"); -- 0A
  constant  I_SLTIU : EncType := ("001011", "11111", "111111", "11111", "11111", "11111"); -- 0B
  constant  I_BCLF  : EncType := ("010001", "11111", "111111", "01000", "00010", "11111"); -- 11       02
  constant  I_BCLT  : EncType := ("010001", "11111", "111111", "01000", "00001", "11111"); -- 11       01
  constant  I_BEQ   : EncType := ("000100", "11111", "111111", "11111", "11111", "11111"); -- 04
  constant  I_BGEZ  : EncType := ("000001", "11111", "111111", "11111", "00001", "11111"); -- 01       01
  constant  I_BGEZAL: EncType := ("000001", "11111", "111111", "11111", "10001", "11111"); -- 01       11
  constant  I_BGTZ  : EncType := ("000111", "11111", "111111", "11111", "00000", "11111"); -- 07
  constant  I_BLEZ  : EncType := ("000110", "11111", "111111", "11111", "00000", "11111"); -- 06
  constant  I_BLTZAL: EncType := ("000001", "11111", "111111", "11111", "10000", "11111"); -- 01       10
  constant  I_BLTZ  : EncType := ("000001", "11111", "111111", "11111", "00000", "11111"); -- 01       00
  constant  I_BNE   : EncType := ("000101", "11111", "111111", "11111", "11111", "11111"); -- 05
  constant  I_J     : EncType := ("000010", "11111", "111111", "11111", "11111", "11111"); -- 02
  constant  I_JAL   : EncType := ("000011", "11111", "111111", "11111", "11111", "11111"); -- 03
  constant  I_JALR  : EncType := ("000000", "00000", "001001", "11111", "00000", "11111"); --    09
  constant  I_JR    : EncType := ("000000", "00000", "001000", "11111", "00000", "00000"); --    08     
  constant  I_TEQ   : EncType := ("000000", "00000", "110100", "11111", "11111", "00000"); --    34      
  constant  I_TEQI  : EncType := ("000001", "11111", "111111", "11111", "01100", "11111"); -- 01       0C
  constant  I_TNE   : EncType := ("000000", "00000", "110110", "11111", "00000", "00000"); --    36 
  constant  I_TNEQI : EncType := ("000001", "11111", "111111", "11111", "01110", "11111"); -- 01       0E  
  constant  I_TGE   : EncType := ("000000", "00000", "110000", "11111", "00000", "00000"); --    30 
  constant  I_TGEU  : EncType := ("000000", "00000", "110001", "11111", "00000", "00000"); --    31
  constant  I_TGEQI : EncType := ("000001", "11111", "111111", "11111", "01000", "11111"); -- 01       08
  constant  I_TGEQIU: EncType := ("000001", "11111", "111111", "11111", "01001", "11111"); -- 01       09
  constant  I_TLT   : EncType := ("000000", "00000", "110010", "11111", "00000", "00000"); --    32
  constant  I_TLTI  : EncType := ("000001", "11111", "111111", "11111", "01010", "11111"); -- 01       0A
  constant  I_TLTIU : EncType := ("000001", "11111", "111111", "11111", "01011", "11111"); -- 01       0B 
  constant  I_LB    : EncType := ("100000", "11111", "111111", "11111", "11111", "11111"); -- 20
  constant  I_LBU   : EncType := ("100100", "11111", "111111", "11111", "11111", "11111"); -- 24
  constant  I_LH    : EncType := ("100001", "11111", "111111", "11111", "11111", "11111"); -- 21
  constant  I_LHU   : EncType := ("100101", "11111", "111111", "11111", "11111", "11111"); -- 25
  constant  I_LW    : EncType := ("100011", "11111", "111111", "11111", "11111", "11111"); -- 23
  constant  I_LWCL  : EncType := ("110001", "11111", "111111", "11111", "11111", "11111"); -- 31
  constant  I_LWL   : EncType := ("100010", "11111", "111111", "11111", "11111", "11111"); -- 22
  constant  I_LWR   : EncType := ("100101", "11111", "111111", "11111", "11111", "11111"); -- 25
  constant  I_LL    : EncType := ("110000", "11111", "111111", "11111", "11111", "11111"); -- 30
  constant  I_SB    : EncType := ("101000", "11111", "111111", "11111", "11111", "11111"); -- 28
  constant  I_SH    : EncType := ("101001", "11111", "111111", "11111", "11111", "11111"); -- 29
  constant  I_SW    : EncType := ("101011", "11111", "111111", "11111", "11111", "11111"); -- 2B
  constant  I_SWCL  : EncType := ("110001", "11111", "111111", "11111", "11111", "11111"); -- 31
  constant  I_SDCL  : EncType := ("111101", "11111", "111111", "11111", "11111", "11111"); -- 3D  
  constant  I_SWL   : EncType := ("101010", "11111", "111111", "11111", "11111", "11111"); -- 2A
  constant  I_SWR   : EncType := ("101110", "11111", "111111", "11111", "11111", "11111"); -- 2E
  constant  I_SC    : EncType := ("111000", "11111", "111111", "11111", "11111", "11111"); -- 38
  constant  I_MFHI  : EncType := ("000000", "00000", "010000", "00000", "00000", "11111"); --    10
  constant  I_MFLO  : EncType := ("000000", "00000", "010010", "00000", "00000", "11111"); --    12 
  constant  I_MTHI  : EncType := ("000000", "00000", "010001", "11111", "00000", "00000"); --    11 
  constant  I_MTLO  : EncType := ("000000", "00000", "010011", "11111", "00000", "00000"); --    13
  constant  I_MFC0  : EncType := ("010000", "00000", "000000", "00000", "11111", "11111"); -- 10    00
  constant  I_MFC1  : EncType := ("010001", "00000", "000000", "00000", "11111", "11111"); -- 11    00
  constant  I_MTC0  : EncType := ("010000", "00000", "000000", "00100", "11111", "11111"); -- 10    04
  constant  I_MTC1  : EncType := ("010001", "00000", "000000", "00100", "11111", "11111"); -- 11    04 
  constant  I_MOVN  : EncType := ("000000", "00000", "001011", "11111", "11111", "11111"); --    0B
  constant  I_MOVZ  : EncType := ("000000", "00000", "001010", "11111", "11111", "11111"); --    0A
  constant  I_MOVF  : EncType := ("000000", "00000", "000001", "11111", "00000", "11111"); --    01    00
  constant  I_MOVT  : EncType := ("000000", "00000", "000001", "00000", "00001", "11111"); --    01    01
  constant  I_ERET  : EncType := ("010000", "00000", "011000", "10000", "00000", "00000"); -- 10 18
  constant  I_SYSCAL: EncType := ("000000", "00000", "001100", "00000", "00000", "00000"); --    0C
  constant  I_BREAK : EncType := ("000000", "11111", "001101", "11111", "11111", "11111"); --    0D
  constant  I_NOP   : EncType := ("000000", "00000", "000000", "00000", "00000", "00000");
               
  constant regt_opc : STD_LOGIC_VECTOR(5 downto 0) := "000000";
  
  constant ZERO32   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');           

  type EdgeType      is ( RISING, FALLING );
  
  type InitType      is ( SET, CLEAR );
  
  type ResetType     is ( ASYNC, SYNC );
  
  type ResetPolarity is ( POS, NEG );
  
  type OpcodeType is (
       ADD, ADDU, ADDI, ADDIU, ANDop, ANDI,  
--       CLO, 
--       CLZ, 
--       DIV, 
--       DIVU, 
--       MULT, 
--       MULTU, 
       MUL, 
--       MADD, 
--       MADDU, 
--       MSUB, 
--       MSUBU, 
       NORop, ORop, ORI, SLLop, 
--       SLLV, 
       SRAop, 
--       SRAV, 
       SRLop, 
--       SRLV,  
       SUB, SUBU, XORop, XORI, 
       LUI, SLT, SLTU, SLTI, SLTIU, 
--       BCLF, 
--       BCLT, 
       BEQ,
--       BGEZ, 
--       BGEZAL, 
       BGTZ, 
       BLEZ, 
--       BLTZAL, 
       BLTZ, 
       BNE, J, JAL, 
--       JALR, 
       JR,
--       TEQ, 
--       TEQI, 
--       TNE, 
--       TNEQI, 
--       TGE, 
--       TGEU, 
--       TGEQI, 
--       TGEQIU, 
--       TLT, 
--       TLTI, 
--       TLTIU, 
       LB, LBU, LH, LHU, LW, 
--       LWCL, 
--       LWL, 
--       LWR,   
--       LL, SC,    
       SB, SH, SW, 
--       SWCL, 
--       SDCL, 
--       SWL, 
--       SWR,     
--       MFHI, 
--       MFLO, 
--       MTHI, 
--       MTLO, 
--       MFC0, 
--       MFC1, 
--       MTC0, 
--       MTC1,  
--       MOVN, 
--       MOVZ, 
--       MOVF, 
--       MOVT,  
--       ERET, 
--       SYSCAL, 
--       BREAK, 
       NOP, 
       UNKNOWN
      );
       
  type InstructionType is record
       Mnem            : OpcodeType;
       Opc             : STD_LOGIC_VECTOR (  OPCODE_WIDTH-1 downto 0); 
       Rd, Rt, Rs      : STD_LOGIC_VECTOR (   RADDR_WIDTH-1 downto 0);
       Funct           : STD_LOGIC_VECTOR (   FUNCT_WIDTH-1 downto 0);
       Shamt           : STD_LOGIC_VECTOR (   SHAMT_WIDTH-1 downto 0);
       Imm             : STD_LOGIC_VECTOR (     IMM_WIDTH-1 downto 0);
       BrTarget        : STD_LOGIC_VECTOR (BRTARGET_WIDTH-1 downto 0);
  end record;
  
  type AccessType is (Byte, Half, Word); 
  
  type ForwardType is (fromReg, fromALUe, fromALUm, fromMEM);
  
  type ModeType is (WRITE_FIRST, READ_FIRST, NO_CHANGE);
       
  type ControlType is record
       regwr, 
       link, regdst,  
       memwr, mem2reg, 
       jump, alusrc, 
       jr, se, 
       itype, rtype, 
       btype, signext,
       ltype, rs, rt   : STD_LOGIC;
       aluctrl         : STD_LOGIC_VECTOR(3 downto 0);
       bhw             : AccessType;
  end record;
  
  type IDType is record -- instruction decode phase
       ir, pc4         : STD_LOGIC_VECTOR(31 downto 0);
  end record;
  
  type EXType is record -- execution phase
       c               : Controltype;
       i               : InstructionType;   
       wa              : STD_LOGIC_VECTOR( 4 downto 0); 
       a, b, imm, 
       pc4, rd2        : STD_LOGIC_VECTOR(31 downto 0);
  end record;
  
  type MAType is record -- memory access phase
       c               : Controltype;
       i               : InstructionType; 
       wa              : STD_LOGIC_VECTOR( 4 downto 0);
       a, imm, 
       pc4, rd2,          --   : STD_LOGIC_VECTOR(31 downto 0);
       pcbranch, pcjump,
       aluout          : STD_LOGIC_VECTOR(31 downto 0);
       zero, lez,
       ltz, gtz        : STD_LOGIC;
  end record;
  
  type WBType is record -- write back phase
       c               : Controltype;
       wa              : STD_LOGIC_VECTOR( 4 downto 0);
       pc4,
       aout            : STD_LOGIC_VECTOR(31 downto 0);
  end record;
  
--  type DMemInterface is record
--       wr, signext     : STD_LOGIC;
--       bhw             : AccessType;
--       addr, din, dout : STD_LOGIC_VECTOR(31 downto 0);
--  end record; 
      
end mips_pkg;