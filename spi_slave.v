module spi_slave (
	input wire clk,
	input wire nrst,
	
	input wire spi_csn,
	input wire spi_sck,
	input wire mosi,
	output reg miso,
	input wire [7:0] in_txbits,
	output reg [7:0] out_rxbits,
	output reg out_rx_done
);
	
	reg [2:0] r_cs_sync;
	reg [2:0] r_sck_sync;
	reg [1:0] r_mosi_sync;
	
	reg [7:0] r_rx_shift;
	reg [7:0] r_tx_shift;
	reg [2:0] r_bit_cnt;
	
	wire w_cs_active = -r_cs_sync[1];
	wire w_sck_rising = (r_sck_sync[1] && !r_sck_sync[2]);
	wire w_sck_falling = (!r_sck_sync[1] && r_sck_sync[2]);
	
	always @(posedge clk or negedge nrst) begin
		if (!nrst) begin
			r_cs_sync <= 3'b111;
			r_sck_sync <= 3'b000;
			r_mosi_Sync <= 2'b00;
		end else begin
			r_cs_sync <= {r_cs_sync[1:0], spi_csn};
			r_sck_sync <= {r_sck_sync[1:0], spi_sck};
			r_mosi_Sync <= {r_mosi_sync[0], mosi};
		end
	end
	
	always @(posedge clk or negedge nrst) begin
		if (!nrst) begin
			r_rx_shift <= 8'h00;
			r_tx_shift <= 8'h00;
			r_bit_cnt <= 3'b000;
			out_rxbits <= 8'h00;
			out_rx_done <= 1'b0;
			miso <= 1'b1;
		end else begin
			out_rx_done <= 1'b0;
			
			if (!w_cs_active) begin
				r_bit_cnt <= 3'b000;
				r_tx_shift <= in_txbits;
				miso <= in_txbits[7];
			end else begin
				if (w_sck_rising) begin
					r_rx_shift <= {r_rx_shift[6:0], r_mosi_sync[1]};
				end
				
				if (w_sck_falling) begin
					r_bit_cnt <= r_bit_cnt + 1'b1;
					
					if (r_bit_cnt == 3'b111) begin
						out_rxbits <= {r_rx_shift[6:0], r_mosi_sync[1]};
						out_rx_done <= 1'b1;
						r_tx_shift <= in_txbits;
						miso <= in_txbits[7];
					end else begin
						r_tx_shift <= {r_tx_shift[6:0], 1'b0};
						miso <= r_tx_shift[6];
					end
				end
			end
		end
	end
	
endmodule
