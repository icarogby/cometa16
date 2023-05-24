-- ||***********************************************************||
-- ||                                                           ||
-- ||   FEDERAL UNIVERSITY OF PIAUI                             ||
-- ||   NATURE SCIENCE CENTER                                   ||
-- ||   COMPUTING DEPARTMENT                                    ||
-- ||                                                           ||
-- ||   Computer for Every Task Architecture 16 Bits Mark II    ||
-- ||   COMETA 16 II                                            ||
-- ||                                                           ||
-- ||   Developer: Icaro Gabryel de Araujo Silva                ||
-- ||                                                           ||
-- ||***********************************************************||

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cometa16_data_mem is
    port(
        clk: in std_logic;
        rst: in std_logic;

        ctrl_wr_data_mem: in std_logic;
        ctrl_rd_data_mem: in std_logic;

        alu_out: in std_logic_vector(15 downto 0);
        ac_out: in std_logic_vector(15 downto 0);

        css_out: in std_logic_vector(64 downto 0);
        
        ctrl_wr_main_mem: out std_logic;
        data_hit_out: out std_logic;
        data_mem_out: out std_logic_vector(15 downto 0)
        data_mem_to_css: out std_logic_vector(64 downto 0)

    );

end cometa16_data_mem;

architecture behavior_data_mem of cometa16_data_mem is
    type memory is array(0 to 3, 0 to 3) of std_logic_vector(29 downto 0);
    signal data_mem: memory;

    signal hit_signal: std_logic;
    signal ctrl_wr_main_mem: std_logic;

begin
    -- Read the data memory and send the data to the ac registers
    data_mem_out <= data_mem(conv_integer(alu_out(3 downto 2)), conv_integer(alu_out(1 downto 0)))(15 downto 0);
    
    -- "write in maim memory" control signal check if any word in the block
    -- is modified (29 is modified bit) and if the bock is being substituted. If so, the
    -- modified block is written back to the memory at the same moment the
    -- "write in data memory" control signal is activated.
    ctrl_wr_main_mem <=
        ctrl_wr_data_mem and
        (
        data_mem(conv_integer(alu_out)/4, 0)(29) or
        data_mem(conv_integer(alu_out)/4, 1)(29) or
        data_mem(conv_integer(alu_out)/4, 2)(29) or
        data_mem(conv_integer(alu_out)/4, 3)(29)
        );
    
    -- Send the block to the main memory and use the "write in data memory" control signal
    -- to enable the written in the main.
    data_mem_to_css <=
        data_mem(conv_integer(alu_out)/4, 0) &
        data_mem(conv_integer(alu_out)/4, 1) &
        data_mem(conv_integer(alu_out)/4, 2) &
        data_mem(conv_integer(alu_out)/4, 3);
    
    hit_process: process (clk, rst)
    
    begin
        -- check if the label of the address is the same as the label of the
        -- data memory block and if the block is valid. If so, the hit signal
        -- is activated.
        if ((alu_out(15 downto 4) = data_mem_out(27 downto 16)) and (data_mem_out(28) = '1')) then
            hit_signal <= '1';
        else
            hit_signal <= '0';
        end if;

    end process hit_process;
    
    -- check if the data memory is being read. If so, the hit signal is send.
    -- If not, the hit signal is always set '1' to not stop pc when the alu exit
    -- point to a invalid address or a modified block.
    with ctrl_rd_data_mem select data_hit_out <=
        '1'        when '0',
        hit_signal when '1',
        'X'        when others;

    wr_data_mem_process: process(clk, rst, ctrl_wr_data_mem)

    begin
        if (rst = '1') then
            data_mem(0)  <= "0000000000000000"; 
            data_mem(1)  <= "0000000000000000";
            data_mem(2)  <= "0000000000000000";
            data_mem(3)  <= "0000000000000000";
            data_mem(4)  <= "0000000000000000";
            data_mem(5)  <= "0000000000000000";
            data_mem(6)  <= "0000000000000000";
            data_mem(7)  <= "0000000000000000"; 
            data_mem(8)  <= "0000000000000000"; 
            data_mem(9)  <= "0000000000000000";  
            data_mem(10) <= "0000000000000000";
            data_mem(11) <= "0000000000000000"; 
            data_mem(12) <= "0000000000000000"; 
            data_mem(13) <= "0000000000000000"; 
            data_mem(14) <= "0000000000000000"; 
            data_mem(15) <= "0000000000000000";

        elsif ((clk'event and clk = '1') and (ctrl_wr_data_mem = '1')) then -- todo: wr ctrl, label, modified bit
            data_mem(conv_integer(alu_out(3 downto 2)), conv_integer(alu_out(1 downto 0))) <= ac_out;

        end if;

	end process wr_data_mem_process;

end behavior_data_mem;
