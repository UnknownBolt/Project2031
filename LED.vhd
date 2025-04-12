-- SingleLEDController.VHD
-- Controls ONLY the first LED (LED 0) when bit 0 is active
-- Uses bits 5:0 for brightness control (6-bit, 64 levels)
-- All other LEDs remain permanently off

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY LED IS
PORT(
    CS          : IN  STD_LOGIC;
    CS1         : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    clock_10kHz : IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC; -- Only LED(0) is used
    LED_DATA    : IN  STD_LOGIC_VECTOR(5 DOWNTO 0)
);
END LED;

ARCHITECTURE a OF LED IS
    -- PWM counter (6-bit for 64 brightness levels)
    SIGNAL pwm_counter : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- Brightness register (6 bits)
    SIGNAL brightness : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- LED enable flag (only for LED 0)
    SIGNAL led0_enable : STD_LOGIC := '0';
    
    -- Combined chip select
    SIGNAL combined_cs : STD_LOGIC;
    
BEGIN
    -- Combine CS signals
    combined_cs <= CS OR CS1;
    
    -- PWM counter process 
    PROCESS (clock_10kHz, RESETN)
    BEGIN
        IF (RESETN = '0') THEN
            pwm_counter <= (OTHERS => '0');
        ELSIF (RISING_EDGE(clock_10kHz)) THEN
            pwm_counter <= pwm_counter + 1;
        END IF;
    END PROCESS;
    
    -- PWM output generation
    PROCESS (pwm_counter, brightness, led0_enable)
    BEGIN
        -- Only control LED 0 (others permanently off)
        IF (led0_enable = '1' AND pwm_counter < brightness) THEN
            LEDs <= '1';
        ELSE
            LEDs <= '0';
        END IF;
    END PROCESS;
    
    -- Control and brightness update process
    -- Now uses the main clock_10kHz for synchronization
    PROCESS (clock_10kHz, RESETN)
    BEGIN
        IF (RESETN = '0') THEN
            led0_enable <= '0';
            brightness <= (OTHERS => '0');
        ELSIF (RISING_EDGE(clock_10kHz)) THEN
            IF (combined_cs = '1' AND WRITE_EN = '1') THEN
                led0_enable <= '1';
                brightness <= LED_DATA(5 DOWNTO 0);
            ELSIF (combined_cs = '1' AND WRITE_EN = '0') THEN
                led0_enable <= led0_enable; -- Maintain current state
            END IF;
        END IF;
    END PROCESS;

END a;