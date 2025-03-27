-- SingleLEDController.VHD
-- Controls ONLY the first LED (LED 0) when bit 0 is active
-- Uses bits 15:10 for brightness control (6-bit, 64 levels)
-- All other LEDs remain permanently off

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY LEDoi IS
PORT(
    CS          : IN  STD_LOGIC;
	 CSL			 : OUT STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
	 LED_Write   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
	 LED_DATA     : OUT  STD_LOGIC_VECTOR(5 DOWNTO 0)
);
END LEDoi;



ARCHITECTURE a OF LEDoi IS
    
    -- Brightness value (shared by all LEDs)
    SIGNAL brightness : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- LED enable registers
    SIGNAL led_enable : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
        
BEGIN
    
   -- PWM output generation
    PROCESS  (led_enable)
    BEGIN
        FOR i IN 0 TO 9 LOOP
            IF (led_enable(i) = '1') THEN
                LED_Write(i) <= '1';
					 
            ELSE
                LED_Write(i) <= '0';
            END IF;
        END LOOP;
    END PROCESS;
    
    -- Control and brightness update process
    PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            --led_enable <= (OTHERS => '0');
            brightness <= (OTHERS => '0');
            
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                -- Bits 9:0 control which LEDs are enabled
                led_enable <= IO_DATA(9 DOWNTO 0);
                
                -- Bits 15:10 set brightness for all LEDs
                LED_DATA <= IO_DATA(15 DOWNTO 10);
            END IF;
        END IF;
    END PROCESS;
END a;