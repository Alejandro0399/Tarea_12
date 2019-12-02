module MIPS_INFINITE
#(
	parameter MEMORY_DEPTH = 64,
	parameter PC_INCREMENT = 4,
	parameter jump_start   = 32'b11_1111_1111_0000_0000_0000_0000_0000_00,
	parameter RA = 31
)
(
	// Inputs
	input clk,
	input reset,
	input [7:0] PortIn,
	// Output
	output [31:0] ALUResultOut,
	output [31:0] PortOut
);
assign  PortOut = 0;
	////////////FETCH WIRES////////////////
	wire [31:0] pc_wire;
	//wire [31:0] NEW_PC;
	wire [31:0] instruction_bus_wire;
	wire [31:0] pc_plus_4_wire;
	
	//////////PIPELINE FETCH_DECODE WIRES//////
	wire [31:0] ID_instruction_bus_wire;
	wire [31:0] ID_pc_plus_4_wire;
	
	///////////DECODE WIRES//////////////////
	wire reg_dst_wire;
	wire [2:0] aluop_wire;
	wire alu_src_wire;
	wire reg_write_wire;
	wire wMemWrite;
	wire wMemRead;
	wire wMemtoReg;
	/*wire branch_ne_wire;
	wire branch_eq_wire;
	wire wJump;
	wire wJump_R;
	wire wJAL;*/
	
	wire [31:0] read_data_1_wire;
	wire [31:0] read_data_2_wire;
	wire [31:0] Inmmediate_extend_wire;
	
	//////////////PIPELINE DECODE_EXECUTE/////////////
	wire EX_wMemtoReg;
	//wire EX_wJump;
	//wire EX_wJump_R;
	//wire EX_wJAL;
	wire EX_reg_dst_wire;
	//wire EX_branch_ne_wire;
	//wire EX_branch_eq_wire;
	wire [2:0] EX_aluop_wire;
	wire EX_alu_src_wire;
	wire EX_reg_write_wire;
	wire EX_wMemWrite;
	wire EX_wMemRead;
	wire [31:0] EX_pc_plus_4_wire;
	wire [31:0] EX_read_data_1_wire;
	wire [31:0] EX_read_data_2_wire;
	wire [31:0] EX_Inmmediate_extend_wire;
	wire [31:0] EX_instruction_bus_wire;
	
	/////////////EXECUTE WIRES//////////////////
	wire [4:0] write_register_wire;
	wire [31:0] read_data_2_orr_inmmediate_wire;
	wire [3:0] alu_operation_wire;
	wire [31:0] alu_result_wire;
	wire zero_wire;
	
	//////////////////////PIPELINE EXECUTE_MEMORY ACCESS////////////////
	wire [4:0] MEM_write_register_wire;
	//MEM_PC_Puls_ShiftLeft_RESULT,
	//MEM_Shift_wire,
	wire [31:0] MEM_read_data_2_wire;
	wire MEM_wMemWrite;
	wire MEM_wMemRead;
	wire MEM_wMemtoReg;
	//MEM_branch_eq_wire,
	//MEM_branch_ne_wire,
	//MEM_wJump_R,
	//MEM_read_data_1_wire,
	//MEM_wJAL,
	wire [31:0] MEM_pc_plus_4_wire;
	//MEM_wJump,
	//MEM_zero_wire,
	wire MEM_reg_write_wire;
	wire [31:0] MEM_alu_result_wire;
	
	/////////////MEMORY ACCESS WIRES/////////////
	wire [31:0] wReadData;
	
	////////////////////////////PIPELINE MEMORY ACCESS _ WRITE BACK/////////////////
	wire [4:0] WB_write_register_wire;
	//WB_PC_Puls_ShiftLeft_RESULT,
	//WB_Shift_wire,
	wire WB_wMemtoReg;
	//WB_wJump_R,
	//WB_wJAL,
	wire [31:0] WB_pc_plus_4_wire;
	//WB_wJump,
	wire [31:0] WB_wReadData;
	//WB_Branch_Analyzer_Result_wire,
	//WB_read_data_1_wire,
	wire WB_reg_write_wire;
	wire [31:0] WB_alu_result_wire;
	
	////////////WRITE BACK///////////////////////
	wire [31:0] wRamAluMux;
	
//////////////////////////////INSTRUCTION FETCH/////////////////////////////	
	PC_Register
	ProgramCounter
	(
		.clk(clk),
		.reset(reset),
		.NewPC(pc_plus_4_wire),
		.PCValue(pc_wire)
	);
	
	ProgramMemory
	#(
		.MEMORY_DEPTH(MEMORY_DEPTH)
	)
	ROMProgramMemory
	(
		.Address(pc_wire),
		.Instruction(instruction_bus_wire)
	);
	
	Adder32bits
	PC_Puls_4
	(
		.Data0(pc_wire),
		.Data1(PC_INCREMENT),
		
		.Result(pc_plus_4_wire)
	);
//////////////////////////PIPELINE_IF_ID/////////////////////////////	
	PipelineRegister
	#(
		.N(32)
	)
	IF_ID_Pipeline(
		.clk(clk),
		.enable(1),
		.reset(reset),
		.DataInput(instruction_bus_wire),
		.DataOutput(ID_instruction_bus_wire)
	);
///////////////////////////INSTRUCTION DECODE//////////////////////////////
	Control
	ControlUnit
	(
		.OP(ID_instruction_bus_wire[31:26]),
		.FUN(ID_instruction_bus_wire[5:0]),
		.RegDst(reg_dst_wire),
		.ALUOp(aluop_wire),
		.ALUSrc(alu_src_wire),
		.RegWrite(reg_write_wire),
		.MemWrite(wMemWrite),
		.MemRead(wMemRead),
		.MemtoReg(wMemtoReg)
	);
	
	
	
	RegisterFile
	Register_File
	(
		.clk(clk),
		.reset(reset),
		.RegWrite(WB_reg_write_wire),
		.WriteRegister(WB_write_register_wire),///////////////////////////////////////////////////////////////
		.ReadRegister1(ID_instruction_bus_wire[25:21]),
		.ReadRegister2(ID_instruction_bus_wire[20:16]),
		.WriteData(wRamAluMux),
		.ReadData1(read_data_1_wire),
		.ReadData2(read_data_2_wire)

	);
	SignExtend
	SignExtendForConstants
	(   
		.DataInput(ID_instruction_bus_wire[15:0]),
		.SignExtendOutput(Inmmediate_extend_wire)
	);
///////////////////////////////////PIPELINE DECODE_EXECUTE /////////////////////////
	PipelineRegister
	#(
		.N(137)//174
	)
	ID_EX_Pipeline(
		.clk(clk),
		.enable(1),
		.reset(reset),
		.DataInput({
						wMemtoReg,
						reg_dst_wire,
						aluop_wire,
						alu_src_wire,
						reg_write_wire,
						wMemWrite,
						wMemRead,
						read_data_1_wire,
						read_data_2_wire,
						Inmmediate_extend_wire,
						ID_instruction_bus_wire
						}),
		.DataOutput({
						EX_wMemtoReg,
						EX_reg_dst_wire,
						EX_aluop_wire,
						EX_alu_src_wire,
						EX_reg_write_wire,
						EX_wMemWrite,
						EX_wMemRead,
						EX_read_data_1_wire,
						EX_read_data_2_wire,
						EX_Inmmediate_extend_wire,
						EX_instruction_bus_wire
						})
	);
////////////////////////////////////EXECUTE///////////////////////////////////////
	Multiplexer2to1
	#(
		.NBits(5)
	)
	MUX_ForRTypeAndIType
	(
		.Selector(EX_reg_dst_wire),
		.MUX_Data0(EX_instruction_bus_wire[20:16]),
		.MUX_Data1(EX_instruction_bus_wire[15:11]),
		
		.MUX_Output(write_register_wire)

	);
	
	Multiplexer2to1
	#(
		.NBits(32)
	)
	MUX_ForReadDataAndInmediate
	(
		.Selector(EX_alu_src_wire),
		.MUX_Data0(EX_read_data_2_wire),
		.MUX_Data1(EX_Inmmediate_extend_wire),
		
		.MUX_Output(read_data_2_orr_inmmediate_wire)

	);

	ALUControl
	ArithmeticLogicUnitControl
	(
		.ALUOp(EX_aluop_wire),
		.ALUFunction(EX_instruction_bus_wire[5:0]),
		.ALUOperation(alu_operation_wire)

	);

	ALU
	ArithmeticLogicUnit 
	(
		.shamt(EX_instruction_bus_wire[10:6]),
		.ALUOperation(alu_operation_wire),
		.A(EX_read_data_1_wire),
		.B(read_data_2_orr_inmmediate_wire),
		.Zero(zero_wire),
		.ALUResult(alu_result_wire)
	);
	assign ALUResultOut = alu_result_wire;
/////////////////////////////////////// PIPELINE EXECUTE_MEMORY ACCESS///////////////////
	PipelineRegister
	#(
		.N(73)//202
	)
	EX_MEM_Pipeline(
		.clk(clk),
		.enable(1),
		.reset(reset),
		.DataInput({
						write_register_wire,
						EX_read_data_2_wire,
						EX_wMemWrite,
						EX_wMemRead,
						EX_wMemtoReg,
						EX_reg_write_wire,
						alu_result_wire
						}),
		.DataOutput({
						MEM_write_register_wire,
						MEM_read_data_2_wire,
						MEM_wMemWrite,
						MEM_wMemRead,
						MEM_wMemtoReg,
						MEM_reg_write_wire,
						MEM_alu_result_wire
						})
	);
///////////////////////////////////////MEMORY ACCESS///////////////////////////////
	DataMemory
	#(	.DATA_WIDTH(32),
		.MEMORY_DEPTH(512)
	)
	RamMemory
	(
		.WriteData(MEM_read_data_2_wire),
		.Address(MEM_alu_result_wire),
		.MemWrite(MEM_wMemWrite),
		.MemRead(MEM_wMemRead),
		.clk(clk),
		.ReadData(wReadData)
	);
	
//////////////////////////////////////PIPELINE MEMORY ACCES _ WRITE BACK/////////////////
PipelineRegister
#(
	.N(71)//198
)
MEM_WB_Pipeline(
	.clk(clk),
	.enable(1),
	.reset(reset),
	.DataInput({
					MEM_write_register_wire,
					MEM_wMemtoReg,
					wReadData,
					MEM_reg_write_wire,
					MEM_alu_result_wire
					}),
	.DataOutput({
					WB_write_register_wire,
					WB_wMemtoReg,
					WB_wReadData,
					WB_reg_write_wire,
					WB_alu_result_wire
					})
);
//////////////////////////////////////WRITE BACK//////////////////////////////////
Multiplexer2to1
#(
	.NBits(32)
)
MUX_ForAluAndRamMemory
(
	.Selector(WB_wMemtoReg),
	.MUX_Data0(WB_alu_result_wire), 
	.MUX_Data1(WB_wReadData),
	.MUX_Output(wRamAluMux)
);


endmodule