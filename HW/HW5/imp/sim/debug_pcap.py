import struct
import sys

filename = "../ref/test.pcap"

try:
    with open(filename, "rb") as f:
        # Global Header
        global_header = f.read(24)
        if len(global_header) != 24:
            print(f"Error reading global header. Read {len(global_header)} bytes.")
            sys.exit(1)
        
        # Check Magic Number (first 4 bytes)
        magic = struct.unpack("I", global_header[0:4])[0]
        print(f"Global Header Magic: 0x{magic:08x}")
        # Standard PCAP magic is 0xa1b2c3d4 (microsecond resolution) or 0xa1b23c4d (nanosecond)
        # If byte-swapped: 0xd4c3b2a1
        
        packet_count = 0
        while True:
            # Packet Header
            packet_header = f.read(16)
            if len(packet_header) == 0:
                print("End of file reached normally.")
                break
            if len(packet_header) != 16:
                print(f"Error: Incomplete packet header. Read {len(packet_header)} bytes.")
                sys.exit(1)
            
            # Extract included length (bytes 8-11 -> index 8,9,10,11)
            # Assuming Little Endian format in file as UVM code does
            incl_len_le = struct.unpack("<I", packet_header[8:12])[0]
            incl_len_be = struct.unpack(">I", packet_header[8:12])[0]
            
            print(f"Packet {packet_count}: incl_len (LE) = {incl_len_le}, incl_len (BE) = {incl_len_be}")
            
            # Read payload
            # Code uses LE
            payload_len = incl_len_le
            payload = f.read(payload_len)
            
            if len(payload) != payload_len:
                print(f"Error reading packet data. Expected {payload_len}, got {len(payload)}")
                sys.exit(1)
                
            packet_count += 1
            print(f"  Read {len(payload)} bytes payload successfully.")
            
            # Print first few bytes for debug (Eth+IP+UDP header)
            if payload_len >= 42:
                eth_type = struct.unpack(">H", payload[12:14])[0]
                ip_proto = payload[23] # IP Byte 9 is Protocol. But offset is 14+9 = 23.
                print(f"  EthType: 0x{eth_type:04x}, IP Proto: 0x{ip_proto:02x}")

except Exception as e:
    print(f"Exception: {e}")
