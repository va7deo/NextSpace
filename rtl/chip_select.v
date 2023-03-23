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
    output reg m68k_dsw1_cs,
    output reg m68k_dsw2_cs,
    output reg m68k_coin_cs,

    output reg m68k_sound_cs,
//    output reg vbl_int_clr_cs,
//    output reg cpu_int_clr_cs,
//    output reg watchdog_clr_cs,

    output reg m68k_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,
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


//	map(0x070000, 0x073fff).ram();
//	map(0x0a0000, 0x0a3fff).ram().share("spriteram");
//	map(0x0d0000, 0x0d0001).nopw(); // unknown write port (0)
//	map(0x0e0000, 0x0e0001).portr("P1");
//	map(0x0e0002, 0x0e0003).portr("P2");
//	map(0x0e0004, 0x0e0005).portr("SYSTEM");
//	map(0x0e0006, 0x0e0007).nopw(); // unknown write port (0)
//	map(0x0e0008, 0x0e0009).portr("DSW1");
//	map(0x0e000a, 0x0e000b).portr("DSW2");
//	map(0x0e000e, 0x0e000f).nopw(); // unknown write port (0)
//	map(0x0e0018, 0x0e0019).r(FUNC(thenextspace_state::sound_cpu_r));
//	map(0x0f0000, 0x0f0001).w(FUNC(thenextspace_state::tnextspc_unknown_w));
//	map(0x0f0002, 0x0f0005).w(FUNC(thenextspace_state::tnextspc_coin_counters_w));
//	map(0x0f0009, 0x0f0009).w(FUNC(thenextspace_state::tnextspc_soundlatch_w));

// z80
//	map(0x0000, 0xefff).rom();
//	map(0xf000, 0xf7ff).ram();
//	map(0xf800, 0xf800).rw(m_soundlatch, FUNC(generic_latch_8_device::read), FUNC(generic_latch_8_device::clear_w));

// z80 io    
//	map.global_mask(0xff);
//	map(0x00, 0x00).rw("ymsnd", FUNC(ym3812_device::status_r), FUNC(ym3812_device::address_w));
//	map(0x20, 0x20).w("ymsnd" , FUNC(ym3812_device::data_w));
//	map(0x3b, 0x3b).nopr(); // unknown read port
//	map(0x3d, 0x3d).nopr(); // unknown read port
//	map(0x7b, 0x7b).nopr(); // unknown read port
    
localparam NEXTSPACE   = 0;

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
            
            //m68k_sound_cs    <= m68k_cs( 24'h0e0002, 24'h0e0003 ) & m68k_rw ;
            m68k_sound_cs    <= m68k_cs( 24'h0e0018, 24'h0e0019 ) & m68k_rw ;
            
            m68k_latch_cs    <= m68k_cs( 24'h0f0008, 24'h0f0009 ) & !m68k_rw ;
            
            z80_rom_cs        <= ( MREQ_n == 0 && z80_addr[15:0] <  16'hf000 );
            z80_ram_cs        <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800 );
            z80_latch_cs      <= ( MREQ_n == 0 && z80_addr[15:0] == 16'hf800 );
            
            z80_opl_addr_cs   <= ( z80_addr[7:0] == 8'h00 ) && ( !IORQ_n ) ; 
            z80_opl_data_cs   <= ( z80_addr[7:0] == 8'h20 ) && ( !IORQ_n ) && (!WR_n); 
        end
    endcase

end

endmodule
