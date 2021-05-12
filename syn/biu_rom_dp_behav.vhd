--//
--//  File Name   :  biu_rom_dp_behav.v
--//  Used on     :  
--//  Author      :  MicroCore Labs
--//  Creation    :  3/17/2016
--//  Code Type   :  Behavioral
--//
--//   Description:
--//   ============
--//   DPRAM behavioral model.
--// 
--//
--
--//------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
USE std.textio.all;

entity biu_rom is
   port( clk   :  in  STD_LOGIC;
         addr  :  in  STD_LOGIC_VECTOR(11 downto 0);
         dout  :  out STD_LOGIC_VECTOR(7 downto 0));
end biu_rom;

architecture Behavioral of biu_rom is
   type t_ram_array is array (natural range <>) of std_logic_vector(7 downto 0);
   
   impure function init_ram(ram_file_name: in string) return t_ram_array is  
      file f            : text;
      variable l        : line;
      variable ram      : t_ram_array(4095 downto 0);
   begin
      file_open(f, ram_file_name, read_mode); 
      for i in 0 to 4095 loop
         readline(f,l);
         read(l,ram(i));
      end loop;
      file_close(f);
      return ram;
   end init_ram;

   signal ram_array           :  t_ram_array(4095 downto 0) := init_ram("C:\Users\esala\Desktop\mcl51\codigo\Objects\codigo.txt");
   signal ram_dataout         :  std_logic_vector(7 downto 0);
   signal i_addr              :  natural range 0 to 4095;
begin
   i_addr  <= to_integer(unsigned(addr ));
   process(clk)
   begin
      if(rising_edge(clk )) then
         dout  <= ram_array(i_addr );
      end if;
   end process;   
end Behavioral;
