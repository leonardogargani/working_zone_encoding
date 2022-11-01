
--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--      *                                                                                             *
--      *         Oggetto:       Prova Finale di Reti Logiche                                         *
--      *         Autore:        Gargani Leonardo                                                     *
--      *         Corso:         Reti Logiche                                                         *
--      *         Linguaggio:    VHDL                                                                 *
--      *         Descrizione:   Implementazione di un modulo che svolge una codifica a bassa         *
--      *                        dissipazione ispiradosi al metodo "Working Zone"                     *
--      *                                                                                             *
--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *




--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--      *                                    PACKAGES & LIBRARIES                                     *
--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

-- package contenenti tutte le costanti da me create: l'implementazione non conterrà in seguito
-- dati numerici, ma sarà anzi parametrica, in modo da rendere il tutto facilmente scalabile
package CONSTANTS is
    constant NWZ                : natural       := 8;       -- numero delle wz totali
	constant DWZ                : natural       := 4;       -- dimensione di ciascuna wz
    constant RAM_ADDR_BITS      : natural       := 16;      -- dimensioni degli indirizzi della ram
    constant RAM_VAL_BITS       : natural       := 8;       -- dimensione dei valori contenuti in ram
end package CONSTANTS;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;


--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--      *                                           ENTITY                                            *
--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

entity project_reti_logiche is

    Port (
        i_clk       : in std_logic;
        i_start     : in std_logic;
        i_rst       : in std_logic;
        i_data      : in std_logic_vector(RAM_VAL_BITS - 1 downto 0);
        o_address   : out std_logic_vector(RAM_ADDR_BITS - 1 downto 0);
        o_done      : out std_logic;
        o_en        : out std_logic;
        o_we        : out std_logic;
        o_data      : out std_logic_vector(RAM_VAL_BITS - 1 downto 0)
         );

end project_reti_logiche;



--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--      *                                        ARCHITECTURE                                         *
--      * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

architecture FSM of project_reti_logiche is

    -- gli stati della FSM sono di tipo state_type, qua definito
    type state_type is (RESET, RAM_QUERYING, RAM_WAITING, RAM_READING, ENCODING, DONE);
    
    
--                                  * * * * * * * * * * * * * * * * * * * *
--                                  *               SIGNALS               *
--                                  * * * * * * * * * * * * * * * * * * * *

    -- segnali che rappresentano i valori futuri dei 5 segnali di uscita, da specifica
    signal o_address_next       : std_logic_vector(RAM_ADDR_BITS - 1 downto 0)  := (others => '0');
	signal o_done_next          : std_logic                                     := '0';
	signal o_en_next            : std_logic                                     := '0';
	signal o_we_next            : std_logic                                     := '0';
	signal o_data_next          : std_logic_vector(RAM_VAL_BITS - 1 downto 0)   := (others => '0');
    
	-- segnali interni
	signal ram_position         : integer range 0 to 8                          := 8;
	signal ram_position_next    : integer range 0 to 8                          := 8;
	signal wz_found             : std_logic                                     := '0';
	signal wz_found_next        : std_logic                                     := '0';
	signal oh_offset            : std_logic_vector(3 downto 0)                  := (others => '0');
	signal oh_offset_next       : std_logic_vector(3 downto 0)                  := (others => '0');
    signal value_to_encode      : std_logic_vector(6 downto 0)                  := (others => '0');
    signal value_to_encode_next : std_logic_vector(6 downto 0)                  := (others => '0');
	signal done_raised          : std_logic                                     := '0';
	signal done_raised_next     : std_logic                                     := '0';
	signal state                : state_type                                    := RESET;
    signal state_next           : state_type                                    := RESET;



begin
    
--                                  * * * * * * * * * * * * * * * * * * * *
--                                  *         PROCESS (registers)         *
--                                  * * * * * * * * * * * * * * * * * * * *
    
    -- processo che gestisce l'evoluzione degli stati
    registers_handler: process(i_clk, i_rst)
    
    begin

        -- se i_rst = '1' assegno ad ogni segnale il proprio valore iniziale
        if (i_rst = '1') then

            o_address           <= (others => '0');
            o_done              <= '0';
            o_en                <= '0';
            o_we                <= '0';
            o_data              <= (others => '0');
            
            ram_position        <= NWZ;
            wz_found            <= '0';
            oh_offset           <= (others => '0');
            value_to_encode     <= (others => '0');
            done_raised         <= '0';
            state               <= RESET;

        -- ad ogni ciclo di clock (con i_rst = '0') assegno ad ogni segnale il proprio valore futuro
        elsif (i_clk'event and i_clk='1') then
                    
            o_address           <= o_address_next;
            o_done              <= o_done_next;
            o_en                <= o_en_next;
            o_we                <= o_we_next;
            o_data              <= o_data_next;
            
            ram_position        <= ram_position_next;
            wz_found            <= wz_found_next;
            oh_offset           <= oh_offset_next;
            value_to_encode     <= value_to_encode_next;
            done_raised         <= done_raised_next;
            state               <= state_next;
                        
        end if;
        
    end process;



--                                  * * * * * * * * * * * * * * * * * * * *
--                                  *           PROCESS (logic)           *
--                                  * * * * * * * * * * * * * * * * * * * *
 
    combinatory_logic: process(i_start, i_data, state, ram_position, wz_found, oh_offset, value_to_encode, done_raised)
    
    begin
    
        -- i seguenti assegnamenti prima del case vengono compiuti in modo tale da assegnare poi, all'interno degli
        -- stati, solamente i segnali che cambiano: in questo modo si prevengono eventuali inferring latch
        
        -- ai futuri segnali di output assegno il loro valore di default (iniziale)
        o_address_next              <= (others => '0');
        o_done_next                 <= '0';
        o_en_next                   <= '0';
        o_we_next                   <= '0';
        o_data_next                 <= (others => '0');
        
        -- ai futuri segnali interni assegno il loro valore corrente
        ram_position_next           <= ram_position;
        wz_found_next               <= wz_found;
        oh_offset_next              <= oh_offset;
        value_to_encode_next        <= value_to_encode;
        done_raised_next            <= done_raised;
        state_next                  <= state;
        

        -- specifico il comportamento che la FSM deve avere per ogni suo stato 
        case state is
        
        
            -- RESET: vado in RAM_QUERYING se e solo se i_start = '1', altrimenti resto in RESET
            when RESET =>
            
                if (i_start = '1') then
                    state_next                  <= RAM_QUERYING;
                else
                    state_next                  <= RESET;
                end if;
                
                
            -- RAM_QUERYING: richiedo un dato alla ram assegnando a o_address_next l'indirizzo ram_position a cui voglio accedere
            when RAM_QUERYING =>
                
                o_en_next                       <= '1';
                o_address_next                  <= std_logic_vector(to_unsigned(ram_position, RAM_ADDR_BITS));
                state_next                      <= RAM_WAITING;
                
                
            -- RAM_WAITING: aspetto un ciclo di clock affinché la ram possa ritornarmi il dato all'indirizo richiesto
            when RAM_WAITING =>
            
                o_en_next                       <= '0';
                state_next                      <= RAM_READING;
               
            
            -- RAM_READING: stato che cambia il proprio comportamento in base ai valori di ram_position e di value_to_encode - i_data
            when RAM_READING =>
            
                -- se ho ricevuto il contenuto di RAM(NWZ), salvalo in value_to_encode_next e torna in RAM_QUERYING richiedendo l'indirizzo precedente
                if (ram_position = NWZ) then
                    value_to_encode_next        <= i_data(RAM_VAL_BITS - 2 downto 0);
                    ram_position_next           <= NWZ - 1;
                    state_next                  <= RAM_QUERYING;
                else
                    -- se ho ricevuto l'indirizzo di una wz e se value_to_encode_next appartiene a tale wz, genera la codifica one-hot dell'offset e passa a ENCODING
                    if ((value_to_encode - i_data >= std_logic_vector(to_unsigned(0, RAM_VAL_BITS - 1))) and (value_to_encode - i_data < std_logic_vector(to_unsigned(DWZ, RAM_VAL_BITS - 1)))) then
                        oh_offset_next(to_integer(unsigned(value_to_encode - i_data))) <= '1';
                        wz_found_next           <= '1';
                        state_next              <= ENCODING;
                    else
                        -- se ho ricevuto l'indirizzo di una wz, se value_to_encode_next non appartiene a tale wz e se ho esaurito le aree di memoria
                        -- a cui accedere, allora passa a ENCODING senza nessun accorgimento
                        if (ram_position = 0) then
                            state_next          <= ENCODING;
                        -- se ho ricevuto l'indirizzo di una wz, se value_to_encode_next non appartiene a tale wz e se non ho ancora esaurito le aree di 
                        -- memoria a cui accedere, allora torna in RAM_QUERYING richiedendo l'indirizzo precedente
                        else
                            ram_position_next   <= ram_position - 1;
                            state_next          <= RAM_QUERYING;
                        end if;
                    end if; 
                end if;
                
                
            -- ENCODING: assegno a o_data_next la codifica del valore in RAM(NWZ), distinguendo se è stata trovata una wz a cui appartiene oppure no
            when ENCODING =>
                
                o_en_next                       <= '1';
                o_we_next                       <= '1';
                if (wz_found = '1') then
                    o_data_next                 <= '1' & std_logic_vector(to_unsigned(ram_position, DWZ - 1)) & oh_offset;
                else
                    o_data_next                 <= '0' & value_to_encode;
                end if;
                o_address_next                  <= std_logic_vector(to_unsigned(NWZ + 1, RAM_ADDR_BITS));
                state_next                      <= DONE;
                    
                    
            -- DONE: stato che cambia il proprio comportamento in base ai valori di dome_raised e di i_start
            when DONE =>
                
                -- se ancora non ho alzato il segnale o_done, lo faccio e rimango in DONE 
                --rimango in DONE fino a quando non ricevo un i_start = '0' (con i_done_raised = 1) , che mi riporta in RESET
                if (done_raised = '0') then
                    o_en_next                   <= '0';
                    o_we_next                   <= '0';
                    o_done_next                 <= '1';
                    done_raised_next            <= '1';
                    state_next                  <= DONE;
                else
                    -- se ho già alzato o_done e ricevo i_start = '0', allora posso andare in RESET e portare i segnali interni ai suoi valori iniziali
                    if (i_start = '0') then
                        o_done_next             <= '0';
                        wz_found_next           <= '0';
                        oh_offset_next          <= (others => '0');
                        value_to_encode_next    <= (others => '0');
                        ram_position_next       <= NWZ;
                        done_raised_next        <= '0';
                        state_next              <= RESET;
                    -- se ho già alzato o_done e non ricevo i_start = '0', allora rimango in DONE
                    else
                        state_next              <= DONE;
                    end if;
                end if;
                
                
        end case;
    
    end process;


end FSM;
