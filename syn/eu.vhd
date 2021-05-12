--//
--//
--//  File Name   :  eu.v
--//  Used on     :  MCL51
--//  Author      :  Ted Fried, MicroCore Labs
--//  Creation    :  3/13/2016
--//  Code Type   :  Synthesizable
--//
--//   Description:
--//   ============
--//   
--//  Execution Unit of the MCL51 processor - Microsequencer
--//
--//------------------------------------------------------------------------
--//
--// Modification History:
--// =====================
--//
--// Revision 1.0 3/13/16
--// Initial revision
--//
--//
--//------------------------------------------------------------------------
--//
--// Copyright (c) 2020 Ted Fried
--// 
--// Permission is hereby granted, free of charge, to any person obtaining a copy
--// of this software and associated documentation files (the "Software"), to deal
--// in the Software without restriction, including without limitation the rights
--// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--// copies of the Software, and to permit persons to whom the Software is
--// furnished to do so, subject to the following conditions:
--// 
--// The above copyright notice and this permission notice shall be included in all
--// copies or substantial portions of the Software.
--// 
--// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--// SOFTWARE.
--//
--//------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity eu is 
   port( CORE_CLK          :  in    STD_LOGIC;
         RST_n             :  in    STD_LOGIC;
         EU_BIU_STROBE     :  out   STD_LOGIC_VECTOR(7  downto 0); -- EU to BIU
         EU_BIU_DATAOUT    :  out   STD_LOGIC_VECTOR(7  downto 0);
         EU_REGISTER_R3    :  out   STD_LOGIC_VECTOR(15 downto 0);
         EU_REGISTER_IP    :  out   STD_LOGIC_VECTOR(15 downto 0);
         BIU_SFR_ACC       :  in    STD_LOGIC_VECTOR(7  downto 0); -- BIU to EU
         BIU_SFR_DPTR      :  in    STD_LOGIC_VECTOR(15 downto 0);
         BIU_SFR_SP        :  in    STD_LOGIC_VECTOR(7  downto 0);
         BIU_SFR_PSW       :  in    STD_LOGIC_VECTOR(7  downto 0);
         BIU_RETURN_DATA   :  in    STD_LOGIC_VECTOR(7  downto 0);
         BIU_INTERRUPT     :  in    STD_LOGIC);
end eu;
    
architecture Behavioral of eu is
   signal   eu_add_carry         :  STD_LOGIC;
   signal   eu_add_carry16       :  STD_LOGIC;
   signal   eu_add_aux_carry     :  STD_LOGIC;
   signal   eu_add_overflow      :  STD_LOGIC;
   signal   eu_stall_pipeline    :  STD_LOGIC;
   signal   eu_opcode_jump_call  :  STD_LOGIC;
   signal   eu_jump_gate         :  STD_LOGIC;
   signal   eu_rom_address       :  STD_LOGIC_VECTOR(9 downto 0);
   signal   eu_calling_address   :  STD_LOGIC_VECTOR(19 downto 0);
   signal   eu_register_r0       :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_register_r1       :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_register_r2       :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_register_r3_i     :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_register_ip_i     :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_biu_strobe_i      :  STD_LOGIC_VECTOR(7 downto 0);
   signal   eu_biu_dataout_i     :  STD_LOGIC_VECTOR(7 downto 0);
   signal   eu_alu_last_result   :  STD_LOGIC_VECTOR(15 downto 0);
   signal   adder_out            :  STD_LOGIC_VECTOR(15 downto 0);
   signal   carry                :  STD_LOGIC_VECTOR(16 downto 0);
   signal   eu_opcode_type       :  STD_LOGIC_VECTOR(2 downto 0);
   signal   eu_opcode_dst_sel    :  STD_LOGIC_VECTOR(2 downto 0);
   signal   eu_opcode_op0_sel    :  STD_LOGIC_VECTOR(3 downto 0);
   signal   eu_opcode_op1_sel    :  STD_LOGIC_VECTOR(2 downto 0);
   signal   eu_opcode_immediate  :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_opcode_jump_src   :  STD_LOGIC_VECTOR(2 downto 0);
   signal   eu_opcode_jump_cond  :  STD_LOGIC_VECTOR(2 downto 0);
   signal   eu_alu2              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu3              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu4              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu5              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu6              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu7              :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_alu_out           :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_operand0          :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_operand1          :  STD_LOGIC_VECTOR(15 downto 0);
   signal   eu_rom_data          :  STD_LOGIC_VECTOR(31 downto 0);
   signal   eu_flags_r           :  STD_LOGIC_VECTOR(15 downto 0);
   --signal   new_instruction      :  STD_LOGIC;

   COMPONENT eu_rom
   PORT (   clka  : IN  STD_LOGIC;
            addra : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
   END COMPONENT;
begin

--//------------------------------------------------------------------------
--//
--// EU Microcode ROM.  1Kx32
--//
--//------------------------------------------------------------------------                                    
   EU_1Kx32: eu_rom
   PORT MAP (  clka  => CORE_CLK,
               addra => eu_rom_address,
               douta => eu_rom_data);

--//------------------------------------------------------------------------
--//
--// Combinationals
--//
--//------------------------------------------------------------------------

   EU_BIU_STROBE        <= eu_biu_strobe_i;
   EU_BIU_DATAOUT       <= eu_biu_dataout_i;
   EU_REGISTER_R3       <= eu_register_r3_i;
   EU_REGISTER_IP       <= eu_register_ip_i;


   --// EU ROM opcode decoder
   eu_opcode_type       <= eu_rom_data(30 downto 28);
   eu_opcode_dst_sel    <= eu_rom_data(26 downto 24);
   eu_opcode_op0_sel    <= eu_rom_data(23 downto 20);
   eu_opcode_op1_sel    <= eu_rom_data(18 downto 16);
   eu_opcode_immediate  <= eu_rom_data(15 downto 0);
   eu_opcode_jump_call  <= eu_rom_data(24);
   eu_opcode_jump_src   <= eu_rom_data(22 downto 20);
   eu_opcode_jump_cond  <= eu_rom_data(18 downto 16);

   with eu_opcode_op0_sel select
      eu_operand0 <= eu_register_r0          when "0000",
                     eu_register_r1          when "0001",
                     eu_register_r2          when "0010",
                     eu_register_r3_i        when "0011",
                     x"00"&BIU_RETURN_DATA   when "0100",
                     eu_flags_r(15 downto 0) when "0101",
                     x"00"&BIU_SFR_ACC       when "0110",
                     eu_register_ip_i        when "0111",
                     (others => '0')         when others;

   with eu_opcode_op1_sel select
      eu_operand1 <= eu_register_r0          when "000",
                     eu_register_r1          when "001",
                     eu_register_r2          when "010",
                     eu_register_r3_i        when "011",
                     x"00"&BIU_SFR_SP        when "100",
                     eu_alu_last_result      when "101",
                     BIU_SFR_DPTR            when "110",
                     eu_opcode_immediate     when others;
                     

    
   --// JUMP condition codes
   eu_jump_gate   <= '1' when eu_opcode_jump_cond = "000" else --// unconditional jump
                     '1' when eu_opcode_jump_cond = "001" and eu_alu_last_result/=x"0000" else
                     '1' when eu_opcode_jump_cond = "010" and eu_alu_last_result =x"0000" else
                     '0';

   --// ** Flags must be written to the PSW through the BIU 
    
   eu_flags_r(15) <=  eu_add_carry;
   eu_flags_r(14) <=  eu_add_aux_carry;
   eu_flags_r(13) <=  eu_add_carry16;
   --//assign eu_flags_r[12]     = 
   eu_flags_r(12) <= '0';
   --//assign eu_flags_r[11]     =  
   eu_flags_r(11) <= '0';
   eu_flags_r(10) <= eu_add_overflow;
   --//assign eu_flags_r[9]      = 
   eu_flags_r(9)  <= '0';
   eu_flags_r(8)  <=  BIU_INTERRUPT;
   eu_flags_r(7)  <=  BIU_SFR_PSW(7);   --// C
   eu_flags_r(6)  <=  BIU_SFR_PSW(6);   --// AC
   eu_flags_r(5)  <=  BIU_SFR_PSW(5);   --// F0
   eu_flags_r(4)  <=  BIU_SFR_PSW(4);   --// RS1
   eu_flags_r(3)  <=  BIU_SFR_PSW(3);   --// RS0
   eu_flags_r(2)  <=  BIU_SFR_PSW(2);   --// Overflow
   eu_flags_r(1)  <=  BIU_SFR_PSW(1);   --// User Defined Flag
   eu_flags_r(0)  <=  BIU_SFR_PSW(0);   --// ACC Parity generated in the BIU


--// EU ALU Operations
--// ------------------------------------------
--//     eu_alu0 = NOP
--//     eu_alu1 = JUMP
   eu_alu2 <= adder_out;                                          --// ADD
   eu_alu3 <= eu_operand0 xor eu_operand1;                        --// XOR
   eu_alu4 <= eu_operand0 or  eu_operand1;                        --// OR
   eu_alu5 <= eu_operand0 and eu_operand1;                        --// AND
   eu_alu6 <= eu_operand0(7 downto 0)&eu_operand0(15 downto 8);   --// BYTESWAP

   with eu_opcode_immediate(1 downto 0) select
      eu_alu7 <=  x"00" & eu_operand0(0) & eu_operand0(7 downto 1)   when "00",     --//  Rotate in bit[0] 
                  x"00" & BIU_SFR_PSW(7) & eu_operand0(7 downto 1)   when "01",     --//  Rotate in Carry bit
                  eu_add_carry16 & eu_operand0(15 downto 1)          when others;   --//  16-bit shift-right

   --// Mux the ALU operations
   with eu_opcode_type select
      eu_alu_out  <= eu_alu2        when "010",
                     eu_alu3        when "011",
                     eu_alu4        when "100",
                     eu_alu5        when "101",
                     eu_alu6        when "110",
                     eu_alu7        when "111",
                     x"EEEE"        when others;
                     
   --// Generate 16-bit full adder for the EU
   carry(0) <= '0';
   GEN_ADDER:  for i in 0 to 15 generate
      adder_out(i)   <= eu_operand0(i) xor eu_operand1(i) xor carry(i);
      carry(i+1)     <= (eu_operand0(i) and eu_operand1(i)) or
                        (eu_operand0(i) and carry(i))       or
                        (eu_operand1(i) and carry(i));
   end generate;

   --new_instruction   <= '1' when eu_rom_address(9 downto 8) = "00" else '0';


--//------------------------------------------------------------------------------------------  
--//
--// EU Microsequencer
--//
--//------------------------------------------------------------------------------------------
   process(CORE_CLK)
   begin
      if(rising_edge(CORE_CLK)) then
         if(RST_n = '0') then
            eu_add_carry16       <= '0';
            eu_add_carry         <= '0';
            eu_add_aux_carry     <= '0';
            eu_add_overflow      <= '0';
            eu_alu_last_result   <= (others => '0');
            eu_register_r0       <= (others => '0');
            eu_register_r1       <= (others => '0');
            eu_register_r2       <= (others => '0');
            eu_register_r3_i     <= (others => '0');
            eu_register_ip_i     <= x"FFFF";      --16'hFFFF; // User Program code starts at 0x0000 after reset. Main loop does initial increment.
            eu_biu_strobe_i      <= (others => '0');
            eu_biu_dataout_i     <= (others => '0');
            eu_stall_pipeline    <= '0';
            eu_rom_address       <= "0100000000";   --9'h100; // Microcode starts here after reset
            eu_calling_address   <= (others => '0');
         else

            --// Generate and store flags for addition
            if (eu_stall_pipeline='0' and eu_opcode_type="010") then
               eu_add_carry16     <= carry(16);
               eu_add_carry       <= carry(8);
               eu_add_aux_carry   <= carry(4);
               eu_add_overflow    <= carry(8) xor carry(7);
            end if;

            --// Register writeback   
            if (eu_stall_pipeline='0' and eu_opcode_type/="000" and eu_opcode_type/="001") then 
               eu_alu_last_result <= eu_alu_out(15 downto 0);
               case eu_opcode_dst_sel is 
                  when "000"     => eu_register_r0    <= eu_alu_out(15 downto 0);
                  when "001"     => eu_register_r1    <= eu_alu_out(15 downto 0);
                  when "010"     => eu_register_r2    <= eu_alu_out(15 downto 0);
                  when "011"     => eu_register_r3_i  <= eu_alu_out(15 downto 0);
                  when "100"     => eu_biu_dataout_i  <= eu_alu_out( 7 downto 0);
                  --when "101"   => 
                  when "110"     => eu_biu_strobe_i   <= eu_alu_out( 7 downto 0);
                  when "111"     => eu_register_ip_i  <= eu_alu_out(15 downto 0);
                  when others    => null; 
               end case;
            end if;
            
            --// JUMP Opcode
            if (eu_stall_pipeline='0' and eu_opcode_type="001" and eu_jump_gate='1') then
               eu_stall_pipeline <= '1';
          
               --// For subroutine CALLs, store next opcode address
               if (eu_opcode_jump_call='1') then
                  --// Two deep calling addresses
                  eu_calling_address <= eu_calling_address(9 downto 0) & eu_rom_address(9 downto 0); 
               end if;           

               case eu_opcode_jump_src is  --// synthesis parallel_case
                  when "000"  => eu_rom_address <= eu_opcode_immediate(9 downto 0);
                  when "001"  => eu_rom_address <= "00"&BIU_RETURN_DATA;                                                   --// Initial opcode jump decoding
                  when "010"  => eu_rom_address <= eu_opcode_immediate(9 downto 4) & eu_register_r0(11 downto 8);          --// EA decoding
                  when "011"  => eu_rom_address <= eu_calling_address(9 downto 0);                                         --// CALL return
                                 eu_calling_address(9 downto 0) <= eu_calling_address(19 downto 10);
                  when "100"  => eu_rom_address <= eu_opcode_immediate(5 downto 0) & BIU_RETURN_DATA(2 downto 0) & "0";    --// Bit Mask decoding table
                  when others => null;
               end case;
            else
               eu_stall_pipeline <= '0';  --// Debounce the pipeline stall
               eu_rom_address    <= std_logic_vector(unsigned(eu_rom_address) + 1); 
            end if;
         end if;
      end if;
   end process;   
end Behavioral;    
 