library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa_task3 is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(17 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0));  -- red lights
end ksa_task3;

-- Architecture part of the description

architecture rtl of ksa_task3 is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT d_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;
	
	COMPONENT e_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, state_fill, state_reads, state_temp, state_temp2, 
								state_swap1, state_swap2, state_swap3, state_done, state_encrypt,
								state_temp3, state_encrypt2, state_temp4, state_encrypt3, state_encrypt4,
								state_encrypt5, state_temp5, state_encrypt6);					
	
	signal reset : std_logic;
	
	type secretKey_array is array (2 downto 0) of std_logic_vector(7 downto 0);
	signal secretKey : secretKey_array;
	
    -- These are signals that are used to connect to the memory													 
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal address_m, address_d : STD_LOGIC_VECTOR (4 DOWNTO 0);
	 signal data, data_d : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren, wren_d : STD_LOGIC;
	 signal q, q_d, q_m : STD_LOGIC_VECTOR (7 DOWNTO 0);

	 begin
	    -- Include the S memory structurally
	
	u0: s_memory port map (
			address, CLOCK_50, data, wren, q);
	
	u1: d_memory port map (
			address_d, CLOCK_50, data_d, wren_d, q_d);
			
	u2: e_memory port map (
			address_m, CLOCK_50, q_m);
	
			  
	 -- write your code here.  As described in the slide set, this 
	 -- code will drive the address, data, and wren signals to
	 -- fill the memory with the values 0...255
		
	 -- You will be likely writing this is a state machine. Ensure
	 -- that after the memory is filled, you enter a DONE state which
	 -- does nothing but loop back to itself.
	
	reset <= not Key(3);
	
	process(clock_50, reset)
	variable i, j, k 								: integer 								:= 0;
	variable temp_si, temp_ji, f, qm_data	: std_logic_vector(7 downto 0)	:= x"00";
	variable mod_temp 							: integer								:= 0;
	variable current_state						: state_type;
	variable secretKey_new						: unsigned(23 downto 0)				:= x"000000";
	begin
		if reset = '1' then
			current_state := state_init;
		elsif rising_edge(clock_50) then
			case current_state is
			
				when state_init =>
					i := 0;
					j := 0;
					k := 0;
					secretKey(0) <= x"00";
					secretKey(1) <= x"00";
					secretKey(2) <= x"00";
					address <= x"00";
					data <= x"00";
					current_state := state_fill;
					
				when state_fill =>
					address <= std_logic_vector(to_unsigned(i, 8));
					data <= std_logic_vector(to_unsigned(i, 8));
					wren <= '1';
					i := i + 1;
					if i = 256 then
						i := 0;
						current_state := state_reads;
					end if;
					
				when state_reads =>
					address <= std_logic_vector(to_unsigned(i, 8));
					wren <= '0';
					current_state := state_temp;
					
				when state_temp =>
					current_state := state_swap1;
					
				when state_swap1 =>
					temp_si := q;
					j := ((j + to_integer(unsigned(temp_si)) + to_integer(unsigned(secretKey(i mod 3)))) mod 256);
					address <= std_logic_vector(to_unsigned(j, 8));
					wren <= '0';
					current_state := state_temp2;
					
				when state_temp2 =>
					current_state := state_swap2;
					
				when state_swap2 =>
					temp_ji := q;
					address <= std_logic_vector(to_unsigned(i, 8));
					data <= temp_ji;
					wren <= '1';
					current_state := state_swap3;
					
				when state_swap3 =>
					address <= std_logic_vector(to_unsigned(j, 8));
					data <= temp_si;
					wren <= '1';
					i := i + 1;
					if i = 256 then
						i := 0;
						j := 0;
						current_state := state_encrypt;
					else
						current_state := state_reads;
					end if;
				
				when state_encrypt =>
					i := (i + 1) mod 256;
					wren_d <= '0';
					address <= std_logic_vector(to_unsigned(i, 8));
					wren <= '0';
					current_state := state_temp3;
				
				when state_temp3 =>
					current_state := state_encrypt2;
					
				when state_encrypt2 =>
					temp_si := q;
					j := ((j + to_integer(unsigned(temp_si))) mod 256);
					address <= std_logic_vector(to_unsigned(j, 8));
					wren <= '0';
					current_state := state_temp4;
					
				when state_temp4 =>
					current_state := state_encrypt3;
				
				when state_encrypt3 =>
					temp_ji := q;
					address <= std_logic_vector(to_unsigned(i, 8));
					data <= temp_ji;
					wren <= '1';
					current_state := state_encrypt4;
					
				when state_encrypt4 => 
					address <= std_logic_vector(to_unsigned(j, 8));
					data <= temp_si;
					wren <= '1';
					current_state := state_encrypt5;
				
				when state_encrypt5 =>
					mod_temp := to_integer(unsigned(temp_si) + unsigned(temp_ji) mod 256);
					address <= std_logic_vector(to_unsigned(mod_temp, 8));
					address_m <= std_logic_vector(to_unsigned(k ,5));
					wren <= '0';
					current_state := state_temp5;
					
				when state_temp5 =>
					current_state := state_encrypt6;
				
				when state_encrypt6 =>
					f := q;
					address_d <= std_logic_vector(to_unsigned(k, 5));
					qm_data := f xor q_m;
					
					if (((qm_data < x"61") or (qm_data > x"7A")) and (qm_data /= x"20") and (k /= 32)) then
						i := 0;
						j := 0;
						k := 0;
						wren_d <= '0';
						if secretKey_new = x"03FFFFF" then
							LEDR <= "000000000000000001";
							current_state := state_done;
						else
							secretKey_new := secretKey_new + 1;
							secretKey(0) <= std_logic_vector(secretKey_new(23 downto 16));
							secretKey(1) <= std_logic_vector(secretKey_new(15 downto 8));
							secretKey(2) <= std_logic_vector(secretKey_new(7 downto 0));
							current_state := state_fill;
						end if;
					elsif k = 32 then
						LEDG <= x"01";
						LEDR <= "000000000000000000";
						current_state := state_done;
					else
						k := k + 1;
						data_d <= qm_data;
						wren_d <= '1';
						LEDG <= x"00";
						LEDR <= "000000000000000000";
						current_state := state_encrypt;
					end if;
					
				when state_done =>
					current_state := state_done;
				end case;
				
			end if;
	end process;
end RTL;
