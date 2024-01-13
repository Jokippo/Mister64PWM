library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Shiftreg is
   generic
   (
      USE_BRAM    : std_logic;
      DEPTH       : natural;
      BITS        : natural
   );
   port
   (
      clk         : in std_logic;
      clk_en      : in std_logic;
      data_in     : in std_logic_vector(BITS-1 downto 0);
      data_out    : out std_logic_vector(BITS-1 downto 0)
   );
end entity;

architecture arch of Shiftreg is

   type tshiftreg is array(0 to DEPTH - 1) of std_logic_vector(BITS-1 downto 0);
   signal shiftreg : tshiftreg := (others => (others => '0'));

begin

   process(clk)
   begin
      if rising_edge(clk) then
         if (clk_en = '1') then
            shiftreg(0) <= data_in;
            for i in 1 to DEPTH - 1 loop
               shiftreg(i) <= shiftreg(i - 1);
            end loop;
         end if;
      end if;
   end process;
   
   data_out <= shiftreg(DEPTH - 1);

end architecture;
