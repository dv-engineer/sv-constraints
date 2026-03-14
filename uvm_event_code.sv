`include "uvm_macros.svh"
import uvm_pkg::*;

//-----------------------------------------------------------------------------
// Interface
//-----------------------------------------------------------------------------
interface my_interface(input logic clk);
  bit valid;
  logic [7 : 0] addr;
  reg           data_reg;
  wire          data;

  assign data = data_reg;
endinterface : my_interface
typedef virtual my_interface my_vif;



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

//-----------------------------------------------------------------------
// Driver Class
//-----------------------------------------------------------------------
class my_driver extends uvm_driver #(my_seq_item);
  my_agent parent;
  uvm_event PKT_TX_CMPLT_EV;
  uvm_event_pool my_event_pool;
  `uvm_component_utils (my_driver)

  function new (string name="my_driver", uvm_component parent=null);
    super.new(name, parent);
    if(!$cast(this.parent, parent)) begin
      `uvm_fatal(get_name(), $sformatf("Casting failed from"))
    end
  endfunction : new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    my_event_pool = uvm_event_pool::get_global_pool();
    // Returns the item with the given key.
    // If no item exists by that key, a new item is created with that key and returned.
    if (!$cast(PKT_TX_CMPLT_EV, my_event_pool.get($sformatf("DRV_EVENT")))) begin
    // OR, you can directly use add method
    // PKT_TX_CMPLT_EV = my_event_pool.add($sformatf("DRV_EVENT"));
      `uvm_fatal(get_name(), $sformatf("casting failed from uvm_object to uvm_event"))
    end
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_name(),
      $sformatf("After get_next_item, my_seq_item : %s", req.convert2string()), UVM_LOW)
      // Item done is non-blocking
      seq_item_port.item_done();
      for (int unsigned i=0; i<8; i ++) begin
        @(posedge parent.vif.clk);
        if (i == 0) begin
          parent.vif.valid     <= 1'b1;
          parent.vif.addr[7:0] <= req.addr[7:0];
        end
        parent.vif.data_reg <= req.data[i];
      end
      @(posedge parent.vif.clk);
      parent.vif.valid <= 1'b0;
      PKT_TX_CMPLT_EV.trigger(req);
    end
  endtask : run_phase
endclass : my_driver

//-----------------------------------------------------------------------
// Agent Class
//-----------------------------------------------------------------------
class my_agent extends uvm_agent;
  my_sequencer sqr;
  my_driver    drv;
  my_vif       vif;
  `uvm_component_utils_begin (my_agent)
    `uvm_field_object(sqr, UVM_DEFAULT)
    `uvm_field_object(drv, UVM_DEFAULT)
  `uvm_component_utils_end
  
  function new (string name="my_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(my_vif) :: get(this, "", $sformatf("vif"), this.vif)) begin
      `uvm_fatal(get_name(), $sformatf("Failed to get virtual interface"))
    end
    sqr = my_sequencer :: type_id :: create("sqr", this);
    drv = my_driver    :: type_id :: create("drv", this);
  endfunction : build_phase

  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction : connect_phase
endclass : my_agent

//-----------------------------------------------------------------------
// UVM event callback class
//-----------------------------------------------------------------------
class my_event_callback extends uvm_event_callback;
  `uvm_object_utils(my_event_callback)
  function new(string name="my_event_callback");
    super.new(name);
  endfunction : new

  // Called just before triggering the associated event.
  // If this function returns 1, then the event will not trigger
  // and the post-trigger callback is not called. 
  // This provides a way for a callback to prevent the event from triggering.
  // e    - is the uvm_event#(T=uvm_object) that is being triggered.
  // data - is the optional data associated with the event trigger.
  virtual function bit pre_trigger (uvm_event e, uvm_object data);
    my_seq_item obj;
    if(!$cast(obj, data)) begin
      `uvm_fatal(get_name(), $sformatf("Casting failed"))
    end
    else begin
      if(obj.pkt_id == 3) begin
        `uvm_info(get_name(),
        $sformatf("pre_trigger: discarding packet from event:%s, pkt:%s",
        e.get_name(), obj.convert2string()), UVM_LOW)
        return 1;
      end
      else begin
        `uvm_info(get_name(),
        $sformatf("pre_trigger: pkt:%s", obj.convert2string()), UVM_LOW)
        return 0;
      end
    end
  endfunction : pre_trigger

  // Called after triggering the associated event.
  // e    - is the uvm_event#(T=uvm_object) that is being triggered.
  // data - is the optional data associated with the event trigger.
  virtual function void post_trigger (uvm_event e, uvm_object data);
    my_seq_item obj;
    if(!$cast(obj, data)) begin
      `uvm_fatal(get_name(), $sformatf("Casting failed"))
    end
    else begin
        `uvm_info(get_name(),
        $sformatf("post_trigger: pkt:%s", obj.convert2string()), UVM_LOW)
    end
  endfunction : post_trigger

endclass : my_event_callback

//-----------------------------------------------------------------------
// Sequence Class
//-----------------------------------------------------------------------
class my_seq extends uvm_sequence #(my_seq_item);
  uvm_event      my_event;
  int unsigned   pkt_id;
  my_event_callback my_event_cb;

  `uvm_object_utils (my_seq)
  `uvm_declare_p_sequencer(my_sequencer)
  function new(string name="my_seq");
    super.new(name);
  endfunction : new

  task get_event(input string event_key,
                 output uvm_event e);
    uvm_event_pool my_event_pool;
    my_event_pool = uvm_event_pool::get_global_pool();
    e = my_event_pool.get(event_key);
  endtask : get_event

  task get_event_data(ref uvm_event e, ref my_seq_item my_item);
    uvm_object item;

    // This method calls wait_ptrigger followed by get_trigger_data (Recommanded)
    `uvm_info(get_name(), $sformatf("before wait_ptrigger_data"), UVM_LOW)
    e.wait_ptrigger_data(item);
    `uvm_info(get_name(), $sformatf("after wait_ptrigger_data"), UVM_LOW)

    if (item == null) begin
      `uvm_error(get_name(),
      $sformatf("Got NULL item from event"))
    end
    else begin
      if ($cast(my_item, item)) begin
        `uvm_info(get_name(),
        $sformatf("Got the item from event %s", my_item.convert2string()), UVM_LOW)
      end
      else begin
        `uvm_error(get_name(),
        $sformatf("Casting failed from %s to %s", item.get_type_name(), my_item.get_type_name()))
      end
    end
  endtask : get_event_data

  task send_tr(input int unsigned pkt_id = 0);
    my_seq_item req;
    `uvm_create_on(req, p_sequencer)
    if(!req.randomize()) begin
      `uvm_fatal(get_name(), $sformatf("Randomization failed"))
    end
    req.pkt_id = pkt_id;
    `uvm_info (get_name(),
    $sformatf("After randomizating, my_seq_item : %s",
    req.convert2string()), UVM_LOW)
    // Sequence will comout from `uvm_send as item_done in driver is non blocking
    `uvm_send(req)
  endtask : send_tr

  task body ();
    my_seq_item my_data;

    pkt_id ++;
    send_tr(pkt_id);
    get_event("DRV_EVENT", my_event);
    get_event_data(my_event, my_data);
    // do manipulation on my_data
    my_data = null;

    my_event_cb = my_event_callback :: type_id :: create ("my_event_cb");
    my_event.add_callback(my_event_cb);
    `uvm_info(get_name(),
    $sformatf("%s event_callback is added for %s event",
    my_event_cb.get_name(), my_event.get_name()), UVM_LOW)

    #200;
    pkt_id ++;
    send_tr(pkt_id);
    get_event("DRV_EVENT", my_event);
    get_event_data(my_event, my_data);
    // do manipulation on my_data
    my_data = null;

    #200;
    pkt_id ++;
    send_tr(pkt_id);
    begin
      fork
        begin
          get_event("DRV_EVENT", my_event);
          get_event_data(my_event, my_data);
          my_data = null;
        end
        begin
          repeat (50) begin
            @(posedge p_sequencer.parent.vif.clk);
          end
          `uvm_info(get_name(), $sformatf("event is not triggered"), UVM_LOW)
        end
      join_any
      disable fork;
    end

    my_event.delete_callback(my_event_cb);
    `uvm_info(get_name(),
    $sformatf("%s event_callback is deleted for %s event",
    my_event_cb.get_name(), my_event.get_name()), UVM_LOW)

    #200;
    pkt_id ++;
    send_tr(pkt_id);
    get_event("DRV_EVENT", my_event);
    get_event_data(my_event, my_data);
    
  endtask : body
endclass : my_seq


//-----------------------------------------------------------------------
// Test Class
//-----------------------------------------------------------------------
class my_test extends uvm_test;
  my_agent agent;
  my_vif vif;
  `uvm_component_utils_begin (my_test)
    `uvm_field_object(agent, UVM_DEFAULT)
  `uvm_component_utils_end

  function new (string name="my_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(my_vif) :: get(this, "", $sformatf("vif"), this.vif)) begin
      `uvm_fatal(get_name(), $sformatf("Failed to get virtual interface"))
    end
    agent = my_agent::type_id::create("agent", this);
    uvm_config_db#(my_vif) :: set(this, "agent", $sformatf("vif"), this.vif);
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    my_seq seq;
    phase.raise_objection(this);
    seq = my_seq::type_id::create ("seq");
    //seq.set_starting_phase(phase);
    #150;
    seq.start(agent.sqr);
    #150;
    phase.drop_objection(this);
  endtask : run_phase
endclass : my_test

// Top module
module top();
  bit clk;

  my_interface intf(clk);

  initial begin
    uvm_config_db#(my_vif) :: set(uvm_root::get(), "uvm_test_top", "vif", intf);
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    run_test("my_test");
  end
endmodule : top