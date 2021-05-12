--//
--//
--//  File Name   :  timer.v
--//  Used on     :  
--//  Author      :  MicroCore Labs
--//  Creation    :  4/15/16
--//  Code Type   :  Synthesizable
--//
--//   Description:
--//   ============
--//   
--//  Two channel, 24-bit timers.
--//
--// Timer-0 = Frequency generator
--// Timer-1 = One-shot generator
--//
--//------------------------------------------------------------------------
--//
--// Modification History:
--// =====================
--//
--// Revision 1.0 4/15/16 
--// Initial revision
--//
--//
--//------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity timer is 
   port (   CORE_CLK    : in  STD_LOGIC;
            RST_n       : in  STD_LOGIC;
            ADDRESS     : in  STD_LOGIC_VECTOR(3 downto 0);
            DATA_IN     : in  STD_LOGIC_VECTOR(7 downto 0);
            DATA_OUT    : out STD_LOGIC_VECTOR(7 downto 0);
            STROBE_WR   : in  STD_LOGIC;
            TIMER0_OUT  : out STD_LOGIC;
            TIMER1_OUT  : out STD_LOGIC);
end timer;


architecture Behavioral of timer is
   signal timer0_enable      :   STD_LOGIC;
   signal timer1_enable      :   STD_LOGIC;
   signal timer1_debounce    :   STD_LOGIC;
   signal timer0_out_int     :   STD_LOGIC;
   signal timer1_out_int     :   STD_LOGIC;
   signal timer0_counter     :   STD_LOGIC_VECTOR(23 downto 0);
   signal timer1_counter     :   STD_LOGIC_VECTOR(23 downto 0);
   signal timer0_count_max   :   STD_LOGIC_VECTOR(23 downto 0);
   signal timer1_count_max   :   STD_LOGIC_VECTOR(23 downto 0);
   
   
   constant C_timer0_c_max   :   STD_LOGIC_VECTOR(23 downto 0) :=
            std_logic_vector(to_unsigned(191109,24));
            -- C4 - Middle C  261.63Hz @ 100Mhz core frequency
begin
   -- //----------------------------------------------------------------------
   -- //
   -- // Combinationals
   -- //
   -- //----------------------------------------------------------------------
   -- //
   TIMER0_OUT <= '1' when timer0_enable = '1' and  timer0_out_int = '1' else '0';
   TIMER1_OUT <= '1' when timer1_enable = '1' and  timer1_out_int = '1' else '0';
   DATA_OUT   <= x"5A"; --// Timer Device ID

   -- //----------------------------------------------------------------------
   -- //
   -- // Timer
   -- //
   -- //----------------------------------------------------------------------
   --//

   process(CORE_CLK)
   begin
      if(rising_edge(CORE_CLK)) then
         if(RST_n = '0') then
            timer0_count_max  <= C_timer0_c_max; 
            timer0_enable     <= '1';
            timer0_counter    <= (others => '0');
            timer0_out_int    <= '1';
            timer1_count_max  <= (others => '0');
            timer1_enable     <= '0';
            timer1_counter    <= (others => '0');
            timer1_out_int    <= '0';	  
            timer1_debounce   <= '0';
         else
            if(STROBE_WR = '1') then
               case ADDRESS is
                  when "0000" => timer0_count_max(23 downto 16) <= DATA_IN;
                  when "0001" => timer0_count_max(15 downto 8)  <= DATA_IN;
                  when "0010" => timer0_count_max( 7 downto 0)  <= DATA_IN;
                  when "0011" => timer0_enable                  <= DATA_IN(0);
                  when "0100" => timer1_count_max(23 downto 16) <= DATA_IN;
                  when "0101" => timer1_count_max(15 downto  8) <= DATA_IN;
                  when "0110" => timer1_count_max( 7 downto  0) <= DATA_IN;
                  when "0111" => timer1_enable                  <= DATA_IN(0);
                  when "1000" => timer1_debounce                <= '1';
                  when others => null;
               end case;
            else
               timer1_debounce <= '0';
            end if;
         end if;
         
         --// Timer0 - Frequency Generator	
         if (timer0_enable = '0' or timer0_counter=timer0_count_max) then
            timer0_counter <= (others => '0');
            timer0_out_int <= not timer0_out_int;
         else 
            timer0_counter <= std_logic_vector(unsigned(timer0_counter) + 1);
         end if;

         -- // Timer1 - One-shot Generator
         if (timer1_enable='0' or timer1_counter=timer1_count_max) then
            timer1_counter <= (others => '0');
         else 
            timer1_counter <= std_logic_vector(unsigned(timer1_counter) + 1);
         end if;
				
         if (timer1_enable = '0' or timer1_debounce = '1') then
            timer1_out_int <= '0';
         elsif (timer1_counter = timer1_count_max) then
            timer1_out_int <= '1';
         end if;
      end if;
   end process;
end Behavioral;
