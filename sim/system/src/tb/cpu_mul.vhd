library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

entity cpu_mul is
   port 
   (
      clk       : in  std_logic;
      sign      : in  std_logic;
      value1_in : in  std_logic_vector(63 downto 0);        
      value2_in : in  std_logic_vector(63 downto 0);      
      result    : out std_logic_vector(127 downto 0)
   );
end entity;

architecture arch of cpu_mul is
   
   signal mul_delay : std_logic_vector(127 downto 0);
  
begin 

   process (clk) is
   begin
      if rising_edge(clk) then

         if (sign = '1') then
            mul_delay <= std_logic_vector(signed(value1_in) * signed(value2_in));
         else
            mul_delay <= std_logic_vector(unsigned(value1_in) * unsigned(value2_in));
         end if;
         
         result <= mul_delay;

      end if;
   end process;

end architecture;





