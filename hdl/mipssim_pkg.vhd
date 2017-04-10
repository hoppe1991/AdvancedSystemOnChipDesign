--------------------------------------------------------------------------------
-- filename : mips_sim_pkg.vhd
-- author   : Meyer zum Felde, Püttjer, Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;
use STD.TEXTIO.ALL;
use work.CASTS.all;

package mipssim_pkg is
 
	-- The integer array contains 10 integer values.
    type integerArray10 is array (10 downto 0) of INTEGER;    

    type integerArray11 is array (11 downto 0) of INTEGER;


	procedure print_array(intArray : in integerArray10; filename : in STRING);
	procedure print_array(intArray : in integerArray11; filename : in STRING);
end mipssim_pkg;

package body mipssim_pkg is

	-- ----------------------------------------------------------------------
	-- Writes the given integer array into a txt file.
	-- ----------------------------------------------------------------------
	procedure print_array(intArray : in integerArray10; 
		filename : in STRING
	) is		
			variable l			: LINE;
    		file outfile        : TEXT;
    		variable f_status	: FILE_OPEN_STATUS;
	begin
			file_open(f_status, outfile, filename, write_mode);
			for I in intArray'RANGE loop
				write(l, INTEGER'IMAGE(intArray(I)));
				write(l, string'(";"));
			end loop;
			WRITELINE(outfile, l);
			file_close(outfile);
	end;

	-- ----------------------------------------------------------------------
	-- Writes the given integer array into a txt file.
	-- ----------------------------------------------------------------------
	procedure print_array(intArray : in integerArray11; 
		filename : in STRING
	) is		
			variable l			: LINE;
    		file outfile        : TEXT;
    		variable f_status	: FILE_OPEN_STATUS;
	begin
			file_open(f_status, outfile, filename, write_mode);
			for I in intArray'RANGE loop
				write(l, INTEGER'IMAGE(intArray(I)));
				write(l, string'(";"));
			end loop;
			WRITELINE(outfile, l);
			file_close(outfile);
	end;
		
end mipssim_pkg;