/*Input: nums = [1,2,3,4,5,6,7], k = 3
Output: [5,6,7,1,2,3,4]
Explanation:
rotate 1 steps to the right: [7,1,2,3,4,5,6]
rotate 2 steps to the right: [6,7,1,2,3,4,5]
rotate 3 steps to the right: [5,6,7,1,2,3,4]*/

class rotate;
  int array [$];
  int r_count;
  
  function new(int count);
    array = {1,2,3,4,5,6,7};
    r_count = count;
  endfunction
  
  function rotate();
    for(int i = 0 ; i< r_count ; i++)begin
      array.push_front(array.pop_back);
    end
  endfunction
  
endclass

module test();
  rotate rotate_c = new(3);
  
  initial begin
  	$display("Array %p",rotate_c.array);
    rotate_c.rotate();
    $display("Array %p",rotate_c.array);
  end
endmodule
