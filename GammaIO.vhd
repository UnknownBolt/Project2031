-- LEDController.VHD
-- Uses bits 9:0 for LED enable and bits 15:10 for brightness of enabled LEDs
-- Allows different brightness levels for different LEDs

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY GammaIO IS
PORT(
    CS          : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    CLOCK       : IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
);
END GammaIO;

ARCHITECTURE a OF GammaIO IS
    -- PWM counter (6-bit for 64 brightness levels)
    SIGNAL pwm_counter : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- Brightness registers for each LED (6 bits each)
    TYPE brightness_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL brightness_regs : brightness_array := (OTHERS => (OTHERS => '0'));
    
    -- LED enable registers
    SIGNAL led_enable : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    
    -- State machine for multi-write brightness programming
    TYPE state_type IS (IDLE, WRITE_BRIGHTNESS);
    SIGNAL state : state_type := IDLE;
    
    -- LED selection register
    SIGNAL led_select : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    
BEGIN
    -- PWM counter process
    PROCESS (CLOCK, RESETN)
    BEGIN
        IF (RESETN = '0') THEN
            pwm_counter <= (OTHERS => '0');
        ELSIF (RISING_EDGE(CLOCK)) THEN
            pwm_counter <= pwm_counter + 1;
        END IF;
    END PROCESS;
    
    -- PWM output generation
    PROCESS (pwm_counter, brightness_regs, led_enable)
    BEGIN
        FOR i IN 0 TO 9 LOOP
            IF (led_enable(i) = '1' AND pwm_counter < brightness_regs(i)) THEN
                LEDs(i) <= '1';
            ELSE
                LEDs(i) <= '0';
            END IF;
        END LOOP;
    END PROCESS;
    
    -- Control and brightness update process
    PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            led_enable <= (OTHERS => '0');
            brightness_regs <= (OTHERS => (OTHERS => '0'));
            state <= IDLE;
            led_select <= (OTHERS => '0');
            
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                CASE state IS
                    WHEN IDLE =>
                        -- First write: bits 9:0 select which LEDs to update
                        led_select <= IO_DATA(9 DOWNTO 0);
                        state <= WRITE_BRIGHTNESS;
                        
                    WHEN WRITE_BRIGHTNESS =>
                        -- Second write: bits 15:10 set brightness for selected LEDs
                        FOR i IN 0 TO 9 LOOP
                            IF led_select(i) = '1' THEN
                                brightness_regs(i) <= IO_DATA(15 DOWNTO 10);
                            END IF;
                        END LOOP;
                        -- Also update enable states for selected LEDs
                        led_enable <= led_enable OR led_select;
                        state <= IDLE;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END a;