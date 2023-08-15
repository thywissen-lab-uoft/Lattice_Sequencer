%-----
%Author: David McKay
%Created: July 2009
%Summary: This function returns the 3 column array for the analog update for a given cloud position.
%Position and time can be 1D arrays. Position is in mm.
%Horizontal is from 0->360mm and vertical is from 360mm->534mm
%Version: 2.0, May 2011
%Vertion Notes:
%This version uses spline curves ONLY and is for CATS 2
%
%
% Author : C Fujiwara
%
% This is me trying to make it ismpler
%------
function y = stupidtransport(time,position)

global seqdata;

%% Spline Parameters

% Location of splines (MOVED!!! CF)
curpath = fileparts(mfilename('fullpath'));
mydir = 'transport_splines';
filename1 = 'rev48coilone.txt';
filename2 = 'rev48coiltwo.txt';

% Load the splines WHAT ARE THESE?
coilone = dlmread(fullfile(curpath,mydir,filename1) ,',',0,1);
coiltwo = dlmread(fullfile(curpath,mydir,filename2),',',0,1);

%% Some Parameters

num_channels = 23;                              % number transport channels
num_analog_channels = 21;                       % number analog channels
num_dig_channels = 2;                           % number digital channels (these MUST be at the end)

coil_scale_factors = 1*ones(1,num_channels);    % scaling of the max current in each coil
coil_widths = ones(1,num_channels);             % widths of each of the coil curves

% Center axis position of each coil in mm (why are there 23 entries?0
coil_offset = [0 30 41 43 85 116 148 179 212 242 274 338 350 365 365 365 ...
    365 365 365 365 365 365 365]; 

% CF : Why does coil offset get overwritten?
coil_offset(1:13) = 0;          % coil_offset(12:end) = 0;
coil_offset(14:end) = 0;        % coil_offset(12:end) = 0;
coil_range = ones(2,num_channels);  % relevant range of the given coil (2xnumber of channels)


% Resistance of each coil (CF : This seems not very useful to caculate since
% thermal parameters are difficult to predict)
coil_resistance = [0 375 418 100 100 100 100 100 100 100 100 ...
    100 100 188 173 173 173+70 310 310 310 310];
% Also kind of dumb since the FETs change.
max_fet_power = [0 700 5000 5000 700 700 700 700 700 700 700 ...
    5000 5000 700 208 208 208 700 5000 700 700]; 

% channels the coils correspond to on the ADWIN
% Negative corresponds to a digital channel
transport_channels = [18 7:17 9 22:24 20:21 1 3 17 -22 -28];
% corresponding coils : [FF Push MOT 3:11 3 12a-13 14 15 16 kitten 11]

% Whether to enable each channel
enable = ones(1,23);

%% Defining the Coil Ranges
% coil_range is 2xN
% The first row is where the control starts and the seconds row is where it
% finishes in position?

%FEED FORWARD
coil_range(1,1) = 0;
coil_range(2,1) = 539;
coil_widths(1) = 1.0;
coil_scale_factors(1) = 1.00;

%Push Coil Range
coil_range(1,2) = 0; %0
coil_range(2,2) = 100; %50 for non-divergent curves
coil_widths(2) = 1.0;
coil_scale_factors(2) = 1.2; %1.05
coil_offset(2) = 0; %-0.65

%MOT Coil range
coil_range(1,3) = 0;
coil_range(2,3) = 100; %75 for non-divergent curves
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
% coil_scale_factors(10) = 1.0;

%coil 10
%eighth horizontal transport
coil_range(1,11) = 200;
coil_range(2,11) = 330;
coil_scale_factors(11) = 1.0;

%coil 11
%ninth horizontal transport
 coil_range(1,12) = 250; %CHANGE TO coil_range(1,11) = 250;
 coil_range(2,12) = 380; %CHANGE TO coil_range(2,11) = 380;
coil_scale_factors(12) = 1.0; %1.15
coil_widths(12) = 1.0;   %0.99
coil_offset(12) = 0;    %-0.5

%coil 11b
%new extra coil set at end of transport
coil_range(1,13) = 250;
coil_range(2,13) = 380;
coil_scale_factors(13) = 0.96; %0.96 %.93
coil_offset(13) = 3; %0 %6
coil_widths(13) = 0.96;

%% Vertical Transport Ranges

%first vertical transport -- coil 12A
coil_range(1,14) = 260; 
coil_range(2,14) = 430; %430
coil_scale_factors(14) = 1.0; %1.0
coil_offset(14) = 0; 
coil_widths(14) = 1.0; 

%second vertical transport -- coil 12B
coil_range(1,15) = 280; 
coil_range(2,15) = 480; %450 %460
coil_scale_factors(15) = -1.0; %-1.0
coil_offset(15) = 0; 
coil_widths(15) = 1.0; 

%third vertical transport -- coil 13
coil_range(1,16) = 358; 
coil_range(2,16) = 520;
coil_scale_factors(16) = 1.0; %1.1  *rev1*1.0  *rev2* 1.3 SC: 1.1

%fourth vertical transport -- coil 14
coil_range(1,17) = 370; %70
coil_range(2,17) = 539;
coil_scale_factors(17) = 1.0;

%Quadrupole factor
qp_scale_factor = 1.0; %1.0  *rev1*1.15  *rev2* 1.0 SC: 1.1

%bottom qp coil
coil_range(1,18) = 427; %427 
coil_range(2,18) = 539;
coil_scale_factors(18) = 1.0*qp_scale_factor;
coil_offset(18) = 0.00; %0

%top qp coil
defVar('QP_16_scale',[1],'arb.')
coil_range(1,19) = 410; 
coil_range(2,19) = 539; 
coil_scale_factors(19) = 1*qp_scale_factor*getVar('QP_16_scale');

%kitten 
coil_range(1,20) = 427; 
coil_range(2,20) = 539;
coil_scale_factors(20) = 0.95*qp_scale_factor;
coil_offset(20) = -0.75; %-0.75

%power dump into 8th horizontal
coil_range(1,21) = 370; 
coil_range(2,21) = 430;
coil_scale_factors(21) = 1.0;
coil_offset(21) = 0; 

%15/16 switch 
%NOTE: This is a "special" channel
coil_range(1,22) = 460; 
coil_range(2,22) = 539;

%coil 3 coil 11b relay switch
%NOTE: This is a "special" channel...switch relay at 210
coil_range(1,23) = 200; 
coil_range(2,23) = 220;

% %total current 
% coil_range(1,20) = 0; 
% coil_range(2,20) = 534;

%check the bounds on position
if (sum(position<-0.1));    
    error('negative Position')
elseif (sum(position>539.1));
    error('position too far')
end

%% Iterate and assign current values

%This value means that this channel value can be neglected from the update
%array
nullval = -100;

% preallocate the full array (we are going to output the current in each
% channel as a function of time); only need to allocate space for those
% channels that are enabled.
currentarray = zeros(length(time)*sum(enable),3); %[time,channel,value]

%go through for each channel
j = 0;
for i = 1:num_channels
    % indices for the current channel
    channel_indices = ((i-1)*length(time)+1):(i*length(time));         
    if i==21
        %for future considerations to keep current constant
        currentarray(channel_indices,3) = nullval;
        continue;
    end    
    
    % At each position get the value of the current
    currentarray(channel_indices,1) = time;
    currentarray(channel_indices,2) = transport_channels(i);
    currentarray(channel_indices,3) = channel_current(i,position,coil_offset(i),...
        coil_widths(i),coil_range(:,i));
        
   
    % If channel is negative it is a digital channel
    if transport_channels(i)<0 
        %see when it switches and set the digital channel high or low
        f = currentarray(channel_indices(2:end),3)-currentarray(channel_indices(1:(end-1)),3); % The difference in value (be careful of -100's)        
        g = currentarray(channel_indices(1:(end-1)),1).*(f~=0);        
        ff = nonzeros(f);
        gg = nonzeros(g);        
        disp(['digital channel ' num2str(abs(transport_channels(i)))]);
        disp('old');
        for j = 1:length(ff)
            if ff(j)==2
                %set digital high
                setDigitalChannel(gg(j),transport_channels(i)*-1,1);    
                disp(['Ch' num2str(abs(transport_channels(i))) ' ' num2str(gg(j)) ',' num2str(1)]);

            elseif ff(j)==-2
                %set digital low
                setDigitalChannel(gg(j),transport_channels(i)*-1,0);    
                disp(['Ch' num2str(abs(transport_channels(i))) ' ' num2str(gg(j)) ',' num2str(0)]);

            end
        end    
        
        disp('New');
        
        % Alternative way of doing digital by CF which makes more sense
        ch = abs(transport_channels(i));            % digital channel number
        vals = currentarray(channel_indices,:);        
        % Remove all references to the null value
        binds = [vals(:,3)==nullval];
        vals(binds,:)=[];        
        dV = diff(vals(:,3));
        inds = find(dV~=0); % Indeces where a change is perceived
        for kk=1:length(inds)
            n = inds(kk);
            if dV(n)>0; state = 1;else;state = 0;end            
            t = vals(n+1,1);            
%            setDigitalChannel(gg(j),abs(transport_channels(i)),state);  
            disp(['Ch' num2str(abs(transport_channels(i))) ' ' num2str(t) ',' num2str(state)]);
        end              
    end
    
    %voltage channel, save for calculating powers later
    if i==1 
        voltages = currentarray(channel_indices,3);
    end
    
    if (i<=num_analog_channels)          
        %check max FET power is not exceeded
        %NOTE: This should not be viewed as perfect...FET's may still fail
        if (transport_channels(i)~=18 && transport_channels(i)~=3) %skip the voltage and kitten channels
            
            if sum(((abs(currentarray(channel_indices,3)).*voltages-currentarray(channel_indices,3).^2*coil_resistance(i)/1000).*(currentarray(channel_indices,3)~=nullval))>max_fet_power(i))
                warning(['FET Power exceeded for channel:' num2str(transport_channels(i))]);
            end
            
        end       
        %convert currents to channel voltages
        currentarray(channel_indices,3) = seqdata.analogchannels(transport_channels(i)).voltagefunc{2}(currentarray(channel_indices,3).*coil_scale_factors(i)).*(currentarray(channel_indices,3)~=nullval)+...
            currentarray(channel_indices,3).*(currentarray(channel_indices,3)==nullval);
        %check the voltages are in range
        if sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)>seqdata.analogchannels(transport_channels(i)).maxvoltage))||...
                sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)<seqdata.analogchannels(transport_channels(i)).minvoltage))
            error(['Voltage out of range when computing transport Channel:' num2str(transport_channels(i))]);
        end
    end      
end

% Remove unused entries and only return the analog channels
ind = logical(currentarray(1:length(time)*num_analog_channels,3)~=nullval);
currentarray = currentarray(ind,:);


% Return
y = currentarray;
%% 

% CF : I belive this function is the real meat which is where we are actually
% use the splines to specify the current value.

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
                % CF: The FF is in some sense, the most complicated because
                % it is non-linear relationship to ALL the currents running
                % from the power supply. It's probably not even a good idea
                % to try to calculate anything.
                %
                % Because we operate the MOSFETs away from saturation for
                % thermal reasons, the MOSFETs are probably close to being
                % modeled as a resistor, whose values depends on the GS
                % voltage. (But the GS votlage controls the current, so
                % does this make a quadratic function more or less?)
    
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
                 MOTvoltage = 10;                  
                 %ramp up and down for the push
                 maxpushvoltage = (30); %24/6.6 %27.66 for 1.2 
                 startpushramp = 10; %10
                 pushramppeak = 43; %40
                 endpushramp = 60; %60                 
                 %steady voltage for horizontal transfer stage
                 horizontalvoltage = 9; %9/6.6 
                 %ramp up and down for the last horiz transport coil
                 maxhorizvoltage = 12.95; %10/6.6
                 starthorizramp = 270; %260
                 peakhorizramp = 310;  %350
                 starthorizrampdown = 340;
                 endhorizramp = 365; %360                     
                 %steady voltage for beginning of vertical transfer
                 beginningverticalvoltage = 10.0; %11/4 %12/4      
                 %=============
                 %BE VERY CAREFUL HERE TO NOT DAMAGE THE BRIDGES!!!!
                 %=============                 
                 %DO NOT GO ABOVE 11.0 volts for the bridges...does not get
                 %more current due to circuit gate voltage limit (~14.3V)
                 
                 %initial_voltage
                 initial_voltage = 10.0;                 
                 num_vert_ramps = 6;                 
                 vert_voltage = zeros(2,num_vert_ramps);
                 vert_volt_pos = zeros(2,num_vert_ramps+1);                 
                                 
                 %ramp 1
                 vert_voltage(1,1) = initial_voltage;
                 vert_voltage(2,1) = 10.5; %10.5
                 vert_volt_pos(1,1) = 365 + 1;
                 vert_volt_pos(2,1) = 365 + 21;
                 
                 %ramp 2
                 vert_voltage(1,2) = vert_voltage(2,1);
                 vert_voltage(2,2) =10.5; %10.5
                 vert_volt_pos(1,2) = vert_volt_pos(2,1);
                 vert_volt_pos(2,2) = 365 + 50;
                 
                 %ramp 3
                 vert_voltage(1,3) = vert_voltage(2,2);
                 vert_voltage(2,3) = 11.25;%11.25
                 vert_volt_pos(1,3) = vert_volt_pos(2,2);
                 vert_volt_pos(2,3) = 365 + 65; %65
                 
                 %ramp 4
                 vert_voltage(1,4) = vert_voltage(2,3);
                 vert_voltage(2,4) = 11.5;11.5; %10.5 11.5
                 vert_volt_pos(1,4) = vert_volt_pos(2,3);
                 vert_volt_pos(2,4) = 365 + 85; %85                
                 
                 %ramp 5
                 vert_voltage(1,5) = vert_voltage(2,4);
                 FF_list = [11.75];11.75;[13];11.75;
                 FF_Voltage = getScanParameter(FF_list, seqdata.scancycle,...
                        seqdata.randcyclelist, 'FF_Voltage_Ramp5','V');
                 vert_voltage(2,5) = FF_Voltage; %13.00 %13.75
                 vert_volt_pos(1,5) = 365+120; %365+110
                 vert_volt_pos(2,5) = 365+140; %365+130     
                 
                 %ramp 6
                 vert_voltage(1,6) = vert_voltage(2,5);
                 vert_voltage(2,6) = 12.25;12.25; %10.0 12.25
                 vert_volt_pos(1,6) = 365+166; %166 %365+160
                 vert_volt_pos(2,6) = 365+174; %365+174
                 
                 %end
                 vert_volt_pos(1,7) = 365+174;

%                %------------------------
%                %horizontal voltage
%                
                 %MOT Voltage
                 y(ind) = y(ind) + MOTvoltage.*(pos(ind)<startpushramp);                 
                 %Ramp up for the push
                 y(ind) = y(ind) + ((maxpushvoltage-MOTvoltage)/(pushramppeak-startpushramp).*(pos(ind)-startpushramp)+MOTvoltage).*(pos(ind)>=startpushramp).*(pos(ind)<pushramppeak);
                 %Ramp down for the middle of the horizontal
                 y(ind) = y(ind) + ((horizontalvoltage-maxpushvoltage)/(endpushramp-pushramppeak).*(pos(ind)-pushramppeak)+maxpushvoltage).*(pos(ind)<endpushramp).*(pos(ind)>=pushramppeak);                 
                 %Steady voltage for the horizontal
                 y(ind) = y(ind) + horizontalvoltage.*(pos(ind)>=endpushramp).*(pos(ind)<starthorizramp);                 
                 %Ramp up at the end of the horizontal
                 y(ind) = y(ind) + ((maxhorizvoltage-horizontalvoltage)/(peakhorizramp-starthorizramp).*(pos(ind)-starthorizramp)+horizontalvoltage).*(pos(ind)>=starthorizramp).*(pos(ind)<peakhorizramp);                 
                 %hold after the ramp
                 y(ind) = y(ind) + maxhorizvoltage.*(pos(ind)>=peakhorizramp).*(pos(ind)<starthorizrampdown);                 
                y(ind) = y(ind) + ((beginningverticalvoltage-maxhorizvoltage)/(endhorizramp-starthorizrampdown).*(pos(ind)-starthorizrampdown)+maxhorizvoltage).*(pos(ind)<endhorizramp).*(pos(ind)>=starthorizrampdown);                
                y(ind) = y(ind) + beginningverticalvoltage.*(pos(ind)<365).*(pos(ind)>=endhorizramp);
                %-----------------
                %Vertical                
                  y(ind) = y(ind) + initial_voltage.*(pos(ind)<vert_volt_pos(1,1)).*(pos(ind)>=365);                  
                    for jj = 1:num_vert_ramps
                         %ramp voltage from previous value
                         vert_volt_slope = (vert_voltage(2,jj)-vert_voltage(1,jj))/(vert_volt_pos(2,jj)-vert_volt_pos(1,jj));                         
                         y(ind) = y(ind) + (vert_volt_slope.*(pos(ind)-vert_volt_pos(1,jj))+ vert_voltage(1,jj)).*(pos(ind)>=vert_volt_pos(1,jj)).*(pos(ind)<vert_volt_pos(2,jj));                         
                         %set voltage in between
                         y(ind) = y(ind) + vert_voltage(2,jj).*(pos(ind)<vert_volt_pos(1,jj+1)).*(pos(ind)>=vert_volt_pos(2,jj));                    
                    end         
                 %------------------------          
            case {2,3,4,5,6,7,8,9,10,11,12} %push and all horizontal   
                 pp = create_transport_splines_nb(channel-1);
                 y(ind) = y(ind) + ppval(pp,x);            
            case 13 %Extra coil                
                %eventually can put into the above when the splines are
                %fixed                
                %for testing just check using the last horizontal channel
                %y(ind) = y(ind) + ppval(create_transport_splines_nb(12-1),x);                
                pp = create_transport_splines_nb(12);
                 y(ind) = y(ind) + ppval(pp,x);                 
            case 14 %1st vert transport coil [Coil 12A]    
                 pp = create_transport_splines_nb(13);                 
                  y(ind) = y(ind) + (x<=365).*ppval(pp,x);%horizontal section
                %ramp between the values from 365-->365.1
                y(ind) = y(ind) + (x>365).*(x<365.1).*...
                    (ppval(pp,365)-(ppval(pp,365)+coilone).*(x-365)/0.1);
                %ramp between the values from 365.1-->368
                y(ind) = y(ind) + (x>=365.1).*(x<368).*...
                    (-coilone+(ppval(pp,368)+coilone).*(x-365.1)/2.9);
                %vertical section
                y(ind) = y(ind) + (x>=368).*ppval(pp,x);     
            case 15 %2nd vert transport coil [Coil 12B]
                 pp = create_transport_splines_nb(14);
                %Modified Nov 1, 2019: ramp coil up explicitly to
                %avoid oscillations at begining
                %horizontal section 
                y(ind) = y(ind) + (x<=365).*(x>=310.0).*ppval(pp,x);
                %ramp between the values from 365-->365.1
                y(ind) = y(ind) + (x>365).*(x<365.1).*...
                    (ppval(pp,365)-(ppval(pp,365)-coiltwo).*(x-365)/0.1);
                %ramp between the values from 365.1-->368
                y(ind) = y(ind) + (x>=365.1).*(x<368).*...
                    (coiltwo+(ppval(pp,368)-coiltwo).*(x-365.1)/2.9);
                %Modified Nov 1, 2019: sets coil to 0 explicitly to
                %avoid oscillations at end 
                %vertical section
                y(ind) = y(ind) + (x>=368).*(x<=467.0).*ppval(pp,x);  
            case 16 %3rd vert transport coil [Coil 13]   
                 pp = create_transport_splines_nb(15);
                %horizontal section
                y(ind) = y(ind) + 0*(x<=365).*ppval(pp,x);
                %ramp between the values from 360-->360.1
                y(ind) = y(ind) + (x>365).*(x<365.1).*...
                    (0.*(x-365)/0.1);
                %ramp between the values from 360.1-->363
                y(ind) = y(ind) + (x>=365.1).*(x<370).*...
                    (0+(ppval(pp,370)+0).*(x-365.1)/4.9);
                %Modified Nov 1, 2019: sets coil to 0 explicitly to
                %avoid oscillations at end
                %vertical section
                y(ind) = y(ind) + (x>=370).*(x<=518.0).*ppval(pp,x);
            case 17 %4th vert transport coil [coil 14]                
                 pp = create_transport_splines_nb(16);  
                 coil14_endpos = 538.9; %538.9           
                %Modified Nov 1, 2019: ramp coil up explicitly to
                %avoid oscillations at begining 
                %curves
                 y(ind) = y(ind) + (x>=387).*(x<=coil14_endpos).*ppval(pp,x);    
                %Modified Nov 1, 2019: sets coil to 0 explicitly to
                %avoid oscillations at end
               y(ind) = y(ind) + (x>coil14_endpos).*(ppval(pp,coil14_endpos)+(+0.01-ppval(pp,coil14_endpos)).*(x-coil14_endpos)/(539-coil14_endpos)); 
            case 18 %bottom QP coil lower FET [coil 15]                
                 %this controls the FET which connects coil 15 to
                 %ground  
                 pp = create_transport_splines_nb(17);
                %Modified Nov 1, 2019: ramp coil up explicitly to
                %avoid oscillations at begining 
                 y(ind) = y(ind) + (x>=431).*ppval(pp,x);                                                            
            case 19 %top qp coil (FET 16)               
                %this is just the current in the top coil
                pp = create_transport_splines_nb(18);
                y(ind) = y(ind) + ppval(pp,x); 
            case 20 %kitten FET
                 %when 15 is positive this is saturated                 
                 %when 15 is negative this is 16-15                    
                pp1 = create_transport_splines_nb(17);
                pp2 = create_transport_splines_nb(21);
                if length(x)>1                     
                     if (x(2)-x(1))>0 %increasing position                     
                        k_turn_on_point = 0.0;                                                  
                     else %coming back                                                   
                        k_turn_on_point = 0;                         
                     end  
                    y(ind) = y(ind) + 60.0*(ppval(pp1,x)>=k_turn_on_point); %some very large current
                    %prevent rippling at the beginning
                    y(ind) = y(ind) + nullval.*(y(ind)==0).*(x<=450);
                    y(ind) = y(ind) + (ppval(pp2,x)+ppval(pp1,x)).*(ppval(pp1,x)<k_turn_on_point).*(x>450);                
                end
            case 21 %Power Dump                
                pp_vert12a = create_transport_splines_nb(13);
                pp_vert12b = create_transport_splines_nb(14);
                pp_vert13 = create_transport_splines_nb(15);
                pp_vert14 = create_transport_splines_nb(16);
                pp_vert15 = create_transport_splines_nb(17);
                pp_vert16 = create_transport_splines_nb(16);                
                Itotal = 100;                
                Ivert = abs(ppval(pp_vert12a,x))+abs(ppval(pp_vert12b,x))+...
                    abs(ppval(pp_vert13,x))+abs(ppval(pp_vert14,x))+...
                    abs(ppval(pp_vert15,x)).*(ppval(pp_vert15,x)>0)+abs(ppval(pp_vert16,x));                
                y(ind) = y(ind) + ...
                (Itotal - Ivert).*...
                ((Itotal - Ivert)>0);                
                y(ind) = y(ind).*(x<429);
            case 22 %15/16 TTL switch           
                %this is TTL low when the current is less than zero                                
                 pp = create_transport_splines_nb(17);                 
                 if length(x)>1                     
                     if (x(2)-x(1))>0 %increasing position    
                        turn_on_point = 0*1.2; %1.2 %0.75                                                 
                     else %coming back
                        turn_on_point = 2.4; %1.5                         
                     end                     
                     y(ind) = y(ind) + (ppval(pp,x)<turn_on_point) + (ppval(pp,x)>=turn_on_point)*-1.0;
                 end            
            case 23 %new coil relay                
                coil_relay_switch_pt = 210;                
                y(ind) = y(ind) + (x>coil_relay_switch_pt) - (x<=coil_relay_switch_pt);                
            otherwise                 
                error('Invalid channel');                
        end        
    end      
end