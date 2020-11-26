/**********************************************************
*** Description: 吧输入的4位并行数据转换为协议要求的串行数据流，
***   并由scl和sda配合输出。
***     通信协议：scl为不断输出的时钟信号，如果scl为高电平时，
***     sda由高变低时刻，串行数据流开始；如果scl为高电平，sda
***     由低变高，串行数据结束。sda信号的串行数据位必须在scl为
***     低电平时变化，若变高则为1，否则为0。
***
**********************************************************/
module ptosda(d_ena,scl,sda,data,sclk,rst_n);
    output d_ena;       // 请求新的转换数据
    output scl;
    inout sda;          // 双向的串行总线
    input [3:0]data;    // 并行口数据输入
    input sclk, rst_n;    // 输入的时钟信号的复位信号
    reg scl, link_sda, d_ena, sdabuf;
    reg [3:0] databuf;
    reg [7:0] state;

    assign sda = link_sda?sdabuf: 1'bz;     // link_sda控制sdabuf输出到串行总线上

    parameter   ready = 8'b0000_0000,
                start = 8'b0000_0001,
                bit1  = 8'b0000_0010,
                bit2  = 8'b0000_0100,
                bit3  = 8'b0000_1000,
                bit4  = 8'b0001_0000,
                bit5  = 8'b0010_0000,
                stop  = 8'b0100_0000,
                IDLE  = 8'b1000_0000;
    
    always @(posedge sclk or negedge rst_n) // 由输入的sclk时钟信号产生串行输出时钟scl
        begin
            if (!rst_n)
                scl <= 1;
            else
                scl <= ~scl;
        end

    always @(posedge d_ena)             // 请求新数据时存入并行总线上要转换的数据
        databuf <= data;
    
    //----------主状态机：产生控制信号，根据databuf中保存的数据，按照协议产生sda串行信号
    always @(negedge sclk or negedge rst_n)
        if (!rst_n)
            begin
                link_sda <= 0;
                state <= ready;
                sdabuf <= 1;
            end
        else
            begin
                case(state)
                    ready:
                        if (d_ena)          // 并行数据已经到达
                            begin
                               link_sda <= 1;       // 把sdabuf与sda串行总线连接
                               state <= start;
                            end
                        else                // 并行数据尚未到达
                            begin
                               link_sda <= 0;       // 把sda总线让出，此时sda可作为输入
                               state <= ready;
                               d_ena <= 1;
                            end
                    start:
                        if (scl && d_ena)   // 产生sda的开始信号
                            begin
                               sdabuf <= 0;     // 在sda连接的前提上，输出开始信号
                               state <= bit1; 
                            end
                    bit1:
                        if (!scl)   // 在scl为低电平时，送出高电位databuf[3]
                            begin
                                sdabuf <= databuf[3]
                                state <= bit2;
                                d_ena <= 0;
                            end
                        else
                            state <= bit1;
                    bit2:
                        if (!scl)   // 在scl为低电平时，送出次高位databuf[2]
                            begin
                                sdabuf <= databuf[2];
                                state <= bit3;
                            end
                        else
                            state <= bit2;
                    bit3:
                        if (!scl)   // 在scl为低电平时，送出次高位databuf[1]
                            begin
                               sdabuf <= databuf[1];
                               state <= bit4;
                            end
                        else
                            state <= bit3;
                    bit4:
                        if (!scl)   // 在scl为低电平时，送出次高位databuf[0]
                            begin
                               sdabuf <= databuf[0];
                               state <= bit5;
                            end
                        else
                            state <= bit4;
                    bit5:
                        if (!scl)   // 为产生结束信号做准备，先把sda变为低电平
                            begin
                                sdabuf <= 0;
                                state <= stop;
                            end
                        else
                            state <= bit5;
                    stop:
                        if (scl)    // 在scl为高时，把sda由低变高产生结束信号
                            begin
                                sdabuf <= 1;
                                state <= IDLE;
                            end
                        else
                            state <= stop;
                    IDLE:
                        begin
                           link_sda <= 0;   // 把sdabuf与sda串行总线脱开
                           state <= ready; 
                        end
                    default:
                        begin
                           link_sda <= 0;
                           sdabuf <= 1;
                           state <= ready; 
                        end
                endcase
            end
endmodule