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
use work.global_pkg.all;


entity mips is -- Pipelined MIPS processor
  generic ( DFileName 			: STRING := "../dmem/isort_pipe";
            IFileName 			: STRING := "../imem/isort_pipe";
	        TAG_FILENAME 		: STRING := "../imem/tagCache";
			DATA_FILENAME		: STRING := "../imem/dataCache";
			FILE_EXTENSION		: STRING := ".imem"
            );
  port ( clk, reset        : in  STD_LOGIC;
         writedata, dataadr: out STD_LOGIC_VECTOR(31 downto 0);
         memwrite          : out STD_LOGIC
       );
end;

architecture struct of mips is

	-- Signals regarding instruction cache.
	constant MEMORY_ADDRESS_WIDTH	: INTEGER := 32;
	constant DATA_WIDTH 			: INTEGER := 32;
	constant BLOCKSIZE 				: INTEGER := 4;
	constant ADDRESSWIDTH         	: INTEGER := 256;
	constant OFFSET               	: INTEGER := 8;
	constant BRAM_ADDR_WIDTH		: INTEGER := 10; -- (11 downto 2) pc
	
	-- Signals count cache hits and cache misses.
	signal hitCounter, missCounter : INTEGER := 0;
	
	-- 
	signal stallFromCache : STD_LOGIC := '0';
	
	--
	signal pc : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');
	
	--
	signal IF_ir : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others=>'0');
	
	
	-- Signals regarding main memory.
	signal readyMEM 	: STD_LOGIC := '0';
	signal addrMEM      : STD_LOGIC_VECTOR(MEMORY_ADDRESS_WIDTH-1 downto 0) := (others=>'0');	
	signal rdMEM, wrMEM : STD_LOGIC := '0';
	signal dataMEM		: STD_LOGIC_VECTOR(BLOCKSIZE * DATA_WIDTH - 1 downto 0);
	
<<<<<<< HEAD
=======
	signal stallFromCache 	: STD_LOGIC := '0';
  	signal stallFromCPU		: STD_LOGIC := '0';
	--signal stallCPU 		: STD_LOGIC := '0';

  signal zero,
         lez,
         ltz,
         gtz,
         branch : STD_LOGIC       := '0';
  
  signal c      : ControlType     	:= INIT_CONTROLTYPE;
  signal i      : InstructionType 	:= INIT_INSTRUCTIONTYPE;
  signal ID     : IDType 			:= INIT_IDTYPE;
  signal EX     : EXType 			:= INIT_EXTYPE;
  signal MA     : MAType 			:= INIT_MATYPE;
  signal WB     : WBType 			:= INIT_WBTYPE;
  
  signal wa,
         EX_Rd  : STD_LOGIC_VECTOR(4 downto 0) := "00000";
  signal MA_Rd  : STD_LOGIC_VECTOR(4 downto 0) := "00000";
  signal pc, pcjump, pcbranch, nextpc, pc4, pc_Jump_BRAM_Adapted, 
  		 pc_Jump_BRAM_Adapted_PredictedAT, 
  		 pc_Jump_BRAM_Adapted_PredictedNT, 
  		 a, signext, b, rd2imm, aluout,
         wd, rd, rd1, rd2, aout, WB_wd, WB_rd,
         IF_ir : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
                  
  signal forwardA,
         forwardB : ForwardType := FromREG;
  signal WB_Opc  ,WB_Func   : STD_LOGIC_VECTOR(5 downto 0) := "000000";
                  
                  
  -- Setting whether the static branch prediction assumes "branch always taken" (1) or "branch never taken" (0)
  signal StaticBranchAlwaysTaken : STD_LOGIC := '1'; 
  signal freezingPC : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
  signal pcbranchIDPhase, pcjumpIDPhase, nextpcPredicted : STD_LOGIC_VECTOR(31 downto 0) := ZERO32;
  signal branchIdPhase, branchIDPhase_History: STD_LOGIC := '0';
  signal branchNotTaken, predictionError : STD_LOGIC := '0';

>>>>>>> origin/branchTask5_staticPrediction
begin
 
	  globalHitCounter <= hitCounter;

<<<<<<< HEAD
 
 
 
 
	-- ------------------------------------------------------------------------------------------
	-- Controller of mips.
	-- ------------------------------------------------------------------------------------------
	mipsContr: entity work.mipsController
		generic map(
			MEMORY_ADDRESS_WIDTH 	=> MEMORY_ADDRESS_WIDTH,
			DFileName     			=> DFileName
		)
		port map(
			clk            => clk,
			writedata      => writedata,
			dataadr        => dataadr,
			memwrite       => memwrite,
			hitCounter     => hitCounter,
			missCounter    => missCounter,
			stallFromCache => stallFromCache,
			IF_ir		   => IF_ir,
			pcToCache	   => pc
		);
 
=======
	-- Determine whether to stall the CPU or not.
	--stallCPU <= stallFromCache ;--or stallFromCPU;


-------------------- Instruction Fetch Phase (IF) -----------------------------
  --pc        <= nextpc when rising_edge(clk);
  pc        <= nextpcPredicted when rising_edge(clk);
  pc4       <= to_slv(unsigned(pc) + 4) ;


	branchIDPhase_History <= branchIDPhase when rising_edge(clk);

  	-- New prediction of the next PC for branch prediction
  	nextpcPredicted    <=	pc_Jump_BRAM_Adapted_PredictedAT	when StaticBranchAlwaysTaken = '0' and predictionError = '1' 	else --normal behaviour if no branch taken
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
                  	
	-- Determine the next PC in case of jump / branch in MA phase since BRAM insertion. Old treatment of the next PC before branch prediction but with bram and cache

		  nextpc	<=		to_slv(unsigned(MA.pcjump) + 0)   when MA.c.jump  = '1' else -- j / jal jump addr
              				to_slv(unsigned(MA.pcbranch) + 4) when branch     = '1' else -- branch (bne, beq) addr
              				to_slv(unsigned(MA.a) + 4)        when MA.c.jr    = '1' else -- jr addr
		                	freezingPC;

	-- The conditions below cause the program counter to stop increasing (freezing the PC)   
	freezingPC		    <=  pc4		when (stallFromCache='0' and stallFromCPU = '0') else
		                	pc		when (stallFromCache='1' or stallFromCPU = '1') else
		                	pc4	; -- standard case: pc + 4, take following instruction;
		                	
 	-- Signal to recognize whether a branch command is in ID phase     				
  branchIdPhase		<= '1'  when 
  							((i.Opc = I_BEQ.Opc) and (EX.i.Opc /= I_BEQ.Opc) and (MA.i.Opc /= I_BEQ.Opc)) 	or
                       		((i.Opc = I_BNE.Opc) and (EX.i.Opc /= I_BNE.Opc) and (MA.i.Opc /= I_BNE.Opc)) 	or
                         	((i.Opc = I_BLEZ.Opc) and (EX.i.Opc /= I_BLEZ.Opc)) or	--not currently used in asm files
                         	((i.Opc = I_BLTZ.Opc) and (EX.i.Opc /= I_BLTZ.Opc)) or	--not currently used in asm files
                         	((i.Opc = I_BGTZ.Opc) and (EX.i.Opc /= I_BGTZ.Opc))	else--not currently used in asm files
               				'0';

>>>>>>> origin/branchTask5_staticPrediction
	-- ------------------------------------------------------------------------------------------
	-- Instruction cache.
	-- ------------------------------------------------------------------------------------------
	imemCache: entity work.cache
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			DATA_WIDTH           => DATA_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			ADDRESSWIDTH         => ADDRESSWIDTH,
			OFFSET               => OFFSET,
			TAG_FILENAME         => TAG_FILENAME,
			DATA_FILENAME        => DATA_FILENAME,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			reset       => reset,
			hitCounter  => hitCounter,
			missCounter => missCounter,
			stallCPU    => stallFromCache,
			rdCPU       => '1',
			wrCPU       => '0',
			addrCPU     => pc,
			dataCPU     => IF_ir,
			readyMEM    => readyMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			addrMEM     => addrMEM,
			dataMEM     => dataMEM
		);

	-- ------------------------------------------------------------------------------------------
	-- Main memory unit.
	-- ------------------------------------------------------------------------------------------
	MMU : entity work.mainMemory
		generic map(
			MEMORY_ADDRESS_WIDTH => MEMORY_ADDRESS_WIDTH,
			BLOCKSIZE            => BLOCKSIZE,
			DATA_WIDTH           => DATA_WIDTH,
			BRAM_ADDR_WIDTH		 => BRAM_ADDR_WIDTH,
			DATA_FILENAME        => IFileName,
			FILE_EXTENSION       => FILE_EXTENSION
		)
		port map(
			clk         => clk,
			readyMEM    => readyMEM,
			addrMEM     => addrMEM,
			rdMEM       => rdMEM,
			wrMEM       => wrMEM,
			dataMEM  	=> dataMEM,
			reset       => reset
		);
		
end;