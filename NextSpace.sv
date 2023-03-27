//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

`default_nettype none

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output        CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,    // = ~(VBlank | HBlank)
    output        VGA_F1,
    output [2:0]  VGA_SL,
    output        VGA_SCALER, // Force VGA scaler

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef MISTER_FB
    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output  [4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output  [7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output  [1:0] BUTTONS,

    input         CLK_AUDIO, // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout   [3:0] ADC_BUS,

    //SD-SPI
    output        SD_SCK,
    output        SD_MOSI,
    input         SD_MISO,
    output        SD_CS,
    input         SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output  [1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input         UART_CTS,
    output        UART_RTS,
    input         UART_RXD,
    output        UART_TXD,
    output        UART_DTR,
    input         UART_DSR,

`ifdef MISTER_ENABLE_YC
	output [39:0] CHROMA_PHASE_INC,
	output        YC_EN,
	output        PALFLAG,
`endif
    
    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT,

    input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_MIX = 0;
assign LED_USER =  | {cfg} ;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

assign m68k_a[0] = 0;

// Status Bit Map:
//              Upper Case                     Lower Case           
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X   XXXXXX        XXXXX XXXXXXXX       X                 XXXXXXXX

wire [1:0]  aspect_ratio = status[9:8];
wire        orientation = ~status[3];
wire [2:0]  scan_lines = status[6:4];

wire [3:0]  hs_offset = status[27:24];
wire [3:0]  vs_offset = status[31:28];
wire [3:0]  hs_width  = status[59:56];
wire [3:0]  vs_width  = status[63:60];

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd8 : 8'd7) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd7 : 8'd8) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
    "The Next Space;;",
    "-;",
    "P1,Video Settings;",
    "P1-;",
    "P1O89,Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
    "P1O3,Orientation,Horz,Vert;",
    "P1-;",
    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%,CRT 100%;",
    "P1OA,Force Scandoubler,Off,On;",
    "P1-;",
    "P1O7,Video Mode,NTSC,PAL;",
    "P1OM,Video Signal,RGBS/YPbPr,Y/C;",
    "P1-;",
    "P1OOR,H-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1OSV,V-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P1oOR,H-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1oSV,V-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P2,Pause Options;",
    "P2-;",
    "P2OK,Pause when OSD is open,Off,On;",
    "P2OL,Dim video after 10s,Off,On;",
    "-;",
    "DIP;",
    "-;",
    "R0,Reset;",
    "J1,Button 1,Button 2,Button 3,Start,Coin,Pause;",
    "jn,A,B,X,R,L,Start;",           // name mapping
    "V,v",`BUILD_DATE
};


wire hps_forced_scandoubler;
wire forced_scandoubler = hps_forced_scandoubler | status[10];

wire  [1:0] buttons;
wire [63:0] status;
wire [10:0] ps2_key;
wire [15:0] joy0, joy1, joy2, joy3;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .buttons(buttons),
    .ps2_key(ps2_key),
    .status(status),
    .status_menumask(direct_video),
    .forced_scandoubler(hps_forced_scandoubler),
    .gamma_bus(gamma_bus),
    .direct_video(direct_video),
    .video_rotated(video_rotated),
    
    .ioctl_download(ioctl_download),
    .ioctl_upload(ioctl_upload),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_din(ioctl_din),
    .ioctl_index(ioctl_index),
    .ioctl_wait(ioctl_wait),

    .joystick_0(joy0),
    .joystick_1(joy1),
    .joystick_2(joy2),
    .joystick_3(joy3)
);

// INPUT

// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end

always @(posedge clk_sys) begin
    if (ioctl_wr && ioctl_index==1) begin
        pcb <= ioctl_dout;
    end
end

wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

reg   [3:0] pcb;
reg   [7:0] cfg;

localparam NEXTSPACE   = 0;
localparam PADDLEMANIA = 1;

wire [21:0] gamma_bus;

//<buttons names="Fire,Jump,Start,Coin,Pause" default="A,B,R,L,Start" />
reg [15:0] p1;
reg [15:0] p2;
reg [15:0] dsw1_m68k;
reg [15:0] dsw2_m68k;
reg [15:0] coin;

always @ (posedge clk_sys ) begin
    if ( pcb == NEXTSPACE ) begin
        p1   <=  ~{ start1, p1_buttons[2:0], p1_right, p1_left, p1_down, p1_up };
        p2   <=  ~{ start2, p2_buttons[2:0], p2_right, p2_left, p2_down, p2_up };

        dsw1_m68k <= { 8'hff, sw[0] };
        dsw2_m68k <= { 8'hff, sw[1] };

        coin <=  ~{ 13'b1, key_service, coin_b, coin_a};
    end else begin
        p1   <=  ~{ 1'b1, p2_buttons[2:0], p2_right, p2_left, p2_down, p2_up, 1'b1, p1_buttons[2:0], p1_right, p1_left, p1_down, p1_up };
        coin <=  ~{ 1'b1, key_service, 4'b1, start2, start1, 6'b1, coin_b, coin_a };
  end
end

wire        p1_right;
wire        p1_left;
wire        p1_down;
wire        p1_up;
wire [2:0]  p1_buttons;

wire        p2_right;
wire        p2_left;
wire        p2_down;
wire        p2_up;
wire [2:0]  p2_buttons;

wire        p3_right;
wire        p3_left;
wire        p3_down;
wire        p3_up;
wire [2:0]  p3_buttons;

wire        p4_right;
wire        p4_left;
wire        p4_down;
wire        p4_up;
wire [2:0]  p4_buttons;

wire start1;
wire start2;
wire start3;
wire start4;
wire coin_a;
wire coin_b;
wire b_pause;
wire service;

always @ * begin
    if ( pcb == NEXTSPACE ) begin
        p1_right   <= joy0[0] | key_p1_right;
        p1_left    <= joy0[1] | key_p1_left;
        p1_down    <= joy0[2] | key_p1_down;
        p1_up      <= joy0[3] | key_p1_up;
        p1_buttons <= joy0[6:4] | {key_p1_c, key_p1_b, key_p1_a};

        p2_right   <= joy1[0] | key_p2_right;
        p2_left    <= joy1[1] | key_p2_left;
        p2_down    <= joy1[2] | key_p2_down;
        p2_up      <= joy1[3] | key_p2_up;
        p2_buttons <= joy1[6:4] | {key_p2_c, key_p2_b, key_p2_a};

        start1  = joy0[7]  | joy1[7]  | key_start_1p;
        start2  = joy0[8]  | joy1[8]  | key_start_2p;
        coin_a  = joy0[9]  | joy1[9]  | key_coin_a;
        coin_b  = joy0[10] | joy1[10] | key_coin_b;
        b_pause = joy0[11] | key_pause;
    end else begin
    p1_right   <= joy0[0] | key_p1_right;
    p1_left    <= joy0[1] | key_p1_left;
    p1_down    <= joy0[2] | key_p1_down;
    p1_up      <= joy0[3] | key_p1_up;
    p1_buttons <= joy0[6:4] | {key_p1_c, key_p1_b, key_p1_a};

    p2_right   <= joy1[0] | key_p2_right;
    p2_left    <= joy1[1] | key_p2_left;
    p2_down    <= joy1[2] | key_p2_down;
    p2_up      <= joy1[3] | key_p2_up;
    p2_buttons <= joy1[6:4] | {key_p2_c, key_p2_b, key_p2_a};

    start1  = joy0[7]  | joy1[7]  | key_start_1p;
    start2  = joy0[8]  | joy1[8]  | key_start_2p;
    coin_a  = joy0[9]  | joy1[9]  | key_coin_a;
    coin_b  = joy0[10] | joy1[10] | key_coin_b;
    b_pause = joy0[11] | key_pause;
  end
end

// Keyboard handler

wire key_start_1p, key_start_2p, key_coin_a, key_coin_b;
wire key_tilt, key_test, key_reset, key_service, key_pause;

wire key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c;
wire key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c;

wire pressed = ps2_key[9];

always @(posedge clk_sys) begin 
    reg old_state;

    old_state <= ps2_key[10];
    if(old_state ^ ps2_key[10]) begin
        casex(ps2_key[8:0])
            'h016: key_start_1p   <= pressed; // 1
            'h01e: key_start_2p   <= pressed; // 2
            'h02E: key_coin_a     <= pressed; // 5
            'h036: key_coin_b     <= pressed; // 6
            'h004: key_reset      <= pressed; // f3
            'h046: key_service    <= pressed; // 9
            'h04D: key_pause      <= pressed; // p

            'hX75: key_p1_up      <= pressed; // up
            'hX72: key_p1_down    <= pressed; // down
            'hX6b: key_p1_left    <= pressed; // left
            'hX74: key_p1_right   <= pressed; // right
            'h014: key_p1_a       <= pressed; // lctrl
            'h011: key_p1_b       <= pressed; // lalt
            'h029: key_p1_c       <= pressed; // spacebar

            'h02d: key_p2_up      <= pressed; // r
            'h02b: key_p2_down    <= pressed; // f
            'h023: key_p2_left    <= pressed; // d
            'h034: key_p2_right   <= pressed; // g
            'h01c: key_p2_a       <= pressed; // a
            'h01b: key_p2_b       <= pressed; // s
            'h015: key_p2_c       <= pressed; // q

        endcase
    end
end

wire pll_locked;

wire clk_sys;
reg  clk_4M,clk_6M,clk_18M;

wire clk_72M;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_sys),
    .outclk_1(clk_72M),
    .locked(pll_locked)
);

assign    SDRAM_CLK = clk_72M;

localparam  CLKSYS=72;

reg [15:0] clk18_count;
reg  [5:0] clk6_count;
reg  [7:0] clk4_count;

always @ (posedge clk_sys) begin

    clk_4M <= ( clk4_count == 0 );
    if ( clk4_count == 17 ) begin 
        clk4_count <= 0;
    end else begin
        clk4_count <= clk4_count + 1;
    end
    
    clk_6M <= ( clk6_count == 0 );
    if ( clk6_count == 11 ) begin 
        clk6_count <= 0;
    end else begin
        clk6_count <= clk6_count + 1;
    end

    // 18MHZ
    clk_18M <= ( clk18_count == 0 );
    if ( clk18_count == 3 ) begin 
        clk18_count <= 0;
    end else begin
        clk18_count <= clk18_count + 1;
    end
end

wire    reset;
assign  reset = RESET | key_reset | status[0] ; 

//////////////////////////////////////////////////////////////////
wire rotate_ccw = 0;
wire no_rotate = orientation | direct_video;
wire video_rotated ;
wire flip = 0;

reg [23:0]     rgb;

wire hbl;
wire vbl;

wire [8:0] hc;
wire [8:0] vc;

wire hsync;
wire vsync;

reg hbl_delay, vbl_delay;

always @ ( posedge clk_6M ) begin
    hbl_delay <= hbl ;
    vbl_delay <= vbl ;
end

video_timing video_timing (
    .clk(clk_sys),
    .clk_pix(clk_6M),
    .pcb(pcb),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

// PAUSE SYSTEM
wire    pause_cpu;
wire    hs_pause;

// 8 bits per colour, 72MHz sys clk
pause #(8,8,8,72) pause 
(
    .clk_sys(clk_sys),
    .reset(reset),
    .user_button(b_pause),
    .pause_request(hs_pause),
    .options(status[21:20]),
    .pause_cpu(pause_cpu),
    .dim_video(dim_video),
    .OSD_STATUS(OSD_STATUS),
    .r(rgb[23:16]),
    .g(rgb[15:8]),
    .b(rgb[7:0]),
    .rgb_out(rgb_pause_out)
);

wire [23:0] rgb_pause_out;
wire dim_video;

arcade_video #(256,24) arcade_video
(
        .*,

        .clk_video(clk_sys),
        .ce_pix(clk_6M),

        .RGB_in(rgb_pause_out),

        .HBlank(hbl_delay),
        .VBlank(vbl_delay),
        .HSync(hsync),
        .VSync(vsync),

        .fx(scan_lines)
);

/*     Phase Accumulator Increments (Fractional Size 32, look up size 8 bit, total 40 bits)
    Increment Calculation - (Output Clock * 2 ^ Word Size) / Reference Clock
    Example
    NTSC = 3.579545
    PAL =  4.43361875
    W = 40 ( 32 bit fraction, 8 bit look up reference)
    Ref CLK = 42.954544 (This could us any clock)
    NTSC_Inc = 3.579545333 * 2 ^ 40 / 96 = 40997413706
    
*/

// SET PAL and NTSC TIMING
`ifdef MISTER_ENABLE_YC
    assign CHROMA_PHASE_INC = PALFLAG ? 40'd67705769163: 40'd54663218274 ;
    assign YC_EN =  status[22];
    assign PALFLAG = status[7];
`endif

screen_rotate screen_rotate (.*);

reg [7:0] hc_del;

reg [4:0] sprite_state;
reg [8:0] sprite_num;

reg   [2:0] pri_buf[0:255];
 
reg  [15:0] spr_pix_data;

reg   [8:0] x;

reg         flip_dip;

wire  [8:0] sp_x    = x ;
wire  [8:0] sp_y    = vc ^ { 8 { flip_dip } };

reg   [7:0] sprite_colour;
reg  [13:0] sprite_tile_num;
reg         sprite_flip_x;
reg         sprite_flip_y;
reg   [1:0] sprite_group;
reg   [4:0] sprite_col;
reg   [7:0] sprite_col_x;
reg   [7:0] sprite_col_y;
reg   [8:0] sprite_col_idx;
reg   [8:0] spr_x_pos;
reg   [3:0] spr_x_ofs;

reg   [1:0] sprite_layer;
wire  [1:0] layer_order [3:0] = '{2'd2,2'd3,2'd1,2'd0};

wire  [3:0] spr_pen = { spr_pix_data[ 4 + spr_x_ofs[1:0]], 
                        spr_pix_data[ 0 + spr_x_ofs[1:0]], 
                        spr_pix_data[12 + spr_x_ofs[1:0]], 
                        spr_pix_data[ 8 + spr_x_ofs[1:0]] }  ;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        sprite_state <= 0;
        sprite_overrun <= 0;
        sprite_rom_cs <= 0;
    end else begin

        // sprites. -- need 3 sprite layers - 1 layer is split
        if ( sprite_state == 0 && hc == 0 ) begin
            // init
            sprite_state <= 21; // 21 = clear buffer, 22 = don't   ***********
            sprite_num <= 0;
            sprite_layer <= 0;
            // setup clearing line buffer
            spr_buf_din <= 0 ;
            spr_x_pos <= 0;
        end else if ( sprite_state == 21 )  begin  
            spr_buf_w <= 1 ;
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            if ( spr_x_pos > 256 ) begin
                spr_buf_w <= 0 ;
                sprite_state <= 22;
            end
            spr_x_pos <= spr_x_pos + 1;
        end else if ( sprite_state == 22 ) begin  
            // start 
            sprite_col   <= 0;
            case ( sprite_layer )
                0: begin
                        sprite_group <= 2;
                   end
                1: begin
                        sprite_group <= 3;
                   end
                2: begin
                        sprite_group <= 1;
                   end
            endcase
            sprite_state <= 1;
        end else if ( sprite_state == 1 )  begin
            spr_buf_w <= 0 ;

            // setup x/y read
            sprite_ram_addr <= { sprite_col, 3'b0, sprite_group } ;
            sprite_state <= 2;
        end else if ( sprite_state == 2 )  begin
            // address valid
            sprite_state <= 3;
        end else if ( sprite_state == 3 )  begin
            // x/y data valid
            
            sprite_col_x <= sprite_ram_dout[7:0] ;
            // sprite_col_y <= 8'h01 - sprite_ram_dout[15:8] ; 
            sprite_col_y <= ( flip_dip ? 8'hff : 8'h01 ) - sprite_ram_dout[15:8] ;
            
            sprite_state <= 4;
        end else if ( sprite_state == 4 )  begin   
            sprite_state <= 5;
        end else if ( sprite_state == 5 )  begin
            // tile ofset from the top of the column
            sprite_col_idx <= sp_y - sprite_col_y[7:0] ; // was plus
            sprite_state <= 6;
        end else if ( sprite_state == 6 )  begin
            sprite_ram_addr <= { sprite_group[1:0], sprite_col[4:0], sprite_col_idx[7:3] };
            sprite_state <= 7;
            
        end else if ( sprite_state == 7 ) begin
            // sprite_ram_addr valid
            sprite_state <= 8;
        end else if ( sprite_state == 8 ) begin
            // sprite_ram_dout valid
            
            // tile num ready
            sprite_tile_num <= sprite_ram_dout[13:0] ;
            sprite_flip_y   <= sprite_ram_dout[14] ;
            
            tile_colour_rom_addr <= { sprite_ram_dout[13:0], sprite_ram_dout[15] };
            
            sprite_state <= 9;
        end else if ( sprite_state == 9 ) begin
            // tile_colour_rom_addr valid

            spr_x_ofs <= 0;
            spr_x_pos <= sprite_col_x[7:0] ;
            sprite_state <= 18;
            
        end else if ( sprite_state == 18 )  begin       
            // tile_colour_rom_data valid
            sprite_colour <= tile_colour_rom_data ;
            sprite_state <= 10;
            
        end else if ( sprite_state == 10 )  begin    
            case ( sprite_flip_y )
                1'b0: sprite_rom_addr <= { sprite_tile_num, ~spr_x_ofs[2],  sprite_col_idx[2:0] } ;  // word addressing
                1'b1: sprite_rom_addr <= { sprite_tile_num, ~spr_x_ofs[2], ~sprite_col_idx[2:0] } ;
            endcase 
            
            sprite_rom_cs <= 1;
            sprite_state <= 11;
        end else if ( sprite_state == 11 ) begin
            // wait for sprite bitmap data
            if ( sprite_rom_valid == 1 ) begin
                // bitmap data valid.  deassert read
                sprite_rom_cs <= 0;
                spr_pix_data <= sprite_rom_data;
                sprite_state <= 12 ;
            end
        end else if ( sprite_state == 12 ) begin
            sprite_state <= 13;
        end else if ( sprite_state == 13 ) begin
            // write to the line buffer
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            
            spr_buf_w <= (| spr_pen ) ; // don't write if 0 - transparent

             spr_buf_din <= { 4'b0, sprite_colour, spr_pen };
            //spr_buf_din <= { 4'b0, 8'b0, spr_pen };

            if ( spr_x_ofs < 7 ) begin
                spr_x_ofs <= spr_x_ofs + 1;
                spr_x_pos <= spr_x_pos + 1;
                if ( spr_x_ofs == 3 ) begin
                    // get data for other side of the tile
                    // spr_x_ofs will be 4 next clock
                    sprite_state <= 10;
                end
            end else begin
                sprite_state <= 17;
            end
       
        end else if ( sprite_state == 17) begin             
            spr_buf_w <= 0 ;
            if ( hc < 340 ) begin
                if ( sprite_col < 31 ) begin
                    sprite_col <= sprite_col + 1;
                    sprite_state <= 1; 
                end else begin
                    if ( sprite_layer < 2 ) begin
                        sprite_layer <= sprite_layer + 1;
                        sprite_state <= 22;  
                    end else begin
                        sprite_state <= 0;  
                    end
                end
            end else begin
                sprite_state <= 0;
            end
        end

    end
end
        
reg sprite_overrun;

reg [11:0] fg;
reg [11:0] sp;

reg [23:0] rgb_fg;
reg [23:0] rgb_sp;

reg [11:0] pen;
reg pen_valid;
                
always @ (posedge clk_sys) begin

    if ( hc < 257 ) begin
        if ( clk6_count == 2 ) begin
            line_buf_addr_r <= { ~vc[0], 1'b0, hc[7:0] ^ { 8 { flip_dip } } } ; 
            //line_buf_addr_r <= { ~vc[0], 1'b0, hc[7:0] } ; 
        end else if ( clk6_count == 3 ) begin
            // line_buf_addr_r valid
        end else if ( clk6_count == 4 ) begin
            clut_addr <= spr_buf_dout[11:0] ;
        end else if ( clk6_count == 5 ) begin
            // clut_addr valid
        end else if ( clk6_count == 7 ) begin
            palette_addr <= clut_data ;
        end else if ( clk6_count == 9 ) begin
            if ( spr_buf_dout[3:0] == 0 ) begin
                rgb <= 0;
            end else begin
                rgb <= {  { 2 { palette_data[27:24] } }, { 2 { palette_data[19:16] }} , { 2 { palette_data[11:8] }} };
            end
        end
    end
end

reg [7:0] tile_bank;
reg [1:0] vbl_sr;
reg [1:0] hbl_sr;

/// 68k cpu
always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        m68k_dtack_n <= 1;
        
        m68k_ipl0_n <= 1 ;
        m68k_ipl1_n <= 1 ;
        
        z80_nmi_n   <= 1 ;
        flip_dip    <= 0 ;
        m68k_latch  <= 0 ;
        
    end else begin
    
        // vblank handling 
        vbl_sr <= { vbl_sr[0], vbl };
        if ( vbl_sr == 2'b01 ) begin // rising edge
            //  68k vbl interrupt
            m68k_ipl0_n <= 0;
        end 

        if ( clk_18M == 1 ) begin
            // cpu acknowledged the interrupt
            // TODO - this should be enable lines set by reading memory locations d8000 & e0000
            if ( ( m68k_as_n == 0 ) && ( m68k_fc == 3'b111 ) ) begin
                m68k_ipl0_n <= 1;
//                m68k_ipl1_n <= 1;
            end
            
            // tell 68k to wait for valid data. 0=ready 1=wait
            // always ack when it's not program rom
            m68k_dtack_n <= m68k_rom_cs ? !m68k_rom_valid : 0; 
                        
            if ( m68k_rw == 1 ) begin                          
                // reads
                m68k_din <=  m68k_rom_cs ? m68k_rom_data :
                             m68k_ram_cs  ? m68k_ram_dout :
                             // high byte of even addressed sprite ram not connected.  pull high.
                             m68k_spr_cs  ? m68k_sprite_dout : // 0xff000000
                             m68k_p1_cs ? p1 :
                             m68k_p2_cs ? p2 :
                             m68k_dsw1_cs ? dsw1_m68k :
                             m68k_dsw2_cs ? dsw2_m68k :
                             m68k_coin_cs ? coin :
                             m68k_sound_cs ? 16'h0001 :
                             16'h0000;
            end else begin        
                // writes
            
                if ( m68k_latch_cs == 1 ) begin
                    if ( m68k_lds_n == 0 ) begin // LDS 0x0f0009
                        m68k_latch <= m68k_dout[7:0];
                        z80_nmi_n <= 0 ;  // trigger nmi
                    end
                end else if ( m68k_flip_cs == 1 ) begin
                    flip_dip <= m68k_dout[0];
                end
            end 
        end
        
        if ( clk_4M == 1 ) begin
       
            z80_wait_n <= 1;
            opl_wr <= 0; 
            
            // reset
            if ( M1_n == 0 ) begin
                // for interrupt ack
                z80_nmi_n <= 1 ;
            end
            
            if ( z80_rd_n == 0 ) begin
                if ( z80_ram_cs == 1 ) begin
                    z80_din <= z80_ram_data ;
                end else if ( z80_latch_cs == 1 ) begin
                    // latch may get cleared before used
                    z80_din <= m68k_latch;
                end else if ( z80_rom_cs == 1 ) begin
                    z80_din <= z80_rom_data ;
                end else if ( z80_opl_addr_cs == 1 ) begin
                    z80_din <= opl_dout ;
                end
            end
           
            if ( z80_wr_n == 0 ) begin
                // WRITE
                if ( z80_latch_cs == 1 ) begin
                    // tell the 68k that the z80 has the data
                    m68k_latch <= 0;
                end
        
                if ( z80_opl_addr_cs == 1 || z80_opl_data_cs == 1) begin    
                    opl_data <= z80_dout;
                    opl_addr <= z80_opl_data_cs ; //   opl2 is single bit address
                    opl_wr <= 1;                
                end
            end
        end
    end
end 

reg        opl_wr;

reg        opl_addr ;
reg  [7:0] opl_data ;
wire [7:0] opl_dout ;

// sound ic write enable

reg signed [15:0] opl_sample;

assign AUDIO_S = 1'b1 ;

wire opl_sample_clk ;

reg  signed  [7:0] dac ;
wire signed [15:0] dac_sample = { ~dac[7], dac[6:0], 8'h0 } ;

always @ * begin
    // mix audio
    AUDIO_L <= opl_sample ; 
    AUDIO_R <= opl_sample ;
end

jtopl #(.OPL_TYPE(2)) opl
(
    .rst(reset),
    .clk(clk_4M),
    .cen(1'b1),
    .din(opl_data),
    .addr(opl_addr),
    .cs_n(~( z80_opl_addr_cs | z80_opl_data_cs )),
    .wr_n(~opl_wr),
    .dout(opl_dout),
    .irq_n( z80_irq_n ),  
    .snd(opl_sample),
    .sample(opl_sample_clk)
);
 
wire    m68k_rom_cs;
wire    m68k_ram_cs;
wire    m68k_spr_cs;
wire    m68k_dsw1_cs;
wire    m68k_dsw2_cs;
wire    m68k_p1_cs;
wire    m68k_p2_cs;
wire    m68k_coin_cs;
wire    m68k_sound_cs;
wire    m68k_flip_cs;
wire    m68k_latch_cs;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_opl_addr_cs;
wire    z80_opl_data_cs;
wire    z80_latch_cs;
  
chip_select cs (
    .clk(clk_sys),
    .pcb(pcb),

    // 68k bus
    .m68k_a,
    .m68k_as_n,
    .m68k_rw,

    .z80_addr,
    .MREQ_n,
    .IORQ_n,
    .RD_n( z80_rd_n ),
    .WR_n( z80_wr_n ),
    
    .M1_n,
    
    // 68k chip selects
    .m68k_rom_cs,
    .m68k_ram_cs,
    .m68k_spr_cs,

    .m68k_p1_cs,
    .m68k_p2_cs,
    .m68k_coin_cs,
    .m68k_flip_cs,
    
    .m68k_dsw1_cs,
    .m68k_dsw2_cs,
   
    .m68k_sound_cs,
    .m68k_latch_cs, 
    
    // z80 
    .z80_rom_cs,
    .z80_ram_cs,
    
    .z80_latch_cs,
    
    .z80_opl_addr_cs,
    .z80_opl_data_cs

);
 
//reg [7:0]  z80_latch;
reg [7:0]  m68k_latch;

// CPU outputs
wire m68k_rw         ;    // Read = 1, Write = 0
wire m68k_as_n       ;    // Address strobe
wire m68k_lds_n      ;    // Lower byte strobe
wire m68k_uds_n      ;    // Upper byte strobe
wire m68k_E;         
wire [2:0] m68k_fc    ;   // Processor state
wire m68k_reset_n_o  ;    // Reset output signal
wire m68k_halted_n   ;    // Halt output

// CPU busses
wire [15:0] m68k_dout       ;
wire [23:0] m68k_a   /* synthesis keep */       ;
reg  [15:0] m68k_din        ;   

// CPU inputs
reg  m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl0_n ;
reg  m68k_ipl1_n ;

wire m68k_vpa_n = ~(m68k_a[22] & ~(m68k_uds_n & m68k_lds_n)) ;   //~int_ack
wire m68k_e ;

reg int_ack ;

wire reset_n;

reg fg_enable;
reg sp_enable;

// fx68k clock generation
reg fx68_phi1;

always @(posedge clk_sys) begin
    if ( clk_18M == 1 ) begin
        fx68_phi1 <= ~fx68_phi1;
    end
end

fx68k fx68k (
    // input
    .clk( clk_18M ),
    .enPhi1(fx68_phi1),
    .enPhi2(~fx68_phi1),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68k_rw),
    .ASn(m68k_as_n),
    .LDSn(m68k_lds_n),
    .UDSn(m68k_uds_n),
    .E(m68k_e),
    .VMAn(),
    .FC0(m68k_fc[0]),
    .FC1(m68k_fc[1]),
    .FC2(m68k_fc[2]),
    .BGn(),
    .oRESETn(m68k_reset_n_o),
    .oHALTEDn(m68k_halted_n),

    // input
    .VPAn( m68k_vpa_n ),  
    .DTACKn( m68k_dtack_n ),     
    .BERRn(1'b1), 
    .BRn(1'b1),  
    .BGACKn(1'b1),
    
    .IPL0n(m68k_ipl0_n),
    .IPL1n(m68k_ipl1_n),
    .IPL2n(1'b1),

    // busses
    .iEdb(m68k_din),
    .oEdb(m68k_dout),
    .eab(m68k_a[23:1])
);


// z80 audio 
wire    [7:0] z80_rom_data;
wire    [7:0] z80_ram_data;

wire   [15:0] z80_addr;
reg     [7:0] z80_din;
wire    [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
reg  z80_wait_n;
reg  z80_irq_n;
reg  z80_nmi_n;

wire IORQ_n;
wire MREQ_n;
wire M1_n;

T80pa z80 (
    .RESET_n    ( ~reset ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk_4M ),
    .CEN_n      ( ~clk_4M ),
    .WAIT_n     ( z80_wait_n ), // z80_wait_n
    .INT_n      ( z80_irq_n ),  
    .NMI_n      ( z80_nmi_n ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     (),
    .IORQ_n     ( IORQ_n ),
    .M1_n       ( M1_n ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);




reg [16:0] gfx1_addr;
reg  [7:0] gfx1_dout;

wire [15:0] m68k_ram_dout;
wire [15:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;

// ioctl download addressing    
wire rom_download = ioctl_download && (ioctl_index==0);

wire z80_ioctl_wr            = rom_download & ioctl_wr & (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h110000) ;

// c_prom - start 0xd0000 - len 0x8000 -->
wire tile_colours_ioctl_wr   = rom_download & ioctl_wr & (ioctl_addr >= 24'h110000) & (ioctl_addr < 24'h118000) ;

// clu - start 0xd8000 - len 0x800 -->
wire clut_ioctl_wr           = rom_download & ioctl_wr & (ioctl_addr >= 24'h118000) & (ioctl_addr < 24'h118800) ;

// palette - start 0xd8800 - len 0x400 -->
wire palette_ioctl_wr        = rom_download & ioctl_wr & (ioctl_addr >= 24'h118800) & (ioctl_addr < 24'h118c00) ;


// main 68k ram high    
dual_port_ram #(.LEN(8192)) ram8kx8_H (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_ram_dout[15:8] ),
    
//    .clock_b ( clk_sys ),
//    .address_b ( mcu_addr ),  
//    .wren_b ( mcu_wh ),
//    .data_b ( mcu_din ),
//    .q_b( mcu_dout )

    );

// main 68k ram low     
dual_port_ram #(.LEN(8192)) ram8kx8_L (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_ram_dout[7:0] ),
    
//    .clock_b ( clk_sys ),
//    .address_b ( mcu_addr ),  
//    .wren_b ( mcu_wl ),
//    .data_b ( mcu_din ),
//    .q_b( mcu_dout )
    );

reg  [13:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout /* synthesis keep */;

// main 68k sprite ram high  
// 2kx16
dual_port_ram #(.LEN(16384)) sprite_ram_H (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[14:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_sprite_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[15:8] )
    );

// main 68k sprite ram low     
dual_port_ram #(.LEN(16384)) sprite_ram_L (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[14:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_sprite_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );
       
// 256 entry colour palette
// merge r,g & b proms so rgb can be read in parallel

reg         palette_buffer_w;
reg  [31:0] palette_buffer_data;
reg   [7:0] palette_addr;
reg  [31:0] palette_data;

always @ (posedge clk_sys) begin
    if ( palette_ioctl_wr == 1 ) begin
        case ( ioctl_addr[1:0] )
            0: palette_buffer_data[31:24] <= ioctl_dout;
            1: palette_buffer_data[23:16] <= ioctl_dout;
            2: palette_buffer_data[15:8]  <= ioctl_dout;
            3: palette_buffer_data[7:0]   <= ioctl_dout;
        endcase
    end
    palette_buffer_w <= palette_ioctl_wr & (ioctl_addr[1:0] == 2'b11 );
end

// palette rom
dual_port_ram #(.LEN(256), .DATA_WIDTH(32)) palette_rom (
    .clock_a( clk_sys ),
    .address_a( ioctl_addr[9:2] ),
    .wren_a( palette_buffer_w ),
    .data_a( palette_buffer_data  ),
    .q_a ( ),

    .clock_b( clk_sys ),
    .address_b( palette_addr ),  
    .wren_b( 1'b0 ),
    .data_b( ),
    .q_b( palette_data[31:0] )
    );
    
// tile colour map

reg [14:0] tile_colour_rom_addr ;
wire [7:0] tile_colour_rom_data ;

dual_port_ram #(.LEN(32768)) tile_colour_rom (
    .clock_a( clk_sys ),
    .address_a( ioctl_addr[14:0] ),   
    .wren_a( tile_colours_ioctl_wr ),
    .data_a( ioctl_dout ),
    .q_a( ),
    
    .clock_b( clk_sys ),
    .address_b( tile_colour_rom_addr ),
    .wren_b( 1'b0 ),
    .data_b(  ),
    .q_b( tile_colour_rom_data )
    );

// colour lookup table
// uses tile colour + pen to get 8 bit palette index

reg          clut_buffer_w;
reg   [7:0]  clut_buffer_data;
reg   [9:0]  clut_addr;
wire  [7:0]  clut_data;
 
always @ (posedge clk_sys) begin
    if ( clut_ioctl_wr == 1 ) begin
        case ( ioctl_addr[0] )
            0: clut_buffer_data[3:0] <= ioctl_dout[3:0];
            1: clut_buffer_data[7:4] <= ioctl_dout[3:0];
        endcase
    end
    clut_buffer_w <= clut_ioctl_wr & (ioctl_addr[0] == 1'b1 );
end

dual_port_ram #(.LEN(1024)) colour_lut_rom (
    .clock_a( clk_sys ),
    .address_a( ioctl_addr[10:1] ),   
    .wren_a( clut_buffer_w ),
    .data_a( clut_buffer_data ),
    .q_a( ),
    
    .clock_b( clk_sys ),
    .address_b( clut_addr ),
    .wren_b( 1'b0 ),
    .data_b(  ), // only low nibble has data
    .q_b( clut_data )
    );
    
// sound cpu

dual_port_ram #(.LEN(65536)) z80_rom (
    .clock_a ( clk_4M ),
    .address_a ( z80_addr[15:0] ),   
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( z80_rom_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[15:0] ),
    .wren_b ( z80_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
    
   
// z80 ram 
dual_port_ram #(.LEN(2048)) z80_ram (
    .clock_b ( clk_4M ), 
    .address_b ( z80_addr[10:0] ),
    .wren_b ( z80_ram_cs & ~z80_wr_n ),
    .data_b ( z80_dout ),
    .q_b ( z80_ram_data )
    );
    
reg   [9:0]  line_buf_addr_r ; 

reg   [9:0]  spr_buf_addr_w;
reg          spr_buf_w;
reg  [15:0]  spr_buf_din;
wire [15:0]  spr_buf_dout;
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) spr_buffer_ram (
    .clock_a ( clk_sys ),
    .address_a ( spr_buf_addr_w ),
    .wren_a ( spr_buf_w ),
    .data_a ( spr_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ), 
    .wren_b ( 0 ),
    .q_b ( spr_buf_dout )
    ); 
    
  
wire [15:0] m68k_rom_data;
wire        m68k_rom_valid;

reg         sprite_rom_cs;
reg  [17:0] sprite_rom_addr;
wire [15:0] sprite_rom_data;
wire        sprite_rom_valid;

rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
    .prog_rom_cs(m68k_rom_cs),
    .prog_rom_oe(1),
    .prog_rom_addr(m68k_a[23:1]),
    .prog_rom_data(m68k_rom_data),
    .prog_rom_data_valid(m68k_rom_valid),

    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_data),
    .sprite_rom_data_valid(sprite_rom_valid),
    
    // IOCTL interface
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_dout),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_download(ioctl_download),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_q(sdram_q)
  );



reg  [22:0] sdram_addr;
reg  [31:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

sdram #(.CLK_FREQ( (CLKSYS+0.0))) sdram
(
  .reset(~pll_locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  
  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);    

endmodule

//module delay
//(
//    input clk,
//    input clk_en,
//    input i,
//    output o
//);
//
//reg [5:0] r;
//
//assign o = r[0]; 
//
//always @(posedge clk) begin
//    if ( clk_en == 1 ) begin
//        r <= { r[4:0], i };
//    end
//end
//
//endmodule



