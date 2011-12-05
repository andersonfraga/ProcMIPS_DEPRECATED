  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use ieee.std_logic_arith.all;
  use work.p_MI0.ALL;  --pacote com as declara��es utilizadas no processador

  ENTITY Processador_TB IS
  END Processador_TB;

  ARCHITECTURE behavior OF Processador_TB IS           
  signal Inst_in, Inst_address, posicaoMem, ula_op1, ula_op2, ula_out: reg32;
  signal Inst_load, Inst_read, clock, regWrite, memWrite: std_logic;
  signal outDados, outInst: memory; -- para acompanhar a mem�ria de dados e de instru��es
  signal regOut: bank; -- para acompanhar o banco de registradores
  
  BEGIN
  -- Instancia��o da UUT
          uut: entity work.Processador PORT MAP(
				Inst_in=>Inst_in, Inst_address=>Inst_address,
				Inst_load=>Inst_load, Inst_read=>Inst_read, clock=>clock,
				outInst=>outInst, outDados=>outDados, 
				posicaoMem=>posicaoMem, regOut=>regOut,
				ula_op1=>ula_op1, ula_op2=>ula_op2, ula_out=>ula_out,
				outregWrite=>regWrite, outmemWrite=>memWrite
          );
			 
    p_clock: process -- gera o clock                         
        begin
        clock <= '0', '1' after 2 ns;
        wait for 4 ns;
    end process p_clock;			 

     tb : PROCESS
     BEGIN
	     
		Inst_read<='0';
		Inst_load<='1'; --come�a a carga das instru��es na mem�ria

		Inst_address<= conv_std_logic_vector(0,32); 
		Inst_in<=x"2673000A";   --00100110011100110000000000001010	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(1,32); 
		Inst_in<=x"26940001";   --00100110100101000000000000000001	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(2,32); 
		Inst_in<=x"27ff000c";	--00100111111111110000000000001100		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(3,32); 
		Inst_in<=x"0260A82A";	--00000010011 00000 10101 00000101010	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(4,32); 
		Inst_in<=x"12b40004";	--00010010101101000000000000000100	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(5,32); 
		Inst_in<=x"0013b080";	--00000000000100111011000010000000	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(6,32); 
		Inst_in<=x"AE760000";	--101011 10011 10110 0000000000000000	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(7,32); 
		Inst_in<=x"02749823";	--00000010011101001001100000100011	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(8,32); 
		Inst_in<=x"03e00008";	--00000011111000000000000000001000		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(9,32); 
		Inst_in<=x"3c08000a";	--001111 0000001000 0000000000001010	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(10,32); 
		Inst_in<=x"3509000a";	--00110101000010010000000000001010		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(11,32); 
		Inst_in<=x"00098402";	--00000000000010011000010000000010		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(12,32); 
		Inst_in<=x"26310001";	--00100110001100010000000000000001		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(13,32); 
		Inst_in<=x"27ff002c";	--00100111111111110000000000101100		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(14,32); 
		Inst_in<=x"0200402a";	--00000010000000000100000000101010		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(15,32); 
		Inst_in<=x"11110007";	--00010001000100010000000000000111		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(16,32); 
		Inst_in<=x"00105880";	--00000000000100000101100010000000		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(17,32); 
		Inst_in<=x"8E0C0000";	--100011 10000 011000000000000000000	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(18,32); 
		Inst_in<=x"000c6042";	--00000000000011000110000001000010		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(19,32); 
		Inst_in<=x"258c0001";	--00100101100011000000000000000001	
		Inst_address<= conv_std_logic_vector(20,32); 
		Inst_in<=x"AE0C0000";	--101011 10000 011000000000000000000		
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(21,32); 
		Inst_in<=x"02118023";	--00000010000100011000000000100011	
		wait for 10 ns;
		Inst_address<= conv_std_logic_vector(22,32); 
		Inst_in<=x"03e00008";	--00000011111000000000000000001000	
		wait for 10 ns;
      
		Inst_load<='0';--terminou de carregar		
		Inst_read<='1';--vou resetar
		wait for 10 ns;
		Inst_read<='0';--come�a

		wait;
     END PROCESS tb;

  END;
