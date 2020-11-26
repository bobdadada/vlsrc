/**********************************************************
*** Description: 使用非阻塞赋值编写D触发器
***
**********************************************************/
module dffx(q, d, clk, rst);
    output q;
    input d, clk, rst;
    reg q;

    always @(posedge clk)  // 时钟上升沿触发
        if (rst) q <= 1'b0;
        else q <= d;
endmodule