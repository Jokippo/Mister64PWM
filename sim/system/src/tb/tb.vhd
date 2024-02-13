library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     
library STD;    
use STD.textio.all;

library tb;
library n64;

library procbus;
use procbus.pProc_bus.all;
use procbus.pRegmap.all;

library reg_map;
use reg_map.pReg_tb.all;

entity etb  is
end entity;

architecture arch of etb is

   constant clk_speed         : integer := 62500000;
   constant baud              : integer := 10000000;
                              
   signal clk1x               : std_logic := '1';
   signal clk93               : std_logic := '1';
   signal clk2x               : std_logic := '1';
   signal clkvid              : std_logic := '1';
                              
   signal reset               : std_logic;
   signal pause               : std_logic := '0';
   signal romcopy_start       : std_logic := '0';
   
   signal command_in          : std_logic;
   signal command_out         : std_logic;
   signal command_out_filter  : std_logic;
   
   signal proc_bus_in : proc_bus_type;
   
   -- settings
   signal n64_on              : std_logic_vector(Reg_n64_on.upper             downto Reg_n64_on.lower)             := (others => '0');
   signal n64_SaveState       : std_logic_vector(Reg_n64_SaveState.upper      downto Reg_n64_SaveState.lower)      := (others => '0');
   signal n64_LoadState       : std_logic_vector(Reg_n64_LoadState.upper      downto Reg_n64_LoadState.lower)      := (others => '0');
   
   -- ddrram
   signal DDRAM_CLK           : std_logic;
   signal DDRAM_BUSY          : std_logic;
   signal DDRAM_BURSTCNT      : std_logic_vector(7 downto 0);
   signal DDRAM_ADDR          : std_logic_vector(28 downto 0);
   signal DDRAM_DOUT          : std_logic_vector(63 downto 0);
   signal DDRAM_DOUT_READY    : std_logic;
   signal DDRAM_RD            : std_logic;
   signal DDRAM_DIN           : std_logic_vector(63 downto 0);
   signal DDRAM_BE            : std_logic_vector(7 downto 0);
   signal DDRAM_WE            : std_logic;
   
   --sdram access 
   signal sdram_dataWrite     : std_logic_vector(31 downto 0);
   signal sdram_dataRead      : std_logic_vector(31 downto 0);
   signal sdram_Adr           : std_logic_vector(26 downto 0);
   signal sdram_be            : std_logic_vector(3 downto 0);
   signal sdram_rnw           : std_logic;
   signal sdram_ena           : std_logic;
   signal sdram_done          : std_logic;        
   signal sdram_reqprocessed  : std_logic;        
   
   -- video
   signal hblank              : std_logic;
   signal vblank              : std_logic;
   signal video_ce            : std_logic;
   signal video_interlace     : std_logic;
   signal video_r             : std_logic_vector(7 downto 0);
   signal video_g             : std_logic_vector(7 downto 0);
   signal video_b             : std_logic_vector(7 downto 0);
   
begin

   -- using wrong 66,6/100mhz clock because of nice values
   clk1x <= not clk1x after 7500 ps;
   clk93 <= not clk93 after 5000 ps;
   clk2x <= not clk2x after 3750 ps;
   
   reset  <= not n64_on(0);
   
   process 
   begin
      wait for 1 ms;
      wait until rising_edge(clk1x);
      romcopy_start <= '0'; --'1';
      wait until rising_edge(clk1x);
      romcopy_start <= '0';
      wait;
   end process;
   
   -- NTSC 48.68 Mhz - 773.5 * 263 - 3094 clock cycles per line (VI_H_SYNC), 526/525 half lines (VI_V_SYNC)
   clkvid <= not clkvid after 10271 ps;
   -- PAL 49.65 Mhz - 3178 clock cycles per line, 626/625 half lines
   --clkvid <= not clkvid after 10070 ps;
   
   -- registers
   iReg_n64_on            : entity procbus.eProcReg generic map (Reg_n64_on)        port map (clk1x, proc_bus_in, n64_on        , n64_on);      
   iReg_n64_SaveState     : entity procbus.eProcReg generic map (Reg_n64_SaveState) port map (clk1x, proc_bus_in, n64_SaveState , n64_SaveState);      
   iReg_n64_LoadState     : entity procbus.eProcReg generic map (Reg_n64_LoadState) port map (clk1x, proc_bus_in, n64_LoadState , n64_LoadState);   
   
   pause <= '0';
   --pause <= not pause after 1 ms;

   in64top : entity n64.n64top
   generic map
   (
      use2Xclock            => '1',
      is_simu               => '1'
   )
   port map
   (
      clk1x                 => clk1x,          
      clk93                 => clk93,          
      clk2x                 => clk2x,          
      clkvid                => clkvid,
      reset                 => reset,
      pause                 => '0',
      errorCodesOn          => '1',
      fpscountOn            => '1',
      
      ISPAL                 => '0',
      FIXEDBLANKS           => '0',
      CROPVERTICAL          => "00",
      VI_BILINEAROFF        => '0',
      VI_GAMMAOFF           => '0',
      VI_NOISEOFF           => '1',
      VI_DEDITHEROFF        => '0',
      VI_DEDITHERFORCE      => '0',
      VI_AAOFF              => '0',
      VI_DIVOTOFF           => '0',
      
      CICTYPE               => "0000",
      RAMSIZE8              => '1',
      FASTRAM               => '0',
      INSTRCACHEON          => '1',
      DATACACHEON           => '1',
      DATACACHESLOW         => "0000",
      DATACACHEFORCEWEB     => '0',
      DATACACHETLBON        => '1',
      RANDOMMISS            => x"0",
      DISABLE_BOOTCOUNT     => '0',
      DISABLE_DTLBMINI      => '0',
      DDR3SLOW              => "0000",
      DISABLEFILTER         => '0',
      DISABLEDITHER         => '0',
      DISABLELOD            => '0',
      
      write9                => '1',
      read9                 => '1',
      wait9                 => '1',
      writeZ                => '1',
      readZ                 => '1',
      
      -- savestates              
      increaseSSHeaderCount => '1',
      save_state            => n64_SaveState(0),
      load_state            => n64_LoadState(0),
      savestate_number      => 2,
      state_loaded          => open,
      
      -- PIFROM download port
      pifrom_wraddress      => 10x"000",
      pifrom_wrdata         => x"00000000",   
      pifrom_wren           => '0',     
               
      -- RDRAM
      ddr3_BUSY             => DDRAM_BUSY,
      ddr3_DOUT             => DDRAM_DOUT,
      ddr3_DOUT_READY       => DDRAM_DOUT_READY,
      ddr3_BURSTCNT         => DDRAM_BURSTCNT,
      ddr3_ADDR             => DDRAM_ADDR,
      ddr3_DIN              => DDRAM_DIN,
      ddr3_BE               => DDRAM_BE,
      ddr3_WE               => DDRAM_WE,
      ddr3_RD               => DDRAM_RD,
      
      -- ROM+SRAM+FLASH
      cartAvailable         => '1',
      romcopy_start         => romcopy_start,
      romcopy_size          => 27x"100000", -- 1 mbyte
      
      sdram_ena             => sdram_ena,      
      sdram_rnw             => sdram_rnw,     
      sdram_Adr             => sdram_Adr,      
      sdram_be              => sdram_be,       
      sdram_dataWrite       => sdram_dataWrite,
      sdram_reqprocessed    => sdram_reqprocessed,     
      sdram_done            => sdram_done,     
      sdram_dataRead        => sdram_dataRead, 
      
      -- pad
      PADTYPE0              => "000",
      PADTYPE1              => "001",
      PADTYPE2              => "001",
      PADTYPE3              => "001",
      MOUSETYPE             => "000",
      PADDPADSWAP           => '0',
      pad_A                 => "0000",
      pad_B                 => "0000",
      pad_Z                 => "0000",
      pad_START             => "0000",
      pad_DPAD_UP           => "0000",
      pad_DPAD_DOWN         => "0000",
      pad_DPAD_LEFT         => "0000",
      pad_DPAD_RIGHT        => "0000",
      pad_L                 => "0000",
      pad_R                 => "0000",
      pad_C_UP              => "0000",
      pad_C_DOWN            => "0000",
      pad_C_LEFT            => "0000",
      pad_C_RIGHT           => "0000",
      pad_0_analog_h        => x"00",
      pad_0_analog_v        => x"00",
      pad_1_analog_h        => x"00",
      pad_1_analog_v        => x"00",
      pad_2_analog_h        => x"00",
      pad_2_analog_v        => x"00",
      pad_3_analog_h        => x"00",
      pad_3_analog_v        => x"00", 
      
      MouseEvent            => '0',
      MouseLeft             => '0',
      MouseRight            => '0',
      MouseMiddle           => '0',
      MouseX                => 9x"00",
      MouseY                => 9x"00",
      
      --snac
      PIFCOMPARE            => '0',
      toPad_readySNAC       => '0',
      toPIF_timeoutSNAC     => '0',
      toPIF_enaSNAC         => '0',
      toPIF_dataSNAC        => x"00",
      
      -- audio
      DISABLE_AI            => '0',
      DISABLE_AI_IRQ        => '0',
      
      -- saves              
      SAVETYPE              => "011",
      CONTROLLERPAK         => '1',
      TRANSFERPAK           => '0',
      
      save                  => '0', 
      load                  => '0', 
      mounted               => '0', 
      changePending         => open,
      save_ongoing          => open,
      save_rd               => open,
      save_wr               => open,
      save_lba              => open,
      save_ack              => '0', 
      save_write            => '0', 
      save_addr             => 8x"0",
      save_dataIn           => 16x"0",
      save_dataOut          => open,
             
      -- video out
      video_hsync           => open,
      video_vsync           => open,
      video_hblank          => hblank,
      video_vblank          => vblank,
      video_ce              => video_ce,
      video_interlace       => video_interlace,
      video_r               => video_r, 
      video_g               => video_g,    
      video_b               => video_b
   );
   
   iddrram_model : entity tb.ddrram_model
   generic map
   (
      SLOWTIMING   => 15,
      RANDOMTIMING => '0' 
   )
   port map
   (
      DDRAM_CLK        => clk2x,      
      DDRAM_BUSY       => DDRAM_BUSY,      
      DDRAM_BURSTCNT   => DDRAM_BURSTCNT,  
      DDRAM_ADDR       => DDRAM_ADDR,      
      DDRAM_DOUT       => DDRAM_DOUT,      
      DDRAM_DOUT_READY => DDRAM_DOUT_READY,
      DDRAM_RD         => DDRAM_RD,        
      DDRAM_DIN        => DDRAM_DIN,       
      DDRAM_BE         => DDRAM_BE,        
      DDRAM_WE         => DDRAM_WE        
   );
   
   isdram_model : entity tb.sdram_model
   generic map
   (
      DOREFRESH         => '0',
      INITFILE          => "NONE",
      SCRIPTLOADING     => '1',
      FILELOADING       => '0'
   )
   port map
   (
      clk               => clk1x,
      addr              => sdram_Adr,
      req               => sdram_ena,
      rnw               => sdram_rnw,
      be                => sdram_be,
      di                => sdram_dataWrite,
      do                => sdram_dataRead,
      reqprocessed      => sdram_reqprocessed,
      done              => sdram_done,
      fileSize          => open
   );
   
   iframebuffer : entity work.framebuffer
   port map
   (
      clk               => clkvid,     
      hblank            => hblank,  
      vblank            => vblank,  
      video_ce          => video_ce,
      video_interlace   => video_interlace,
      video_r           => video_r, 
      video_g           => video_g,    
      video_b           => video_b  
   );
   
   iTestprocessor : entity procbus.eTestprocessor
   generic map
   (
      clk_speed => clk_speed,
      baud      => baud,
      is_simu   => '1'
   )
   port map 
   (
      clk               => clk1x,
      bootloader        => '0',
      debugaccess       => '1',
      command_in        => command_in,
      command_out       => command_out,
            
      proc_bus          => proc_bus_in,
      
      fifo_full_error   => open,
      timeout_error     => open
   );
   
   command_out_filter <= '0' when command_out = 'Z' else command_out;
   
   itb_interpreter : entity tb.etb_interpreter
   generic map
   (
      clk_speed => clk_speed,
      baud      => baud
   )
   port map
   (
      clk         => clk1x,
      command_in  => command_in, 
      command_out => command_out_filter
   );
   
end architecture;


