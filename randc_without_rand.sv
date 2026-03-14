class packet;
  rand bit [2:0] data;
  static bit used[8];
    
  constraint data_c {
    data inside {[0:7]};
    !used[data];    
  }
    
  function void post_randomize();  
    used[data] = 1;    
    if (used.sum() == 8) begin     
      used = '{default:0};      
    end  
  endfunction  
endclass  

module test();
  packet pkt = new();
  
  initial begin
    repeat(8) begin    
      pkt.randomize();
      $display("Data = %0d Used %p",pkt.data,pkt.used);
    end    
  end
endmodule
