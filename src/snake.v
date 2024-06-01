module snake(clk, rst_n, x_px, y_px, rrggbb, left, right, up, down);
    input clk;
    input rst_n;
    input [9:0] x_px;
    input [9:0] y_px;
    input left;
    input right;
    input up;
    input down;
    output wire [5:0] rrggbb;

    localparam MAX_SIZE = 6;

    reg [MAX_SIZE*10-1:0] snakeX = {(MAX_SIZE){10'd100}}, snakeY={(MAX_SIZE){10'd100}};
    reg [9:0] appleX = 10'd150, appleY = 10'd150;
    reg [9:0] prev_y;
    reg [2:0] size = 3'd0;
    reg [9:0] appleX_n, appleY_n;
    reg [1:0] direction = 2'b01;
    reg eat_apple;
    reg game_over;
    
    wire [MAX_SIZE-1:0] body;
    wire [MAX_SIZE-1:0] bodySize;
    wire clk;
    wire border, apple;
    wire R, G, B;
    
    assign R = game_over | apple;
    assign bodySize = body[MAX_SIZE-1:0] & ({(MAX_SIZE){1'b1}} >> (MAX_SIZE-size-1));
    assign G = (|bodySize) && !game_over;
    assign B = border && !game_over;

    assign rrggbb = {R, R, G, G, B, B};
    
    always @(posedge clk) begin
        if (!rst_n) 
            direction <= 2'b01;
        else if (left)
            direction <= 2'b00;
        else if (right)
            direction <= 2'b01;
        else if (up)
            direction <= 2'b10;
        else if (down)
            direction <= 2'b11;
    end

    always @(posedge clk)
    begin
        if(!rst_n)
            game_over <= 1'b0;
        else if((border && bodySize[0]) || (|(bodySize[MAX_SIZE-1:1]) && bodySize[0])) 
            game_over <= 1'b1;
    end

    generate
        genvar i;
        for (i = 0; i < MAX_SIZE; i = i+1) begin
            assign body[i] = ((x_px > snakeX[i*10+9:i*10] && x_px < snakeX[i*10+9:i*10]+10) && 
                                (y_px > snakeY[i*10+9:i*10] && y_px < snakeY[i*10+9:i*10]+10));
        end
    endgenerate

    assign border = (x_px < 11) || (x_px > 629) || (y_px < 11) || (y_px > 469);
    assign apple = ((x_px > appleX && x_px < appleX+10) && 
                 (y_px > appleY && y_px < appleY+10));    
        
    always @*
    begin
        case(direction)
            2'b00: begin
                appleX_n = appleX + 30;
                appleY_n = appleY + 120;
            end
            2'b01: begin
                appleX_n = appleX + 70;
                appleY_n = appleY + 140;
            end
            2'b10: begin
                appleX_n = appleX + 60;
                appleY_n = appleY + 40;
            end
            2'b11: begin
                appleX_n = appleX + 80;
                appleY_n = appleY + 20;
            end                    
        endcase
        if (appleX_n < 11)
            appleX_n = 11;
        if (appleX_n > 619)
            appleX_n = 310;
        if (appleY_n < 11)
            appleY_n = 11;
        if (appleY_n > 459)
            appleY_n = 250;            
    end

    always @(posedge clk)
    begin
        if(!rst_n) begin
            snakeX <= {{(MAX_SIZE-1){10'd700}},10'd100};
            snakeY <= {{(MAX_SIZE-1){10'd700}},10'd100};
            appleX <= 10'd150;
            appleY <= 10'd150;
            size <= 0;
            prev_y  <= 10'b0;
            eat_apple <= 1'b0;
        end
        else
        begin
            prev_y <= y_px;
            if (prev_y != y_px && (y_px == 0)) begin
                case(direction)
                    2'b00: snakeX[9:0] <= snakeX[9:0] - 10;
                    2'b01: snakeX[9:0] <= snakeX[9:0] + 10;
                    2'b10: snakeY[9:0] <= snakeY[9:0] - 10;
                    2'b11: snakeY[9:0] <= snakeY[9:0] + 10;
                endcase
                snakeX[MAX_SIZE*10-1:10] <= snakeX[(MAX_SIZE-1)*10-1:0];
                snakeY[MAX_SIZE*10-1:10] <= snakeY[(MAX_SIZE-1)*10-1:0];

                if(eat_apple) begin
                    if (size < MAX_SIZE-1)
                        size <= size + 1;
                    eat_apple <= 0;
                    appleX <= appleX_n;
                    appleY <= appleY_n;
                end

            end
            else if((apple && bodySize[0]))
                eat_apple <= 1'b1;

        end
    end
    
endmodule

