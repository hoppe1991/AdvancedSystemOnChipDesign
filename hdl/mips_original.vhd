---------------------------------------------------------------------------------
-- filename: mips.vhd
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

entity mips is -- Pipelined MIPS processor   
  generic ( DFileName : STRING := "../dmem/isort_pipe"; 
            IFileName : STRING := "../imem/isort_pipe");
  port ( clk, reset        : in  STD_LOGIC;
         writedata, dataadr: out STD_LOGIC_VECTOR(31 downto 0);
         memwrite          : out STD_LOGIC        
       );
end;

architecture struct of mips is
 
  signal zero,
         lez, 
         ltz, 
         gtz,
         branch : STD_LOGIC       := '0';
  signal c      : ControlType     := ('0','0','0','0','0','0','0','0','0','0',
                                      '0','0','0','0','0','0',"0000",WORD);
  signal i      : InstructionType := (UNKNOWN, "000000", "00000", "00000", "00000",  --i
                                     "000000", "00000", x"0000", "00" & x"000000");
  signal ID     : IDType := (x"00000000", x"00000000");
  signal EX     : EXType := (
                  ('0','0','0','0','0','0','0','0','0','0','0','0','0','0','0',
                   '0', "0000",WORD), 
                  --Opcode,    opc       rd       rt       rs
                  (UNKNOWN, "000000", "00000", "00000", "00000",  
                  --Funct    Shamt     Imm     BrTarget
                  "000000", "00000", x"0000", "00" & x"000000"),  
                  --wa          a         imm         pc4         rd2        rd2imm
                  "00000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000");
  signal MA     : MAType := (
                  ('0','0','0','0','0','0','0','0','0','0','0','0','0','0','0',
                   '0',"0000",WORD), 
                  (UNKNOWN, "000000", "00000", "00000", "00000",  --i
                  "000000", "00000", x"0000", "00" & x"000000"),
                  "00000",x"00000000",x"00000000",x"00000000",x"00000000",
                  x"00000000",x"00000000",x"00000000",'0','0','0','0');  
  signal WB     : WBType := (
                  ('0','0','0','0','0','0','0','0','0','0','0','0','0','0','0',
                   '0',"0000",WORD), 
                  "00000",x"00000000",x"00000000");
  signal wa, 
         EX_Rd  : STD_LOGIC_VECTOR(4 downto 0) := "00000";   
  signal MA_Rd  : STD_LOGIC_VECTOR(4 downto 0) := "00000";
  signal pc, pcjump, pcbranch, nextpc, pc4, a, signext, b, rd2imm, aluout, 
         wd, rd, rd1, rd2, aout, WB_wd, WB_rd, 
         IF_ir : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
  signal forwardA, 
         forwardB : ForwardType := FromREG;  
         
begin
       
-------------------- Instruction Fetch Phase (IF) -----------------------------

  pc        <= nextpc when rising_edge(clk);  
                               
  pc4       <= to_slv(unsigned(pc) + 4); 

  nextpc    <= MA.pcjump   when MA.c.jump  = '1' else -- j / jal jump addr
               MA.pcbranch when branch     = '1' else -- branch (bne, beq) addr
               MA.a        when MA.c.jr    = '1' else -- jr addr
               pc4;                                   -- pc + 4;        
                           
  imem:        entity work.bram  generic map ( INIT =>  (IFileName & ".imem"))                      
               port map (clk, '0', pc(11 downto 2), (others=>'0'), IF_ir); 
              
-------------------- IF/ID Pipeline Register -----------------------------------

  ID        <= (IF_ir, pc4); -- when rising_edge(clk); 
  
-------------------- Instruction Decode and register fetch (ID) ----------------

  dec:         entity work.decoder
               port map ( ID.ir, i );  

  ctrl:        entity work.control
               port map ( i, c ); 
    
  wa        <= i.Rd   when c.regdst = '1' and c.link = '0'  else   -- R-Type
               i.Rt   when c.regdst = '0' and c.link = '0'  else   -- I-Type, lw
               "11111";                                            -- JAL            
                     
  rf:          entity work.regfile 
               generic map (EDGE => FALLING)
               port map ( clk, WB.c.regwr, i.Rs, i.Rt, WB.wa, WB_wd, rd1, rd2); 
               
  signext   <= X"ffff" & i.Imm  when (i.Imm(15) = '1' and c.signext = '1') else 
               X"0000" & i.Imm;             
               
  a         <= rd1; -- ALU A input multiplexer  
                             
                          
  b         <= rd2; -- ALU B input multiplexer
  
              
-------------------- ID/EX Pipeline Register -----------------------------------

  EX        <= (c, i, wa, a, b, signext, ID.pc4, rd2); -- when rising_edge(clk);

-------------------- Execution Phase (EX) --------------------------------------

  rd2imm    <= EX.imm when EX.c.alusrc ='1' else
               EX.b;
                           
  alu_inst:    entity work.alu(withBarrelShift) 
               port map ( EX.a, rd2imm, EX.c.aluctrl, EX.i.Shamt, aluout, 
                          zero, lez, ltz, gtz); 
               
  -- Effective address calculation              
  pcbranch  <= to_slv(signed(EX.pc4) + signed(EX.imm(29 downto 0) & "00")); 
  
  pcjump    <= EX.pc4(31 downto 28) & EX.i.BrTarget & "00";                
              
-------------------- EX/MA Pipeline Register -----------------------------------
 
  MA       <= (EX.c, EX.i, EX.wa, EX.a, EX.imm, EX.pc4, EX.rd2, 
               pcbranch, pcjump, aluout, zero, lez, ltz, gtz);     
               --when rising_edge(clk);
               
-------------------- Memory Access Phase (MA) ----------------------------------
  
  wd        <= MA.rd2; --b;                         
  aout      <= MA.aluout; 
  
  branch    <= '1'  when (MA.i.Opc = I_BEQ.Opc  and     MA.zero = '1') or 
                         (MA.i.Opc = I_BNE.Opc  and not MA.zero = '1') or
                         (MA.i.Opc = I_BLEZ.Opc and     MA.lez  = '1') or
                         (MA.i.Opc = I_BLTZ.Opc and     MA.ltz  = '1') or
                         (MA.i.Opc = I_BGTZ.Opc and     MA.gtz  = '1') else 
               '0'; 
                              
  dmem:        entity work.bram_be   -- data memory  
               generic map ( EDGE => Falling, FNAME => DFileName)  
               port    map ( clk, MA.c, aout(12 downto 0), wd, WB_rd);                                                           
                        
-------------------- MA/WB Pipeline Register -----------------------------------
  
  WB        <= (MA.c, MA.wa, MA.pc4, aout); -- when rising_edge(clk);
  
-------------------- Write back Phase (WB) -------------------------------------

  WB_wd     <= WB_rd   when WB.c.mem2reg = '1' and WB.c.link = '0' else -- from DMem
               WB.aout when WB.c.mem2reg = '0' and WB.c.link = '0' else -- from ALU
               WB.pc4;                                                  -- ret. Addr 

  writedata <= wd; 
  dataadr   <= aout;     
  memwrite  <= c.memwr;

end;
