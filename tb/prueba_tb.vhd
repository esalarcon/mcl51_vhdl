LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY prueba_tb IS
END prueba_tb;
 
ARCHITECTURE behavior OF prueba_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MCL51_top
    PORT(
         CLK : IN  std_logic;
         RESET_n : IN  std_logic;
         SPEAKER : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RESET_n : std_logic := '0';

 	--Outputs
   signal SPEAKER : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MCL51_top PORT MAP (
          CLK => CLK,
          RESET_n => RESET_n,
          SPEAKER => SPEAKER
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '1';
		wait for CLK_period/2;
		CLK <= '0';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      RESET_n <= '0';
      wait for CLK_period*4;
      RESET_n <= '1';

      -- insert stimulus here 

      wait;
   end process;

END;
