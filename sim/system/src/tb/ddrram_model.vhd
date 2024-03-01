library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     
use STD.textio.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

library tb;
use tb.globals.all;

entity ddrram_model is
   generic
   (
      LOADRDRAM     : std_logic := '0';
      SLOWTIMING    : integer := 0;
      RANDOMTIMING  : std_logic := '0';
      OUTPUT_VIFB   : std_logic := '0'
   );
   port 
   (
      DDRAM_CLK        : in  std_logic;                    
      DDRAM_BUSY       : out std_logic := '0';                    
      DDRAM_BURSTCNT   : in  std_logic_vector(7 downto 0); 
      DDRAM_ADDR       : in  std_logic_vector(28 downto 0);
      DDRAM_DOUT       : out std_logic_vector(63 downto 0) := (others => '0');
      DDRAM_DOUT_READY : out std_logic := '0';                    
      DDRAM_RD         : in  std_logic;                    
      DDRAM_DIN        : in  std_logic_vector(63 downto 0);
      DDRAM_BE         : in  std_logic_vector(7 downto 0); 
      DDRAM_WE         : in  std_logic                    
   );
end entity;

architecture arch of ddrram_model is

   -- not full size, because of memory required
   type t_data is array(0 to (2**28)-1) of integer;
   type bit_vector_file is file of bit_vector;
   type t_ssfile is file of character;
   
   signal intern_addr : STD_LOGIC_VECTOR(DDRAM_ADDR'left downto 0);
   
begin

   intern_addr <= "000" & DDRAM_ADDR(24 downto 0) & "0";

   process
   
      variable seed1 : positive;
      variable seed2 : positive;
      variable rnd   : real;
      variable waittiming     : integer := 0;
   
      variable data : t_data := (others => 0);
      variable cmd_address_save : STD_LOGIC_VECTOR(DDRAM_ADDR'left downto 0);
      variable cmd_burst_save   : STD_LOGIC_VECTOR(DDRAM_BURSTCNT'left downto 0);
      variable cmd_din_save     : STD_LOGIC_VECTOR(63 downto 0);
      variable cmd_be_save      : STD_LOGIC_VECTOR(7 downto 0);
      
      file infile             : bit_vector_file;
      variable f_status       : FILE_OPEN_STATUS;
      variable read_byte0     : std_logic_vector(7 downto 0);
      variable read_byte1     : std_logic_vector(7 downto 0);
      variable read_byte2     : std_logic_vector(7 downto 0);
      variable read_byte3     : std_logic_vector(7 downto 0);
      variable next_vector    : bit_vector (3 downto 0);
      variable actual_len     : natural;
      variable targetpos      : integer;
      variable loadcount      : integer;
      
      variable readval        : signed(31 downto 0); 
      
      file ssfile             : t_ssfile;
      
      file outfile            : text;
      variable line_out       : line;
      variable stringbuffer   : string(1 to 31);
      variable pixel_posx     : integer;
      variable pixel_posy     : integer;
      variable pixelcolor     : unsigned(31 downto 0);
      
      -- copy from std_logic_arith, not used here because numeric std is also included
      function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) return STD_LOGIC_VECTOR is
        variable result: STD_LOGIC_VECTOR (SIZE-1 downto 0);
        variable temp: integer;
      begin
 
         temp := ARG;
         for i in 0 to SIZE-1 loop
 
         if (temp mod 2) = 1 then
            result(i) := '1';
         else 
            result(i) := '0';
         end if;
 
         if temp > 0 then
            temp := temp / 2;
         elsif (temp > integer'low) then
            temp := (temp - 1) / 2; -- simulate ASR
         else
            temp := temp / 2; -- simulate ASR
         end if;
        end loop;
 
        return result;  
      end;
   
   begin
      
      if (LOADRDRAM = '1') then
         file_open(f_status, infile, "R:\\RDRAM_FPGN64.bin", read_mode);
         
            targetpos := 0;
         
            while (not endfile(infile)) loop
               
               read(infile, next_vector, actual_len);  
               
               read_byte0 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(0)), 8);
               read_byte1 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(1)), 8);
               read_byte2 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(2)), 8);
               read_byte3 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(3)), 8);
            
               data(targetpos) := to_integer(signed(read_byte0 & read_byte1 & read_byte2 & read_byte3));
               targetpos       := targetpos + 1;

            end loop;
         
            file_close(infile);
            
            report "RDRAM loaded";
         
      end if;
      
      if (OUTPUT_VIFB = '1') then
         file_open(f_status, outfile, "gra_VIFB.gra", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "gra_VIFB.gra", append_mode);
         write(line_out, string'("640#480#2")); 
         writeline(outfile, line_out);
      end if;
      
      seed1 := 1;
      seed2 := 1;
      
      while (1=1) loop
   
         wait until rising_edge(DDRAM_CLK);
         
         if (DDRAM_RD = '1') then
            cmd_address_save := intern_addr;
            cmd_burst_save   := DDRAM_BURSTCNT;
            wait until rising_edge(DDRAM_CLK);
            if (SLOWTIMING > 0) then
               waittiming := SLOWTIMING;
               if (RANDOMTIMING = '1') then
                  uniform(seed1, seed2, rnd);
                  waittiming := waittiming + integer(floor(rnd * real(SLOWTIMING)));
               end if;
               for i in 1 to waittiming loop
                  wait until rising_edge(DDRAM_CLK);
               end loop;
            end if;
            --report "read from " & integer'image(to_integer(unsigned(cmd_address_save)));
            for i in 0 to (to_integer(unsigned(cmd_burst_save)) - 1) loop
               DDRAM_DOUT       <= std_logic_vector(to_signed(data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 1), 32)) & 
                                   std_logic_vector(to_signed(data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 0), 32));
               DDRAM_DOUT_READY <= '1';
               wait until rising_edge(DDRAM_CLK);
            end loop;
            --report "data = " & integer'image(to_integer(unsigned(DDRAM_DOUT(31 downto 0))));
            DDRAM_DOUT_READY <= '0';
         end if;  
         
         if (DDRAM_WE = '1') then
            DDRAM_BUSY       <= '1';
            cmd_address_save := intern_addr;
            cmd_burst_save   := DDRAM_BURSTCNT;
            cmd_din_save     := DDRAM_DIN;
            cmd_be_save      := DDRAM_BE;
            for i in 0 to (to_integer(unsigned(cmd_burst_save)) - 1) loop    
               
               -- lower 32 bit
               readval := to_signed(data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 0), 32);
               if (cmd_be_save(0) = '1') then readval( 7 downto  0) := signed(DDRAM_DIN( 7 downto  0)); end if;
               if (cmd_be_save(1) = '1') then readval(15 downto  8) := signed(DDRAM_DIN(15 downto  8)); end if;
               if (cmd_be_save(2) = '1') then readval(23 downto 16) := signed(DDRAM_DIN(23 downto 16)); end if;
               if (cmd_be_save(3) = '1') then readval(31 downto 24) := signed(DDRAM_DIN(31 downto 24)); end if;
               data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 0) := to_integer(readval);
               
               -- upper 32 bit
               readval := to_signed(data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 1), 32);
               if (cmd_be_save(4) = '1') then readval( 7 downto  0) := signed(DDRAM_DIN(39 downto 32)); end if;
               if (cmd_be_save(5) = '1') then readval(15 downto  8) := signed(DDRAM_DIN(47 downto 40)); end if;
               if (cmd_be_save(6) = '1') then readval(23 downto 16) := signed(DDRAM_DIN(55 downto 48)); end if;
               if (cmd_be_save(7) = '1') then readval(31 downto 24) := signed(DDRAM_DIN(63 downto 56)); end if;
               data(to_integer(unsigned(cmd_address_save)) + (i * 2) + 1) := to_integer(readval);

               --wait until rising_edge(DDRAM_CLK);
            end loop;
            --wait for 200 ns;
            if (RANDOMTIMING = '1') then
               uniform(seed1, seed2, rnd);
               waittiming := integer(floor(rnd * 100.0));
            end if;
            for i in 97 to waittiming loop
               wait until rising_edge(DDRAM_CLK);
            end loop;
            DDRAM_BUSY       <= '0';
         end if;  
         
         COMMAND_FILE_ACK_2 <= '0';
         if COMMAND_FILE_START_2 = '1' then
            
            assert false report "received" severity note;
            assert false report COMMAND_FILE_NAME(1 to COMMAND_FILE_NAMELEN) severity note;
         
            file_open(f_status, infile, COMMAND_FILE_NAME(1 to COMMAND_FILE_NAMELEN), read_mode);
         
            targetpos := COMMAND_FILE_TARGET;
            
            report "written to " & integer'image(targetpos);
         
            for i in 1 to (COMMAND_FILE_OFFSET / 4) loop
               read(infile, next_vector, actual_len); 
            end loop;
         
            loadcount := 0;

            while (not endfile(infile) and (COMMAND_FILE_SIZE = 0 or loadcount < COMMAND_FILE_SIZE)) loop
               
               read(infile, next_vector, actual_len);  
               
               read_byte0 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(0)), 8);
               read_byte1 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(1)), 8);
               read_byte2 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(2)), 8);
               read_byte3 := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(3)), 8);
            
               if (COMMAND_FILE_ENDIAN = '1') then
                  data(targetpos) := to_integer(signed(read_byte3 & read_byte2 & read_byte1 & read_byte0));
               else
                  data(targetpos) := to_integer(signed(read_byte0 & read_byte1 & read_byte2 & read_byte3));
               end if;
                              
               --if (loadcount = 0) then
               --    report "First DWORD = " & integer'image(data(targetpos));
               --end if;
               
               targetpos       := targetpos + 1;
               loadcount       := loadcount + 4;
               
            end loop;
            
            report "bytes loaded " & integer'image(loadcount);
         
            file_close(infile);
         
            COMMAND_FILE_ACK_2 <= '1';
         
         end if;
         
         if (OUTPUT_VIFB = '1') then
            if (DDRAM_WE = '1' and DDRAM_ADDR(24 downto 21) = "0001") then
               
               if (pixel_posy /= to_integer(unsigned(DDRAM_ADDR(17 downto 9)))) then
                  file_close(outfile);
                  file_open(f_status, outfile, "gra_VIFB.gra", append_mode);
               end if;
               
               pixel_posx := to_integer(unsigned(DDRAM_ADDR(8 downto 0))) * 2;
               pixel_posy := to_integer(unsigned(DDRAM_ADDR(17 downto 9)));
               
               pixelcolor := x"00" & unsigned(DDRAM_DIN(7 downto 0)) & unsigned(DDRAM_DIN(15 downto 8)) & unsigned(DDRAM_DIN(23 downto 16));
               write(line_out, to_integer(pixelcolor));
               write(line_out, string'("#"));
               write(line_out, pixel_posx);
               write(line_out, string'("#")); 
               write(line_out, pixel_posy);
               writeline(outfile, line_out);
               
               pixelcolor := x"00" & unsigned(DDRAM_DIN(39 downto 32)) & unsigned(DDRAM_DIN(47 downto 40)) & unsigned(DDRAM_DIN(55 downto 48));
               write(line_out, to_integer(pixelcolor));
               write(line_out, string'("#"));
               write(line_out, pixel_posx + 1);
               write(line_out, string'("#")); 
               write(line_out, pixel_posy);
               writeline(outfile, line_out);
               
            end if;
         end if;
      
      end loop;
   
   
   end process;
   
end architecture;


