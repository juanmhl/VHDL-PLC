----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.01.2022 12:46:50
-- Design Name: 
-- Module Name: Test_Bench - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.textIO.ALL;

use work.Tipos_FSM_PLC.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Test_Bench is
--  Port ( );
end Test_Bench;

architecture Behavioral of Test_Bench is

    constant k : natural := k_Max;  -- entradas
    constant p : natural := p_Max;  -- salidas
    constant m : natural := m_Max;  -- biestables
    
    constant Medio_Periodo : Time := 5 ns;
    
    signal x : std_logic_vector(k-1 downto 0) := (others=>'0');
    signal y : std_logic_vector(p-1 downto 0) := (others=>'0');
    signal clk     : std_logic := '0';
    signal cke     : std_logic := '0';
    signal reset   : std_logic := '0';
    signal Trigger : std_logic := '0';
    
    -- Ecuación de transición de estado
    constant Tabla_De_Estado : Tabla_FSM := (
        -- Entrada:
        --     7    6    5    4     3    2    1    0
        --                                                      Estado:
            b"0000_0000_0000_0000_0011_0010_0001_0000",  -- 0   B
            b"0000_0000_0000_0000_0011_0010_0001_0000",  -- 1   MBS
            b"0000_0000_0000_0000_0011_0010_0001_0000",  -- 2   MAS
            b"0000_0000_0000_0000_0011_0100_0101_0000",  -- 3   A
            b"0000_0000_0000_0000_0011_0100_0101_0000",  -- 4   MAB
            b"0000_0000_0000_0000_0011_0100_0101_0000",  -- 5   MBB
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 6
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 7
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 8
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 9
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 10
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 11
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 12
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 13
            b"0000_0000_0000_0000_0000_0000_0000_0000",  -- 14
            b"0000_0000_0000_0000_0000_0000_0000_0000"   -- 15
         );
         
    constant Tabla_De_Salida : Tabla_FSM := (
        --                      Estado:
           x"00000003",  -- 0   B
           x"00000007",  -- 1   MBS
           x"00000005",  -- 2   MAS
           x"00000000",  -- 3   A
           x"00000004",  -- 4   MAB
           x"00000005",  -- 5   MBB
           x"00000000",  -- 6
           x"00000000",  -- 7
           x"00000000",  -- 8
           x"00000000",  -- 9
           x"00000000",  -- 10
           x"00000000",  -- 11
           x"00000000",  -- 12
           x"00000000",  -- 13
           x"00000000",  -- 14
           x"00000000"   -- 15
        );

    component FSM_PLC is
        generic( k    : natural := 32;    -- k entradas.
                 p    : natural := 32;    -- p salidas.
                 m    : natural := 32;    -- m biestables. (Hasta 16 estados)
                 T_DM : time    := 10 ps; -- Tiempo de retardo desde el cambio de dirección del MUX hasta la actualización de la salida Q.
                 T_D  : time    := 10 ps; -- Tiempo de retardo desde el flanco activo del reloj hasta la actualización de la salida Q.
                 T_SU : time    := 10 ps; -- Tiempo de Setup.
                 T_H  : time    := 10 ps; -- Tiempo de Hold.
                 T_W  : time    := 10 ps); -- Anchura de pulso.
         port   (   x : in  STD_LOGIC_VECTOR( k - 1 downto 0 );     -- x es el bus de entrada.
                    y : out STD_LOGIC_VECTOR( p - 1 downto 0 );     -- y es el bus de salida.
                  Tabla_De_Estado : in Tabla_FSM( 0 to 2**m - 1 );  -- Contiene la Tabla de Estado estilo Moore: Z(n+1)=T1(Z(n),x(n))
                  Tabla_De_Salida : in Tabla_FSM( 0 to 2**m - 1 );  -- Contiene la Tabla de Salida estilo Moore: Y(n  )=T2(Z(n))
                  clk     : in STD_LOGIC;   -- La señal de reloj.
                  cke     : in STD_LOGIC;   -- La señal de habilitación de avance: si vale '1' el autómata avanza a ritmo de clk y si vale '0' manda Trigger.              
                  reset   : in STD_LOGIC;   -- La señal de inicialización.
                  Trigger : in STD_LOGIC ); -- La señal de disparo (single shot) asíncrono y posíblemente con rebotes para hacer un avance único. Ha de llevar un sincronizador.
    end component;

begin

    DUT : FSM_PLC
        generic map (k=>k, p=>p, m=>m)
        port map (x=>x,y=>y,Tabla_De_Estado=>Tabla_De_Estado,Tabla_De_Salida=>Tabla_De_Salida,clk=>clk,cke=>cke,reset=>reset,Trigger=>Trigger);
        
    Reloj : process
    begin
        clk <= '0';
        wait for Medio_Periodo;
        clk <= '1';
        wait for Medio_Periodo;
    end process Reloj;
    
    Inicializacion : process
    begin
        reset<='1';
        wait for 3ns;
        reset<='0';
        wait;
    end process;
    
--    Pulsador : process
--    begin
--        cke <= '1';
--        wait;
--    end process Pulsador;
    
    Rebotes : process
    begin
        Trigger <= '0';
--        wait for 253847ps;
        wait for 20 ns;
        for i in 0 to 4 loop
            Trigger <= '0';
            wait for 7870ps;
            Trigger <= '1';
            wait for 5210ps;
        end loop;
        wait for 200ns;
        for i in 0 to 7 loop
            Trigger <= '0';
            wait for 2000ps;
            Trigger <= '1';
            wait for 967ps;
        end loop;
        Trigger <= '0';
        wait for (780ns - 89136 ps);
    end process Rebotes;
    
    Estimulos_Desde_Fichero : process
    
        file  Input_File : text;
        file Output_File : text;
        
        variable     Input_Data : BIT_VECTOR(k-1 downto 0 ) := ( OTHERS => '0' );
        variable          Delay :      time := 0 ms;
        variable     Input_Line :      line := NULL;
        variable    Output_Line :      line := NULL;
        variable   Std_Out_Line :      line := NULL;
        variable       Correcto :   Boolean := True;
        constant           Coma : character := ',';
    
        
        begin
        
    -- estimulos.txt contiene los estímulos y los tiempos de retardo.
            file_open(  Input_File, "C:\Users\Usuario\Desktop\estimulos.txt", read_mode );
    -- etimulos.csv contiene los estímulos y los tiempos de retardo para el Analog Discovery 2.
            file_open( Output_File, "C:\Users\Usuario\Desktop\estimulos.csv", write_mode );
            
    -- Titles: Son para el formato EXCEL *.CSV (Comma Separated Values):
            write( Std_Out_Line, string'(  "Retardo" ), right, 7 );
            write( Std_Out_Line,                  Coma, right, 1 );
            write( Std_Out_Line, string'( "Entradas" ), right, 8 );
                    
            Output_Line := Std_Out_Line;
                   
            writeline(      output, Std_Out_Line );
            writeline( Output_File,  Output_Line );
    
            while ( not endfile( Input_File ) ) loop    
            
                readline( Input_File, Input_Line );
                
                read( Input_Line, Delay, Correcto );	-- Comprobación de que se trata de un texto que representa
                                                        -- el retardo, si no es así leemos la siguiente línea.           
                if Correcto then
    
                    read( Input_Line, Input_Data );		-- El siguiente campo es el vector de pruebas.
                    
                    x <= TO_STDLOGICVECTOR( Input_Data )(k-1 downto 0);
                                                        -- De forma simultánea lo volcaremos en consola en csv.
                    write( Std_Out_Line,        Delay, right, 5 ); -- Longitud del retardo, ej. "20 ms".
                    write( Std_Out_Line,         Coma, right, 1 );
                    write( Std_Out_Line,   Input_Data, right, 2 ); --Longitud de los datos de entrada.
                    
                    Output_Line := Std_Out_Line;
                    
                    writeline(      output, Std_Out_Line );
                    writeline( Output_File, Output_Line );
            
                    wait for Delay;
                end if;
             end loop;
             
             file_close(  Input_File );	-- Cerramos el fichero de entrada.
             file_close( Output_File );	-- Cerramos el fichero de salida.
             wait;		 
    end process Estimulos_Desde_Fichero;
        
    

end Behavioral;
