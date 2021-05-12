--//
--//
--//  File Name   :  MCL51_top.v
--//  Used on     :  
--//  Author      :  MicroCore Labs
--//  Creation    :  5/9/2016
--//  Code Type   :  Synthesizable
--//
--//   Description:
--//   ============
--//   
--//  MCL51 processor - Top Level  For 'Arty' Artix-7 Test Board
--//
--//------------------------------------------------------------------------
--//
--// Modification History:
--// =====================
--//
--// Revision 1.0 5/1/16
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

entity MCL51_top  is 
   port( CLK      : in  STD_LOGIC;
         RESET_n  : in  STD_LOGIC;
         SPEAKER  : out STD_LOGIC);
end MCL51_top;

architecture   Behavioral of MCL51_top is
   signal t_biu_interrupt     :  STD_LOGIC;
   signal t_eu_biu_strobe     :  STD_LOGIC_VECTOR(7 downto 0);
   signal t_eu_biu_dataout    :  STD_LOGIC_VECTOR(7 downto 0);
   signal t_eu_register_r3    :  STD_LOGIC_VECTOR(15 downto 0);
   signal t_biu_sfr_psw       :  STD_LOGIC_VECTOR(7 downto 0);
   signal t_biu_sfr_acc       :  STD_LOGIC_VECTOR(7 downto 0);
   signal t_biu_sfr_sp        :  STD_LOGIC_VECTOR(7 downto 0);
   signal t_eu_register_ip    :  STD_LOGIC_VECTOR(15 downto 0);
   signal t_biu_sfr_dptr      :  STD_LOGIC_VECTOR(15 downto 0);
   signal t_biu_return_data   :  STD_LOGIC_VECTOR(7 downto 0);
begin

   --//------------------------------------------------------------------------
   --// EU Core 
   --//------------------------------------------------------------------------
   EU_CORE: entity work.eu(Behavioral)
            port map(   CORE_CLK        => CLK,
                        RST_n           => RESET_n,
                        EU_BIU_STROBE   => t_eu_biu_strobe,
                        EU_BIU_DATAOUT  => t_eu_biu_dataout,
                        EU_REGISTER_R3  => t_eu_register_r3,
                        EU_REGISTER_IP  => t_eu_register_ip,
                        BIU_SFR_ACC     => t_biu_sfr_acc,
                        BIU_SFR_DPTR    => t_biu_sfr_dptr,
                        BIU_SFR_SP      => t_biu_sfr_sp,
                        BIU_SFR_PSW     => t_biu_sfr_psw,
                        BIU_RETURN_DATA => t_biu_return_data,
                        BIU_INTERRUPT   => t_biu_interrupt);
            
   --//------------------------------------------------------------------------
   --// BIU Core 
   --//------------------------------------------------------------------------
   BIU_CORE:entity work.biu(Behavioral)
            port map(   CORE_CLK        => CLK,
                        RST_n           => RESET_n,
                        SPEAKER         => SPEAKER,
                        EU_BIU_STROBE   => t_eu_biu_strobe,   
                        EU_BIU_DATAOUT  => t_eu_biu_dataout,
                        EU_REGISTER_R3  => t_eu_register_r3,
                        EU_REGISTER_IP  => t_eu_register_ip,
                        BIU_SFR_ACC     => t_biu_sfr_acc,
                        BIU_SFR_DPTR    => t_biu_sfr_dptr,
                        BIU_SFR_SP      => t_biu_sfr_sp,
                        BIU_SFR_PSW     => t_biu_sfr_psw,
                        BIU_RETURN_DATA => t_biu_return_data,
                        BIU_INTERRUPT   => t_biu_interrupt);
end Behavioral;
