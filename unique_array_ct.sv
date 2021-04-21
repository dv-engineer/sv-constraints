class array_ct;
  
  rand logic [15:0] my_arr[10];
  
  constraint array_ct {
    unique (my_arr);
  }
  
  function new();
  endfunction
  
endclass
