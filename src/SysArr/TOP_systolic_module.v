module TOP_systolic_module #(
    parameter WEIGHT_BW = 8,
    parameter DATA_BW = 8,
    parameter PARTIAL_SUM_BW = 19,
    parameter MATRIX_SIZE = 8,
    parameter NUM_PE_ROWS = 8
) (
    input wire clk,
    input wire rstn,
    input wire we_rl,
    input wire signed [MATRIX_SIZE*DATA_BW-1:0] DIN,
    input wire signed [NUM_PE_ROWS*MATRIX_SIZE*WEIGHT_BW-1:0] WEIGHTS,
    output wire signed [(NUM_PE_ROWS*PARTIAL_SUM_BW)-1:0] result
);

    // 각 행 간 데이터를 전달할 신호를 `df_wire`로 선언
    wire signed [MATRIX_SIZE*DATA_BW-1:0] df_wire [0:NUM_PE_ROWS];

    // 첫 번째 PE의 입력에 `DIN`을 직접 연결
    assign df_wire[0] = DIN;

    genvar i;
    generate
        for (i = 0; i < NUM_PE_ROWS; i = i + 1) begin : pe_row

            wire [MATRIX_SIZE*WEIGHT_BW-1 : 0] selected_weights = {                 // wanted to make it with only parameters, but it takes inreadable
                WEIGHTS[(64 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(56 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(48 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(40 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(32 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(24 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(16 - i) * WEIGHT_BW-1 -: WEIGHT_BW],
                WEIGHTS[(8 - i) * WEIGHT_BW-1 -: WEIGHT_BW]
            };
            
            PE_hori #(
                .WEIGHT_BW(WEIGHT_BW),
                .DATA_BW(DATA_BW),
                .PARTIAL_SUM_BW(PARTIAL_SUM_BW),
                .MATRIX_SIZE(MATRIX_SIZE)
            ) pe_hori_inst (
                .clk(clk),
                .rstn(rstn),
                .we_rl(we_rl),
                .DIN(df_wire[i]),  // current dataflow
                .WEIGHTS(selected_weights),        // weight mapping
                .DF(df_wire[i+1]),  // next pe dataflow (latency 1cycle)
                .result(result[(i+1)*PARTIAL_SUM_BW-1 -: PARTIAL_SUM_BW])
            );
        end
    endgenerate

endmodule
