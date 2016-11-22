---------------------------------------------------------------------------------
-- DMemFile: ram.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all; -- VHDL2008 lib
use STD.textio.all;

entity convertMemFiles is 
  generic ( DMemLen   : integer:= 2048;
            IMemLen   : integer:= 1024;
            DFileName : string := "../dmem/isort";
            IFileName : string := "../imem/dhazard_lw"
                                  --"../imem/shift"
                                  --"../imem/dhazard" 
                                  --"../imem/isort_pipe2"
          );
            
end;

architecture behav of convertMemFiles is
begin  

  process   
    
    file dmemfile      : TEXT open READ_MODE   is DFileName & ".dmem";
    file imemfile0     : TEXT open READ_MODE   is IFileName & ".imem";
    file imemfile1     : TEXT open APPEND_MODE is IFileName & ".imem";
    file dmemfile0     : TEXT open WRITE_MODE  is DFileName & "0.dmem";
    file dmemfile1     : TEXT open WRITE_MODE  is DFileName & "1.dmem";
    file dmemfile2     : TEXT open WRITE_MODE  is DFileName & "2.dmem";
    file dmemfile3     : TEXT open WRITE_MODE  is DFileName & "3.dmem";
    variable li0, li1,
             ld0, ld1,
             ld2, ld3,
             ld        : LINE;
    variable v         : STD_LOGIC_VECTOR(31 downto 0);
    variable is_string : BOOLEAN;  
    variable i,k       : INTEGER; 
    variable xoo       : STD_LOGIC_VECTOR( 7 downto 0) := x"00";  
    variable xoooooooo : STD_LOGIC_VECTOR(31 downto 0) := x"00000000"; 
         
  begin
    --write(li0, string'("reading IMEM file"));
    --writeline(output, l);
    i := 0;
    while not endfile(imemfile0) loop
      readline(imemfile0, li0);
      i:= i+1;
    end loop;  
--    write(li0, integer'(i));
--    writeline(output, li0);
    for j in 0 to IMemLen-1-i loop
      hwrite(li1, xoooooooo);
      writeline(imemfile1, li1);
    end loop;
    
--    write(l, string'("reading DMEM file"));
--    writeline(output, l);
      k := 0;
    while not endfile(dmemfile) loop
      readline(dmemfile, ld0);
      hread(ld0, v, is_string);
      hwrite(ld0, v( 7 downto  0));
      writeline(dmemfile0, ld0);
      hwrite(ld0, v(15 downto  8));
      writeline(dmemfile1, ld0);
      hwrite(ld0, v(23 downto 16));
      writeline(dmemfile2, ld0);
      hwrite(ld0, v(31 downto 24));
      writeline(dmemfile3, ld0);
      k:= k+1;                
    end loop;
    for j in 0 to DMemLen-1-k loop
      hwrite(ld1, xoo);
      writeline(dmemfile0, ld1);
      hwrite(ld1, xoo);
      writeline(dmemfile1, ld1);
      hwrite(ld1, xoo);
      writeline(dmemfile2, ld1);
      hwrite(ld1, xoo);
      writeline(dmemfile3, ld1);
    end loop;
    wait;
  end process;
  
end architecture;