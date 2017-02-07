--------------------------------------------------------------------------------
-- filename : cacheController.vhd
-- author   : Hoppe
-- company  : TUHH
-- revision : 0.1
-- date     : 24/01/17
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity cacheController is
  generic (
            DATAWIDTH     : INTEGER := 32;  -- Length of instruction/data words.
            BLOCKSIZE     : INTEGER := 4;  -- Number of words that a block contains.
            ADDRESSWIDTH  : INTEGER := 256;   -- Number of cache blocks.
            OFFSET        : INTEGER := 8;    -- Number of bits that can be selected in the cache.
            TagFileName   : STRING  := "../imem/tagFileName";
            DataFileName  : STRING  := "../imem/dataFileName"
          );

  port (
    clk       : in    STD_LOGIC;
    reset     : in    STD_LOGIC;

    stallCPU  : out    STD_LOGIC;
    rdCPU     : in    STD_LOGIC;
    wrCPU     : in    STD_LOGIC;
    addrCPU   : in    STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0 );
    dataCPU   : inout STD_LOGIC_VECTOR( OFFSET-1 downto 0 );

    readyMEM  : in    STD_LOGIC;
    rdMEM     : out   STD_LOGIC;
    wrMEM     : out   STD_LOGIC;
    addrMEM   : out   STD_LOGIC_VECTOR( DATAWIDTH-1 downto 0 );
    dataMEM   : inout STD_LOGIC_VECTOR( OFFSET-1 downto 0 )
   );

end;


architecture synth of cacheController is

  type statetype is (
          IDLE,
          CW,
          CMW,
          WBW,
          WCW,

          CR,
          CMR,
          WBR,
          WCR
  );

  signal state, nextstate: statetype;

  signal cacheHit : STD_LOGIC := '0';
  signal isDirty : STD_LOGIC := '0';

  signal dataCPUIn : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
  signal dataCPUOut : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
  signal dataMEMIn : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
  signal dataMEMOut : STD_LOGIC_VECTOR( OFFSET-1 downto 0 ) := (others => '0');
  signal rd : STD_LOGIC := '0';
  signal wr : STD_LOGIC := '0';
  signal valid : STD_LOGIC := '0';
  signal dirty : STD_LOGIC := '0';
  signal hit : STD_LOGIC := '0';
  signal wrCacheBlockLine : STD_LOGIC := '0';

begin

cache : entity work.directMappedCache
        generic map (
            DATA_WIDTH => DATAWIDTH,
            BLOCKSIZE => BLOCKSIZE,
            ADDRESSWIDTH => ADDRESSWIDTH,
            OFFSET => OFFSET,
            TagFileName => TagFileName,
            DataFileName => DataFileName
        )
        port map( clk => clk,
                  dataCPUIn => dataCPUIn,
                  addrCPU => addrCPU,
                  dataCPUOut => dataCPUOut,
                  dataMEMIn => dataMemIn,
                  dataMEMOut => dataMemOut,
                  rd => rd,
                  wr => wr,
                  valid => valid,
                  dirty => dirty,
                  hit => hit,
                  wrCacheBlockLine => wrCacheBlockLine
        );



  -- state register
  state <= IDLE when reset='1' else
           nextstate when rising_edge(clk);

  transition_logic: process( state )
  begin
    case state is
      when IDLE =>
           if wrCPU='1' then nextstate <= CW;
           elsif rdCPU='1' then nextstate <= CR;
           end if;

      when CW =>
          if cacheHit='1' then nextstate <= IDLE;
          elsif cacheHit='0' then nextstate <= CMW;
          end if;

      when CMW =>
          if isDirty='1' then nextstate <= WBW;
          elsif isDirty='0' then nextstate <= WCW;
          end if;

      when WBW =>
          if readyMEM='0' then nextstate <= WBW;
          elsif readyMEM='1' then nextstate <= WCW;
          end if;

      when WCW =>
          if readyMEM='0' then nextstate <= WCW;
          elsif readyMEM='1' then nextstate <= IDLE;
          end if;

      when CR =>
         if cacheHit='1' then nextstate <= IDLE;
         elsif cacheHit='0' then nextstate <= CMR;
         end if;

      when CMR =>
         if isDirty='1' then nextstate <= WBR;
         elsif isDirty='0' then nextstate <= WCR;
         end if;

      when WBR =>
         if readyMEM='0' then nextstate <= WBR;
         elsif readyMEM='1' then nextstate <= WCR;
         end if;

      when WCR =>
         if readyMEM='0' then nextstate <= WCR;
         elsif readyMEM='1' then nextstate <= IDLE;
         end if;

      when others => nextstate <= IDLE;
    end case;
  end process;


  -- Output logic.
  dataCPUIn <= dataCPUIn when ( cacheHit='1' and state=CW );
  wr <= '1' when ( cacheHit='1' and state=CW );

  stallCPU <= '1' when ( cacheHit='0' and state=CW ) else
              '1' when ( cacheHit='0' and state=CR ) else
              '0';

  wrMEM <= '1' when ( isDirty='1' and state=CMW ) else
           '1' when ( isDirty='1' and state=CMR ) else
           '0';

  rdMEM <= '1' when ( isDirty='1' and state=CMW ) else
           '1' when ( readyMEM='1' and state=WBW ) else
           '1' when ( readyMEM='1' and state=CMW ) else
           '1' when ( isDirty='0' and state=CMR ) else
           '1' when ( readyMEM='1' and state=WBR ) else
           '1' when ( readyMEM='1' and state=WCR ) else
           '0';

  dataCPU <= dataCPUOut when ( cacheHit='1' and state=CR );

end synth;
