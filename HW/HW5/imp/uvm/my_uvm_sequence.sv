
`ifndef MY_UVM_SEQUENCE_SV
`define MY_UVM_SEQUENCE_SV

class my_uvm_sequence extends uvm_sequence#(my_uvm_transaction);
    `uvm_object_utils(my_uvm_sequence)

    function new(string name = "my_uvm_sequence");
        super.new(name);
    endfunction

    virtual task body;
        int fd;
        int code;
        logic [7:0] global_header[24];
        logic [7:0] packet_header[16];
        logic [31:0] incl_len; // Number of bytes of packet data
        my_uvm_transaction tr;

        // Open the PCAP file
        // Note: Run simulation from 'sim' directory, so path is set in globals
        fd = $fopen(PCAP_INPUT_NAME, "rb");
        if (fd == 0) begin
            `uvm_fatal("SEQ", $sformatf("Could not open %s", PCAP_INPUT_NAME))
        end

        // Read and skip Global Header (24 bytes)
        code = $fread(global_header, fd);
        if (code != 24) begin
            `uvm_fatal("SEQ", "Error reading PCAP global header")
        end

        forever begin
            // Read Packet Header (16 bytes)
            code = $fread(packet_header, fd);
            if (code == 0) break; // EOF
            if (code != 16) begin
                `uvm_warning("SEQ", "Incomplete packet header at end of file")
                break;
            end

            // Extract incl_len (Bytes 8-11). Assuming Little Endian PCAP.
            incl_len = {packet_header[11], packet_header[10], packet_header[9], packet_header[8]};
            
            // Create Transaction
            tr = my_uvm_transaction::type_id::create("tr");
            tr.payload = new[incl_len];
            
            // Read Packet Data
            code = $fread(tr.payload, fd, 0, incl_len);
            if (code != incl_len) begin
                `uvm_fatal("SEQ", $sformatf("Error reading packet data. Expected %0d, got %0d", incl_len, code))
            end

            start_item(tr);
            finish_item(tr);
        end

        $fclose(fd);
    endtask

endclass

`endif
