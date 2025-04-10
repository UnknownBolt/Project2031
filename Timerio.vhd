
-- SingleLEDController.VHD
-- Controls LED sequence with configurable delay between LEDs
-- Brightness ramps from 0 to max (63) over the delay period
-- Uses bits 15:10 for maximum brightness (6-bit, 64 levels)
-- Uses bits 5:0 for delay between LEDs (1-63 seconds)

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY Timerio IS
PORT(
    CS2         : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    clock_1Hz   : IN  STD_LOGIC;
    LED_Write2  : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    LED_DATA    : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    TimeV       : OUT STD_LOGIC;
	 LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    CS1         : OUT  STD_LOGIC
);
END Timerio;

ARCHITECTURE a OF Timerio IS
    
    -- LED control signals
    SIGNAL led_enable : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL led_counter : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL cs2_prev : STD_LOGIC := '0';
    
    -- Timing control signals
    SIGNAL delay_counter : INTEGER RANGE 0 TO 63 := 0;
    SIGNAL delay_value : INTEGER RANGE 1 TO 63 := 1;
    SIGNAL delay_active : STD_LOGIC := '0';
    
    -- Brightness control signals
    SIGNAL brightness : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    SIGNAL max_brightness : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '1');
    SIGNAL brightness_step : INTEGER RANGE 0 TO 63 := 1;
    
    -- CS1 control signal
    SIGNAL cs1_internal : STD_LOGIC := '0';
        
BEGIN
 PROCESS (RESETN, CS2)
    BEGIN
	 -- reset logic 
        IF (RESETN = '0') THEN
                delay_value <= 1;
                max_brightness <= (OTHERS => '1');
				
            
        ELSIF (RISING_EDGE(CS2)) THEN
            -- Update delay and brightness values when WRITE_EN is active
            IF WRITE_EN = '1' THEN
                -- Set delay value (1-63 seconds)
                IF IO_DATA(5 DOWNTO 0) > 0 AND IO_DATA(5 DOWNTO 0) < 64 THEN
                    delay_value <= CONV_INTEGER(IO_DATA(5 DOWNTO 0));
						  LEDs <= IO_DATA(9 DOWNTO 0);
                ELSE 
                    delay_value <= 1;  -- Default to 1 second if out of range
                END IF;
                
                -- Calculate brightness step size to reach max in delay_value seconds
                brightness_step <= (CONV_INTEGER(max_brightness)/delay_value);
            END IF;
        END IF;
    END PROCESS;
    
    -- Connect internal CS1 signal to output
    CS1 <= cs1_internal;
END a;