function y = create_transport_splines_nb(coil_num)

%create splines for the vertical coils

x = [];
y2 = [];

vertical_scale = 1.0;


M12A = dlmread('rev44coil1.txt',',',0,1)*vertical_scale;
M12B = dlmread('rev44coil2.txt',',',0,1)*vertical_scale;
M13 = dlmread('rev44coil3.txt',',',0,1)*vertical_scale;
M14 = dlmread('rev44coil4.txt',',',0,1)*vertical_scale;
M15 = dlmread('rev44coil5.txt',',',0,1)*vertical_scale;
M16 = dlmread('rev44coil6.txt',',',0,1)*vertical_scale;

%vertical fill
M17 = dlmread('rev43coilpushfill.txt',',',0,2)*vertical_scale;
M18 = dlmread('rev43coilMOTfill.txt',',',0,2)*vertical_scale;

%horizontal fill...for constant current, i think this requires too much
%current in MOT and push during the end of the horizontal section...don't
%use 
%M19 = dlmread('rev43coilPushfillhorizontal.txt',',',0,1)*vertical_scale;
%M20 = dlmread('rev43coilMOTfillhorizontal.txt',',',0,1)*vertical_scale;


ver_vec_length = 534;  

 if coil_num == 11  
%     
%      %last horizontal
%     
%     %before turning off
%     x = [x 0:1:250];
%     y2 = [y2 0*(0:1:250)];
%     
%     %horizontal part
%     x = [x   252 255 260 270 280 290 300 310];
%     y2 = [y2 0   0   5   10  30  50  60  65];
%     
%     x = [x   320 330 340 345 350 355 360];
%     y2 = [y2 70  85  90  75  60  45  0];
%     
%     x = [x 360.1:1:534];
%     y2 = [y2 ((360.1:1:534)*0)];
%     
%     y2 = y2*1.0;

   % 11 horizontal section
    x = [x (0:1:360)];
    
    %don't change this current
    y2 = [y2 0 0 dlmread('rev0coil11.txt',',',0,1)];
    
    % 11 vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 (361:1:ver_vec_length)*0];

%  elseif (coil_num == 12 || coil_num == 13)
%     
%     % 12A and 12B horizontal section
%     x = [x (0:1:360)];
%     
%     y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    
    
elseif coil_num == 12    
     
     % 12A horizontal section
    x = [x (0:1:360)];
    
     %don't change this current
    y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    
    %12A vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 -1*M12A];
    
    
elseif coil_num == 13
    
     % 12B horizontal section
    x = [x (0:1:360)];
    
     %don't change this current
    y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    
     %12B vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 M12B];
    
elseif coil_num == 14
    
    %third vertical
    
    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0 ];
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 M13];
    
        
elseif coil_num == 15
    
    %fourth vertical

    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0];
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 M14];
   
elseif coil_num == 16
    
    %bottom QP
   
    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0];
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 M15];
    
    
elseif coil_num == 17
    
    %top QP
    
    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0];
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 M16];
    
elseif coil_num == 18
    
    %push fill current
    
    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0]; %0 M19
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 26 1.2*M17];
    
 elseif coil_num == 19
    
    %MOT fill current
    
    %horizontal section
    x = [x (0:1:360)];
    
    y2 = [y2 (0:1:360)*0]; %0 M20
    
    %vertical section
    x = [x (361:1:ver_vec_length)];
    
    y2 = [y2 18.5 0.8*M18];
    
        
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