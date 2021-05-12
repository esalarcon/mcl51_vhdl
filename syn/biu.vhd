--//
--//
--//  File Name   :  biu.v
--//  Used on     :  
--//  Author      :  Ted Fried, MicroCore Labs
--//  Creation    :  3/13/16
--//  Code Type   :  Synthesizable
--//
--//   Description:
--//   ============
--//   
--//  Bus Interface Unit of the MCL51 processor 
--//  ported to the Lattice XO2 Breakout Board.
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

entity biu is
   port (   CORE_CLK          :  in   STD_LOGIC;
            RST_n             :  in   STD_LOGIC;
            SPEAKER           :  out  STD_LOGIC;
            EU_BIU_STROBE     :  in   STD_LOGIC_VECTOR(7 downto 0);  --// EU to BIU Signals
            EU_BIU_DATAOUT    :  in   STD_LOGIC_VECTOR(7 downto 0);
            EU_REGISTER_R3    :  in   STD_LOGIC_VECTOR(15 downto 0);
            EU_REGISTER_IP    :  in   STD_LOGIC_VECTOR(15 downto 0);
            BIU_SFR_ACC       :  out  STD_LOGIC_VECTOR(7 downto 0);  --// BIU to EU Signals
            BIU_SFR_DPTR      :  out  STD_LOGIC_VECTOR(15 downto 0);
            BIU_SFR_SP        :  out  STD_LOGIC_VECTOR(7 downto 0);
            BIU_SFR_PSW       :  out  STD_LOGIC_VECTOR(7 downto 0);
            BIU_RETURN_DATA   :  out  STD_LOGIC_VECTOR(7 downto 0);
            BIU_INTERRUPT     :  out  STD_LOGIC);
end biu;


architecture Behavioral of biu is
   signal biu_pxy_rd             :  STD_LOGIC;
   signal biu_pxy_wr             :  STD_LOGIC;
   signal core_interrupt_disable :  STD_LOGIC;
   signal biu_int2               :  STD_LOGIC;
   signal biu_sfr_select         :  STD_LOGIC;
   signal acc_parity             :  STD_LOGIC;
   signal biu_timer_wr_strobe    :  STD_LOGIC;  
   signal biu_ram_wr             :  STD_LOGIC;
   signal eu_register_r3_d1      :  STD_LOGIC_VECTOR(15 downto 0);
   signal biu_sfr_dpl_int        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_dph_int        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_ie_int         :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_psw_int        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_acc_int        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_sp_int         :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_b_int          :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_pxy_addr       :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_pxy_dout       :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_pxy_din        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_dataout        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_sfr_is_int         :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_program_data       :  STD_LOGIC_VECTOR(7 downto 0);
   signal eu_biu_strobe_mode     :  STD_LOGIC_VECTOR(2 downto 0);
   signal eu_biu_strobe_int      :  STD_LOGIC_VECTOR(2 downto 0);
   signal biu_ram_dataout        :  STD_LOGIC_VECTOR(7 downto 0);
   signal biu_timer_dataout      :  STD_LOGIC_VECTOR(7 downto 0);  
begin
--//------------------------------------------------------------------------
--//
--// User Program ROM.  4Kx8 
--//
--//------------------------------------------------------------------------                                    
BIU_4Kx8:   entity work.biu_rom(Behavioral)
            port map(clk  => CORE_CLK,
                     addr => EU_REGISTER_IP(11 downto 0),
                     dout => biu_program_data);


--//------------------------------------------------------------------------
--//
--// User Data RAM.  512x8 
--//
--//------------------------------------------------------------------------                                    
BIU_512x8 : entity work.biu_ram(Behavioral)
            port map(clk   => CORE_CLK,
                     addr  => eu_register_r3_d1(8 downto 0),
                     din   => EU_BIU_DATAOUT,
                     dout  => biu_ram_dataout,
                     we    => biu_ram_wr);

--//------------------------------------------------------------------------
--//
--// BIU  Combinationals
--//
--//------------------------------------------------------------------------
   --// Outputs to the EU
   --//
   BIU_SFR_ACC       <= biu_sfr_acc_int;
   BIU_SFR_DPTR      <= biu_sfr_dph_int&biu_sfr_dpl_int;
   BIU_SFR_SP        <= biu_sfr_sp_int;
   BIU_SFR_PSW       <= biu_sfr_psw_int(7 downto 1)&acc_parity;
   BIU_RETURN_DATA   <= biu_program_data when eu_biu_strobe_mode(1 downto 0)= "00"    else
                        biu_sfr_dataout  when biu_sfr_select = '1'                    else
                        biu_ram_dataout;
                                             
   --// Parity for the Accumulator
   --// This can be removed if parity is not used in firmware.
   acc_parity <= biu_sfr_acc_int(0) xor biu_sfr_acc_int(1) xor biu_sfr_acc_int(2) xor biu_sfr_acc_int(3) xor
                 biu_sfr_acc_int(4) xor biu_sfr_acc_int(5) xor biu_sfr_acc_int(6) xor biu_sfr_acc_int(7);
                 
   --// EU strobes to request BIU processing.
   eu_biu_strobe_mode   <= EU_BIU_STROBE(6 downto 4);  
   eu_biu_strobe_int    <= EU_BIU_STROBE(2 downto 0); 

   --// Select the SFR range if the address is 0x0080 to 0x00FF and addressing mode is Direct
   biu_sfr_select <= '1' when eu_register_r3_d1(15 downto 7)= "000000001"  and 
                              eu_biu_strobe_mode(1 downto 0)= "01"         else '0';

   --// Decode the write enable to the RAM block
   biu_ram_wr <= '1' when biu_sfr_select='0' and eu_biu_strobe_int="001" else '0';


   --// Mux the SFR data outputs
   with eu_register_r3_d1(7 downto 0) select
      biu_sfr_dataout <=   biu_sfr_sp_int   when x"81",
                           biu_sfr_dpl_int  when x"82",
                           biu_sfr_dph_int  when x"83",
                           biu_sfr_ie_int   when x"A8",
                           biu_sfr_is_int   when x"A9",
                           biu_sfr_pxy_din  when x"C0",
                           biu_sfr_psw_int  when x"D0",
                           biu_sfr_acc_int  when x"E0",
                           biu_sfr_b_int    when x"F0",
                           x"EE"            when others;
                           
   --// Simple fixed priority interrupt controller
   --// biu_sfr_ie_int[7] is the global_intr_enable 
   --// biu_sfr_is_int[3:0] contains the interrupt source
   --// Interrupt 2 = Timer Interrupt        Vector at address 0x4 
   --//
   BIU_INTERRUPT <= '1' when core_interrupt_disable = '0' and biu_sfr_ie_int(7) = '1' and biu_int2 = '1' else '0';
   biu_sfr_is_int(7 downto 4) <= "0000";
   biu_sfr_is_int(3 downto 0) <= "0010" when biu_int2='1' else "1111";
                                 
   --//------------------------------------------------------------------------
   --//
   --// BIU Controller
   --//
   --//------------------------------------------------------------------------
   --//
   process(CORE_CLK)
   begin
      if(rising_edge(CORE_CLK)) then
         if(RST_n = '0') then
            biu_sfr_dpl_int         <= (others => '0');
            biu_sfr_dph_int         <= (others => '0');
            biu_sfr_ie_int          <= (others => '0');
            biu_sfr_psw_int         <= (others => '0');
            biu_sfr_acc_int         <= (others => '0');
            biu_sfr_b_int           <= (others => '0');
            biu_sfr_sp_int          <= x"07";
            eu_register_r3_d1       <= (others => '0');
            biu_pxy_rd              <= '0';
            biu_pxy_wr              <= '0';
            biu_sfr_pxy_addr        <= (others => '0');
            biu_sfr_pxy_dout        <= (others => '0');
            core_interrupt_disable  <= '0';
         else
            
            eu_register_r3_d1  <= EU_REGISTER_R3;
      
            if (eu_biu_strobe_int="011") then
               core_interrupt_disable <= '1';
            end if;
        
            if (eu_biu_strobe_int="100") then 
               core_interrupt_disable <= '0';
            end if;
        
        
            --// Writes to SFR's
            if (biu_sfr_select='1' and eu_biu_strobe_int="001") then
               case eu_register_r3_d1(7 downto 0) is  --// synthesis parallel_case
                  when x"81"  => biu_sfr_sp_int    <= EU_BIU_DATAOUT(7 downto 0);
                  when x"82"  => biu_sfr_dpl_int   <= EU_BIU_DATAOUT(7 downto 0);
                  when x"83"  => biu_sfr_dph_int   <= EU_BIU_DATAOUT(7 downto 0);
                  when x"A8"  => biu_sfr_ie_int    <= EU_BIU_DATAOUT(7 downto 0);
                  when x"D0"  => biu_sfr_psw_int   <= EU_BIU_DATAOUT(7 downto 0);
                  when x"E0"  => biu_sfr_acc_int   <= EU_BIU_DATAOUT(7 downto 0);
                  when x"F0"  => biu_sfr_b_int     <= EU_BIU_DATAOUT(7 downto 0);
                  --// Proxy Addressing Registers
                  when x"C1"  => biu_sfr_pxy_dout  <= EU_BIU_DATAOUT(7 downto 0);
                  when x"C2"  => biu_sfr_pxy_addr  <= EU_BIU_DATAOUT(7 downto 0);
                  when others => null;
               end case;
            end if;
        
            --// Assert the write strobe to the proxy addressed peripherals
            if (biu_sfr_select='1' and eu_biu_strobe_int="001" and eu_register_r3_d1(7 downto 0)=x"C1") then
               biu_pxy_wr <= '1';
            else
               biu_pxy_wr <= '0';
            end if;                         
        
            --// Assert the read strobe to the proxy addressed peripherals
            if (biu_sfr_select='1' and eu_biu_strobe_int="001" and eu_register_r3_d1(7 downto 0)=x"C2") then
               biu_pxy_rd <= '1';
            else
               biu_pxy_rd <= '0';
            end if;     
     
         end if;
      end if;
   end process;
   
--//------------------------------------------------------------------------
--//------------------------------------------------------------------------
--//------------------------------------------------------------------------
--
--//
--// Peripherals accessed with proxy addressing  
--//
--// BIU SFR  biu_sfr_pxy_addr - 0xC2  = Address[7:0]
--//          biu_sfr_pxy_dout - 0xC1  = Write Data and strobe to the peripherals
--//          biu_sfr_pxy_din  - 0xC0  = Read Data from the peripherals
--//
--//
--//
--//------------------------------------------------------------------------
--//

   --// Steer the peripheral read data
   biu_sfr_pxy_din <= biu_timer_dataout when biu_sfr_pxy_addr(7 downto 4)="0000" else x"EE";
                                            
   --// Gate the peripheral read and write strobes
   biu_timer_wr_strobe <= '1' when biu_sfr_pxy_addr(7 downto 4)="0000" else '0';

--//------------------------------------------------------------------------
--//
--// Timer - Dual output 24-bit programmable timer
--//
--// Timer-0 = Frequency generator
--// Timer-1 = Pulse generator
--//
--//------------------------------------------------------------------------                                    
BIU_TIMER:  entity work.timer(Behavioral)
            port map(CORE_CLK    => CORE_CLK,
                     RST_n       => RST_n,
                     ADDRESS     => biu_sfr_pxy_addr(3 downto 0),
                     DATA_IN     => biu_sfr_pxy_dout,
                     DATA_OUT    => biu_timer_dataout,
                     STROBE_WR   => biu_timer_wr_strobe,
                     TIMER0_OUT  => SPEAKER,
                     TIMER1_OUT  => biu_int2);                                                         
end Behavioral;        
