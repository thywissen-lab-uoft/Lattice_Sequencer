function y = create_transport_splines_nb(coil_num)

global seqdata;

%create splines for transport system

x = [];
y2 = [];

horizontal_scale = 1.0;
vertical_scale = 1.0;

% Directory name where the splies are stored
dirName='Current Transport Splines';

% The directory of this folder
curpath = fileparts(mfilename('fullpath'));

% The parent directory is two levels up
upPath=fileparts(fileparts(curpath));

% create the transport folder name
transportfolder=fullfile(upPath,dirName);

if ~exist(transportfolder,'dir')
   error('the transport folder is specified incorrectly!');
end
transportfolder=[fullfile(upPath,dirName) filesep];


% transportfolder = 'C:\Lattice Sequencer\Current Transport Splines\';

%vertical currents revision number (remember to change in transport_coil_currents)
%rev45 -> raised QP
%rev47 -> raised QP with relaxed gradient near 15 cross over
%rev44 -> normal QP
cur_rev = 'rev45';

%horizontal currents to spline
MPush = dlmread([transportfolder 'Hextra1coilPush.txt'],',',0,1)*horizontal_scale;
MMOT = dlmread([transportfolder 'Hextra1coilMOT.txt'],',',0,1)*horizontal_scale;
M3 = dlmread([transportfolder 'Hextra1coil3.txt'],',',0,1)*horizontal_scale;
M4 = dlmread([transportfolder 'Hextra1coil4.txt'],',',0,1)*horizontal_scale;
M5 = dlmread([transportfolder 'Hextra1coil5.txt'],',',0,1)*horizontal_scale;
M6 = dlmread([transportfolder 'Hextra1coil6.txt'],',',0,1)*horizontal_scale;
M7 = dlmread([transportfolder 'Hextra1coil7.txt'],',',0,1)*horizontal_scale;
M8 = dlmread([transportfolder 'Hextra1coil8.txt'],',',0,1)*horizontal_scale; 
M9 = dlmread([transportfolder 'Hextra1coil9.txt'],',',0,1)*horizontal_scale;
M10 = dlmread([transportfolder 'Hextra1coil10.txt'],',',0,1)*horizontal_scale;
M11 = dlmread([transportfolder 'Hextra1coil11.txt'],',',0,1)*horizontal_scale;
M12 = dlmread([transportfolder 'Hextra1coil12.txt'],',',0,1)*horizontal_scale;
MExtra = dlmread([transportfolder 'Hextra1coilextra.txt'],',',0,1)*horizontal_scale;

%vertical points to spline
M12A = dlmread([transportfolder cur_rev 'coil1.txt'],',',0,1)*vertical_scale;
M12B = dlmread([transportfolder cur_rev 'coil2.txt'],',',0,1)*vertical_scale;
M13 = dlmread([transportfolder cur_rev 'coil3.txt'],',',0,1)*vertical_scale;
M14 = dlmread([transportfolder cur_rev 'coil4.txt'],',',0,1)*vertical_scale;
M15 = dlmread([transportfolder cur_rev 'coil5.txt'],',',0,1)*vertical_scale;
M16 = dlmread([transportfolder cur_rev 'coil6.txt'],',',0,1)*vertical_scale;

%vertical fill
M17 = dlmread([transportfolder cur_rev 'coilpushfill.txt'],',',0,2)*vertical_scale;
M18 = dlmread([transportfolder cur_rev 'coilMOTfill.txt'],',',0,2)*vertical_scale;

%horizontal fill...for constant current, i think this requires too much
%current in MOT and push during the end of the horizontal section...don't
%use 
%M19 = dlmread('rev43coilPushfillhorizontal.txt',',',0,1)*vertical_scale;
%M20 = dlmread('rev43coilMOTfillhorizontal.txt',',',0,1)*vertical_scale;


ver_vec_length = 539;  

if coil_num == 1
    
    %Push
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 MPush ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 2
    
    %MOT
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 MMOT ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = splinefit(x,y2,250);
    
    elseif coil_num == 3
                   
    %Coil 3
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M3 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
%     
     elseif coil_num == 4
    
    %Coil 4
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M4 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 5
    
    %Coil 5
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M5 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 6
    
    %Coil 6
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M6 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 7
    
    %Coil 7
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M7 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 8
    
    %Coil 8
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M8 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 9
    
    %Coil 9
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M9 ];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    elseif coil_num == 10
    
    %Coil 10
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 M10 ]; 
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    
    elseif coil_num == 11  
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
    x = [x (0:1:365)];
    
    %don't change this current
    %y2 = [y2 0 0 dlmread('rev0coil11.txt',',',0,1)];
    y2 = [y2 M11];
    
    % 11 vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);

%  elseif (coil_num == 12 || coil_num == 13)
%     
%     % 12A and 12B horizontal section
%     x = [x (0:1:360)];
%     
%     y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    
elseif coil_num == 12
    
    %Extra Coil
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 MExtra ]; 
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 (366:1:ver_vec_length)*0];
    
    %spline or splinefit this
    y = spline(x,y2);    

elseif coil_num == 13    
     
     % 12A horizontal section
    x = [x (0:1:365)];
    
     %don't change this current
    %y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    y2 = [y2 M12];
    
    %12A vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 -1*M12A];
    
    %spline or splinefit this
    y = spline(x,y2);
    
     
elseif coil_num == 14
    
     % 12B horizontal section
    x = [x (0:1:365)];
    
     %don't change this current
    %y2 = [y2 0 0 dlmread('rev0coil1h.txt',',',0,1)];
    y2 = [y2 M12];
    
     %12B vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 M12B];  %M12B
    
    %spline or splinefit this
    y = spline(x,y2); 
    
elseif coil_num == 15
    
    %third vertical
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0 ];
    
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2  M13];
    
    %spline or splinefit this
    y = spline(x,y2);
        
elseif coil_num == 16
    
    %fourth vertical

    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0];
        
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 M14];
    
    %spline or splinefit this
    y = spline(x,y2);
    
      
elseif coil_num == 17
    
    %bottom QP
   
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 M15];
    
    %spline or splinefit this
    y = spline(x,y2);
    
    
elseif coil_num == 18
    
    %top QP
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0];
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 M16];
    
    %spline or splinefit this
    y = spline(x,y2);
    
elseif coil_num == 19
    
    %push fill current
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0]; %0 M19
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 26 1.2*M17];
    
    %spline or splinefit this
    y = spline(x,y2);
    
 elseif coil_num == 20
    
    %MOT fill current
    
    %horizontal section
    x = [x (0:1:365)];
    
    y2 = [y2 (0:1:365)*0]; %0 M20
    
    %vertical section
    x = [x (366:1:ver_vec_length)];
    
    y2 = [y2 18.5 0.8*M18];
    
    %spline or splinefit this
    y = spline(x,y2);
    
        
else
    
    error('Undefined coil spline');
    
end

% if coil_num~=11 && coil_num~=12 && coil_num~=13
%     y2 = y2*vertical_scale;
% end

%y = spline(x,y2);
    
% figure
% plot(x,y2);



end