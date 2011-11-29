--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Implementar em VHDL uma descrição do processador MIPS (mono-ciclo)
--que implemente o conjunto de instruções
--ADDU, ADDIU, SUBU, ORI, LW, LUI, SLL, SRL, SLT, SW, JR, BEQ

--Como já temos implementadas as instruções
--ADDU, SUBU, AAND, OOR, XXOR, NNOR, LW, SW, ORI

--Vamos implementar
--ADDIU Add immediate unsigned (no overflow)
--LUI Load upper immediate
--SLL Shift left logical
--SRL Shift right logical
--SLT Set on less than (signed)
--JR Jump register
--BEQ Branch on equal

--Precisa ser SSLL e SSRL pois SLL e SRL são funções do VHDL
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- package com tipos básicos
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;

package p_MI0 is

  subtype reg32 is std_logic_vector(31 downto 0);
  -- tipo para os barramentos de 32 bits

  type inst_type is (ADDU, SUBU, AAND, OOR, XXOR, NNOR, LW, SW,
  	ORI, ADDIU, LUI, SSLL, SSRL, SLT, JR, BEQ, invalid_instruction);

  type microinstruction is record
    ce:    std_logic;       -- ce e rw são os controles da memória
    rw:    std_logic;
    i:     inst_type;
    wreg:  std_logic;       -- wreg diz se o banco de registradores
							-- deve ou não ser escrito
  end record;

end p_MI0;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Registrador genérico - com possibilidade de inicialização de valor
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MI0.all;

entity registrador is
           generic( INIT_VALUE : reg32 := (others=>'0') );
           port(  ck, rst, ce : in std_logic;
                  D : in  reg32;
                  Q : out reg32
               );
end registrador;

architecture regn of registrador is
begin

  process(ck, rst)
  begin
       if rst = '1' then
              Q <= INIT_VALUE(31 downto 0);
       elsif ck'event and ck = '1' then
           if ce = '1' then
              Q <= D;
           end if;
       end if;
  end process;

end regn;


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Registrador sensível a borda de descida - para implementação do BEQ
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MI0.all;

entity registrador2 is
           generic( INIT_VALUE : reg32 := (others=>'0') );
           port(  ck, rst, ce : in std_logic;
                  D : in  reg32;
                  Q : out reg32
               );
end registrador2;

architecture regn2 of registrador2 is
begin

  process(ck, rst)
  begin
       if rst = '1' then
              Q <= INIT_VALUE(31 downto 0);
       elsif ck'event and ck = '0' then --borda de descida
           if ce = '1' then
              Q <= D;
           end if;
       end if;
  end process;

end regn2;


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Banco de registradores - 31 registradores de uso geral - reg(0): cte 0
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use work.p_MI0.all;

entity reg_bank is
       port( ck, rst, wreg :    in std_logic;
             AdRs, AdRt, adRD : in std_logic_vector( 4 downto 0);
             RD : in reg32;
             R1, R2: out reg32
           );
end reg_bank;

architecture reg_bank of reg_bank is
   type bank is array(0 to 31) of reg32;
   signal reg : bank ;
   signal wen : reg32 ;
begin

    g1: for i in 0 to 31 generate

        wen(i) <= '1' when i/=0 and adRD=i and wreg='1' else '0';

        rx: entity work.registrador
			port map(ck=>ck, rst=>rst, ce=>wen(i), D=>RD, Q=>reg(i));

    end generate g1;

    R1 <= reg(CONV_INTEGER(AdRs));    -- seleção do fonte 1

    R2 <= reg(CONV_INTEGER(AdRt));    -- seleção do fonte 2

end reg_bank;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ALU - a operação depende somente da instrução corrente que é
-- 	decodificada na Unidade de Controle
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.p_MI0.all;

entity alu is
       port( op1, op2 : in  reg32;
             outalu :   out reg32;
             op_alu :   in  inst_type;
			 zero : out std_logic
           );
end alu;

architecture alu of alu is
signal int_ula: reg32;
begin

    int_ula <=
        op1 - op2      when  op_alu=SUBU or op_alu=BEQ else
        op1 and op2    when  op_alu=AAND               else
        op1 or  op2    when  op_alu=OOR  or op_alu=ORI else
        op1 xor op2    when  op_alu=XXOR               else
        op1 nor op2    when  op_alu=NNOR               else
        op1 + op2;      --- default é a soma

	outalu<=int_ula;
	zero <= '1' when int_ula=0 else '0'; --para nova instrução BEQ
end alu;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Descrição do Bloco de Dados (Datapath)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_signed.all;
use work.p_MI0.all;

entity datapath is
      port(  ck, rst :     in    std_logic;
             i_address :   out   reg32;
             instruction : in    reg32;
             d_address :   out   reg32;
             data :        inout reg32;
             uins :        in    microinstruction;
             IR_OUT :      out   reg32;
				 deb :      out   reg32
          );
end datapath;

architecture datapath of datapath is
   signal incpc, pcnormal, pcdesvio, pc, IR, result, R1, R2, ext32, op2, reg_dest: reg32;
   signal adD   : std_logic_vector(4 downto 0) ;
   signal instR, zero : std_logic ;
begin

   instR <= '1' when uins.i=ADDU or uins.i=SUBU or
		uins.i=AAND or uins.i=OOR or uins.i=XXOR or uins.i=NNOR or uins.i=BEQ else
            '0';

   --======  Hardware para a busca de instruções  =============================================

   pcnormal <= pc + 4;
   pcdesvio <= pcnormal + ("00000000000000" & IR(15 downto 0) & "00"); --calculado para o salto
   incpc <= pcdesvio when uins.i=BEQ and zero='1' else pcnormal;

   rpc: entity work.registrador2 --para nova instrução
	   generic map(INIT_VALUE=>x"00400000")	-- ATENÇÃO a este VALOR!!
	   										-- Ele depende do simulador!!
	   										-- Para o SPIM --> 	use x"00400020"
											-- Para o MARS -->	use x"00400000"
              port map(ck=>ck, rst=>rst, ce=>'1', D=>incpc, Q=>pc);

   RIR: entity work.registrador  port map(ck=>ck, rst=>rst, ce=>'1', D=>instruction, Q=>IR);

   IR_OUT <= ir ;	-- IR_OUT é o sinal de saída do Bloco de Dados, que contém
   					-- o código da instrução em execução no momento. É passado
   					-- ao Bloco de Controle
   i_address <= pc;

   --======== hardware do banco de registradores e extensão de sinal ou de 0 ================

   adD <= IR(15 downto 11)   when instR='1'  else
          IR(20 downto 16) ;

   REGS: entity work.reg_bank port map
	   (ck=>ck, rst=>rst, wreg=>uins.wreg, AdRs=>IR(25 downto 21),
	   		AdRt=>ir(20 downto 16), adRD=>adD, RD=>reg_dest, R1=>R1, R2=>R2);

   -- Extensão de 0 ou extensão de sinal
   ext32 <=	x"FFFF" & IR(15 downto 0) when (IR(15)='1' and (uins.i=LW or uins.i=SW)) else
	   		-- LW and SW use signal extension, ORI uses 0-extension
			x"0000" & IR(15 downto 0);
	   		-- other instructions do not use this information,
			-- thus anything is good 0 or sign extension

   --=========  hardware da ALU e em volta dela ==========================================

   op2 <= R2 when instR='1' else
          ext32;

   inst_alu: entity work.alu port map (op1=>R1, op2=>op2, outalu=>result, op_alu=>uins.i, zero=>zero);

   -- operacao com a memória de dados

   d_address <= result;

   data <= R2 when uins.ce='1' and uins.rw='0' else (others=>'Z');

   reg_dest <=  data when uins.i=LW else result;

end datapath;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  Unidade de Controle - decodifica a instrução e gera os sinais de controle
--		nesta implementação é um bloco puramente combinacional
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use work.p_MI0.all;

entity control_unit is
	port(   ck, rst: in std_logic; 	-- estes sinais são inúteis nesta versão da
									-- Unidade de Controle, pois ela é combinacional
                uins :   out microinstruction;
                ir :     in reg32
             );
end control_unit;

architecture control_unit of control_unit is
  signal i : inst_type;
begin

    uins.i <= i;

    i <= ADDU   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100001" else
         SUBU   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100011" else
         AAND   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100100" else
         OOR    when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100101" else
         XXOR   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100110" else
         NNOR   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100111" else
         ORI    when ir(31 downto 26)="001101" else
         LW     when ir(31 downto 26)="100011" else -- LW = 100011 $16 = 10000 $17 = 10001 deslocar = 0000000000000000
         SW     when ir(31 downto 26)="101011" else

         ADDIU  when ir(31 downto 26)="001001" else --Novas instruções
			LUI    when ir(31 downto 26)="001111" else
			SSLL   when ir(31 downto 26)="000000" and ir(5 downto 0)="000000" else
			SSRL   when ir(31 downto 26)="000000" and ir(5 downto 0)="000010" else
			SLT    when ir(31 downto 26)="000000" and ir(10 downto 0)="00000101010" else
			JR     when ir(31 downto 26)="000000" and ir(20 downto 0)="000000000000000001000" else
			BEQ    when ir(31 downto 26)="000100" else
         invalid_instruction ; -- IMPORTANTE: condição "default" é invalid instruction;

    assert i /= invalid_instruction
          report "******************* INVALID INSTRUCTION *************"
          severity error;

    uins.ce    <= '1' when i=SW  or i=LW else '0';

    uins.rw    <= '0' when i=SW  else '1';

    uins.wreg  <= '0' when i=SW  else '1';

end control_unit;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Topo da Hierarquida do Processador -  instanciação dos Blocos de
-- 		Dados e de Controle
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use work.p_MI0.all;

entity MRstd is
    port( clock, reset:         in    std_logic;
          ce, rw, bw:           out   std_logic;
          i_address, d_address: out   reg32;
          instruction:          in    reg32;
          data:                 inout reg32;
			 deb:          out    reg32
			 );
end MRstd;

architecture MRstd of MRstd is
      signal IR: reg32;
      signal uins: microinstruction;
 begin

     dp: entity work.datapath
         port map( ck=>clock, rst=>reset, IR_OUT=>IR, uins=>uins, i_address=>i_address,
                   instruction=>instruction, d_address=>d_address,  data=>data, deb=>deb);

     ct: entity work.control_unit port map( ck=>clock, rst=>reset, IR=>IR, uins=>uins);

     ce <= uins.ce;
     rw <= uins.rw;

     bw <= '1';	-- Esta versão trabalha apenas em modo word (32 bits).
	 			-- Logo, este sinal é inútil aqui

end MRstd;