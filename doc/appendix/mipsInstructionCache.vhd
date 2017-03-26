-- ------------------------------------------------------------
-- Instruction cache.
-- ------------------------------------------------------------
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

--  imem:   entity work.bram  generic map ( INIT =>  (IFileName & ".imem"))
--          port map (clk, '0', pc(11 downto 2), (others=>'0'), IF_ir);
