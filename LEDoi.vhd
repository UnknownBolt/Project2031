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
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    CS2         : IN  STD_LOGIC;
    LED_Write   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    clock_1Hz   : IN  STD_LOGIC;
	 clock_10Hz   : IN  STD_LOGIC;
    CS1         : OUT STD_LOGIC;
    LED_DATA    : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	
);
END LEDoi;

ARCHITECTURE a OF LEDoi IS
    
    -- LED enable registers
    SIGNAL led_enable : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
	 SIGNAL led_enable1 : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
	 SIGNAL led_enable2 : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    
    -- Brightness registers for each LED (6 bits each to match LED_DATA)
    TYPE brightness_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL brightness_regs : brightness_array := (OTHERS => (OTHERS => '0'));
    
    -- Current LED being controlled in timer mode
    SIGNAL current_led : INTEGER RANGE 0 TO 9 := 0;
    
    -- Timer mode active flag
    SIGNAL timer_mode_active : STD_LOGIC := '0';
    
    -- State for brightness update
    TYPE state_type IS (IDLE, TIMER_MODE);
    SIGNAL state : state_type := IDLE;
    
    -- Synchronized signals for cross-clock domain
    SIGNAL cs2_sync : STD_LOGIC := '0';
    SIGNAL cs2_prev : STD_LOGIC := '0';
    SIGNAL cs2_pulse : STD_LOGIC := '0';
    
    -- LED output register
    SIGNAL led_data_reg : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
    
    -- Internal signal for timer mode brightness updates
    SIGNAL timer_led_data : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');
	 
  -- CS1 control signal
    SIGNAL cs1_reg : STD_LOGIC := '0';
    SIGNAL cs1_pulse : STD_LOGIC := '0';
    
	  SIGNAL timer_duration : INTEGER RANGE 0 TO 63 := 63; -- Default to max (64 seconds)
    SIGNAL timer_counter : INTEGER RANGE 0 TO 63 := 0;
    
    
BEGIN
  
    -- Output assignments
    CS1 <= cs1_reg;  -- Registered output synchronized with 1Hz clock
    LED_DATA <= timer_led_data WHEN timer_mode_active = '1' ELSE led_data_reg;
	 led_enable <= led_enable2 WHEN timer_mode_active = '1' ELSE led_enable1;
	 
	     -- CS1 and CS2 synchronization process
		  
	 PROCESS(led_enable)
    BEGIN
        FOR i IN 0 TO 9 LOOP
            LED_Write(i) <= led_enable(i);
        END LOOP;
    END PROCESS;
	  
    PROCESS(clock_10Hz, RESETN)
    BEGIN
        IF RESETN = '0' THEN
            cs1_reg <= '0';
            cs1_pulse <= '0';
        ELSIF RISING_EDGE(clock_10Hz) THEN
            -- Generate CS1 pulse
            cs1_pulse <= NOT cs1_pulse;
            
            
            -- Generate CS1 output (active high for one clock cycle)
            IF cs1_pulse = '1' THEN
                cs1_reg <= '1';
            ELSE
                cs1_reg <= '0';
            END IF;
        END IF;
    END PROCESS;
    
    
    PROCESS(CS2, RESETN)
    BEGIN
        IF RESETN = '0' THEN
            cs2_sync <= '0';
            cs2_prev <= '0';
            cs2_pulse <= '0';
        ELSIF RISING_EDGE(CS2) THEN
            -- CS2 synchronization
            cs2_sync <= '1';
            cs2_prev <= cs2_sync;
            cs2_pulse <= cs2_sync AND NOT cs2_prev;
        END IF;
    END PROCESS;
    
    -- Main control process (clocked by CS) - handles direct writes
    PROCESS(RESETN, CS)
    BEGIN
        IF RESETN = '0' THEN
            led_enable1 <= (OTHERS => '0');
            led_data_reg <= (OTHERS => '0');
        ELSIF RISING_EDGE(CS) THEN
            IF WRITE_EN = '1' THEN
                -- Bits 9:0 control which LEDs are enabled
                led_enable1 <= IO_DATA(9 DOWNTO 0);
                
                -- Bits 15:10 set brightness for all LEDs
                led_data_reg <= IO_DATA(15 DOWNTO 10);
            END IF;
        END IF;
    END PROCESS;
    
-- Timer mode process (clocked by clock_1Hz) - handles automatic brightness changes
PROCESS(clock_1Hz, RESETN)
    TYPE t_led_state IS (RAMP_UP, HOLD_MAX, TRANSITION);
    VARIABLE led_state : t_led_state := RAMP_UP;
    VARIABLE transition_counter : INTEGER RANGE 0 TO 1 := 0;
BEGIN
    IF RESETN = '0' THEN
        FOR i IN 0 TO 9 LOOP
            brightness_regs(i) <= (OTHERS => '0');
        END LOOP;
        current_led <= 0;
        state <= IDLE;
        timer_mode_active <= '0';
        timer_led_data <= (OTHERS => '0');
        led_enable2 <= (OTHERS => '0');
        led_state := RAMP_UP;
        transition_counter := 0;
    ELSIF RISING_EDGE(clock_1Hz) THEN
        -- Detect CS2 pulse to start timer mode
        IF cs2_sync = '1' AND state /= TIMER_MODE THEN
            timer_mode_active <= '1';
            current_led <= 0;
            state <= TIMER_MODE;
            led_state := RAMP_UP;
            transition_counter := 0;
            -- Initialize all brightness registers
            FOR i IN 0 TO 9 LOOP
                brightness_regs(i) <= (OTHERS => '0');
            END LOOP;
            led_enable2 <= (OTHERS => '0');
            led_enable2(0) <= '1';  -- Enable first LED immediately
        END IF;
        
        -- Timer mode operation
        IF state = TIMER_MODE THEN
            CASE led_state IS
                WHEN RAMP_UP =>
                    -- Increment brightness if not at max
                    IF brightness_regs(current_led) < "111111" THEN
                        brightness_regs(current_led) <= brightness_regs(current_led) + 1;
                        timer_led_data <= brightness_regs(current_led) + 1;
                    ELSE
                        timer_led_data <= "111111"; -- Stay at max brightness
                        led_state := HOLD_MAX;
                    END IF;
                    
                WHEN HOLD_MAX =>
                    -- Stay at max brightness for one cycle
                    led_state := TRANSITION;
                    
                WHEN TRANSITION =>
                    -- First, disable current LED and set brightness to 0
                    led_enable2(current_led) <= '0';
                    timer_led_data <= "000000";
                    
                    -- Then move to next LED if available
                    IF current_led < 9 THEN
                        current_led <= current_led + 1;
                        -- Initialize and enable new LED
                        brightness_regs(current_led + 1) <= (OTHERS => '0');
                        led_enable2(current_led + 1) <= '1';
                        led_state := RAMP_UP;
                    ELSE
                        -- All LEDs completed, return to idle
                        current_led <= 0;
                        timer_mode_active <= '0';
                        state <= IDLE;
                    END IF;
            END CASE;
        END IF;
    END IF;
END PROCESS;
END a;
