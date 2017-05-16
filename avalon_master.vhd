-- Filename: Lab 06_task2
-- Author 1: Dennis Huebert	
-- Author 1 Student #: 301200111
-- Author 2: Eva Liu
-- Author 2 Student #: 301243938
-- Group Number: 1
-- Lab Section
-- Lab: Friday Morning
-- Task Completed: task2
-- Date: 2017.04.07
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity avalon_master is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --Bus ports
        addr : out std_logic_vector(31 downto 0);
        avread : out std_logic;
        avwrite : out std_logic;
        byteenable : out std_logic_vector(3 downto 0);
        readdata : in std_logic_vector(31 downto 0);
        writedata : out std_logic_vector(31 downto 0);
        waitrequest : in std_logic;
        readdatavalid : in std_logic;
        writeresponsevalid : in std_logic;
        
        --L/S interface
        addr_in : in std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        data_valid : out std_logic;
        ready : out std_logic;
        new_request : in std_logic;
        rnw : in std_logic;
        be : in std_logic_vector(3 downto 0);
        data_ack : in std_logic
    );
end avalon_master;
    
architecture Behavioral of avalon_master is
	type state_type is (ini_state, pre_read, read_state,write_state,ready_state);
	signal current_state : state_type;
        
begin  
   process (clk)
   begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= ini_state;
         else
				case current_state is
					--Initialization state 
					when ini_state =>
						avread <= '0';
						avwrite <= '0';
                  data_valid <= '0';
                  ready <= '1';
						current_state <= pre_read;
						
					--Prepare to read or write 								 
					when pre_read=>
                  if (new_request = '1') then
							if (rnw = '1') then
								current_state <= read_state;
								avread <= '1';
                        avwrite <= '0';
                        ready <= '0';
                        addr <= addr_in;
                        byteenable <= be;
							else
                        current_state <= write_state;
                        avwrite <= '1';
                        avread <= '0';
                        ready <= '0';
                        addr <= addr_in;
                        byteenable <= be;
								writedata <= data_in;
							end if;
                  else
                     current_state <= pre_read;
                  end if;
						
               --Read state, check waitrequest            
					when read_state =>
                  if (waitrequest = '0') then
                     data_out <= readdata;
                     data_valid <= '1';
                     avread <= '0';
                     current_state <= ready_state;
                  else
							data_valid <= '0';
                     avread <= '1';
							current_state <= read_state;
                  end if;
               
					--Ready state, check data_ack, whether Load/Store gets data
					when ready_state =>
                  if (data_ack = '1') then
                     ready <= '1';
                     data_valid <= '0';
                     current_state <= ini_state;
						else
							ready <= '0';
                     data_valid <= '1';
                     current_state <= ready_state;
                  end if;
						
               --Write state, check waitrequest                
					when write_state =>
                  if (waitrequest = '0') then
							ready <= '1';
                     avwrite <= '0';
                     current_state <= ini_state;
						else
							ready <= '0';
                     avwrite <= '1';
                     current_state <= write_state;
                  end if;
               
					--Other conditions
					when others =>
						current_state <= ini_state;                     
               end case;
				end if;
          end if;
        end process;
  
end Behavioral;

    
    
    

    
    
    
