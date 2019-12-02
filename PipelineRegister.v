
module PipelineRegister
#(
	parameter N=32,
	parameter start=0
)
(
	input clk,
	input enable,
	input reset,
	input  [N-1:0] DataInput,
	
	output reg [N-1:0] DataOutput
);	
	always@(negedge reset or negedge clk) begin
		if(reset==0)
			DataOutput <=start;
		else
			if(enable==1)
				DataOutput<=DataInput;
	end
	
endmodule
	