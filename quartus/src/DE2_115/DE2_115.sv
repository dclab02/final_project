module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

logic key0down, key1down, key2down, key3down;
logic CLK_12M, CLK_100K, CLK_800K;

// Internal 125 MHz clock
logic clk_int;
logic rst_int;

logic pll_rst;
assign pll_rst = ~KEY[3];
logic pll_locked;

logic clk90_int;

altpll #(
    .bandwidth_type("AUTO"),
    .clk0_divide_by(2),
    .clk0_duty_cycle(50),
    .clk0_multiply_by(5),
    .clk0_phase_shift("0"),
    .clk1_divide_by(2),
    .clk1_duty_cycle(50),
    .clk1_multiply_by(5),
    .clk1_phase_shift("2000"),
    .compensate_clock("CLK0"),
    .inclk0_input_frequency(20000),
    .intended_device_family("Cyclone IV E"),
    .operation_mode("NORMAL"),
    .pll_type("AUTO"),
    .port_activeclock("PORT_UNUSED"),
    .port_areset("PORT_USED"),
    .port_clkbad0("PORT_UNUSED"),
    .port_clkbad1("PORT_UNUSED"),
    .port_clkloss("PORT_UNUSED"),
    .port_clkswitch("PORT_UNUSED"),
    .port_configupdate("PORT_UNUSED"),
    .port_fbin("PORT_UNUSED"),
    .port_inclk0("PORT_USED"),
    .port_inclk1("PORT_UNUSED"),
    .port_locked("PORT_USED"),
    .port_pfdena("PORT_UNUSED"),
    .port_phasecounterselect("PORT_UNUSED"),
    .port_phasedone("PORT_UNUSED"),
    .port_phasestep("PORT_UNUSED"),
    .port_phaseupdown("PORT_UNUSED"),
    .port_pllena("PORT_UNUSED"),
    .port_scanaclr("PORT_UNUSED"),
    .port_scanclk("PORT_UNUSED"),
    .port_scanclkena("PORT_UNUSED"),
    .port_scandata("PORT_UNUSED"),
    .port_scandataout("PORT_UNUSED"),
    .port_scandone("PORT_UNUSED"),
    .port_scanread("PORT_UNUSED"),
    .port_scanwrite("PORT_UNUSED"),
    .port_clk0("PORT_USED"),
    .port_clk1("PORT_USED"),
    .port_clk2("PORT_UNUSED"),
    .port_clk3("PORT_UNUSED"),
    .port_clk4("PORT_UNUSED"),
    .port_clk5("PORT_UNUSED"),
    .port_clkena0("PORT_UNUSED"),
    .port_clkena1("PORT_UNUSED"),
    .port_clkena2("PORT_UNUSED"),
    .port_clkena3("PORT_UNUSED"),
    .port_clkena4("PORT_UNUSED"),
    .port_clkena5("PORT_UNUSED"),
    .port_extclk0("PORT_UNUSED"),
    .port_extclk1("PORT_UNUSED"),
    .port_extclk2("PORT_UNUSED"),
    .port_extclk3("PORT_UNUSED"),
    .self_reset_on_loss_lock("ON"),
    .width_clock(5)
)
altpll_component (
    .areset(pll_rst),
    .inclk({1'b0, CLOCK_50}),
    .clk({clk90_int, clk_int}),
    .locked(pll_locked),
    .activeclock(),
    .clkbad(),
    .clkena({6{1'b1}}),
    .clkloss(),
    .clkswitch(1'b0),
    .configupdate(1'b0),
    .enable0(),
    .enable1(),
    .extclk(),
    .extclkena({4{1'b1}}),
    .fbin(1'b1),
    .fbmimicbidir(),
    .fbout(),
    .fref(),
    .icdrclk(),
    .pfdena(1'b1),
    .phasecounterselect({4{1'b1}}),
    .phasedone(),
    .phasestep(1'b1),
    .phaseupdown(1'b1),
    .pllena(1'b1),
    .scanaclr(1'b0),
    .scanclk(1'b0),
    .scanclkena(1'b1),
    .scandata(1'b0),
    .scandataout(),
    .scandone(),
    .scanread(1'b0),
    .scanwrite(1'b0),
    .sclkout0(),
    .sclkout1(),
    .vcooverrange(),
    .vcounderrange()
);

my_pll pll2(
	.areset(KEY[3]),
	.inclk0(CLOCK_50),
	.c0(CLK_12M),
	.c1(CLK_800K),
	.locked()
);

// you can decide key down settings on your own, below is just an example
Debounce deb0(
	.i_in(KEY[0]), // Record/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key0down) 
);

Debounce deb1(
	.i_in(KEY[1]), // Play/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key1down) 
);

Debounce deb2(
	.i_in(KEY[2]), // Stop
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key2down) 
);

final_project_core top0(
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.i_clk12M(CLK_12M),
	.i_key_0(key0down),
	.i_key_1(key1down),
	.i_key_2(key2down),
	// .i_speed(SW[3:0]), // design how user can decide mode on your own
	
	// SRAM
	.o_SRAM_ADDR(SRAM_ADDR), // [19:0]
	.io_SRAM_DQ(SRAM_DQ),    // [15:0]
	.o_SRAM_WE_N(SRAM_WE_N),
	.o_SRAM_CE_N(SRAM_CE_N),
	.o_SRAM_OE_N(SRAM_OE_N),
	.o_SRAM_LB_N(SRAM_LB_N),
	.o_SRAM_UB_N(SRAM_UB_N),
	
	// I2C
	.i_clk_100k(CLK_100K),
	.o_I2C_SCLK(I2C_SCLK),
	.io_I2C_SDAT(I2C_SDAT),
	
	// AudPlayer
	// .i_AUD_ADCDAT(AUD_ADCDAT),
	// .i_AUD_ADCLRCK(AUD_ADCLRCK),
	// .i_AUD_BCLK(AUD_BCLK),
	// .i_AUD_DACLRCK(AUD_DACLRCK),
	// .o_AUD_DACDAT(AUD_DACDAT)

	// SEVENDECODER (optional display)
	// .o_record_time(recd_time),
	// .o_play_time(play_time),

	// LCD (optional display)
	// .i_clk_800k(CLK_800K),
	// .o_LCD_DATA(LCD_DATA), // [7:0]
	// .o_LCD_EN(LCD_EN),
	// .o_LCD_RS(LCD_RS),
	// .o_LCD_RW(LCD_RW),
	// .o_LCD_ON(LCD_ON),
	// .o_LCD_BLON(LCD_BLON),

	// LED
	// .o_ledg(LEDG), // [8:0]
	// .o_ledr(LEDR) // [17:0]

    /*
     * GPIO
     */
    // .btn(btn_int),
    // .sw(sw_int),
    .led_g(LEDG),
    // .ledr(LEDR),
    // .hex0(HEX0),
    // .hex1(HEX1),
    // .hex2(HEX2),
    // .hex3(HEX3),
    // .hex4(HEX4),
    // .hex5(HEX5),
    // .hex6(HEX6),
    // .hex7(HEX7),
    // .gpio(GPIO),

);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~pll_locked),
    .out(rst_int)
);

udp_wrapper udp0(

	.i_clk(clk_int),
    .i_clk90(clk90_int),
	.i_rst(rst_int),
    // .i_rst_n(KEY[3]),

	.udp_tx_ready(),
    .udp_tx_length(),
    .udp_rx_avail(),
    .udp_rx_last(),
    .udp_data_rx(),
    .udp_data_tx(),

	.led_r(LEDR),
	.hex0(HEX0),
    .hex1(HEX1),
    .hex2(HEX2),
    .hex3(HEX3),
    .hex4(HEX4),
    .hex5(HEX5),
    .hex6(HEX6),
    .hex7(HEX7),

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy0_rx_clk(ENET0_RX_CLK),
    .phy0_rxd(ENET0_RX_DATA),
    .phy0_rx_ctl(ENET0_RX_DV),
    .phy0_tx_clk(ENET0_GTX_CLK),
    .phy0_txd(ENET0_TX_DATA),
    .phy0_tx_ctl(ENET0_TX_EN),
    .phy0_reset_n(ENET0_RST_N),
    .phy0_int_n(ENET0_INT_N)

);





endmodule