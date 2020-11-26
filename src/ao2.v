/**********************************************************
*** Description: 4输入与或门逻辑
***
**********************************************************/
module ao2(y, a, b, c, d);
    output y;
    input a, b, c, d;
    reg y, tmp1, tmp2;

    always @(a or b or c or d) begin
        tmp1 = a & b;
        tmp2 = c & d;
        y = tmp1 | tmp2;
    end
endmodule