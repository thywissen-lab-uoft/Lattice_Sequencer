% TransportCloud2
%
% This is CF's attempt at rewriting this code.
function timeout = TransportCloud2(timein,opts)

curtime = timein;
global seqdata;

% % hor_transport_type,ver_transport_type, image_loc
% % 
horiz_length = 365;
vert_length = 174;


hor_transport_type            = 1;
ver_transport_type            = 3;
image_loc                     = 1;   

% Horitzonl used "1 : slow down in middle section curv"
% Vertical uses "3 : linear"


%% Horizontal Transport

%Distance to the second zone and time to get there
D1 = 300; %300
T1 = 1800; %1800
%Distance to the third zone and time to get there
Dm = 45; %45
Tm =1000; %1000
%Distance to the fourth zone and time to get there
D2 = 20; %15
T2 = 500; %600

% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,d1,t1,dm,tm,d2,t2) (for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)), ...
    T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);

%% Vertical Transport

vert_lin_trans_times = [450 250 450 800 450 250 500 200 150 500 500 300];
vert_lin_trans_distances = [0 20  40  60  80  100 120 140 151 154 160 173.9 174];
            

percent_trans = 1;
dist_temp = vert_lin_trans_distances;
time_temp = vert_lin_trans_times;

vert_lin_trans_distances = [0];
vert_lin_trans_times = [];

for ii = 2:length(dist_temp)

    if percent_trans==0
        break;
    end

    if dist_temp(ii) < (percent_trans*174)
        vert_lin_trans_distances(ii) = dist_temp(ii);
        vert_lin_trans_times(ii-1) = time_temp(ii-1);
    else
        vert_lin_trans_distances(ii) = (percent_trans*174);
        vert_lin_trans_times(ii-1) = ((percent_trans*174)-dist_temp(ii-1))*time_temp(ii-1)/(dist_temp(ii)-dist_temp(ii-1));
        break;
    end
end     

vert_lin_total_time = zeros(size(vert_lin_trans_distances));
for ii = 2:length(vert_lin_trans_distances)
vert_lin_total_time(ii) = vert_lin_total_time(ii-1) + vert_lin_trans_times(ii-1);
end             
vert_pp = pchip(vert_lin_total_time,vert_lin_trans_distances+horiz_length);  
DigitalPulse(curtime,12,100,1);


% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,tt,aa)(ppval(aa,t)),...
    vert_lin_total_time(end),vert_lin_total_time(end),vert_pp);

%% Turn off Vertical Coils 12A-14

setAnalogChannel(calctime(curtime,0),22,0,1);
setAnalogChannel(calctime(curtime,0),23,0,1);
setAnalogChannel(calctime(curtime,0),24,0,1);
setAnalogChannel(calctime(curtime,0),20,0,1);

timeout = curtime;

end