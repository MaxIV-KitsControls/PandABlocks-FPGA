--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Shifts data onto the front panel included on daq board shift registers (SN74HC595PW)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.slow_defines_daq.all;

library unisim;
use unisim.vcomponents.all;

entity fpanel_if_daq is
port (
    -- 50MHz system clock.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Front-Panel Control Values.
    ttl_leds_i          : in  std_logic_vector(3 downto 0);
    ttlin_term_i        : in  std_logic_vector(1 downto 0);
    status_leds_i       : in  std_logic_vector(3 downto 0);
    -- Shift Register Interface.
    shift_reg_sdata_o   : out std_logic;
    shift_reg_sclk_o    : out std_logic;
    shift_reg_latch_o   : out std_logic;
    shift_reg_oe_n_o    : out std_logic
);
end fpanel_if_daq;

architecture rtl of fpanel_if_daq is

type shift_fsm_t is (IDLE, SYNC, SHIFTING, LATCH);
signal shift_fsm        : shift_fsm_t;

-- Number of bits to shifth
signal shift_clock      : std_logic;
signal shift_reg_sclk   : std_logic;
signal shift_reg_latch  : std_logic;

signal data             : std_logic_vector(15 downto 0);
signal data_prev        : std_logic_vector(15 downto 0);
signal data_slr         : std_logic_vector(15 downto 0);

signal shift_index      : integer range 0 to 15;

begin

--
-- Shift register clock rate is 2x1usec.
--
shift_clk: entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(160, 32),
    pulse_o         => shift_clock
);

--
-- Latch and shift data on DATA change. Make sure that there is not
-- already an ongoing shifting.
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            shift_reg_oe_n_o <= '1';
            shift_reg_sclk <= '0';
            shift_reg_latch <= '0';
            shift_index <= 0;
            data <= (6=>'1',others => '0');
            data_prev <= (others => '0');
            data_slr <= (6=>'1',others => '0');-- bit 9 Power led to send data on power on reset
            shift_fsm <=SYNC;
        else
            -- Register input data with gaps according to schematics;
            data <= BITREV(ttl_leds_i(3 downto 0)) & BITREV(ttlin_term_i(1 downto 0)) & '1' &
                         status_leds_i(1) & status_leds_i(2) & status_leds_i(3) & "000000";

            case shift_fsm is
                -- Wait for change on data;
                when IDLE =>
                    shift_reg_sclk <= '0';
                    shift_reg_latch <= '0';

                    if (data /= data_prev) then
                        data_prev <= data;
                        data_slr <= data;
                        shift_fsm <= SYNC;
                    end if;

                -- Sync data stream to shift clock before starting
                when SYNC =>
                    if (shift_clock = '1') then
                        shift_fsm <= SHIFTING;
                    end if;

                -- Shift data and keep track of bits;
                when SHIFTING =>
                    -- Toggle clock at 1usec
                    if (shift_clock = '1') then
                        shift_reg_sclk <= not shift_reg_sclk;
                    end if;

                    -- Shift new bit on falling edge of sclk to have enough
                    -- setup time;
                    if (shift_reg_sclk = '1' and shift_clock = '1') then
                        data_slr <= '0' & data_slr(15 downto 1);
                        -- Last bit shifted, now latch.
                        if (shift_index = 15) then
                            shift_reg_latch <= '1';
                            shift_fsm <= LATCH;
                            shift_index <= 0;
                        -- Continue shifting;
                        else
                            shift_index <= shift_index + 1;
                        end if;
                    end if;

                -- 1usec latch pulse;
                when LATCH =>
                    if (shift_clock = '1') then
                        shift_reg_latch <= '0';
                        shift_fsm <= IDLE;
                    end if;

                    -- Enable shift register output permanently after the 
                    --first write;
                    shift_reg_oe_n_o <= '0';


                when others =>
            end case;
        end if;
    end if;
end process;

shift_reg_sclk_o <= shift_reg_sclk;
shift_reg_sdata_o <= data_slr(0);
shift_reg_latch_o <= shift_reg_latch;

end rtl;
