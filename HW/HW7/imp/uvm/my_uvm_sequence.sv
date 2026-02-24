
`ifndef MY_UVM_SEQUENCE_SV
`define MY_UVM_SEQUENCE_SV

class my_uvm_sequence extends uvm_sequence#(my_uvm_transaction);
    `uvm_object_utils(my_uvm_sequence)

    function new(string name = "my_uvm_sequence");
        super.new(name);
    endfunction

    virtual task body();
        int fd_r, fd_i;
        int val_r, val_i;
        int status_r, status_i;

        req = my_uvm_transaction::type_id::create("req");
        
        fd_r = $fopen(REF_REAL_IN, "r");
        fd_i = $fopen(REF_IMAG_IN, "r");

        if (fd_r == 0 || fd_i == 0) begin
            `uvm_fatal("SEQ", "Could not open input reference files")
        end

        `uvm_info("SEQ", "Starting sequence - reading samples", UVM_LOW)

        // Read all samples and put into a single transaction (or multiple if N is large)
        // Here we'll do one N-point block
        start_item(req);
        req.real_payload = new[FFT_N];
        req.imag_payload = new[FFT_N];

        for (int i = 0; i < FFT_N; i++) begin
            status_r = $fscanf(fd_r, "%h\n", val_r);
            status_i = $fscanf(fd_i, "%h\n", val_i);
            req.real_payload[i] = val_r;
            req.imag_payload[i] = val_i;
        end
        finish_item(req);

        $fclose(fd_r);
        $fclose(fd_i);
    endtask

endclass

`endif
