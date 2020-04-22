function y = create_transport_splines(coil_num)

%create splines for the vertical coils

x = [];
y2 = [];

vertical_scale = 1.5;

if coil_num == 11  
    
     %last horizontal
    
    %before turning off
    x = [x 0:1:250];
    y2 = [y2 0*(0:1:250)];
    
    %horizontal part
    x = [x   252 255 260 270 280 290 300 310];
    y2 = [y2 0   0   5   10  30  50  60  65];
    
    x = [x   320 330 340 345 350 355 360];
    y2 = [y2 70  85  90  75  60  45  0];
    
    x = [x 360.1:1:534];
    y2 = [y2 ((360.1:1:534)*0)];
    
    y2 = y2*0.8;

elseif (coil_num == 12 || coil_num == 13)
    
    %first vertical horizontal part
    
    %before turning off
    x = [x 0:1:275];
    y2 = [y2 0*(0:1:275)];
    
    %horizontal part
    x = [x 300 310 320 330 340 350 360];
    y2 = [y2 2.5 5 7.5 12.5 17.5 22.5 20];
    
    x = [x 361:1:534];
    y2 = [y2 ((361:1:534)*0+20)];
    
    y2 = y2*1.0;
    
    
elseif coil_num == 12.5    
    
    %first vertical vertical part
    
    %ramp into vertical
    x = [x (0:1:360)];
    y2 = [y2 ((0:1:360)*0 + 14)];
    
    x = [x 361 370 380 382.5 390 400 410 420 425];
    y2 = [y2 14 19 26  28    26 15 10 5 0];
    
    x = [x 426:1:534];
    y2 = [y2 0*(426:1:534)];
    
    
elseif coil_num == 13.5
    
    %second vertical vertical part
    
    %ramp into vertical
    x = [x (0:1:360)];
    y2 = [y2 ((0:1:360)*0 + 15)];
    
    x = [x 361 370 380 382.5 390 400 410];
    y2 = [y2 15 8 2.5  0     -5 -12 -20];
    
    x = [x  420 430 440 450];
    y2 = [y2 -35 -30 -15 0];
    
    x = [x 451:1:534];
    y2 = [y2 0*(451:1:534)];
    
elseif coil_num == 14
    
    %third vertical
    x = [x (0:1:360)];
    y2 = [y2 ((0:1:360)*0 + 13)];
    
    x = [x 361 370 380 382.5 390 400 410];
    y2 = [y2 13 16 26  28    22 12 8];
    
    x = [x  420 430 440 450 460];
    y2 = [y2 3 -4 -12 -22 -32];
    
    x = [x  470 480 490 500 505];
    y2 = [y2 -18 -10 -6 -3 0];
    
    x = [x 506:1:534];
    y2 = [y2 0*(506:1:534)];
    
    y2 = y2*1.0;
    
        
elseif coil_num == 15
    
    %fourth vertical
    x = [x (0:1:382)];
    y2 = [y2 (0:1:382)*0];
    
    x = [x 383 390 400 410 420];
    y2 = [y2 0 5 13 20 34];
    
    x = [x 430 440 450 460 470 480];
    y2 = [y2 24 10 2 -8 -12 -14];
    
%     x = [x 490 500 510 520 530 534 540 550];
%     y2 = [y2 -16 -20 -28 -28 -13 -12 -12 -12];
    
     x = [x 490 500 510 520 530 534 540 550];
    y2 = [y2 -16 -20 -30 -30 -10 0 0 0]; 
    
    y2 = y2*1.0;
    
elseif coil_num == 16
    
    %bottom QP
    x = [x (0:1:424)];
    y2 = [y2 (0:1:424)*0];
    
    x = [x   425 430 440 450 460 470];
    y2 = [y2 0   2   10  22  30  20];
    
    x = [x   480 490 500 505 510 520 530 534 540 550];
    y2 = [y2 10  6   3   0   -3  -6  -10  -12 -12 -12];
    
    
elseif coil_num == 17
    
    %top QP
    x = [x (0:1:449)];
    y2 = [y2 (0:1:449)*0];
    
    x = [x   450 460 470 480 490 500 505];
    y2 = [y2 0   8   12  13  18  27  32];
    
    x = [x   510 520 530 534 540 550];
    y2 = [y2 27  18  13  12  12  12];
    
        
else
    
    error('Undefined coil spline');
    
end

if coil_num~=11 && coil_num~=12 && coil_num~=13
    y2 = y2*vertical_scale;
end

y = spline(x,y2);
    
% figure
% plot(x,y2);

end