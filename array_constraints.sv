class RandomArray2D;
    rand bit [7:0] array_2d [][];

    constraint row_constraint {
        array_rd.size() == 10;
        foreach(array_2d[i][j]){
            array_rd[i].size() == 10;
            if(i == j){
                array_2d[i][j] == 8'hFF;
            }
            else if(i+j == 9){
                array_2d[i][j] == 8'hFF;
            } else {
                array_2d[i][j] != 8'hFF;
            }
        }
    }

endclass