//

module chip_select
(
    input        clk,
    input  [3:0] pcb,

    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_rw,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,
    input        RD_n,
    input        WR_n,
    input        M1_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_ram_cs,
    output reg m68k_spr_cs,

    output reg m68k_p1_cs,
    output reg m68k_p2_cs,
    output reg m68k_coin_cs,
    output reg m68k_dsw1_cs,
    output reg m68k_dsw2_cs,
    output reg m68k_flip_cs,

    output reg m68k_sound_cs,

    output reg m68k_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,
    output reg   z80_ram2_cs,
    output reg   z80_latch_cs,
    output reg   z80_opl_addr_cs, // OPL YM3812
    output reg   z80_opl_data_cs
);


function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( m68k_a[23:0] >= start_address && m68k_a[23:0] <= end_address) & !m68k_as_n;
end
endfunction

function z80_mem_cs;
        input [15:0] base_address;
        input  [7:0] width;
begin
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n ;
end
endfunction
   
localparam NEXTSPACE   = 0;
localparam PADDLEMANIA = 1;

always @ (*) begin
    // Memory mapping based on PCB type
    case (pcb)
        NEXTSPACE: begin
            m68k_rom_cs      <= m68k_cs( 24'h000000, 24'h03ffff ) ;
            m68k_ram_cs      <= m68k_cs( 24'h070000, 24'h073fff ) ;
            m68k_spr_cs      <= m68k_cs( 24'h0a0000, 24'h0a3fff ) ;
            
            m68k_p1_cs      <= m68k_cs( 24'h0e0000, 24'h0e0001 ) & m68k_rw ;
            m68k_p2_cs      <= m68k_cs( 24'h0e0002, 24'h0e0003 ) & m68k_rw ;
            m68k_coin_cs    <= m68k_cs( 24'h0e0004, 24'h0e0005 ) & m68k_rw ;
            
            m68k_dsw1_cs     <= m68k_cs( 24'h0e0008, 24'h0e0009 ) ;
            m68k_dsw2_cs     <= m68k_cs( 24'h0e000a, 24'h0e000b ) ;
            
            m68k_sound_cs    <= m68k_cs( 24'h0e0018, 24'h0e0019 ) & m68k_rw ;
            
            m68k_flip_cs     <= m68k_cs( 24'h0f0000, 24'h0f0001 ) & !m68k_rw ;
            m68k_latch_cs    <= m68k_cs( 24'h0f0008, 24'h0f0009 ) & !m68k_rw ;            
            
            z80_rom_cs        <= ( MREQ_n == 0 && z80_addr[15:0] <  16'hf000 );
            z80_ram_cs        <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800 );
            z80_ram2_cs       <= 0;

            z80_latch_cs      <= ( MREQ_n == 0 && z80_addr[15:0] == 16'hf800 );
            z80_opl_addr_cs   <= ( z80_addr[7:0] == 8'h00 ) && ( !IORQ_n ) ; 
            z80_opl_data_cs   <= ( z80_addr[7:0] == 8'h20 ) && ( !IORQ_n ) && (!WR_n); 
        end
        
        PADDLEMANIA: begin
            m68k_rom_cs      <= m68k_cs( 24'h000000, 24'h03ffff ) ;
            m68k_ram_cs      <= m68k_cs( 24'h080000, 24'h083fff ) ;
            m68k_spr_cs      <= m68k_cs( 24'h100000, 24'h103fff ) ;

            m68k_dsw1_cs     <= m68k_cs( 24'h180000, 24'h180001 ) ;
            m68k_dsw2_cs     <= m68k_cs( 24'h180008, 24'h180009 ) ;
            
            m68k_p1_cs      <= m68k_cs( 24'h300000, 24'h300001 ) & m68k_rw ;
            m68k_p2_cs      <= m68k_cs( 24'h380000, 24'h380001 ) & m68k_rw ;
            m68k_coin_cs    <= m68k_cs( 24'h340000, 24'h340001 ) & m68k_rw ;
            
            m68k_latch_cs    <= m68k_cs( 24'h380000, 24'h380001 ) & !m68k_rw ;

            m68k_sound_cs    <= 0 ;
            m68k_flip_cs     <= 0 ;
            
            z80_rom_cs        <= ( MREQ_n == 0 && z80_addr[15:0] <  16'ha000 );
            z80_ram_cs        <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800 );
            z80_ram2_cs       <= ( MREQ_n == 0 && z80_addr[15:0] == 16'hfc00 );

            z80_latch_cs      <= ( MREQ_n == 0 && z80_addr[15:0] == 16'he000 ); 
            z80_opl_addr_cs   <= ( MREQ_n == 0 && z80_addr[15:0] == 16'he800 ); 
            z80_opl_data_cs   <= ( MREQ_n == 0 && z80_addr[15:0] == 16'hec00 ) && (!WR_n); 
        end
    endcase

end

endmodule
