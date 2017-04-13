---------------------------------------------------------------------------------
-- filename: mips_controller_task5_btb.vhd
-- author  : Meyer zum Felde, Püttjer, Hoppe
-- company : TUHH
-- revision: 0.1
-- date    : 01/04/17 
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.mips_pkg.all;
use work.casts.all;

---------------------------------------------------------------------------------
-- Entity controls the behavior of the MIPS regarding task sheet 5.
---------------------------------------------------------------------------------
entity mips_controller_task5_btb is -- Pipelined MIPS processor
    generic ( DFileName 			: STRING := "../dmem/isort_pipe";
			MEMORY_ADDRESS_WIDTH	: INTEGER := 32-- Width of memory address.
            );
  port (
  		clk, reset        : in  STD_LOGIC;
        writedata, dataadr: out STD_LOGIC_VECTOR(31 downto 0);
        memwrite          : out STD_LOGIC;
        
        -- Indicates whether the instruction cache stalls ('1') the CPU or not ('0').
        stallFromCache		: in STD_LOGIC;
        
        -- PC send to instruction cache.
        pcToCache			: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
        
        -- Instruction to be read from or written to instruction cache.
        IF_ir 				: inout STD_LOGIC_VECTOR(31 downto 0);
        
        -- Branch prediction calculated from BHT.
        predictionFromBHT	: in STD_LOGIC := '0';
        
        -- Signal indicates whether the branch is taken or not.
        branchTaken 		: out STD_LOGIC := '0';
        
        -- Signal indicates whether the BHT should be rewritten.
        writeEnableBHT 		: out STD_LOGIC := '0';
        
        
        -- New program counter predicted by BTB.
        -- TODO How does the MIPS use this signal?
        targetPCFromBTB	: STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
        
        -- Signal indicates whether the predicted program counter from BTB is valid ('1') or not ('0').
        -- TODO How does the MIPS use this signal?
        targetPCIsValidFromBTB : in STD_LOGIC := '0';
        
  		-- Signlal 
  		dataWriteID	: out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
 		
 		-- Siganl 
 		dataWriteEX    : out STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0);
  		
  		-- Signal
  		writeEnableID  : out STD_LOGIC;
  		
  		-- Signal
  		writeEnableEX  : out STD_LOGIC
       );
end;
---------------------------------------------------------------------------------
-- Entity controls the behavior of the MIPS regarding task sheet 5.
---------------------------------------------------------------------------------
architecture struct of mips_controller_task5_btb is
 
  	signal stallFromCPU		: STD_LOGIC := '0';
	--signal stallCPU 		: STD_LOGIC := '0';
	
	signal zero,
           lez,
           ltz,
           gtz,
           branch : STD_LOGIC       := '0';
     
    signal c      : ControlType     := INIT_CONTROLTYPE;
  	signal i      : InstructionType := INIT_INSTRUCTIONTYPE;
  	signal ID     : IDType 			:= INIT_IDTYPE;
  	signal EX     : EXType 			:= INIT_EXTYPE;
  	signal MA     : MAType 			:= INIT_MATYPE;
  	signal WB     : WBType 			:= INIT_WBTYPE;
	
	signal wa	  : STD_LOGIC_VECTOR(4 downto 0) := "00000";
  	signal pc, pcjump, pcbranch, nextpc, oldPc, pc4, a, signext, b, rd2imm, aluout,
           wd, rd, rd1, rd2, aout, WB_wd, WB_rd,
           pc_Jump_BRAM_Adapted_PredictedNT,
           pc_Jump_BRAM_Adapted_PredictedAT,
           freezingPC : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
    signal forwardA,
           forwardB : ForwardType := FromREG;
	signal WB_Opc  ,WB_Func   : STD_LOGIC_VECTOR(5 downto 0) := "000000";

  	signal StaticBranchAlwaysTaken : STD_LOGIC := '0';
  	signal pcbranchIDPhase, pcjumpIDPhase, nextpcPredicted : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
  	signal branchIdPhase, branchIDPhase_History : STD_LOGIC := '0';
  	--TODO Remove debug signals
  	signal branchNotTaken, predictionError, predictionError2, predictionError3 : STD_LOGIC := '0';

  	signal predictionFromBHT2 : STD_LOGIC := '0';
  	signal readyToWriteBHT	: STD_LOGIC := '0';
  	
  	signal writeEnableBHT_i	: STD_LOGIC := '0';
  	
  	signal dontStallFromBTB : STD_LOGIC := '0';
  	signal counter : INTEGER := 0;
  	
begin
	
	StaticBranchAlwaysTaken <= '1' when (predictionFromBHT='1') else
							   '0' when (predictionFromBHT='0') ;
	
	-- TODO Correct?
	-- Write into BHT whenever a branch command is fetched and decoded
	writeEnableBHT_i <=	'1'	when i.Opc = I_BEQ.OPC	and readyToWriteBHT = '1'	and stallFromCPU = '0'	else
  						'1' when i.Opc = I_BNE.OPC	and readyToWriteBHT	= '1'	and stallFromCPU = '0'	else
  						'0';
  	
  	-- Allow 1 write cycle for each branch instruction					
	readyToWriteBHT	<=	'1' when	pc /= oldPc				and rising_edge(clk) else
						'0'	when	writeEnableBHT_i = '1'	and rising_edge(clk);
	
	-- Determine whether to stall the CPU or not.
	--stallCPU <= stallFromCache ;--or stallFromCPU;

-------------------- Instruction Fetch Phase (IF) -----------------------------

	-- -----------------------------------------------------------
	-- Logic to compute the words given to BTB.
	--
	-- The BTB is read at the IF stage for prediction and 
	-- written in either ID stage (jump) or EX stage (branch).
	-- -----------------------------------------------------------
	btbLogic: block
	
	begin 
		
		
		
		-- TODO Update the logic of these signals.
		-- TODO Is is possible to place this signal logic into entity of BTB?
		
		dataWriteID		<= pcJumpIDPhase;
 		writeEnableID  	<= '1' when (i.Opc=I_J.Opc 								and EX.i.Opc/=I_J.Opc									) else
 						   '1' when (i.Opc=I_JAL.Opc							and EX.i.Opc/=I_JAL.Opc									) else
 						   '1' when (i.Opc=I_JALR.Opc and i.Funct=I_JALR.Funct	and EX.i.Opc/=I_JALR.Opc and EX.i.Funct/=I_JALR.Funct	) else
 						   '1' when (i.Opc=I_JR.Opc   and i.Funct=I_JR.Funct	and EX.i.Opc/=I_JR.Opc   and EX.i.Funct=I_JR.Funct		) else
 						   '0';

		dataWriteEX	 	<= pc_Jump_BRAM_Adapted_PredictedAT;
  		writeEnableEX 	<= '1' when ((EX.a  = EX.b)  and EX.i.Opc = I_BEQ.Opc) else
						   '1' when ((EX.a /= EX.b) and EX.i.Opc = I_BNE.Opc) else
							'0';
  		
	end block;
	
	-- TODO Is this signal logic necessary?
  	oldPc		<= pc when rising_edge(clk);

	-- -----------------------------------------------------------
	-- Logic to compute the new program counter.
	-- -----------------------------------------------------------
	pcLogic: block
	begin
	
	-- i.Opc       <= instructionWord (31 downto 26);
 -- 		i.Rs        <= instructionWord (25 downto 21);
 -- i.Rt        <= instructionWord (20 downto 16);
 -- i.Rd        <= instructionWord (15 downto 11);
 -- i.shamt     <= instructionWord (10 downto  6);
--  i.Funct     <= instructionWord ( 5 downto  0);    
--  i.Imm       <= instructionWord (15 downto  0);
 -- i.BrTarget  <= instructionWord (25 downto  0);   
	
	
	-- pc        <= nextpc when rising_edge(clk);
	pc        <= nextpcPredicted when rising_edge(clk);
  	pc4       <= to_slv(unsigned(pc) + 4) ;

	--
	branchIDPhase_History <= branchIDPhase when rising_edge(clk);
	
  	-- New prediction of the next PC for branch prediction
  	nextpcPredicted    <=	
  							targetPCFromBTB when targetPCIsValidFromBTB='1' and IF_ir(31 downto 26)=I_J.Opc else
  							--targetPCFromBTB when targetPCIsValidFromBTB='1' and branchIdPhase='1' else
  	
  							pc_Jump_BRAM_Adapted_PredictedAT	when StaticBranchAlwaysTaken = '0' and predictionError = '1' 	else --normal behaviour if no branch taken
  							--nextpc							    when StaticBranchAlwaysTaken = '0' and predictionError = '1' 	else
							pc_Jump_BRAM_Adapted_PredictedNT   	when StaticBranchAlwaysTaken = '0' and c.jump  = '1' 			else -- j / jal jump addr
		              		pc_Jump_BRAM_Adapted_PredictedNT	when StaticBranchAlwaysTaken = '0' and branchIdPhase     = '1' 	else -- branch (bne, beq) addr
		              		pc_Jump_BRAM_Adapted_PredictedNT    when StaticBranchAlwaysTaken = '0' and c.jr    = '1' 			else -- jr addr   
							
							nextpc							    when StaticBranchAlwaysTaken = '1' and predictionError = '1' 	else
  							--pc_Jump_BRAM_Adapted_Predicted 		when StaticBranchAlwaysTaken = '0' 	else -- never jump Not correct: not possible to jump anymore
							pc_Jump_BRAM_Adapted_PredictedAT   	when StaticBranchAlwaysTaken = '1' and c.jump  = '1' 			else -- j / jal jump addr
		              		pc_Jump_BRAM_Adapted_PredictedAT	when StaticBranchAlwaysTaken = '1' and branchIdPhase     = '1' 	else -- branch (bne, beq) addr
		              		pc_Jump_BRAM_Adapted_PredictedAT    when StaticBranchAlwaysTaken = '1' and c.jr    = '1' 			else -- jr addr   
		                	freezingPC;



	pc_Jump_BRAM_Adapted_PredictedNT <=	pc	when (EX.i.mnem = BNE) or (EX.i.mnem = BEQ) else -- keep PC the same if BNE or BEQ occurs in EX phase.
	--  									    pc4 when StaticBranchAlwaysTaken = '0' else -- never jump
										to_slv(unsigned(pcjumpIDPhase) + 0) 	when c.jump  = '1' else -- j / jal jump addr
              						--	to_slv(unsigned(pcbranchIDPhase) + 4) 	when branchIdPhase     = '1' else -- branch (bne, beq) addr
              							to_slv(unsigned(a) + 4)        			when c.jr    = '1' else
              							nextpc; -- jr addr

  	pc_Jump_BRAM_Adapted_PredictedAT <=	pc	when (EX.i.mnem = BNE) or (EX.i.mnem = BEQ) else -- keep PC the same if BNE or BEQ occurs in EX phase.
										to_slv(unsigned(pcjumpIDPhase) + 0) 	when c.jump  = '1' 	else -- j / jal jump addr
              							to_slv(unsigned(pcbranchIDPhase) + 4) 	when branchIdPhase     = '1' and (branchIDPhase /= branchIDPhase_History) else -- branch (bne, beq) addr
              							to_slv(unsigned(a) + 4)        			when c.jr    = '1' ; -- jr addr
            
	-- Determine the next PC in case of jump / branch in MA phase since BRAM insertion.
	-- Old treatment of the next PC before branch prediction but with bram and cache
	nextpc			<=	to_slv(unsigned(MA.pcjump) + 0)   when MA.c.jump  = '1' else -- j / jal jump addr
              			to_slv(unsigned(MA.pcbranch) + 4) when branch     = '1' else -- branch (bne, beq) addr
              			to_slv(unsigned(MA.a) + 4)        when MA.c.jr    = '1' else -- jr addr
		                freezingPC;

	-- The conditions below cause the program counter to stop increasing (freezing the PC)   
	freezingPC		<=  pc4		when (stallFromCache='0' and stallFromCPU = '0') else
		                pc		when (stallFromCache='1' or stallFromCPU = '1') else
		                pc4	; -- standard case: pc + 4, take following instruction;
		    
 	-- Signal to recognize whether a branch command is in ID phase     				
  	branchIdPhase	<= '1'  when 
  							((i.Opc = I_BEQ.Opc) and (EX.i.Opc /= I_BEQ.Opc) and (MA.i.Opc /= I_BEQ.Opc)) 	or
                       		((i.Opc = I_BNE.Opc) and (EX.i.Opc /= I_BNE.Opc) and (MA.i.Opc /= I_BNE.Opc)) 	or
                         	((i.Opc = I_BLEZ.Opc) and (EX.i.Opc /= I_BLEZ.Opc)) or	--not currently used in asm files
                         	((i.Opc = I_BLTZ.Opc) and (EX.i.Opc /= I_BLTZ.Opc)) or	--not currently used in asm files
                         	((i.Opc = I_BGTZ.Opc) and (EX.i.Opc /= I_BGTZ.Opc))	else--not currently used in asm files
               				'0';
   	end block;
   	
--  imem:        entity work.bram  generic map ( INIT =>  (IFileName & ".imem"))
--               port map (clk, '0', pc(11 downto 2), (others=>'0'), IF_ir);

-------------------- IF/ID Pipeline Register -----------------------------------
                                                 
  ID        <=  (IF_ir, pc) when rising_edge(clk);			   
    
-------------------- Instruction Decode and register fetch (ID) ----------------

  dec:         entity work.decoder
               port map ( ID.ir, i );

  ctrl:        entity work.control
               port map ( i, c );

  wa        <= i.Rd   when c.regdst = '1' and c.link = '0'  else   -- R-Type
               i.Rt   when c.regdst = '0' and c.link = '0'  else   -- I-Type, lw
               "11111";                                            -- JAL

  rf:          entity work.regfile
               generic map (EDGE => RISING)
               port map ( clk, WB.c.regwr, i.Rs, i.Rt, WB.wa, WB_wd, rd1, rd2);

  signext   <= X"ffff" & i.Imm  when (i.Imm(15) = '1' and c.signext = '1') else
               X"0000" & i.Imm;
               
 -- Effective address calculation for branch prediction in ID-Phase
  pcbranchIDPhase  <= to_slv(signed(ID.pc4) + signed(signext(29 downto 0) & "00"));

  pcjumpIDPhase    <= ID.pc4(31 downto 28) & i.BrTarget & "00";

-------------------- Multiplexers regarding Forwarding -------------------------
  a <=  rd1 when (ForwardA = fromReg) else
        aluout when (ForwardA = fromALUe) else
        WB_wd when (ForwardA = fromALUm) else
        wd  when (ForwardA = fromMEM);

  b <=  rd2 when (ForwardB = fromReg) else
        aluout when (ForwardB = fromALUe) else
        WB_wd when (ForwardB = fromALUm) else
        wd  when (ForwardB = fromMEM);

-------------------- Hazard Detection and Forward Logic ------------------------
	ForwardA <= fromALUe when ( i.Rs /= "00000" and i.Rs = EX.wa and EX.c.regwr = '1' ) else
            	fromALUm when ( i.Rs /= "00000" and i.Rs = MA.wa and MA.c.regwr = '1' ) else
            	fromMEM  when ( i.Rs /= "00000" and i.Rs = WB.wa and WB.c.regwr = '1' ) else
            	fromReg;

	ForwardB <= fromALUe when ( i.Rt /= "00000" and i.Rt = EX.wa and EX.c.regwr = '1' ) else
            	fromALUm when ( i.Rt /= "00000" and i.Rt = MA.wa and MA.c.regwr = '1' ) else
            	fromMEM  when ( i.Rt /= "00000" and i.Rt = WB.wa and WB.c.regwr = '1' ) else
            	fromReg;

-- Explanation aim is to detect data dependencies by checking registers of consequent commands:
-- if ( (EX.MemRead == 1) // Detect Load in EX stage
-- and (ForwardA==1 or ForwardB==1)) then Stall // RAW Hazard
-- PC needs to be frozen and nops inserted as is instructed by the Stall_disablePC signal below.

	--TODO place in correct part in mips_pkg, it doesnt actually belong here			
	WB_Opc  <= 	MA.i.Opc when rising_edge(clk);
	WB_Func <= 	MA.i.funct when rising_edge(clk); --TODO replace using mips_PKG WB_func, WB_Opc do not belong here

-- The following logic looks for all kinds of jump commands and orders 3 stalls.
-- TODO EX.MemRead is equal to EX.c.mem2reg ?
				
	counter			 <= 2 when (targetPCIsValidFromBTB='1' and IF_ir(31 downto 26)=I_J.Opc) else
					    -- 1 when (targetPCIsValidFromBTB='1' and IF_ir(31 downto 26)=I_JAL.Opc) else
					    counter - 1 when rising_edge(clk) and counter > 0;
					    
	dontStallFromBTB <= '0' when (targetPCIsValidFromBTB='1' and IF_ir(31 downto 26)=I_J.Opc) else
						'1' when (counter=0);
				
				
	stallFromCPU <= 	--'0' when (branchIdPhase = '1' or branchIDPhase_History = '1')  and predictionError = '0' and rising_edge(clk) else
		
		'0' when ( dontStallFromBTB='1' ) else 
		'1' when ( (EX.c.mem2reg = '1') and (ForwardA = fromALUe or ForwardB = fromALUe) ) else
		'1' when ( ((EX.i.Opc = I_J.OPC) or (MA.i.Opc = I_J.OPC)) and dontStallFromBTB='0'	) else
      	'1' when (  (EX.i.Opc = I_JAL.OPC)                                     or (MA.i.Opc = I_JAL.OPC)     or  (WB_Opc = I_JAL.OPC)			) else
      	'1' when ( ((EX.i.Opc = I_JALR.OPC)	and (EX.i.funct = I_JALR.funct))  or ((MA.i.Opc = I_JALR.OPC)   and (MA.i.funct = I_JALR.funct))	) else
        '1' when ( ((EX.i.Opc = I_JR.OPC)   and (EX.i.funct = I_JR.funct))    or ((MA.i.Opc = I_JR.OPC)     and (MA.i.funct = I_JR.funct))		) else
	    '1' when ( (WB_Opc = I_JR.OPC) 		and (WB_Func = I_JR.funct)																			) else		
	    
		-- Some commands have duplicate opc therefore additional information like (funct) is needed. 
		-- Supervisor said, only implement most important commands
	  	'0' when  (ForwardA /= fromALUe)    		and (ForwardB /= fromALUe) 			and (MA.i.Opc = I_LW.OPC) else
		'0' when  ((EX.i.Opc /= I_J.OPC)     		and (MA.i.Opc /= I_J.OPC) 
		       and (EX.i.Opc /= I_JAL.OPC)   		and (MA.i.Opc /= I_JAL.OPC) 
			   and (EX.i.funct /= I_JALR.funct)  	and (MA.i.funct /= I_JALR.funct)
			   and (EX.i.funct /= I_JR.funct)    	and (MA.i.funct /= I_JR.funct)      
			   and rising_edge(clk));

-------------------- ID/EX Pipeline Register with Multiplexer Stalling----------
-- bubble = "0000..." nop command. It will passed on at each Stalling signal

-- TODO Debug and verify working implementation of predectionError and branchTaken signals
 
  predictionError	<=	'1'	when (StaticBranchAlwaysTaken = '1' and (a /= b) 	and i.Opc = I_BEQ.OPC)	else	--assumed to take branch but not taken at BEQ 
  						'1' when (StaticBranchAlwaysTaken = '1' and (a = b) 	and i.Opc = I_BNE.OPC)	else	--assumed to take branch but not taken at BNE 
  						'1' when (StaticBranchAlwaysTaken = '0' and (a = b) 	and i.Opc = I_BEQ.OPC)	else  	--assumed not to take branch but taken at BEQ 
  						'1' when (StaticBranchAlwaysTaken = '0' and (a /= b) 	and i.Opc = I_BNE.OPC)	else	--assumed not to take branch but taken at BNE  						
  						'0';
  			
  branchTaken		<=	'1' when (a = b) 	and i.Opc = I_BEQ.OPC	else							
  						'1' when (a /= b) 	and i.Opc = I_BNE.OPC	else
  						'0';
  						
  predictionError2	<=	'1'	when (predictionFromBHT = '1'	and (a /= b) 	and i.Opc = I_BEQ.OPC)	else
  						'1' when (predictionFromBHT = '0'	and (a = b) 	and i.Opc = I_BEQ.OPC)	else
  						'1' when (predictionFromBHT = '1'	and (a = b) 	and i.Opc = I_BNE.OPC)	else
  						'1' when (predictionFromBHT = '0'	and (a /= b) 	and i.Opc = I_BNE.OPC)	else
  						'0';
  						
  predictionFromBHT2 <= predictionFromBHT when rising_edge(clk);
  
  predictionError3	<=	'1'	when (predictionFromBHT2 = '1'	and (a /= b) 	and i.Opc = I_BEQ.OPC)	else
  						'1' when (predictionFromBHT2 = '0'	and (a = b) 	and i.Opc = I_BEQ.OPC)	else
  						'1' when (predictionFromBHT2 = '1'	and (a = b) 	and i.Opc = I_BNE.OPC)	else
  						'1' when (predictionFromBHT2 = '0'	and (a /= b) 	and i.Opc = I_BNE.OPC)	else
  						'0';
  
  -- TODO Clean Up
  EX  <= 	Bubble when (stallFromCache='1' or stallFromCPU='1' or (predictionError='1' and StaticBranchAlwaysTaken='1')) and rising_edge(clk) else
  			Bubble when (stallFromCache='1' or stallFromCPU='1' or (predictionError='0' and StaticBranchAlwaysTaken='0')) and rising_edge(clk) else
         	(c, i, wa, a, b, signext, ID.pc4, rd2)  when rising_edge(clk);
  --  EX  <= Bubble when (stallFromCache = '1' or stallFromCPU = '1') and rising_edge(clk) else
  --         (c, i, wa, a, b, signext, ID.pc4, rd2)  when rising_edge(clk);
  --  EX        <= (c, i, wa, a, b, signext, ID.pc4, rd2) when rising_edge(clk);

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
               pcbranch, pcjump, aluout, zero, lez, ltz, gtz)
               when rising_edge(clk);

-------------------- Memory Access Phase (MA) ----------------------------------

  wd        <= MA.rd2; --b;
  aout      <= MA.aluout;

-- TODO Are the signals branch and branchNotTaken still needed?
-- A branch command was fetched and in MA-Phase a jump-decision is made.
  branch    <= '1'  when (MA.i.Opc = I_BEQ.Opc  and     MA.zero = '1') or
                         (MA.i.Opc = I_BNE.Opc  and not MA.zero = '1') or
                         (MA.i.Opc = I_BLEZ.Opc and     MA.lez  = '1') or
                         (MA.i.Opc = I_BLTZ.Opc and     MA.ltz  = '1') or
                         (MA.i.Opc = I_BGTZ.Opc and     MA.gtz  = '1') else
               '0';

-- A branch command was fetched and in MA-Phase a jump-decision is made.               
  branchNotTaken    <= '1'  when (MA.i.Opc = I_BEQ.Opc  and     MA.zero = '0') or
                         	(MA.i.Opc = I_BNE.Opc  		and not MA.zero = '0') or
                         	(MA.i.Opc = I_BLEZ.Opc 		and     MA.lez  = '0') or
                         	(MA.i.Opc = I_BLTZ.Opc 		and     MA.ltz  = '0') or
                         	(MA.i.Opc = I_BGTZ.Opc 		and     MA.gtz  = '0') else
               				'0';

  dmem:        entity work.bram_be   -- data memory
               generic map ( EDGE => Falling, FNAME => DFileName)
               port    map ( clk, MA.c, aout(12 downto 0), wd, WB_rd);

-------------------- MA/WB Pipeline Register -----------------------------------

  WB        <= (MA.c, MA.wa, MA.pc4, aout) when falling_edge(clk);
	  
-------------------- Write back Phase (WB) -------------------------------------

  WB_wd     <= WB_rd   when WB.c.mem2reg = '1' and WB.c.link = '0' else -- from DMem
               WB.aout when WB.c.mem2reg = '0' and WB.c.link = '0' else -- from ALU
               WB.pc4;                                                  -- ret. Addr

  writedata 		<= wd;
  dataadr   		<= aout;
  memwrite  		<= c.memwr;
  pcToCache			<= pc;
  writeEnableBHT	<= writeEnableBHT_i;

end;
