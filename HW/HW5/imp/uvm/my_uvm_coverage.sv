
`ifndef MY_UVM_COVERAGE_SV
`define MY_UVM_COVERAGE_SV

class my_uvm_coverage extends uvm_subscriber #(my_uvm_transaction);
    `uvm_component_utils(my_uvm_coverage)

    // Covergroup
    covergroup cg_packet;
        // Cover payload length
        cp_length: coverpoint tr_t.payload.size() {
            bins len_normal = {[0:1023]};
            bins len_jumbo  = {[1024:$]};
        }
    endgroup

    my_uvm_transaction tr_t;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_packet = new();
    endfunction

    virtual function void write(my_uvm_transaction t);
        tr_t = t;
        cg_packet.sample();
        `uvm_info("COV", $sformatf("Sampled packet len=%0d", t.payload.size()), UVM_HIGH)
    endfunction

endclass

`endif
