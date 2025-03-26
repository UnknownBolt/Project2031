-- LEDController.VHD
-- Uses bits 9:0 for LED control and bits 15:10 for brightness (6-bit, 64 levels)

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY LEDController IS
PORT(
    CS          : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    clock_10kHz : IN  STD_LOGIC;  -- Clock input for PWM
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END LEDController;

ARCHITECTURE a OF LEDController IS
    -- PWM counter (6-bit for 64 brightness levels)
    SIGNAL pwm_counter : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- Brightness value (shared by all LEDs)
    SIGNAL brightness : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- LED enable registers
    SIGNAL led_enable : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    
BEGIN
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
    PROCESS (pwm_counter, brightness, led_enable)
    BEGIN
        FOR i IN 0 TO 9 LOOP
            IF (led_enable(i) = '1' AND pwm_counter < brightness) THEN
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
            brightness <= (OTHERS => '0');
            
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                -- Bits 9:0 control which LEDs are enabled
                led_enable <= IO_DATA(9 DOWNTO 0);
                
                -- Bits 15:10 set brightness for all LEDs
                brightness <= IO_DATA(15 DOWNTO 10);
            END IF;
        END IF;
    END PROCESS;
END a;