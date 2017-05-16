-- Filename: Lab 06_task3+ Challenge
-- Author 1: Dennis Huebert	
-- Author 1 Student #: 301200111
-- Author 2: Eva Liu
-- Author 2 Student #: 301243938
-- Group Number: 1
-- Lab Section
-- Lab: Friday Morning
-- Task Completed: task3+ challenge
-- Date: 2017.04.07
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;   
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity bitops_unit is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --decode/issue
        new_request_dec : in std_logic;
        new_request : in std_logic;
        ready : out std_logic;
        
        --writeback
        early_done : out std_logic;
        accepted : in std_logic;
        rd : out std_logic_vector(31 downto 0);
        
        --inputs
        rs1 : in std_logic_vector(31 downto 0);
        fn3 : in std_logic_vector(2 downto 0);
        fn3_dec : in std_logic_vector(2 downto 0)
    );
end bitops_unit;
    
architecture Behavioral of bitops_unit is
	type state_type is (ini_state, pre_state,clz,popc,bswap,sqrt, read_state);
	signal current_state : state_type; 
begin
	
	process (clk)
		variable clz_i,popc_i,sqrt_i: integer;
		variable clz_y: unsigned (31 downto 0);
		variable popc_y,popc_result: unsigned (31 downto 0);
		variable bswap_result, bswap_y: unsigned (31 downto 0);
		variable q : unsigned(15 downto 0);
		variable s_left,s_right,r : unsigned(17 downto 0);
		variable sqrt_y: unsigned (31 downto 0);
		
		
   begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= ini_state;
				rd <= "00000000000000000000000000000000";
         else
				case current_state is
					when ini_state =>
						early_done <= '0';
						ready <= '1';
						popc_result := "00000000000000000000000000000000";
						clz_i := 31;
						popc_i := 0;
						current_state <= pre_state;
						
					when pre_state =>
						if (new_request = '1') then
							if (fn3 = "000") then 
								current_state <= clz;
								ready <= '0';
							elsif (fn3 = "001") then 
								current_state <= popc;
								ready <= '0';
								popc_i := 0;
							elsif (fn3 = "010") then 
								current_state <= bswap;
								ready <= '0';
							else 
								current_state <= sqrt;
								sqrt_i := 0;
								ready <= '0';					
							end if;
						else 
							current_state <= pre_state;
							ready <= '1';
						end if;
						
					--Count Leading zeros
					when clz=>
						if (rs1 = "00000000000000000000000000000000" ) then 
							rd <= std_logic_vector(to_unsigned(32,32));
							early_done <= '1';
							current_state <= ini_state;
						elsif(clz_i >= 0) then 
							clz_y := shift_right(unsigned(rs1), clz_i);
							if (clz_y = "00000000000000000000000000000001" ) then 
								rd <= std_logic_vector(to_unsigned((31-clz_i),32));
								early_done <= '1';
								current_state <= ini_state;
							else
								current_state <= clz;
							end if;
							clz_i := clz_i - 1;
						else 
							rd <= std_logic_vector(to_unsigned(32,32));
							early_done <= '1';
							current_state <= ini_state;
						end if;
						
					--Population count 
					when popc=>
						if (popc_i <32) then 
							popc_result := popc_result + ("0000000000000000000000000000000" & rs1(popc_i));
							current_state <= popc;
							popc_i := popc_i +1;
						elsif (popc_i = 32) then 
							rd <= std_logic_vector(popc_result);
							early_done <= '1';
							current_state <= ini_state;
						end if;
						
					
					--Swap bits
					when bswap=>
						bswap_result := "00000000000000000000000011111111" AND (shift_right(unsigned(rs1), 24));
						bswap_result := bswap_result OR ("00000000000000001111111100000000"  AND (shift_right(unsigned(rs1), 8)));
						bswap_result := bswap_result OR ("00000000111111110000000000000000"  AND (shift_left(unsigned(rs1), 8)));
						bswap_result := bswap_result OR ("11111111000000000000000000000000" AND (shift_left(unsigned(rs1), 24)));
						rd <= std_logic_vector(bswap_result);
						early_done <= '1';
						current_state <= ini_state;
					
					when sqrt=>
					
						s_left:= (others => '0');
						s_right:=(others => '0');
						r:= (others => '0');
						q:= (others => '0');
						sqrt_y:= unsigned(rs1);
						for sqrt_i in 0 to 15 loop
								s_right(0):='1';
								s_right(1):=r(17);
								s_right(17 downto 2):=q;
								s_left(1 downto 0):=sqrt_y(31 downto 30);
								s_left(17 downto 2):=r(15 downto 0);
								sqrt_y(31 downto 2):= sqrt_y(29 downto 0);  --shifting by 2 bit.
								
							if ( r(17) = '1') then
								r := s_left + s_right;
							else
								r := s_left - s_right;
							end if;
							q(15 downto 1) := q(14 downto 0);
							q(0) := NOT(r(17));
						end loop;
						rd <= std_logic_vector("0000000000000000"&q(15 downto 0));
						early_done <= '1';
						current_state <= ini_state;
							
					when others =>
						current_state <= ini_state;
					end case;
					
				end if;		
			end if;
		end process;		
end Behavioral;

    
    
    
