library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity master_fir is
  -- generic(N      : integer := 16);
  Port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    -- start      : in  std_logic; -- !!!
    i_coeff_0 : in  std_logic_vector(31 downto 0);
    i_coeff_1 : in  std_logic_vector(31 downto 0);
    i_coeff_2 : in  std_logic_vector(31 downto 0);
    i_coeff_3 : in  std_logic_vector(31 downto 0);
    x_in       : in  std_logic_vector(31 downto 0);
    y_out      : out std_logic_vector(31 downto 0);
    we_out     : out std_logic; -- !!!                   -- write enable for the dpram
    -- address_read  : in std_logic_vector(9 downto 0);
    address_write : out std_logic_vector(9 downto 0));
end master_fir;


architecture Behavioral of master_fir is

component fir_filter_4 is
  port (
    i_clk     : in  std_logic;
    i_rstb    : in  std_logic;
    -- coefficient
    i_coeff_0 : in  std_logic_vector(31 downto 0);
    i_coeff_1 : in  std_logic_vector(31 downto 0);
    i_coeff_2 : in  std_logic_vector(31 downto 0);
    i_coeff_3 : in  std_logic_vector(31 downto 0);
    -- data input
    i_data    : in  std_logic_vector(31 downto 0);
    -- filtered data
    o_data    : out std_logic_vector(31 downto 0));
end component;



signal we : std_logic;
signal addr_0, addr_1: std_logic_vector(9 downto 0);
signal fir_clk : std_logic;
signal samples: integer;
signal first_run: std_logic;
type state is (s_idle, s_read, s_write);
signal state_fsm: state;
signal next_s: state;
signal y: std_logic_vector(31 downto 0);
--signal encoded_state : unsigned(1 downto 0);
signal x:std_logic_vector(31 downto 0);


--signal addr_0: std_logic_vector(8 downto 0);
--signal samples: std_logic_vector(8 downto 0);
type t_data_pipe is array (0 to 3) of signed(31 downto 0);
type t_coeff is array (0 to 3) of signed(31 downto 0);

type t_mult is array (0 to 3) of signed(31 downto 0);

signal r_coeff   : t_coeff;
signal p_data    : t_data_pipe;


--signal i_coeff_0  : std_logic_vector(31 downto 0) := X"00000001";
--signal i_coeff_1  : std_logic_vector(31 downto 0) := X"00000001";
--signal i_coeff_2  : std_logic_vector(31 downto 0) := X"00000001";
--signal i_coeff_3  : std_logic_vector(31 downto 0) := X"00000001";




begin

states_change:process(clk) is
    begin
    if falling_edge(clk) then
        state_fsm<=next_s;
    end if;
    end process;





fsm_fir: process(clk, rst) is --, state_fsm) is
    -- clk, rst: sensitivity list
    begin

        if rst = '1' then
            p_data  <= (others => (others => '0'));
            samples <= 0;
            we <= '0';
            next_s <= s_idle;
            fir_clk <= '0';
            --first_run <= '1';


        elsif rising_edge(clk) then

            case next_s is
            --case state_fsm is
            when s_idle =>
                we <= '0';
                -- if (start = '1') and (first_run = '1') then
                -- if (first_run = '1') then
                --first_run <= '0';
                addr_0 <= std_logic_vector(to_unsigned(samples, addr_0'length));
                next_s <= s_read;
                --else
                    --state_fsm <= s_idle;
                --end if;
            when s_read =>
                we <= '0';
                address_write <= std_logic_vector(to_unsigned(samples, addr_0'length));
                --y_out <= x_in;
                fir_clk <= '1';
                x <= std_logic_vector(unsigned(x_in));
                next_s <= s_write;

            when s_write =>
                we <= '1';
                address_write <= std_logic_vector(to_unsigned(samples+512, addr_0'length));-- + std_logic_vector(to_unsigned(512, addr_0'length));
                -- x <= std_logic_vector(unsigned(x_in));
                p_data <= signed(x)&p_data(0 to p_data'length-2);
                y_out  <= std_logic_vector(resize(
                                            p_data(0)*signed(i_coeff_0) +
                                            p_data(1)*signed(i_coeff_1) +
                                            p_data(2)*signed(i_coeff_2) +
                                            p_data(3)*signed(i_coeff_3), 32));--std_logic_vector(unsigned(y)); --x_in; --X"00000100";--y;
                --addr_1 <= std_logic_vector(to_unsigned(samples, addr_0'length)) + std_logic_vector(to_unsigned(512, addr_0'length));
                fir_clk <= '0';
                samples <= samples + 1;
                if samples = 512 then
                    samples <= 0;
                    we <= '0';
                    -- address_write <= std_logic_vector(to_unsigned(samples, addr_0'length));
                    next_s <= s_idle;
                else
                    next_s <= s_read;
                end if;

            when others =>
                next_s <= s_idle;

            end case;


        end if;
    end process;




--fsm_fir: process(clk, rst) is --, state_fsm) is
--    -- clk, rst: sensitivity list
--    begin

--        if rst = '1' then
--            samples <= "000000000";
--            we <= '0';
--            next_s <= s_idle;
--            fir_clk <= '0';
--            --first_run <= '1';


--        elsif rising_edge(clk) then

--            case next_s is
--            --case state_fsm is
--            when s_idle =>
--                we <= '0';
--                -- if (start = '1') and (first_run = '1') then
--                -- if (first_run = '1') then
--                --first_run <= '0';
--                addr_0 <= std_logic_vector(unsigned(samples));
--                next_s <= s_read;
--                --else
--                    --state_fsm <= s_idle;
--                --end if;
--            when s_read =>
--                we <= '0';
--                address_write <= "1" & std_logic_vector(unsigned(samples));
--                --y_out <= x_in;
--                fir_clk <= '1';
--                x <= std_logic_vector(unsigned(x_in));
--                next_s <= s_write;

--            when s_write =>
--                we <= '1';
--                address_write <= "1" & addr_0;-- + std_logic_vector(to_unsigned(512, addr_0'length));
--                x <= std_logic_vector(unsigned(x_in));
--                y_out <= x; --std_logic_vector(unsigned(x_in)); --x_in; --X"00000100";--y;
--                --addr_1 <= std_logic_vector(to_unsigned(samples, addr_0'length)) + std_logic_vector(to_unsigned(512, addr_0'length));
--                fir_clk <= '0';
--                samples <= std_logic_vector(unsigned(samples)+1);
--                next_s <= s_idle;

--            when others =>
--                next_s <= s_idle;

--            end case;


--        end if;
--    end process;



-- address_read <= addr_0;
--address_write <= addr_1 when we='1' else addr_0;
--y_out <= y when we='1' else x_in;


--y_out <= y;

--fir_p2 : fir_filter_4
--  port map (i_clk   => fir_clk,
--            i_rstb  => rst,
--            i_coeff_0 => i_coeff_0,
--            i_coeff_1 => i_coeff_1,
--            i_coeff_2 => i_coeff_2,
--            i_coeff_3 => i_coeff_3,
--            i_data  => x_in,
--            o_data  => y);



we_out <= we;
end Behavioral;


































----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04/18/2020 05:11:30 PM
-- Design Name:
-- Module Name: adder - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.numeric_std.ALL;
--use work.ipbus.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--entity my_adder is
-- generic(
--		ADDR_WIDTH: natural
--	);
-- port(

-- led0_ap: out std_logic := '1';
-- we_add: out std_logic;
-- addr_add_i: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
-- addr_add_o: out std_logic_vector(ADDR_WIDTH - 1 downto 0);
-- add_in: in std_logic_vector(31 downto 0);
-- add_out: out std_logic_vector(31 downto 0) := (others => '0');
-- add_clk: in std_logic

-- );
--end my_adder;

--architecture avioral of my_adder is
--type state is (upad_read, read,upad_write, write);
--signal curr_s, next_s : state;

--signal addr_sgn: std_logic_vector(ADDR_WIDTH - 1 downto 0);
--signal value: std_logic_vector(31 downto 0);

--begin

--  led0_ap<='1'; --led di debug non funziona :(

--states:process(add_clk) is
--    begin
--    if rising_edge(add_clk) then
--        curr_s<=next_s;
--    end if;
--    end process;



-- operation: process (add_clk) is
-- begin

-- case curr_s is
-- when upad_read =>
--    next_s <= read;
--    addr_add_o <= addr_sgn;
-- when read =>  --read & compute
--    next_s<= upad_write;
--    value <=std_logic_vector(unsigned(add_in)+1);
-- when upad_write =>
--    next_s<= write;
--    addr_add_o <= addr_sgn;
-- when write =>
--    we_add <= '1';
--    next_s<= upad_read;
--    add_out<=value;
--    addr_sgn <= std_logic_vector(unsigned(addr_sgn)+1);
-- end case;
-- end process;




--end avioral;
