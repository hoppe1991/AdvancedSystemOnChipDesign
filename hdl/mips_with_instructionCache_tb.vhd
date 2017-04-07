---------------------------------------------------------------------------------
-- filename: mips_tb.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use work.CASTS.all;
use work.global_pkg.all;
use STD.TEXTIO.ALL;
use IEEE.std_logic_textio.all;

entity mips_with_instructionCache_tb is
  generic (DFileName : string := "../dmem/isort_pipe";
           IFileName : string := "../imem/isort_pipe";
           TAG_FILENAME 		: STRING := "../imem/tagCache";
		   DATA_FILENAME		: STRING := "../imem/dataCache";
		   FILE_EXTENSION		: STRING := ".imem"
           );
end;

architecture test of mips_with_instructionCache_tb is
	
	signal writedata, dataadr   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	signal clk, reset			: STD_LOGIC := '0';
	signal memwrite, memwrite_i : STD_LOGIC := '0';
  	--signal t                 :  STD_LOGIC_VECTOR(1 downto 0):="10";
	signal writedataI			: INTEGER := 0;
	signal dataadrI				: INTEGER := 0;
	
	
	
    constant ADDR_WIDTH     : integer  := 11;
    signal addr : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others=>'0');
    signal addrI : INTEGER := 0;
    
    
    impure function RETURN_WRITEDATAINTEGER return INTEGER is 
    begin
    	
    	for I in writedata'RANGE loop
    	if writedata(I)/='0' and writedata(I)/='1' then
    		report "WARNING" severity NOTE;
    		return 0;
    	end if;
    	end loop;
    	return to_i(writedata);
    end;
    
    
    type integerArray is array (9 downto 0) of INTEGER;
  	signal writeDataArray: integerArray := (others => 0);

	impure function PUSH_INTEGER(int : in INTEGER) return integerArray is
		variable a : integerArray;
	begin
		for I in 9 downto 1 loop
			a(I) := writeDataArray(I-1);
		end loop;
		a(0) := int;
		
		return a;
	end;
	
	



begin

	memwrite_i <= memwrite when rising_edge(clk); 


  -- instantiate device to be tested
  dut: entity work.mips
       generic map(DFileName => DFileName, IFileName => IFileName, 
       	TAG_FILENAME => TAG_FILENAME, DATA_FILENAME=> DATA_FILENAME, 
       	FILE_EXTENSION => FILE_EXTENSION
       )
       port map(clk, reset, writedata, dataadr, memwrite);

  -- Generate clock with 10 ns period
  process begin
    clk <= '1';
    wait for 5 ns; 
    clk <= '0';
    wait for 5 ns;
  end process;



	addr <= dataadr(ADDR_WIDTH+1 downto 2) when memwrite_i='1' and memwrite='0';
	addrI <= to_i(addr);
	writedataI <= to_i(writedata) when memwrite_i='1' and memwrite='0';
	

	process(memwrite_i) is
		
		procedure print_array is
			
			variable l : LINE;
    		file outfile         : text;
    		variable f_status: FILE_OPEN_STATUS;
		begin
			 
			
			file_open(f_status, outfile, "mySimulation.txt", write_mode);
			for I in writeDataArray'RANGE loop
				write(l, INTEGER'IMAGE(writeDataArray(I)));
				write(l, string'(";"));
			end loop;
			WRITELINE(outfile, l);
			file_close(outfile);
			
		end;
		
			
		
	begin
	
	if memwrite_i='1' then
		writeDataArray <= PUSH_INTEGER(writedataI);	
		report "write data: " & INTEGER'IMAGE(writedataI);
	    report "address: " & INTEGER'IMAGE(addrI); 
	    print_array;
	    report "----------------------------------";
	end if;
	
	end process;
    	


  -- Generate reset for first two clock cycles
  process is 
   
  begin
  	
  	reset <= '1';
	wait until rising_edge(clk);
    reset <= '0';
     

    
    wait;
     

--    reset <= '0';
--    wait for 2 ns;
--    reset <= '1';
--    wait for 20 ns;
--    reset <= '0';
--    wait;
end process;

process is
begin
	
	wait for 35 us;
	
	assert writeDataArray(0)=5 report "ERROR" severity FAILURE;
	assert writeDataArray(1)=10 report "ERROR" severity FAILURE;
	assert writeDataArray(2)=10 report "ERROR" severity FAILURE;
	assert writeDataArray(3)=20 report "ERROR" severity FAILURE;
	assert writeDataArray(4)=25 report "ERROR" severity FAILURE;
	assert writeDataArray(5)=30 report "ERROR" severity FAILURE;
	assert writeDataArray(6)=30 report "ERROR" severity FAILURE;
	assert writeDataArray(7)=40 report "ERROR" severity FAILURE;
	assert writeDataArray(8)=50 report "ERROR" severity FAILURE;
	assert writeDataArray(9)=60 report "ERROR" severity FAILURE;
	report "test successfully.";
end process;


	
  -- check that 7 gets written to address 84 at end of program
--  process (clk) begin
--    if (clk'event and clk = '0' and memwrite = '1') then
--      if (to_integer(dataadr) = 84 and to_integer(writedata) = 7) then 
--        report "NO ERRORS: Simulation succeeded" severity failure;
--      --elsif (dataadr = x"50") then 
--      --  report "Simulation failed" severity failure;
--      end if;
--    end if;
--  end process;
end;
