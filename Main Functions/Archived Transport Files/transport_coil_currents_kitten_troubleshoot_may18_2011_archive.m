%------
%Author: David McKay
%Created: July 2009
%Summary: This function returns the 3 column array for the analog update for a given cloud position.
%Position and time can be 1D arrays. Position is in mm.
%Horizontal is from 0->360mm and vertical is from 360mm->534mm
%------
function y = transport_coil_currents_kitten_troubleshoot(time,position,flag)

global seqdata;

%if the flag = 1 this outputs a nxm array where n is the number of channels
%and m is the position
if nargin < 3
    flag = 0;
end

%define the transport parameters

%% switches


%vertical current curves
    vert_current_rev = 2; %0: rev0, 1: rev1, 2: rev2, 3: rev0/rev0 concatenation

%try using spline interpolations
use_hor_splines = 1;  %this is for horizontal splines
use_splines = 1;  %this is for vertical splines
use_fill = 0;

if ~use_splines
    use_fill = 0;
end

%import currents for spline
vertical_scale = 1.0;

coilone = dlmread('rev30coilone.txt',',',0,1)*vertical_scale;
coiltwo = dlmread('rev30coiltwo.txt',',',0,1)*vertical_scale;



%end of fit coil values
fit_coil_14 = -.0064;
fit_coil_15 = -11.9114;
fit_coil_16 = 11.2517;

connect_spline_to_fit = 0;


%final_handoff type for fitted curves
final_handoff = 0; %0: all FETS control current, 1: kitten fully on when 16 off, 2: kitten and 16 fully on

handoff_position = 506.5; %506.5

%kitten or no kitten
use_kitten = 1;  %0: no kitten, 1: kitten, 2: coil 15 h-bridge

%% parameters

overallscale = 1.0; %scales all the transport currents
verticalscale = 1.0; %scales the vertical currents

coil_scale_factors = ones(1,20);%scaling of the max current in each coil

coil_widths = ones(1,20);%widths of each of the coil curves

%coil_offset = [0 30 41 43 85 116 148 179 212 242 274 338 360 360 360 360 360 360 360]; %the peak of each coil in position (mm)
coil_offset = [0 30 41 43 85 116 148 179 212 242 274 338 360 360 360 360 360 360 360 360]; %338
%coil_offset = [0 30 41 43 85 116 148 179 212 242 274 338 360 360 358 360 359 361 360]; rev1 

if use_hor_splines
    coil_offset(1:12) = 0; %coil_offset(12:end) = 0;
     %coil_offset(12) = 1;
end


%coil_offset(3) = 41;

if use_splines
    coil_offset(13:end) = 0; %coil_offset(12:end) = 0;
     %coil_offset(12) = 1;
end

%coil resistances are in mOhms
coil_resistance = [0 312.5 357 85 85 85 85 85 85 85 85 85 167 192 192 192 192 192 192 192];

coil_range = ones(2,20); %relevant range of the given coil (2xnumber of channels)


%FEED FORWARD
coil_range(1,1) = 0;
coil_range(2,1) = 534;
coil_widths(1) = 1.0;
coil_scale_factors(1) = 1.0/overallscale;



%Push Coil Range
coil_range(1,2) = 0; %0
coil_range(2,2) = 534; %50 for non-divergent curves
coil_widths(2) = 1.0;
coil_scale_factors(2) = 1.0; %1.05
coil_offset(2) = 0; %-0.65

% %  %list
%    MOT_offset_list=[-4:0.4:4 -4:0.4:4];
% %   Create linear list
% %  index=seqdata.cycle;
% %  
% %  Create Randomized list
%   index=seqdata.randcyclelist(seqdata.cycle);
% %  
%   MOT_offset = MOT_offset_list(index)
%    addOutputParam('hor_transport_distance',MOT_offset);
    

%MOT Coil range
coil_range(1,3) = 0;
coil_range(2,3) = 534; %75 for non-divergent curves
coil_scale_factors(3) = 1.0;
coil_offset(3) =  0;

 %First horizontal transport
coil_range(1,4) = 0;
coil_range(2,4) = 115; %115 for non-divergent curves
coil_scale_factors(4) = 1.0;
coil_offset(4) = 0;

%second horizontal transport
coil_range(1,5) = 35;
coil_range(2,5) = 140;
coil_scale_factors(5) = 1.0;

%third horizontal transport
coil_range(1,6) = 50;
coil_range(2,6) = 180;
coil_scale_factors(6) = 1.0;

%fourth horizontal transport
coil_range(1,7) = 90;
coil_range(2,7) = 210;
coil_scale_factors(7) = 1.0;

%fifth horizontal transport
coil_range(1,8) = 110;
coil_range(2,8) = 250;
coil_scale_factors(8) = 1.0;

%sixth horizontal transport
coil_range(1,9) = 150;
coil_range(2,9) = 270;
coil_scale_factors(9) = 1.0;

%coil 9
%seventh horizontal transport
coil_range(1,10) = 180;
coil_range(2,10) = 300;
coil_scale_factors(10) = 1.0;

%coil 10
%eighth horizontal transport
coil_range(1,11) = 200;
coil_range(2,11) = 330;
coil_scale_factors(11) = 1.0;

%coil 11
%ninth horizontal transport
 coil_range(1,12) = 250; %CHANGE TO coil_range(1,11) = 250;
 coil_range(2,12) = 380; %CHANGE TO coil_range(2,11) = 380;
coil_scale_factors(12) = 1.15; %1.1
coil_widths(12) = 0.99;   %0.99
coil_offset(12) = -0.5;    %-0.5

%first vertical transport
coil_range(1,13) = 260; 
coil_range(2,13) = 430; %430
coil_scale_factors(13) = 1.0; %1.0*1.1  *rev1* 1.0  *rev2* 1.0 SC: 1.1
coil_offset(13) = 0; 
coil_widths(13) = 1.0; 

%second vertical transport
coil_range(1,14) = 280; 
coil_range(2,14) = 450; %450 %460
coil_scale_factors(14) = -1.0; %-0.85*1.1  *rev1* -1.0  *rev2* -1.0 SC: -0.85*1.4
coil_offset(14) = 0; 
coil_widths(14) = 1.0; 

%third vertical transport
coil_range(1,15) = 358; 
coil_range(2,15) = 520;
coil_scale_factors(15) = 1.0; %1.1  *rev1*1.0  *rev2* 1.3 SC: 1.1

%fourth vertical transport
coil_range(1,16) = 70; 
coil_range(2,16) = 534;
coil_scale_factors(16) = 1.0;
if ~use_splines
    coil_scale_factors(16) = 1.0*verticalscale; %1.4  *rev1*1.3  *rev2* 1.0 SC: 1.4
end

%Quadrupole factor
qp_scale_factor = 1.0*verticalscale; %1.0  *rev1*1.15  *rev2* 1.0 SC: 1.1

%bottom qp coil
coil_range(1,17) = 427; %410 
coil_range(2,17) = 534;
coil_scale_factors(17) = 1.0*qp_scale_factor;

%top qp coil
coil_range(1,18) = 410; 
coil_range(2,18) = 534; 
coil_scale_factors(18) = 1.0*qp_scale_factor;

%kitten 
coil_range(1,19) = 427; 
coil_range(2,19) = 534;
coil_scale_factors(19) = 1.0*qp_scale_factor;

%new FET 
coil_range(1,20) = 427; 
coil_range(2,20) = 534;
coil_scale_factors(20) = 1.0*qp_scale_factor;

%check the bounds on position
if (sum(position<-0.1)); 
   
    error('negative Position')
elseif (sum(position>534.1));
    error('position too far')
end


%This value means that this channel value can be neglected from the update
%array
nullval = -100;

%number of transport channels
num_channels = 20; 
%channels the coils correspond to on the ADWIN
transport_channels = [18 7:17 22:24 20:21 1 3 32]; %CHANGE TO 7:17;

%preallocate the full array (we are going to output the current in each
%channel as a function of time)
currentarray = zeros(length(time)*num_channels,3);

%entries for the voltage feedforward
% voltage_indices = 1:length(time);
% currentarray(voltage_indices,1) = time-calctime(0,50);
% currentarray(voltage_indices,2) = transport_channels(1);
% 
% %set the voltage feedforward to a minimum of 8 volts (to not turn off the
% %vertical CATS)
%currentarray(voltage_indices,3) = 8/6.6;

%go through for each channel
for i = 1:num_channels
    
    
    
    %indices for the current channel
    channel_indices = ((i-1)*length(time)+1):(i*length(time));
     
    currentarray(channel_indices,1) = time;
    currentarray(channel_indices,2) = transport_channels(i);
    currentarray(channel_indices,3) = channel_current(i,position,coil_offset(i),coil_widths(i),coil_range(:,i));
    
%     %determine the voltage required to drive the current for this channel
%     %total voltage is the maximum from all the channels
%     cur_channel_voltages = currentarray(channel_indices,3)*coil_resistance(i)*1E-3/6.6 + 2.0/6.6; 
%     currentarray(voltage_indices,3) = currentarray(voltage_indices,3).*(cur_channel_voltages<=currentarray(voltage_indices,3)) + ...
%         cur_channel_voltages.*(cur_channel_voltages>currentarray(voltage_indices,3));
    
    if ~flag
        %convert currents to channel voltages
        currentarray(channel_indices,3) = seqdata.analogchannels(transport_channels(i)).voltagefunc{2}(currentarray(channel_indices,3).*overallscale*coil_scale_factors(i)).*(currentarray(channel_indices,3)~=nullval)+...
            currentarray(channel_indices,3).*(currentarray(channel_indices,3)==nullval);

        %check the voltages are in range
        if sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)>seqdata.analogchannels(transport_channels(i)).maxvoltage))||...
                sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)<seqdata.analogchannels(transport_channels(i)).minvoltage))
            error(['Voltage out of range when computing transport Channel:' num2str(transport_channels(i))]);
        end
    end
    
%     if (transport_channels(i)==18)
%         currentarray(channel_indices,3)=nullval;
%     end
    
%     if (transport_channels(i)~=20 && transport_channels(i)~=18 && transport_channels(i)~=21 && transport_channels(i)~=24 && transport_channels(i)~=23 && transport_channels(i)~=1)
%         currentarray(channel_indices,3)=nullval;
%     end
    
%     if (transport_channels(i)~=20 && transport_channels(i)~=18)
%         currentarray(channel_indices,3)=nullval;
%     end
    

end

if flag
    ind = logical(currentarray(:,3)==nullval);
    currentarray(ind,3) = 0;
    
    y = zeros(num_channels,length(position));
    for i = 1:num_channels
        y(i,:) = currentarray(((i-1)*length(position)+1):(i*length(position)),3);
    end
       
    return;
end

% %shift around feedforward to pre-empt changes
% numsteps = floor(calctime(0,50)/(time(2)-time(1)));
% 
% %take the max of the current voltages and the voltages shifted 50ms in the
% %future
% cur_voltages = currentarray(voltage_indices(1:(end-numsteps)),3);
% future_voltages = currentarray(voltage_indices((numsteps+1):end),3);
% currentarray(voltage_indices(1:end-numsteps),3) = future_voltages.*(cur_voltages<=future_voltages) + ...
%         cur_voltages.*(cur_voltages>future_voltages);
%     
% cur_voltages = currentarray(voltage_indices((numsteps+1):end),3);
% past_voltages = currentarray(voltage_indices(1:(end-numsteps)),3);
% currentarray(voltage_indices((numsteps+1):end),3) = past_voltages.*(cur_voltages<=past_voltages) + ...
%         cur_voltages.*(cur_voltages>past_voltages);
% 
% %check the feedforward voltages are in range
% if sum((currentarray(voltage_indices,3)~=nullval).*(currentarray(voltage_indices,3)>seqdata.analogchannels(transport_channels(1)).maxvoltage))||...
%         sum((currentarray(voltage_indices,3)~=nullval).*(currentarray(voltage_indices,3)<seqdata.analogchannels(transport_channels(1)).minvoltage))
%     error(['Voltage out of range when computing feed forward voltage:' num2str(transport_channels(1))]);
% end

%weed out any entries that are less than zero
ind = logical(currentarray(:,3)~=nullval);
currentarray = currentarray(ind,:);

%return
y = currentarray;

%sub function that calculates the current values of the different channels
    function y = channel_current(channel,pos,offset,width,coilrange)
       
        y = (pos<coilrange(1))*nullval;
        y = y + (pos>=coilrange(2))*nullval;
        
        %indices of non-null value entries
        ind = (y~=nullval);
        
        %put the position coordinates into the frame of the coil
        x = (pos(ind)-offset)/width;
        

            
        switch channel
            
            case 1  %This is the FF channel

                 %FET + coil resistances
                 %MOT: 357mOhm
                 %Push:312.5mOhm
                 %Horiz Trans: 85mOhm
                 %12a: 167mOhm
                 %12b: 192mOhm
                
                 %------------------------
                 %feedforward parameters
                 %------------------------
                 
 
                 
                 
                 %voltage when MOT trapping
                 MOTvoltage = 10/6.6*overallscale; %10/4
                 
                 %ramp up and down for the push
                 maxpushvoltage = (28)/6.6*overallscale; %24/6.6 %27.66 for 1.2 
                 startpushramp = 10; %10
                 pushramppeak = 43; %40
                 endpushramp = 60; %60
                 
                 %steady voltage for horizontal transfer stage
                 horizontalvoltage = 9.0/6.6*overallscale; %9/6.6
                 
                 %steady_voltage =10/6.6;
                 
                 %ramp up and down for the last horiz transport coil
                 maxhorizvoltage = 11.5/6.6*overallscale; %10/6.6
                 starthorizramp = 300; %260
                 peakhorizramp = 336;  %350
                 endhorizramp = 360; %360
 
                 

                  
                 %steady voltage for beginning of vertical transfer
                 beginningverticalvoltage = 10.0/6.6*overallscale; %11/4 %12/4
                 
                 
                  %    %list
%   ver_voltage_list=[9.8:0.1:10.4];
%   %Create linear list
%  %index=seqdata.cycle;
%  
%  %Create Randomized list
%  index=seqdata.randcyclelist(seqdata.cycle);
% %  
%  ver_voltage=  ver_voltage_list(index)
%   addOutputParam('hor_transport_distance', ver_voltage);
                 
                 %ramp up vertical transport coil
%                  maxverticalvoltage =  9.9/6.6*overallscale; %11.5/4  %14.5 %9.5
%                   startverticalrampup = 360; %360 %360
%                  endverticalrampup = 360.1; %360.1 %370
%                   
%                  %ramp down vertical transport coil
%                  startverticalrampdown = 485; %410 %510
%                  endverticalrampdown = 534; %434 %534
%                  
%                  %steady voltage for end of vertical transfer
%                  endverticalvoltage = 10.0/6.6*overallscale; %12/4  %10
                 %------------------------
                 
                
                 %vertical FF parameters
                 
                 %=============
                 %BE VERY CAREFUL HERE TO NOT DAMAGE THE BRIDGES!!!!
                 %=============
                 
                 %initial_voltage
                 initial_voltage = 9.9/6.6;
                 
                  %ramp 1
                 voltage1_start = initial_voltage;
                 voltage1_end = 9.9/6.6;
                 position1_start = 360 + 1;
                 position1_end = 360 + 21;
                 
                 %ramp 2
                 voltage2_start = voltage1_end;
                 voltage2_end = 9.9/6.6;
                 position2_start = position1_end;
                 position2_end = 360 + 50;
                 
                 %ramp 3
                 voltage3_start = voltage2_end;
                 voltage3_end = 9.9/6.6;
                 position3_start = position2_end;
                 position3_end = 360 + 65;
                 
                 %ramp 4
                 voltage4_start = voltage3_end;
                 voltage4_end = 9.9/6.6;
                 position4_start = position3_end;
                 position4_end = 360 + 85;
                
                 %ramp 5
                 voltage5_start = voltage4_end;
                 voltage5_end = 9.9/6.6;
                 position5_start = position4_end;
                 position5_end = 360 + 174;
                 
                 %end
                 FF_end = 360 + 174;
%                  
%                   
%                   %------------------------
%                   %horizontal voltage
%                   
                 y(ind) = y(ind) + MOTvoltage.*(pos(ind)<startpushramp);
                 
                 y(ind) = y(ind) + ((maxpushvoltage-MOTvoltage)/(pushramppeak-startpushramp).*(pos(ind)-startpushramp)+MOTvoltage).*(pos(ind)>=startpushramp).*(pos(ind)<pushramppeak);
                 
                 y(ind) = y(ind) + ((horizontalvoltage-maxpushvoltage)/(endpushramp-pushramppeak).*(pos(ind)-pushramppeak)+maxpushvoltage).*(pos(ind)<endpushramp).*(pos(ind)>=pushramppeak);
                 
                 y(ind) = y(ind) + horizontalvoltage.*(pos(ind)>=endpushramp).*(pos(ind)<starthorizramp);
                 
                 y(ind) = y(ind) + ((maxhorizvoltage-horizontalvoltage)/(peakhorizramp-starthorizramp).*(pos(ind)-starthorizramp)+horizontalvoltage).*(pos(ind)>=starthorizramp).*(pos(ind)<peakhorizramp);
                 
                y(ind) = y(ind) + ((beginningverticalvoltage-maxhorizvoltage)/(endhorizramp-peakhorizramp).*(pos(ind)-peakhorizramp)+maxhorizvoltage).*(pos(ind)<endhorizramp).*(pos(ind)>=peakhorizramp);
                
                y(ind) = y(ind) + beginningverticalvoltage.*(pos(ind)<360).*(pos(ind)>=endhorizramp);
                %y(ind) = y(ind) + beginningverticalvoltage.*(pos(ind)<startverticalrampup).*(pos(ind)>=endhorizramp);
                 
                 %------------------------
                  %vertical voltage
                   
%                  y(ind) = y(ind) + ((maxverticalvoltage-beginningverticalvoltage)/(endverticalrampup-startverticalrampup).*(pos(ind)-startverticalrampup)+beginningverticalvoltage).*(pos(ind)>=startverticalrampup).*(pos(ind)<endverticalrampup);
%                  
%                  y(ind) = y(ind) + maxverticalvoltage.*(pos(ind)<startverticalrampdown).*(pos(ind)>=endverticalrampup);
%                  
%                  y(ind) = y(ind) + ((endverticalvoltage-maxverticalvoltage)/(endverticalrampdown-startverticalrampdown).*(pos(ind)-startverticalrampdown)+maxverticalvoltage).*(pos(ind)>=startverticalrampdown).*(pos(ind)<endverticalrampdown);
%                  
%                  y(ind) = y(ind) + endverticalvoltage.*(pos(ind)<535).*(pos(ind)>=endverticalrampdown);
                 
                 %------------------------
                 
                  y(ind) = y(ind) + initial_voltage.*(pos(ind)<position1_start).*(pos(ind)>=360);
%                  
                 %ramp1
                 y(ind) = y(ind) + ((voltage1_end-voltage1_start)/(position1_end-position1_start).*(pos(ind)-position1_start)+ initial_voltage).*(pos(ind)>=position1_start).*(pos(ind)<position1_end);
                 y(ind) = y(ind) + voltage1_end.*(pos(ind)<position2_start).*(pos(ind)>=position1_end);
                 
                  %ramp2
                 y(ind) = y(ind) + ((voltage2_end-voltage2_start)/(position2_end-position2_start).*(pos(ind)-position2_start)+ voltage1_end).*(pos(ind)>=position2_start).*(pos(ind)<position2_end);
                 y(ind) = y(ind) + voltage2_end.*(pos(ind)<position3_start).*(pos(ind)>=position2_end);
                 
                  %ramp3
                 y(ind) = y(ind) + ((voltage3_end-voltage3_start)/(position3_end-position3_start).*(pos(ind)-position3_start)+ voltage2_end).*(pos(ind)>=position3_start).*(pos(ind)<position3_end);
                 y(ind) = y(ind) + voltage3_end.*(pos(ind)<position4_start).*(pos(ind)>=position3_end);
                 
                  %ramp4
                 y(ind) = y(ind) + ((voltage4_end-voltage4_start)/(position4_end-position4_start).*(pos(ind)-position4_start)+ voltage3_end).*(pos(ind)>=position4_start).*(pos(ind)<position4_end);
                 y(ind) = y(ind) + voltage4_end.*(pos(ind)<position5_start).*(pos(ind)>=position4_end);
                 
                  %ramp5
                 y(ind) = y(ind) + ((voltage5_end-voltage5_start)/(position5_end-position5_start).*(pos(ind)-position5_start)+ voltage4_end).*(pos(ind)>=position5_start).*(pos(ind)<position5_end);
                 y(ind) = y(ind) + voltage5_end.*(pos(ind)<=FF_end).*(pos(ind)>=position5_end);
                 
                 %------------------------
          
                 
            case 2 %push    
                
                if use_hor_splines
                     pp = create_transport_splines_nb(1);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-30).*...
                    (0.365494*(x+30)+0.0393257*(x+30).^2);
                
                y(ind) = y(ind) + (x<14).*(x>=0).*...
                    (46.2416-2.25861*(x+1)+3.51015*(x+1).^2-1.19336*(x+1).^3+0.216452*(x+1).^4-0.0216174*(x+1).^5+...
                    0.0011149*(x+1).^6-0.0000235111*(x+1).^7);
                
                y(ind) = y(ind);
                
                end
                
                if use_fill
                   
                 pp = create_transport_splines_nb(18);
                    y(ind) = y(ind) + (x<534-30).*(x>=360-30).*ppval(pp,x+30);   
                    
                else
               
                end 
                               
            case 3 %MOT 
                 
                if use_hor_splines
                     pp = create_transport_splines_nb(2);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                    
                y(ind) = y(ind) + (x<0).*(x>=-41).*...
                    (18.8132-0.0252293*(x+41)+0.0139316*(x+41).^2-0.00160342*(x+41).^3+0.0000582156*(x+41).^4-6.93292E-7*(x+41).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<5).*...
                    (29.0516-31.1518*(x+1)+24.0873*(x+1).^2-8.28676*(x+1).^3+0.942994*(x+1).^4+0.0997906*(x+1).^5-0.0302388*(x+1).^6+0.00179111*(x+1).^7);
                
                y(ind) = y(ind) + (x>=5).*(x<27).*...
                    (8.31257-0.299131*(x-4)-0.00130763*(x-4).^2-0.000860555*(x-4).^3+0.0000347087*(x-4).^4);
                
                end
                
                 if use_fill
                   
                 pp = create_transport_splines_nb(19);
                    y(ind) = y(ind) + (x<534-41).*(x>=360-41).*ppval(pp,x+41);   
                    
                 else
                 
                 end
                                
               case 4 %1st transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(3);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                   
                y(ind) = y(ind) + (x<0).*(x>=-43).*...
                    (5.86264*(x+43)-0.276793*(x+43).^2+0.00705393*(x+43).^3-0.00010412*(x+43).^4+8.06799E-7*(x+43).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<6).*...
                    (59.1092+5.02669*(x+1)+0.663354*(x+1).^2-0.771293*(x+1).^3+0.139931*(x+1).^4-0.00786621*(x+1).^5);
                
                y(ind) = y(ind) + (x>=6).*(x<59).*...
                    (65.6381-0.144979*(x-5)-0.0525976*(x-5).^2+0.00109299*(x-5).^3-0.0000170024*(x-5).^4+1.48227E-7*(x-5).^5);
              
               end
                
            case 5 %2nd transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(4);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-42).*...
                    (2.08226*(x+42)-0.0857661*(x+42).^2+0.00390637*(x+42).^3-0.0000944415*(x+42).^4+7.95421E-7*(x+42).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<43).*...
                    (35.5106+0.14955*(x+3)-0.03984449*(x+3).^2+0.000328995*(x+3).^3+2.12379E-6*(x+3).^4);
                
                end
                
            case 6 %3rd transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(5);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
              y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
                end
                             
            case 7 %4th transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(6);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                
                end 
            
            case 8 %5th transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(7);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
                end
            
            case 9 %6th transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(8);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                
                end
            
            case 10 %7th transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(9);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
                end
            
            case 11 %8th transport coil
                
                if use_hor_splines
                     pp = create_transport_splines_nb(10);
                     y(ind) = y(ind) + ppval(pp,x);
                                                              
                else
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                
                end
                
            case 12 %9th transport coil (last pure horizontal coil)
                
                if use_splines
                    
                    pp = create_transport_splines_nb(11);
                    y(ind) = y(ind) + ppval(pp,x);
                    
                else
                
                     y(ind) = y(ind) + (x<0).*(x>=-81).*...
                        (-1.399576152198809 + 0.6128959132776826*(x+81) + 0.05818092411674249*(x+81).^2 - 0.0020273894601591496*(x+81).^3 +...
                        0.00006390066486350164*(x+81).^4 - 1.576426225114415E-6*(x+81).^5 + 1.9412239479883187E-8*(x+81).^6 - 8.747493861499982E-11*(x+81).^7);

                     y(ind) = y(ind) + (x>=0).*(x<=23).*...
                        (87.68973301076208 + 0.17258405557431836*(x) - 0.02392088676738215*(x).^2 - 0.006588669866824533*(x).^3 +...
                        0.0000614116598770041*(x).^4);
                
                end
                
                
            case 13 %1st vert transport coil
              
                if use_splines
                     pp = create_transport_splines_nb(12);
                      %y(ind) = y(ind) + ppval(pp,x);
                     
                     %horizontal section
                     y(ind) = y(ind) + (x<=360).*ppval(pp,x);
                    
                    %ramp between the values from 360-->360.1
                    y(ind) = y(ind) + (x>360).*(x<360.1).*...
                        (ppval(pp,360)-(ppval(pp,360)+coilone).*(x-360)/0.1);
                    
                    %ramp between the values from 360.1-->363
                    y(ind) = y(ind) + (x>=360.1).*(x<363).*...
                        (-coilone+(ppval(pp,363)+coilone).*(x-360.1)/2.9);
                    
                    %vertical section
                    y(ind) = y(ind) + (x>=363).*ppval(pp,x);
                    
%                                         
                else

                    %*****************************rev0/rev2 concatenation below
                    if vert_current_rev == 3
                    y(ind) = y(ind) + (x<=0).*(x>=-67).*...
                         (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                         0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);

    %                  y(ind) = y(ind) + (x>0).*(x<26).*...
    %                     -(-17.66251711119374 - 0.8803557826834764*x +
    %                     0.014838875332075424*x.^2 - 0.005037847776532191*x.^3
    %                     +... 0.0001692253268397948*x.^4);

                    %smoother curve
                    y(ind) = y(ind) + verticalscale*(x>0).*(x<26).*...
                        -(-19.0519 + (- 0.8803557826834764*x + 0.014838875332075424*x.^2 - 0.005037847776532191*x.^3 +...
                        0.0001692253268397948*x.^4)*0.93); 

                     y(ind) = y(ind) + verticalscale*(x>=26).*(x<=64).*...
                        -(-43.13897558568566 - 1.0886525433210776*(x-21) + 0.3384633114295477*(x-21).^2 - 0.016929027331642556*(x-21).^3 +...
                        0.00034701862849640676*(x-21).^4 - 2.561116083403605E-6*(x-21).^5);

                    %minus signs below may need to be fixed
                    y(ind) = y(ind) + verticalscale*(x>20).*(x<=66).*...
                        -(-25.94202900068819-1.2330684828778178*(x-20)+0.24761537415091986*(x-20).^2-0.011758456767792856*(x-20).^3+0.00023179910227504207*(x-20).^4-1.61647924389463E-6*(x-20).^5);
                    end


                    %*****************************rev2 below
                    if vert_current_rev == 2
                     y(ind) = y(ind) + (x-(360-coil_offset(13))<=0).*(x-(360-coil_offset(13))>=-67).*...
                         1/verticalscale.*(-0.24894053840627586 + 0.21549342441239006*(x-(360-coil_offset(13))+69) + 0.010610913626239617*(x-(360-coil_offset(13))+69).^2 - 0.0011035186372974687*(x-(360-coil_offset(13))+69).^3 +...
                         0.00005994384121982444*(x-(360-coil_offset(13))+69).^4 - 1.4556975877409068E-6*(x-(360-coil_offset(13))+69).^5 +  1.615819365079346E-8*(x-(360-coil_offset(13))+69).^6 - 6.840008875660139E-11*(x-(360-coil_offset(13))+69).^7);

    %                  y(ind) = y(ind) + (x>0).*(x<26).*...
    %                     -(-17.66251711119374 - 0.8803557826834764*x + 0.014838875332075424*x.^2 - 0.005037847776532191*x.^3 +...
    %                     0.0001692253268397948*x.^4);

                    %coil_offset connection
                     y(ind) = y(ind) + (x-(360-coil_offset(13))>0).*(x<=0).*...
                         19.0519/verticalscale;
    
                    %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<26).*...
                        -(-19.0519/verticalscale + (- 0.8803557826834764*x + 0.014838875332075424*x.^2 - 0.005037847776532191*x.^3 +...
                        0.0001692253268397948*x.^4)*(-0.6179+2.2031*verticalscale-0.6538*verticalscale^2)); %.93

                     y(ind) = y(ind) + (x>=26).*(x<=64).*...
                        -(-43.13897558568566 - 1.0886525433210776*(x-21) + 0.3384633114295477*(x-21).^2 - 0.016929027331642556*(x-21).^3 +...
                        0.00034701862849640676*(x-21).^4 - 2.561116083403605E-6*(x-21).^5);
                    end

                    %*****************************rev1 below
                    if vert_current_rev == 1

                    y(ind) = y(ind) + (x<=0).*(x>=-67).*...
                         (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                         0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);

                    y(ind) = y(ind) + (x>0).*(x<23).*...
                        -(-13.084634685954311 - 0.5078525133988221*x + 0.029530708843928746*x.^2 - 0.004732305919679242*x.^3 +...
                        0.00012054141936362747*x.^4);

                    %smoother curve
    %                 y(ind) = y(ind) + (x>0).*(x<23).*...
    %                     -(-19.0519 + (-0.5078525133988221*x + 0.029530708843928746*x.^2 - 0.004732305919679242*x.^3 +...
    %                     0.00012054141936362747*x.^4)*.7);

                    y(ind) = y(ind) + (x>=23).*(x<=64).*...
                        -(-32.510912502003556 - 1.4684157376578684*(x-23) + 0.3073516913396905*(x-23).^2 - 0.01465583397609228*(x-23).^3 +...
                        0.00029706024445705034*(x-23).^4 - 2.1878797546571903E-6*(x-23).^5);
                    end

                    %*************rev0 below
                    if vert_current_rev == 0

                    y(ind) = y(ind) + (x<=0).*(x>=-69).*...
                        (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                        0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);

    %                %minus signs below may need to be fixed
    %                 y(ind) = y(ind) + (x>0).*(x<=20).*...
    %                     -(-13.838258411267354+0.05947239838899692*x-0.07100519794104734*x.^2+0.0018251714087331981*x.^3);

                     %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<=20).*...
                        -(-19.06+(0.05947239838899692*x-0.07100519794104734*x.^2+0.0018251714087331981*x.^3)*0.55);


                    %minus signs below may need to be fixed
                    y(ind) = y(ind) + (x>20).*(x<=66).*...
                        -(-25.94202900068819-1.2330684828778178*(x-20)+0.24761537415091986*(x-20).^2-0.011758456767792856*(x-20).^3+0.00023179910227504207*(x-20).^4-1.61647924389463E-6*(x-20).^5);
                    end
                    
                end

            case 14 %2nd vert transport coil
                
                
                
                if use_splines
                     pp = create_transport_splines_nb(13);
                      %y(ind) = y(ind) + ppval(pp,x);
                     
                     %horizontal section
                     y(ind) = y(ind) + (x<=360).*ppval(pp,x);
                    
                    %ramp between the values from 360-->360.1
                    y(ind) = y(ind) + (x>360).*(x<360.1).*...
                        (ppval(pp,360)-(ppval(pp,360)-coiltwo).*(x-360)/0.1);
                    
                    %ramp between the values from 360.1-->363
                    y(ind) = y(ind) + (x>=360.1).*(x<363).*...
                        (coiltwo+(ppval(pp,363)-coiltwo).*(x-360.1)/2.9);
                    
                    %vertical section
                    y(ind) = y(ind) + (x>=363).*ppval(pp,x);
                    
                               
                    
                else

                     %*****************************rev0/rev2 concatenation below
                    if vert_current_rev == 3
                    y(ind) = y(ind) + (x<=0).*(x>=-67).*...
                         (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                         0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);


    %                 y(ind) = y(ind) + (x>=0).*(x<65).*...
    %                     (15.061316784847765- 1.2652029019479034*x + 0.11486467115660891*x.^2 - 0.008390176189246068*x.^3 + 0.00027622984671112056*x.^4 -...
    %                     4.113417480388124E-6*x.^5 + 2.2470935296260115E-8*x.^6);

                    %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<50).*...
                        (19.0519 + (- 1.2652029019479034*x + 0.11486467115660891*x.^2 - 0.008390176189246068*x.^3 + 0.00027622984671112056*x.^4 -...
                        4.113417480388124E-6*x.^5 + 2.2470935296260115E-8*x.^6)*1.08);

                    y(ind) = y(ind) + (x>=50).*(x<=59).*...
                        (19.06 -1.6740512977777005*x+0.1596506794975819*x.^2-0.01106184280319563*x.^3+0.00036306990649827845*x.^4-...
                            5.537722308312364E-6*x.^5+3.1403594860980533E-8*x.^6);

                    %minus signs below may need to be fixed
                    y(ind) = y(ind) + (x>59).*(x<=92).*...  
                        (-33.374078751779564-0.4354378184557704*(x-59)+0.09912738144033928*(x-59).^2-0.0016851950599533617*(x-59).^3);
                    end

                    %*****************************rev2 below
                    if vert_current_rev == 2
                    y(ind) = y(ind) + (x-(360-coil_offset(14))<=0).*(x-(360-coil_offset(14))>=-67).*...
                         1/verticalscale.*(-0.24894053840627586 + 0.21549342441239006*(x-(360-coil_offset(14))+69) + 0.010610913626239617*(x-(360-coil_offset(14))+69).^2 - 0.0011035186372974687*(x-(360-coil_offset(14))+69).^3 +...
                         0.00005994384121982444*(x-(360-coil_offset(14))+69).^4 - 1.4556975877409068E-6*(x-(360-coil_offset(14))+69).^5 +  1.615819365079346E-8*(x-(360-coil_offset(14))+69).^6 - 6.840008875660139E-11*(x-(360-coil_offset(14))+69).^7);

                      %coil_offset connection
                     y(ind) = y(ind) + (x-(360-coil_offset(14))>0).*(x<=0).*...
                         19.0519/verticalscale;
                     
                     
                     %connect above to below in 1mm (note:  need to change
                     %start of curve below)
%                      y(ind) = y(ind) + (x>0).*(x<=1).*... 
%                      (19.0519/verticalscale - 51.49*x.^3 + 77.2349*x.^4 - 30.894*x.^5);
                     
                     
                     %connect above to below in 2mm
%                      y(ind) = y(ind) + (x>0).*(x<=2).*...
%                      (19.0519/verticalscale - 7.6554*x.^3 + 5.74155*x.^4 - 1.14831*x.^5);

                    %connect above to below in 5mm
%                         y(ind) = y(ind) + (x>0).*(x<=5).*...
%                         (19.0519/verticalscale - 0.666685*x.^3 + 0.200006*x.^4 - 0.0160005*x.^5);
                    
                    %connect above to below in 10mm
%                         y(ind) = y(ind) + (x>0).*(x<=10).*...
%                         (19.0519/verticalscale - 0.111728*x.^3 + 0.0167593*x.^4 - 0.000670371*x.^5);
                    
                     %connect above to below linearly
%                         y(ind) = y(ind) + (x>0).*(x<=1).*...
%                         (19.0519/verticalscale - 5.149/1*x);


                    %true curve  
%                        y(ind) = y(ind) + (x>1).*(x<65).*...
%                         (15.061316784847765- 1.2652029019479034*x + 0.11486467115660891*x.^2 - 0.008390176189246068*x.^3 + 0.00027622984671112056*x.^4 -...
%                         4.113417480388124E-6*x.^5 + 2.2470935296260115E-8*x.^6);

                    %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<65).*...
                        (19.0519/verticalscale + (- 1.2652029019479034*x + 0.11486467115660891*x.^2 - 0.008390176189246068*x.^3 + 0.00027622984671112056*x.^4 -...
                        4.113417480388124E-6*x.^5 + 2.2470935296260115E-8*x.^6)*(1.53-0.575*verticalscale+0.125*verticalscale^2)); %1.08

                    y(ind) = y(ind) + (x>=65).*(x<=96).*...
                        (-31.452259174298774 - 1.2702262032678195*(x-63) + 0.2298292163194396*(x-63).^2 - 0.008008378549751036*(x-63).^3 +...
                        0.00009268801863835773*(x-63).^4);
                    end
                     %*****************************rev1 below
                    if vert_current_rev == 1
                    y(ind) = y(ind) + (x<=0).*(x>=-67).*...
                         (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                         0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);

    %                 y(ind) = y(ind) + (x>0).*(x<=63).*... 
    %                     (18.615428355372888- 1.9595331073062283*x + 0.19985515658683706*x.^2 - 0.012084215840939057*x.^3 + 0.0003463290473478845*x.^4 -...
    %                     4.70102884611014E-6*x.^5 + 2.4159675720810597E-8*x.^6);

                    %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<=63).*... 
                        (19.0519 + (- 1.9595331073062283*x + 0.19985515658683706*x.^2 - 0.012084215840939057*x.^3 + 0.0003463290473478845*x.^4 -...
                        4.70102884611014E-6*x.^5 + 2.4159675720810597E-8*x.^6)*1);

                    y(ind) = y(ind) + (x>=63).*(x<=96).*... 
                        (-31.47119251414051 - 1.2693831431654374*(x-63) + 0.229993850333604*(x-63).^2 - 0.008019943330503572*(x-63).^3 +...
                        0.00009288057340950048*(x-63).^4);
                    end

                    %********************rev0 below
                    if vert_current_rev == 0
                    y(ind) = y(ind) + (x<=0).*(x>=-69).*...
                        (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
                        0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);

    %                 %minus signs below may need to be fixed
    %                 y(ind) = y(ind) + (x>0).*(x<=59).*...
    %                     (16.960938781084813 -1.6740512977777005*x+0.1596506794975819*x.^2-0.01106184280319563*x.^3+0.00036306990649827845*x.^4-...
    %                         5.537722308312364E-6*x.^5+3.1403594860980533E-8*x.^6);
    %                     
                        %smoother curve
                    y(ind) = y(ind) + (x>0).*(x<=59).*...
                        (19.06 -1.6740512977777005*x+0.1596506794975819*x.^2-0.01106184280319563*x.^3+0.00036306990649827845*x.^4-...
                            5.537722308312364E-6*x.^5+3.1403594860980533E-8*x.^6);

                    %minus signs below may need to be fixed
                    y(ind) = y(ind) + (x>59).*(x<=92).*...  
                        (-33.374078751779564-0.4354378184557704*(x-59)+0.09912738144033928*(x-59).^2-0.0016851950599533617*(x-59).^3);
                    end
                    
                end
                
            case 15 %3rd vert transport coil
               
                if use_splines
                     pp = create_transport_splines_nb(14);
                      %y(ind) = y(ind) + ppval(pp,x);
                     
                       %horizontal section
                     y(ind) = y(ind) + 0*(x<=360).*ppval(pp,x);
                    
                    %ramp between the values from 360-->360.1
                    y(ind) = y(ind) + (x>360).*(x<360.1).*...
                        (0.*(x-360)/0.1);
                    
                    %ramp between the values from 360.1-->363
                    y(ind) = y(ind) + (x>=360.1).*(x<365).*...
                        (0+(ppval(pp,365)+0).*(x-360.1)/4.9);
                    
                    %vertical section
                    y(ind) = y(ind) + (x>=365).*ppval(pp,x);
                    
                else
                
                     %*****************************rev0/rev2 concatenation below
                    if vert_current_rev == 3
                    %smoother curve 
                    y(ind) = y(ind) + (x>=0).*(x<=23).*...
                        1/verticalscale.*(0+ (0.07653548019444462*x + 0.12307976604235762*x.^2 - 0.0034234185654575815*x.^3)*1.75);

    %                 y(ind) = y(ind) + (x>=0).*(x<=23).*...
    %                     (18.850478905609116+ 0.07653548019444462*x + 0.12307976604235762*x.^2 - 0.0034234185654575815*x.^3);

                    y(ind) = y(ind) + (x>23).*(x<=50).*...
                        (42.64309332201683+ 1.5138311436848597*(x-21) - 0.4371306410120366*(x-21).^2 + 0.026353588424580635*(x-21).^3 - 0.0007780942193956761*(x-21).^4 +...
                        0.00001229906810546282*(x-21).^5 - 9.97537818197219E-8*(x-21).^6 + 3.2606551700630824E-10*(x-21).^7);

                     y(ind) = y(ind) + (x>50).*(x<=100).*... 
                        (26.57914422544793 -1.114628270812311*(x-28)-0.03140520264627124*(x-28).^2+0.006020772968931128*(x-28).^3-0.00028532386557755546*(x-28).^4+...
                            6.2150178590944775E-6*(x-28).^5-6.557536075206112E-8*(x-28).^6+2.709367015136489E-10*(x-28).^7);

                    y(ind) = y(ind) + (x>100).*(x<=145).*...    
                        (-29.27906767092452+0.08512921151928889*(x-100)+0.15113776915766508*(x-100).^2-0.008452909182811094*(x-100).^3+0.0001796339300691302*(x-100).^4-...
                            1.340528229129355E-6*(x-100).^5);
                    end

                    %*****************************rev2 below
                    if vert_current_rev == 2
                    %smoother curve 
                    y(ind) = y(ind) + (x>=0).*(x<=23).*...
                        (0+ (0.07653548019444462*x + 0.12307976604235762*x.^2 - 0.0034234185654575815*x.^3)*1.75);

    %                 y(ind) = y(ind) + (x>=0).*(x<=23).*...
    %                     (18.850478905609116+ 0.07653548019444462*x + 0.12307976604235762*x.^2 - 0.0034234185654575815*x.^3);

                    y(ind) = y(ind) + (x>23).*(x<=101).*...
                        (42.64309332201683+ 1.5138311436848597*(x-21) - 0.4371306410120366*(x-21).^2 + 0.026353588424580635*(x-21).^3 - 0.0007780942193956761*(x-21).^4 +...
                        0.00001229906810546282*(x-21).^5 - 9.97537818197219E-8*(x-21).^6 + 3.2606551700630824E-10*(x-21).^7);

                    y(ind) = y(ind) + (x>101).*(x<=145).*... 
                        (-21.135037022697375 - 0.5566506067075936*(x-100) + 0.15671503792138652*(x-100).^2 - 0.007647921704816918*(x-100).^3 +...
                        0.00015383928635804908*(x-100).^4 - 1.111471413554831E-6*(x-100).^5);
                    end


                 %*****************************rev1 below
                    if vert_current_rev == 1
    %                 y(ind) = y(ind) + (x>=0).*(x<=24).*... 
    %                     (14.385035518049165 - 0.2910960141433065*x + 0.09350763992080242*x.^2 - 0.002018013564683889*x.^3);

                    %smoother curve
                    y(ind) = y(ind) + (x>=4).*(x<=24).*... 
                        (0 + (-0.2910960141433065*x + 0.09350763992080242*x.^2 - 0.002018013564683889*x.^3)*1.8);

                    y(ind) = y(ind) + (x>24).*(x<=100).*... 
                        (33.228717345384936+ 1.2472278492485915*(x-24) - 0.3464266900200403*(x-24).^2 + 0.021492115288838144*(x-24).^3 - 0.0006665280249327951*(x-24).^4 +...
                        0.000011130546486753431*(x-24).^5 - 9.547801511709915E-8*(x-24).^6 + 3.2983310320099297E-10*(x-24).^7);

                    y(ind) = y(ind) + (x>100).*(x<=145).*... 
                        (-21.135037022697375 - 0.5566506067075936*(x-100) + 0.15671503792138652*(x-100).^2 - 0.007647921704816918*(x-100).^3 +...
                        0.00015383928635804908*(x-100).^4 - 1.111471413554831E-6*(x-100).^5);
                    end
                    %*****************************rev0 below
                    if vert_current_rev == 0
    %                 y(ind) = y(ind) + (x>=0).*(x<=28).*...  
    %                     (14.035113352825304 -0.1629088948989349*x+0.08300820420415693*x.^2-0.002196443032212637*x.^3);

                    %smooth curve
                    y(ind) = y(ind) + (x>=0).*(x<=28).*...  
                        (-0.1629088948989349*x+0.08300820420415693*x.^2-0.002196443032212637*x.^3)*2.15;


                    y(ind) = y(ind) + (x>28).*(x<=100).*... 
                        (26.57914422544793 -1.114628270812311*(x-28)-0.03140520264627124*(x-28).^2+0.006020772968931128*(x-28).^3-0.00028532386557755546*(x-28).^4+...
                            6.2150178590944775E-6*(x-28).^5-6.557536075206112E-8*(x-28).^6+2.709367015136489E-10*(x-28).^7);

                    y(ind) = y(ind) + (x>100).*(x<=145).*...    
                        (-29.27906767092452+0.08512921151928889*(x-100)+0.15113776915766508*(x-100).^2-0.008452909182811094*(x-100).^3+0.0001796339300691302*(x-100).^4-...
                            1.340528229129355E-6*(x-100).^5);
                    end
                    
                 end
                
            case 16 %4th vert transport coil
                
                 if use_splines
                    
%                      pp = create_transport_splines_nb(15);
%                     %use spline
%                      y(ind) = y(ind) + (x<510).*ppval(pp,x);
%                      
%                      %connect spline to fit
%                      y(ind) = y(ind) + (x>=510).*...
%                         (ppval(pp,510)+(-ppval(pp,510)).*(x-510)/24);
                     
                     
                     if connect_spline_to_fit == 0
                    pp = create_transport_splines_nb(15);
                                        
                    %curves
                    y(ind) = y(ind) + (x<=533.9).*ppval(pp,x);
                    
                    %ramp to zero over last 0.1mm
                     y(ind) = y(ind) + (x>533.9).*(ppval(pp,533.9)+(+0.01-ppval(pp,533.9)).*(x-533.9)/0.1);
                                       
                        
                    
                     elseif connect_spline_to_fit == 1
                     %ver transport to 170mm
                      pp = create_transport_splines_nb(15);
                     y(ind) = y(ind) + (x<=533.9).*ppval(pp,x);
                     
                     %smoothly connect spline to fit over the last 4mm
                    y(ind) = y(ind) + (x>533.9).*...
                        (ppval(pp,533.9)+(fit_coil_14-ppval(pp,533.9)).*(x-533.9)/.1);
                    
                     end             
                    
                  
                    
                else
                
                     %*****************************rev0/rev2 concatenation below
                    if vert_current_rev == 3
                    y(ind) = y(ind) + (x>=23).*(x<=49.5).*...
                        (-1.8148370790233872 + 1.5144973503087735*(x-21) - 0.09524317895103225*(x-21).^2 + 0.003065077128389471*(x-21).^3 -...
                         0.000021150874057021092*(x-21).^4 - 1.7732463662989254E-7*(x-21).^5);

                     y(ind) = y(ind) + (x>49.5).*(x<=66).*... 
                        (-0.2576648428865376+1.0220527679882903*(x-23)-0.02715927598266327*(x-23).^2-0.0009910689389852595*(x-23).^3+0.0001028224130901927*(x-23).^4-...
                            1.58931002093577E-6*(x-23).^5);

                     y(ind) = y(ind) + (x>66).*(x<=135).*...
                        (32.70282097851701 +0.07469869898883208*(x-66)-0.18137828396713512*(x-66).^2+0.010863684110019468*(x-66).^3-0.0003634470557875602*(x-66).^4+...
                            7.1083970085635875E-6*(x-66).^5-7.240801400199198E-8*(x-66).^6+2.9149046071876575E-10*(x-66).^7);

    %                  y(ind) = y(ind) + (x>135).*(x<=174).*... 
    %                     (-22.08431859763566-0.5239835660990726*(x-135)-0.13080969712019103*(x-135).^2+0.017333407037712963*(x-135).^3-0.0007052410835237223*(x-135).^4+...
    %                         0.000012469136759791687*(x-135).^5-8.292190209162253E-8*(x-135).^6);

                    y(ind) = y(ind) + (x>135).*(x<=174).*... 
                        (-10.51-0.5239835660990726*(x-135)-0.13080969712019103*(x-135).^2+0.017333407037712963*(x-135).^3-0.0007052410835237223*(x-135).^4+...
                            0.000012469136759791687*(x-135).^5-8.292190209162253E-8*(x-135).^6)*2.0;
                    end

                    %*****************************rev2 below
                    if vert_current_rev == 2
                    y(ind) = y(ind) + (x>=23).*(x<=67).*...
                        (-1.8148370790233872 + 1.5144973503087735*(x-21) - 0.09524317895103225*(x-21).^2 + 0.003065077128389471*(x-21).^3 -...
                         0.000021150874057021092*(x-21).^4 - 1.7732463662989254E-7*(x-21).^5);

                      y(ind) = y(ind) + (x>67).*(x<=144).*... 
                        (31.322029646462475+ 1.5262939088106109*(x-63) - 0.30913067382716536*(x-63).^2 + 0.016413897570273107*(x-63).^3 - 0.000474985466153365948*(x-63).^4 +...
                        7.829400899713762E-6*(x-63).^5 - 6.789474993761223E-8*(x-63).^6 + 2.3795549285456477E-10*(x-63).^7);

    %                 y(ind) = y(ind) + (x>143).*(x<=174).*... 
    %                     (-28.597800892933428 - 0.4356090542377702*(x-143) + 0.09839829203139863*(x-143).^2 - 0.0011823196349129614*(x-143).^3 -...
    %                     0.00015271894271541334*(x-143).^4 + 5.986775669395166E-6*(x-143).^5 - 6.628793898737863E-8*(x-143).^6);

                        y(ind) = y(ind) + (x>144).*(x<=174).*... 
                        (-28.597800892933428/1.64 - 0.4356090542377702*(x-143) + 0.09839829203139863*(x-143).^2 - 0.0011823196349129614*(x-143).^3 -...
                        0.00015271894271541334*(x-143).^4 + 5.986775669395166E-6*(x-143).^5 - 6.628793898737863E-8*(x-143).^6)*1.64;
                    end


                   %*****************************rev1 below
                    if vert_current_rev == 1
                    y(ind) = y(ind) + (x>=28).*(x<=63).*... 
                        (-1.718444191533655 + 1.5860461262562313*(x-26) - 0.12025043812300588*(x-26).^2 + 0.0055343768687731295*(x-26).^3 -...
                        0.00008513854608588902*(x-26).^4 + 2.7046566422013455E-7*(x-26).^5);

                    y(ind) = y(ind) + (x>=63).*(x<=143).*... 
                        (31.322029646462475+ 1.5262939088106109*(x-63) - 0.30913067382716536*(x-63).^2 + 0.016413897570273107*(x-63).^3 - 0.000474985466153365948*(x-63).^4 +...
                        7.829400899713762E-6*(x-63).^5 - 6.789474993761223E-8*(x-63).^6 + 2.3795549285456477E-10*(x-63).^7);

    %                 y(ind) = y(ind) + (x>143).*(x<=174).*... 
    %                     (-28.597800892933428 - 0.4356090542377702*(x-143) + 0.09839829203139863*(x-143).^2 - 0.0011823196349129614*(x-143).^3 -...
    %                     0.00015271894271541334*(x-143).^4 + 5.986775669395166E-6*(x-143).^5 - 6.628793898737863E-8*(x-143).^6);

                    y(ind) = y(ind) + (x>143).*(x<=174).*... 
                        (-28.597800892933428/1.64 - 0.4356090542377702*(x-143) + 0.09839829203139863*(x-143).^2 - 0.0011823196349129614*(x-143).^3 -...
                        0.00015271894271541334*(x-143).^4 + 5.986775669395166E-6*(x-143).^5 - 6.628793898737863E-8*(x-143).^6)*1.64;
                    end

                    %*****************************rev0 below
                    if vert_current_rev == 0
                    y(ind) = y(ind) + (x>=23).*(x<=66).*... 
                        (-0.2576648428865376+1.0220527679882903*(x-23)-0.02715927598266327*(x-23).^2-0.0009910689389852595*(x-23).^3+0.0001028224130901927*(x-23).^4-...
                            1.58931002093577E-6*(x-23).^5);

                     y(ind) = y(ind) + (x>66).*(x<=135).*...
                        (32.70282097851701 +0.07469869898883208*(x-66)-0.18137828396713512*(x-66).^2+0.010863684110019468*(x-66).^3-0.0003634470557875602*(x-66).^4+...
                            7.1083970085635875E-6*(x-66).^5-7.240801400199198E-8*(x-66).^6+2.9149046071876575E-10*(x-66).^7);

    %                  y(ind) = y(ind) + (x>135).*(x<=174).*... 
    %                     (-22.08431859763566-0.5239835660990726*(x-135)-0.13080969712019103*(x-135).^2+0.017333407037712963*(x-135).^3-0.0007052410835237223*(x-135).^4+...
    %                         0.000012469136759791687*(x-135).^5-8.292190209162253E-8*(x-135).^6);

                    y(ind) = y(ind) + (x>135).*(x<=174).*... 
                        (-10.51-0.5239835660990726*(x-135)-0.13080969712019103*(x-135).^2+0.017333407037712963*(x-135).^3-0.0007052410835237223*(x-135).^4+...
                            0.000012469136759791687*(x-135).^5-8.292190209162253E-8*(x-135).^6)*2.0;
                    end               
                    
                 end

            case 17 %bottom qp coil (15u FET and also controls 15d)
                
                %this is the negative of the current in the 
                %bottom coil where positive current direction is when 
                %these two coils are in anti-helmholtz                
                if use_kitten ==1;
                 
                  if use_splines
                    
                     
                     pp = create_transport_splines_nb(16);
                     
                     if connect_spline_to_fit == 0
                     
                        if final_handoff == 0 || final_handoff == 1
                    
                            y(ind) = y(ind) - ppval(pp,x);
                        
                        elseif final_handoff == 2
                            
                            y(ind) = y(ind) - (x<=handoff_position).*ppval(pp,x);

                            y(ind) = y(ind) + (x>handoff_position).*60;

                        end
                        
                     elseif connect_spline_to_fit == 1
                        %ver transport to 170mm
                          pp = create_transport_splines_nb(16);
                         y(ind) = y(ind) - (x<=533.9).*ppval(pp,x);

                         %smoothly connect spline to fit over the last 4mm
                        y(ind) = y(ind) - (x>533.9).*...
                            (ppval(pp,533.9)+(fit_coil_15-ppval(pp,533.9)).*(x-533.9)/.1);
                     end
                     
                 else
                
                    if final_handoff == 0 || final_handoff == 1
                     
                    y(ind) = y(ind) - qp_currents(x,0);
                        
                    elseif final_handoff == 2
                        
                    y(ind) = y(ind) - (qp_currents(x,0)>=-1.1).*qp_currents(x,0);
                    
                    y(ind) = y(ind) + (qp_currents(x,0)<-1.1).*(qp_currents(x,0)>=-10.1)*15;
                    
                     y(ind) = y(ind) + (qp_currents(x,0)<-10.1)*25;
                    
                    else
                        error('invalid final handoff type')
                    end
                    
                 end
                
                elseif use_kitten==0;
                  
                    pp = create_transport_splines_nb(16);
                    
                    % active if current <0
                    y(ind) = y(ind) - (ppval(pp,x)>=0).*ppval(pp,x);
                    
                    % closed if current is positive?
                    y(ind) = y(ind) - (ppval(pp,x)<0).*0; 
                     
                elseif use_kitten == 2;
                    
                    %coil 15 h-bridge here
                     pp = create_transport_splines_nb(16);
                    % y(ind) = y(ind) - ppval(pp,x);
                    
                    %curves
                    y(ind) = y(ind) - (x<=533.9).*ppval(pp,x);
                    
                    %make 15 the same current as 16 at end and equal to 10A
                    final_value15 = 10.9; %to make currents equal 
                     y(ind) = y(ind) - (x>533.9).*(ppval(pp,533.9)+(-final_value15 - ppval(pp,533.9)).*(x-533.9)/0.1);
                     
                    
                end
                 
            case 18 %top qp coil (FET 16)
               
                %this is just the current in the top coil
                
                if use_kitten ==1;
                
                if use_splines
                    
                    pp = create_transport_splines_nb(17);
                    
                    if connect_spline_to_fit == 0
                    
                    y(ind) = y(ind) + ppval(pp,x);
                    
                    elseif connect_spline_to_fit == 1
                    %ver transport to 170mm
                      pp = create_transport_splines_nb(17);
                     y(ind) = y(ind) + (x<=533.9).*ppval(pp,x);
                     
                     %smoothly connect spline to fit over the last 4mm
                    y(ind) = y(ind) + (x>533.9).*...
                        (ppval(pp,533.9)+(fit_coil_16-ppval(pp,533.9)).*(x-533.9)/.1);
                    end
                    
                else
                
                    y(ind) = y(ind) + qp_currents(x,1);
                                        
                end
                
                elseif use_kitten ==0;
                   
                    %put non kitten stuff here  
                    pp = create_transport_splines_nb(17);
                    y(ind) = y(ind) + ppval(pp,x);
                                     
                    
                elseif use_kitten == 2;
                    
                    %coil 15 h-bridge here
                    pp1 = create_transport_splines_nb(16);
                    pp2 = create_transport_splines_nb(17);
                    
                    %curves
                    y(ind) = y(ind) + (x<=533.9).*ppval(pp2,x);
                    
                    %make 16 the same current as 15 at end
                    final_value16 = 10.9; %to make currents equal 
                     y(ind) = y(ind) + (x>533.9).*(ppval(pp2,533.9)+(final_value16-ppval(pp2,533.9)).*(x-533.9)/0.1);
                                       
                    
                end
                 
            case 19 %kitten FET
               
               
                if use_kitten == 1;
                
                if use_splines
                    
                    pp1 = create_transport_splines_nb(16);
                    pp2 = create_transport_splines_nb(17);
                    
                    if final_handoff == 0
                        
                      y(ind) = y(ind) + (ppval(pp1,x)+ppval(pp2,x));
                        
                    elseif final_handoff == 1 || final_handoff == 2
                    
                    y(ind) = y(ind) + (x>handoff_position).*(ppval(pp1,x)+ppval(pp2,x));
                    
                    y(ind) = y(ind) + (x<=handoff_position).*60;
                    
                    end
                                       
                    
                else

                    %this is the current of the top coil minus the current in
                    %the bottom coil
                    
                    if final_handoff == 0
                    
                    y(ind) = y(ind) + (qp_currents(x,1)+qp_currents(x,0));
                    
                    elseif final_handoff == 1 || final_handoff == 2
                    
                      y(ind) = y(ind)+ (x>=65).*(x<=90).*(20+(36-20)/(90-65).*(x-65)); 
                      
                      y(ind) = y(ind)+ (x>90).*(x<=115).*36;
                      
                      y(ind) = y(ind)+ (x>115).*(x<=143).*(36+(36-26)/(115-143).*(x-115));
                      
                      y(ind) = y(ind)+ (x>143).*(x<=144).*26;
                        
                      y(ind) = y(ind) + (x>144).*(x<=176).*(qp_currents(x,1)+qp_currents(x,0));
                        
                        
%                     y(ind) = y(ind) + (qp_currents(x,0)<=0).*(qp_currents(x,1)+qp_currents(x,0));
%                     
%                     y(ind) = y(ind) + (qp_currents(x,0)>0).*(qp_currents(x,0)<=12).*27;
%                     
%                     y(ind) = y(ind) + (qp_currents(x,0)>12).*34;
                    
                    else
                        error('invalid final handoff type')
                        
                    end
                                        
                end
                
                elseif use_kitten == 0;
                    
                    pp = create_transport_splines_nb(16);
                    
                   
                    % switch is open if current is negative?
                    y(ind) = y(ind) + (ppval(pp,x)>=0.01).*60;
                    
                    % switch is closed if current is positive?
                    y(ind) = y(ind) + (ppval(pp,x)<0.01).*0;
                    
                elseif use_kitten == 2;
                    
                    %coil 15 h-bridge here
                    %do nothing.  channel not connected.
                                                           
                end
                    
                    
           case 20 %new FET
               
               if use_kitten == 1;
                   
               %this channel is inactive if not using kitten
               
               elseif use_kitten ==0;
               
               pp = create_transport_splines_nb(16);
                    
                    % closed if current is negative
                    y(ind) = y(ind) - (ppval(pp,x)>0).*0;
               
                    % active if current >0
                    y(ind) = y(ind) - (ppval(pp,x)<=0).*ppval(pp,x);
                    
                   
                    
               
               
               end      
        
               
                %check for min conditions
                ind2 = (y<=0 & y~=nullval);
                y(ind2) = -0.2;
                
                
                
            otherwise 
                
                error('Invalid channel');
                
        end
       
        function y = qp_currents(x,index)
            %index: 1 is top coil, 0 is bottom coil
            
            y = zeros(size(x));
            
            if index==1
                
                if vert_current_rev == 2
               
                y = y + (x>=98).*(x<=142).*... 
                    (-1.251614977548714 + 1.1415565356894957*(x-96) - 0.017085927728184742*(x-96).^2 - 0.001635975940584514*(x-96).^3 +...
                    0.00007577594876871123*(x-96).^4 - 8.104565146404895E-7*(x-96).^5);
                
                y = y + (x>142).*(x<=174).*... 
                    (28.112183882432376+ 0.6059818037651911*(x-142) - 0.09496077478369246*(x-142).^2 - 0.00006193032575588043*(x-142).^3 +...
                    0.00021128685952547435*(x-142).^4 - 7.041274789902348E-6*(x-142).^5 + 7.238217833468994E-8*(x-142).^6);
                end
                
                %*****************************
                if vert_current_rev == 0 || vert_current_rev == 1 || vert_current_rev == 3
                
                 y = y + (x>=92).*(x<=138).*... 
                    (-1.3933048433956314+1.9170339866332295*(x-92)-0.08741203724647845*(x-92).^2+0.0009440722200383801*(x-92).^3+0.00002519895538810482*(x-92).^4-...
                        3.9420176937309534E-7*(x-92).^5);
                 
                 y = y + (x>138).*(x<=174).*...
                    (25.380015360377875 +0.8270816166519087*(x-138)+0.004130396345414532*(x-138).^2-0.010226492418791576*(x-138).^3+0.0005905332132747151*(x-138).^4-...
                     0.000013184801422214478*(x-138).^5+1.0714734735744564E-7*(x-138).^6);
                end
                 
            elseif index==0
                
                if vert_current_rev == 2
                y = y + (x>=68).*(x<=100).*... 
                    (-1.0377904632301045 + 0.9735602426784792*(x-66) - 0.008714495031733945*(x-66).^2 - 0.001970698284763165*(x-66).^3 +...
                    0.00011716154509784856*(x-66).^4 - 1.7513038913475032E-6*(x-66).^5);
                
                y = y + (x>100).*(x<=176).*... 
                    (21.411781182582278+ 0.4307490378578966*(x-100) - 0.14558085385680058*(x-100).^2 + 0.007652928321718914*(x-100).^3 - 0.0001821716477970409*(x-100).^4 +...
                    2.036843938707042E-6*(x-100).^5 - 8.685492810560131E-9*(x-100).^6);
                end
                 %*****************************
                
                if vert_current_rev == 0 || vert_current_rev == 1 || vert_current_rev == 3
                 y = y + (x>=67).*(x<=99).*...
                    (-0.5242843400416173+1.347537639897927*(x-67)-0.07659789635587849*(x-67).^2+0.004452547880334847*(x-67).^3-0.00007723202546822751*(x-67).^4);
  
                y = y + (x>99).*(x<=176).*...
                    (28.756390124608473 +0.29977790350549016*(x-99)-0.22879972905714865*(x-99).^2+0.015074078677112161*(x-99).^3-0.000456931051691088*(x-99).^4+...
                        7.205528701427198E-6*(x-99).^5-5.733395769127594E-8*(x-99).^6+1.8186535177502566E-10*(x-99).^7);
                end
                
                else
                error('QP Current called with incorrect index')
            end
            
        end
        
    end



end