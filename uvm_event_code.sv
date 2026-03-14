class my_seq_item extends uvm_sequence_item;
  rand logic [7:0] addr;
  rand logic [7:0] data;
  int unsigned pkt_id;

  constraint addr_range_cn {
    addr inside {[10:20]};
  }
  constraint data_range_cn {
    data inside {[100:200]};
  }
  `uvm_object_utils_begin(my_seq_item)
  `uvm_field_int(pkt_id, UVM_ALL_ON| UVM_DEC)
  `uvm_field_int(addr,   UVM_ALL_ON| UVM_HEX)
  `uvm_field_int(data,   UVM_ALL_ON| UVM_HEX)
  `uvm_object_utils_end

  function new(string name="my_seq_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    convert2string =
    $sformatf("pkt_id:%0d, addr=0x%0h, data=0x%0h", pkt_id, addr, data);
  endfunction : convert2string
endclass : my_seq_item

//-----------------------------------------------------------------------
// Sequencer Class
//-----------------------------------------------------------------------
typedef class my_agent;
class my_sequencer extends uvm_sequencer #(my_seq_item);
  my_agent parent;
  `uvm_component_utils (my_sequencer)

  function new (string name="my_sequencer", uvm_component parent=null);
    super.new(name, parent);
    if(!$cast(this.parent, parent)) begin
      `uvm_fatal(get_name(), $sformatf("Casting failed from"))
    end
  endfunction : new
endclass : my_sequencer