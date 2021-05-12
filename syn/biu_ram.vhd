library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity biu_ram is
    Port ( clk    : in  STD_LOGIC;
           addr   : in  STD_LOGIC_VECTOR (8 downto 0);
           din    : in  STD_LOGIC_VECTOR (7 downto 0);
           dout   : out STD_LOGIC_VECTOR (7 downto 0);
           we     : in  STD_LOGIC);
end biu_ram;

architecture Behavioral of biu_ram is
   type t_ram is array (natural range <>) of std_logic_vector(7 downto 0);
   signal ram     :  t_ram(511 downto 0)  := (others => (others => '0'));  
   signal i_addr  :  natural range 0 to 511;
begin
   i_addr <= to_integer(unsigned(addr));
   process(clk)
   begin
      if(rising_edge(clk)) then
         dout <= ram(i_addr);
         if(we = '1') then
            ram(i_addr) <= din;
         end if;
      end if;
   end process;
end Behavioral;

