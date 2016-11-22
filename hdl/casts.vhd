---------------------------------------------------------------------------------
-- filename: casts.vhd
-- author  : Wolfgang Brandt
-- company : TUHH, Institute of embedded systems
-- revision: 0.1
-- date    : 26/11/15   
---------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.NUMERIC_STD.all;

package CASTS is

  function TO_I  (ARG: in STD_LOGIC_VECTOR) return NATURAL;
  function TO_SLV(ARG: in UNSIGNED)         return STD_LOGIC_VECTOR;
  function TO_SLV(ARG: in SIGNED)           return STD_LOGIC_VECTOR;
  function TO_STR(ARG: in STD_LOGIC_VECTOR) return STRING;

end;

package body CASTS is

  function TO_I(ARG: in STD_LOGIC_VECTOR) return NATURAL IS     
  begin     
    return TO_INTEGER(UNSIGNED(ARG));    
  end; 
  
  function TO_SLV(ARG: in UNSIGNED) return STD_LOGIC_VECTOR IS     
  begin     
    return STD_LOGIC_VECTOR(ARG);    
  end;
  
  function TO_SLV(ARG: in SIGNED) return STD_LOGIC_VECTOR IS     
  begin     
    return STD_LOGIC_VECTOR(ARG);    
  end;   

  function TO_STR(ARG: in STD_LOGIC_VECTOR) return STRING is
    variable S : STRING (ARG'length-1 downto 1) := (others => NUL);
  begin
        for i in ARG'length-1 downto 1 loop
          S(i) := STD_LOGIC'image(ARG((i-1)))(2);
        end loop;
    return S;
  end function;
  
end;  
