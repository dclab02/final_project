module Float32toInt16(
    input  [31:0]      floatdata,
    output [15:0]      intdata
);

    logic [7:0] section;
    logic [14:0] x;
    logic [14:0] value;

    assign x = {1'b1, floatdata[22:9]}; // clip 14 bit , and add bit '1' in msb, total 15 bits
    assign value = x >> (14 - section);
    assign intdata = floatdata[31] ? ~{1'b0, value} + 16'd1 : {1'b0, value};

    always_comb begin
        if ($signed(floatdata[30:23] - 8'd127) >= 0) begin
            section = floatdata[30:23] - 8'd127;
        end
        else begin
            section = 8'b0;
        end   
    end
endmodule