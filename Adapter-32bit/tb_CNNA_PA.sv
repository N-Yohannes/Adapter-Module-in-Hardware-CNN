`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.10.2023 19:07:40
// Design Name: 
// Module Name: tb_CNNA_PA
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_CNNA_PA;
/*------------------------------------------------------------------------------
--  Module Parameters
------------------------------------------------------------------------------*/
//// Hardware Parameters ////
parameter int BIT_WIDTH = 32;
parameter int BW = BIT_WIDTH -1;

// Inputs
parameter int PA_IMAGE_CHANNELS = 1;  
parameter int PA_IMAGE_SIZE = 28*28; 
parameter int PA_IMAGE_LENGTH = PA_IMAGE_CHANNELS * PA_IMAGE_SIZE;  
parameter int PA_FMAP_CHANNELS = 6;  
parameter int PA_FMAP_IMAGE_SIZE = 28*28; 
parameter int PA_FMAP_LENGTH = PA_FMAP_CHANNELS * PA_FMAP_IMAGE_SIZE; 

// Kernels
parameter int PA_KERNELS = 1;
parameter int PA_KERNELS_TOTAL = 6;


// Neuron Count
parameter int PA_LENGTH = PA_KERNELS * PA_FMAP_IMAGE_SIZE; // 6x576 = 3456

// Output
parameter int PA_OUTPUT_Z_LENGTH = PA_LENGTH; // 6x576 = 3456

// Parameters
parameter int PA_WEIGHTS_LENGTH = PA_KERNELS;
parameter int PA_BIASES_LENGTH = PA_KERNELS;
parameter int PA_POOL_ERROR_LENGTH = PA_OUTPUT_Z_LENGTH;


//// Test Parameters ////
parameter int TEST_LENGTH = 4;

// FP Inputs //
parameter int TEST_PA_IMAGE_LENGTH = TEST_LENGTH * PA_IMAGE_LENGTH;
parameter int TEST_PA_FMAP_LENGTH = TEST_LENGTH * PA_FMAP_LENGTH;
parameter int TEST_PA_WEIGHTS_LENGTH = TEST_LENGTH * PA_WEIGHTS_LENGTH * PA_KERNELS_TOTAL;
parameter int TEST_PA_BIASES_LENGTH = TEST_LENGTH * PA_BIASES_LENGTH * PA_KERNELS_TOTAL;

// BP Inputs //
parameter int TEST_PA_DERIV_ACTV_LENGTH = TEST_LENGTH * PA_OUTPUT_Z_LENGTH * PA_KERNELS_TOTAL; 
parameter int TEST_PA_POOL_ERROR_LENGTH = TEST_LENGTH * PA_POOL_ERROR_LENGTH * PA_KERNELS_TOTAL; //temp0 error 576*6
parameter int TEST_PA_DELTA_ERROR_LENGTH = TEST_LENGTH * PA_LENGTH * PA_KERNELS_TOTAL;
parameter int TEST_PA_DELTA_WEIGHTS_LENGTH = TEST_PA_WEIGHTS_LENGTH;
parameter int TEST_PA_DELTA_BIASES_LENGTH = TEST_PA_BIASES_LENGTH;

/*------------------------------------------------------------------------------
--  Input / Output Control signals for Adapter
------------------------------------------------------------------------------*/

reg clk = 0;
reg rst;
logic do_fp, do_bp;

logic done_FP, done_BP;

/*------------------------------------------------------------------------------
--  I/O Data Signals for Adapter
------------------------------------------------------------------------------*/
logic [(PA_IMAGE_LENGTH -1):0]                   [BW:0]   fp_PA_image;        // 6*24*24  = 3456

logic [(PA_LENGTH -1):0]                        [BW:0]   fp_PA_fmap;        // 6*24*24  = 3456
logic [(PA_WEIGHTS_LENGTH -1):0]                [BW:0]   fp_PA_weights;     // Kernels * FMAP channels = 6*6 = 36
logic [(PA_BIASES_LENGTH -1):0]                 [BW:0]   fp_PA_biases;      // 1 per kernel = 6 

logic [(PA_OUTPUT_Z_LENGTH -1):0]               [BW:0]   bp_PA_pool_error;  // 6*24*24 (error from actv(conv+adapt) layer)

logic [(PA_OUTPUT_Z_LENGTH -1):0]               [BW:0]   fp_PA_output_z;    // 6*24*24  = 3456

logic [(PA_OUTPUT_Z_LENGTH -1):0]               [BW:0]   bp_PA_deriv_actv;  // 6*24*24  = 3456
logic [(PA_LENGTH -1):0]                        [BW:0]   bp_PA_delta_error; // 6*24*24  = 3456 (error propogated backwards from adapter layer)
logic [(PA_WEIGHTS_LENGTH -1):0]                [BW:0]   bp_PA_delta_weights; // Kernels * FMAP channels = 6*6 = 36
logic [(PA_BIASES_LENGTH -1):0]                 [BW:0]   bp_PA_delta_biases;  // 1 per kernel = 6  

/*------------------------------------------------------------------------------
--  Memory Signals (ONLY INPUTS WE NEED i.e NOT COMPARING)
------------------------------------------------------------------------------*/

logic [BW:0] mem_fp_PA_image          [(TEST_PA_IMAGE_LENGTH -1):0]; 

logic [BW:0] mem_fp_PA_fmap          [(TEST_PA_FMAP_LENGTH -1):0]; 

logic [BW:0] mem_fp_PA_weights       [(TEST_PA_WEIGHTS_LENGTH -1):0]; 
logic [BW:0] mem_fp_PA_biases        [(TEST_PA_BIASES_LENGTH -1):0]; 

logic [BW:0] mem_bp_PA_pool_error    [(TEST_PA_POOL_ERROR_LENGTH -1):0]; 


/*------------------------------------------------------------------------------
--  Data signals for testbench
------------------------------------------------------------------------------*/
logic               start;
logic [3:0]         test_counter;
logic [3:0]         channel; 
logic               finished;


/*------------------------------------------------------------------------------
--  I/O Data Signals for RAM
------------------------------------------------------------------------------*/

integer i = 0;
integer j = 0;
shortreal real_number1;
integer fd_fp_PA_adapter_z;
integer fd_fp_PA_adapter_z_bychan;
integer fd_bp_PA_deriv_actv;
integer fd_bp_PA_delta_error;
integer fd_bp_PA_delta_weights;
integer fd_bp_PA_delta_biases;
logic new_input_en;
logic write_to_file;


/*------------------------------------------------------------------------------
--  Generate modules
------------------------------------------------------------------------------*/

PA_topmodule top_module_PA (
    .clk(clk), // Control //
    .rst(rst),
    .do_fp(do_fp),
    .do_bp(do_bp),
    .done_FP(done_FP),
    .done_BP(done_BP),

    .image_IN(fp_PA_image),
    .fp_fmap(fp_PA_fmap), // FP //
    .weights_PA(fp_PA_weights),
    .biases_PA(fp_PA_biases),

    .adapter_z(fp_PA_output_z),

    .error_IN(bp_PA_pool_error), // BP //

    .acc_deriv_PA(bp_PA_deriv_actv),
    .error_OUT_PA(bp_PA_delta_error),
    .bpWchange_PA(bp_PA_delta_weights),
    .bpBchange_PA(bp_PA_delta_biases)
);

integer fd_fp_PA_biases;

/*------------------------------------------------------------------------------
--  Start Simulation
------------------------------------------------------------------------------*/

// Clock generation
initial begin
    forever #5 clk <= ~clk;
end

// Reset generation
initial begin

    /*------------------------------------------------------------------------------
    --  Read from memory into RAM (ONLY INPUTS WE NEED i.e NOT COMPARING)
    ------------------------------------------------------------------------------*/
    // FP //
    $readmemh("mnist_hex.mem", mem_fp_PA_image);
    $readmemh("pa.conv1.fmap_hex.mem", mem_fp_PA_fmap);
    $readmemh("pa.weights_hex.mem", mem_fp_PA_weights);
    $readmemh("pa.biases_hex.mem", mem_fp_PA_biases);

    // BP //
    $readmemh("pa.maxpool_error_hex.mem", mem_bp_PA_pool_error); //How maxpool is read in affects how to calculate bp_PA_delta_error//

    /*------------------------------------------------------------------------------
    --  Prepare write to file 
    ------------------------------------------------------------------------------*/
    fd_fp_PA_biases = $fopen("test_write.txt", "w");
    $display("fd_fp_PA_biases: %d ", fd_fp_PA_biases);
    $fwrite(fd_fp_PA_biases,"%s","File cleared\n");
    $fclose(fd_fp_PA_biases);   
    fd_fp_PA_biases = $fopen("test_write.txt", "a");
    $fwrite(fd_fp_PA_biases,"%s","Test write begins\n");
    $fwrite(fd_fp_PA_biases,"%s","Test write DONE\n");
    $fclose(fd_fp_PA_biases);
    
    fd_fp_PA_adapter_z_bychan = $fopen("adapter_z_bychan_pa.txt", "w");
    $display("fd_fp_PA_adapter_z_bychan: %d ", fd_fp_PA_adapter_z_bychan);
    $fwrite(fd_fp_PA_adapter_z_bychan,"%s","File cleared\n");
    $fclose(fd_fp_PA_adapter_z_bychan);  
    
    fd_fp_PA_adapter_z = $fopen("adapter_z_pa.txt", "w");
    $display("fd_fp_PA_adapter_z: %d ", fd_fp_PA_adapter_z);
    $fwrite(fd_fp_PA_adapter_z,"%s","File cleared\n");
    $fclose(fd_fp_PA_adapter_z);  
    
    fd_bp_PA_deriv_actv = $fopen("deriv_actv_pa.txt", "w");
    $display("fd_bp_PA_deriv_actv: %d ", fd_bp_PA_deriv_actv);
    $fwrite(fd_bp_PA_deriv_actv,"%s","File cleared\n");
    $fclose(fd_bp_PA_deriv_actv);  

    fd_bp_PA_delta_error = $fopen("delta_error_pa.txt", "w");
    $display("fd_bp_PA_delta_error: %d ", fd_bp_PA_delta_error);
    $fwrite(fd_bp_PA_delta_error,"%s","File cleared\n");
    $fclose(fd_bp_PA_delta_error);

    fd_bp_PA_delta_weights = $fopen("delta_weights_pa.txt", "w");
    $display("fd_bp_PA_delta_weights: %d ", fd_bp_PA_delta_weights);
    $fwrite(fd_bp_PA_delta_weights,"%s","File cleared\n");
    $fclose(fd_bp_PA_delta_weights);

    fd_bp_PA_delta_biases = $fopen("delta_biases_pa.txt", "w");
    $display("fd_bp_PA_delta_biases: %d ", fd_bp_PA_delta_biases);
    $fwrite(fd_bp_PA_delta_biases,"%s","File cleared\n");
    $fclose(fd_bp_PA_delta_biases);


    /*------------------------------------------------------------------------------
    --  Start Processing
    ------------------------------------------------------------------------------*/
    rst <= 1;
    start <= 0;

    repeat (2) @ (posedge clk);

    repeat (1) @ (posedge clk) begin
        rst <= 0;
    end

    repeat (2) @ (posedge clk);

    repeat (1) @ (posedge clk) begin
        start <= 1;
    end 

end

/*------------------------------------------------------------------------------
    --  Control Signal
------------------------------------------------------------------------------*/
enum logic [2:0] {idle, read_data, fp_bp, write, new_data, finish} cs, ns;

always_ff @(posedge clk, posedge rst)
    if (rst) cs <= idle;
    else cs <= ns;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        finished <= 0;
        test_counter <= 0;
        channel <= 0;
    end
    else begin
        case(cs)
            write: begin
                //test_counter <= test_counter + 1;
                channel <= channel + 1;
                test_counter <= (channel < PA_KERNELS_TOTAL - 1) ? test_counter : test_counter + 1;

            end
            new_data: begin
                //test_counter <= test_counter + 1;
                channel <= 0;
            end
       endcase
    end
end

// Next state and output logic
always_comb begin
    do_fp = 0;
    do_bp = 0;
    new_input_en = 0;
    write_to_file = 0;
    case (cs) 
        idle: begin
            ns = start ? read_data : idle;
        end
        read_data: begin
            new_input_en = 1;
            ns = fp_bp;
        end
        fp_bp: begin
            do_fp = 1;
            do_bp = 1;
            ns = done_BP ? write : fp_bp;
        end
        write: begin
            //test_counter = test_counter + 1;
            write_to_file = 1;
            ns = (channel < PA_KERNELS_TOTAL - 1) ? read_data : new_data;
        end
        new_data: begin
            ns = (test_counter < TEST_LENGTH) ? idle : finish;
        end
        finish: begin
            finished = 1;
            $finish;
        end
    endcase
end 

/*------------------------------------------------------------------------------
    --  Write to file
------------------------------------------------------------------------------*/
always @(posedge clk) begin //write_to_file

    if (write_to_file == 1) begin

        // Print adapter z by channel logic
        fd_fp_PA_adapter_z_bychan = $fopen("adapter_z_bychan_pa.txt", "a");
        for (i=0; i<PA_FMAP_IMAGE_SIZE; i = i+1) begin // 576

            real_number1 = $bitstoshortreal(fp_PA_output_z[i]); //[0...3455]
            $fwrite(fd_fp_PA_adapter_z_bychan,"%f\n",real_number1);
    
        end
        //$fwrite(fd_fp_PA_adapter_z_bychan,"%s","Test write DONE\n");
        $fclose(fd_fp_PA_adapter_z_bychan);  

        // Print adapter z logic
        fd_fp_PA_adapter_z = $fopen("adapter_z_pa.txt", "a");
        for (j=0; j<PA_FMAP_IMAGE_SIZE; j = j+1) begin //576

            real_number1 = $bitstoshortreal(fp_PA_output_z[j]); //[0...3455]
            $fwrite(fd_fp_PA_adapter_z,"%f\n",real_number1);

        end        
        //$fwrite(fd_fp_PA_adapter_z,"%s","Test write DONE\n");
        $fclose(fd_fp_PA_adapter_z); 

        // Print deriv_actv
        fd_bp_PA_deriv_actv = $fopen("deriv_actv_pa.txt", "a");
        for (j=0; j<PA_FMAP_IMAGE_SIZE; j = j+1) begin //576

            real_number1 = $bitstoshortreal(bp_PA_deriv_actv[j]); //[0...3455]
            $fwrite(fd_bp_PA_deriv_actv,"%f\n",real_number1);

        end        
        //$fwrite(fd_bp_PA_deriv_actv,"%s","Test write DONE\n");
        $fclose(fd_bp_PA_deriv_actv); 

        // Print delta_error
        fd_bp_PA_delta_error = $fopen("delta_error_pa.txt", "a");
        for (j=0; j<PA_FMAP_IMAGE_SIZE; j = j+1) begin //576

            real_number1 = $bitstoshortreal(bp_PA_delta_error[j]); //[0...3455]
            $fwrite(fd_bp_PA_delta_error,"%f\n",real_number1);

        end        
        //$fwrite(fd_bp_PA_delta_error,"%s","Test write DONE\n");
        $fclose(fd_bp_PA_delta_error); 

        // Print delta_weights
        fd_bp_PA_delta_weights = $fopen("delta_weights_pa.txt", "a");
        for (i=0; i<PA_KERNELS; i = i+1) begin // 6

            real_number1 = $bitstoshortreal(bp_PA_delta_weights[i]); //[0...36]
            $fwrite(fd_bp_PA_delta_weights,"%f\n",real_number1);

        end
        //$fwrite(fd_bp_PA_delta_weights,"%s","Test write DONE\n");
        $fclose(fd_bp_PA_delta_weights); 

        // Print delta_biases
        fd_bp_PA_delta_biases = $fopen("delta_biases_pa.txt", "a");

            real_number1 = $bitstoshortreal(bp_PA_delta_biases); //[0...6]
            $fwrite(fd_bp_PA_delta_biases,"%f\n",real_number1);
       
        //$fwrite(fd_bp_PA_delta_biases,"%s","Test write DONE\n");
        $fclose(fd_bp_PA_delta_biases); 
        
        $display("test_counter_updated: %d test_channel_updated %d", test_counter, channel);

    end
end

/*------------------------------------------------------------------------------
    --  Read in new input Signal
------------------------------------------------------------------------------*/
always @(new_input_en) begin

    if (new_input_en == 1) begin

        // Load Image
        for (i=0; i<PA_IMAGE_LENGTH; i = i+1) begin
        fp_PA_image[i] = mem_fp_PA_image[test_counter*PA_IMAGE_LENGTH + i];
        end

        // Load FMAPs
        for (i=0; i<PA_FMAP_LENGTH; i = i+1) begin
        fp_PA_fmap[i] = mem_fp_PA_fmap[test_counter*PA_POOL_ERROR_LENGTH*PA_KERNELS_TOTAL + channel*784 + i];
        end

        // Load Weights
        for (i=0; i<PA_WEIGHTS_LENGTH; i = i+1) begin
        fp_PA_weights[i] = mem_fp_PA_weights[test_counter*PA_WEIGHTS_LENGTH*PA_KERNELS_TOTAL + channel + i];
        end

        // Load Biases
        for (i=0; i<PA_BIASES_LENGTH; i = i+1) begin
        fp_PA_biases[i] = mem_fp_PA_biases[test_counter*PA_BIASES_LENGTH*PA_KERNELS_TOTAL + channel + i];
        end

        //Load pool error
        for (i=0; i<PA_POOL_ERROR_LENGTH; i = i+1) begin
          bp_PA_pool_error[i] = mem_bp_PA_pool_error[test_counter*PA_POOL_ERROR_LENGTH*PA_KERNELS_TOTAL + channel*784 + i];
        end

    end
end

endmodule
