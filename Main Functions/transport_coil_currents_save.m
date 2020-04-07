%------
%Author: David McKay
%Created: July 2009
%Summary: This function returns the 3 column array for the analog update for a given cloud position.
%Position and time can be 1D arrays. Position is in mm.
%Horizontal is from 0->360mm and vertical is from 360mm->534mm
%------
function y = transport_coil_currents_save(time,position)

global seqdata;

%define the transport parameters

overallscale = 1; %scales all the transport currents

coil_scale_factors = ones(1,19);%scaling of the max current in each coil

coil_widths = ones(1,19);%widths of each of the coil curves

coil_offset = [0 30 41 43 85 116 148 179 212 242 274 338 360 361 358 360 358 363 360]; %the peak of each coil in position (mm)

%coil resistances are in mOhms
coil_resistance = [0 312.5 357 85 85 85 85 85 85 85 85 85 167 192 192 192 192 192 192];

coil_range = ones(2,19); %relevant range of the given coil (2xnumber of channels)


%FEED FORWARD
coil_range(1,1) = 0;
coil_range(2,1) = 534;
coil_widths(1) = 1.0;
coil_scale_factors(1) = 1.0/overallscale;

%Push Coil Range
coil_range(1,2) = 0;
coil_range(2,2) = 50; %50 for non-divergent curves
coil_widths(2) = 1.0;
coil_scale_factors(2) = 1.0; %1.6 for non-divergent curves

%MOT Coil range
coil_range(1,3) = 0;
coil_range(2,3) = 75; %75 for non-divergent curves

%First horizontal transport
coil_range(1,4) = 0;
coil_range(2,4) = 115; %115 for non-divergent curves

%second horizontal transport
coil_range(1,5) = 35;
coil_range(2,5) = 140;

%third horizontal transport
coil_range(1,6) = 50;
coil_range(2,6) = 180;

%fourth horizontal transport
coil_range(1,7) = 90;
coil_range(2,7) = 210;

%fifth horizontal transport
coil_range(1,8) = 110;
coil_range(2,8) = 250;

%sixth horizontal transport
coil_range(1,9) = 150;
coil_range(2,9) = 270;

%seventh horizontal transport
coil_range(1,10) = 180;
coil_range(2,10) = 300;

%eighth horizontal transport
coil_range(1,11) = 220;
coil_range(2,11) = 330;

%ninth horizontal transport
 coil_range(1,12) = 250; %CHANGE TO coil_range(1,11) = 250;
 coil_range(2,12) = 380; %CHANGE TO coil_range(2,11) = 380;
coil_scale_factors(12) = 1.0; 

%first vertical transport
coil_range(1,13) = 260; 
coil_range(2,13) = 430;
coil_scale_factors(13) = 1.1; %1.0*1.1

%second vertical transport
coil_range(1,14) = 260; 
coil_range(2,14) = 460;
coil_scale_factors(14) = -0.85*1.1; %-0.85*1.1

%third vertical transport
coil_range(1,15) = 350; 
coil_range(2,15) = 520;
coil_scale_factors(15) = 1.15;

%fourth vertical transport
coil_range(1,16) = 370; 
coil_range(2,16) = 534;
coil_scale_factors(16) = 1.4;

%Quadrupole factor
qp_scale_factor = 1.15;

%bottom qp coil
coil_range(1,17) = 410; 
coil_range(2,17) = 534;
coil_scale_factors(17) = 1.0*qp_scale_factor;

%top qp coil
coil_range(1,18) = 410; 
coil_range(2,18) = 534; 
coil_scale_factors(18) = 1.0*qp_scale_factor;

%kitten 
coil_range(1,19) = 410; 
coil_range(2,19) = 534;
coil_scale_factors(19) = 1.0*qp_scale_factor;

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
num_channels = 19; 
%channels the coils correspond to on the ADWIN
transport_channels = [18 7:17 22:24 20:21 1 3]; %CHANGE TO 7:17;

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
% currentarray(voltage_indices,3) = 2;

%go through for each channel
for i = 1:num_channels
    
    %indices for the current channel
    channel_indices = ((i-1)*length(time)+1):(i*length(time));
     
    currentarray(channel_indices,1) = time;
    currentarray(channel_indices,2) = transport_channels(i);
    currentarray(channel_indices,3) = channel_current(i,position,coil_offset(i),coil_widths(i),coil_range(:,i));
    
%     %determine the voltage required to drive the current for this channel
%     %total voltage is the maximum from all the channels
%     cur_channel_voltages = currentarray(channel_indices,3)*coil_resistance(i)*1E-3/4*1.4 + 0.5; 
%     currentarray(voltage_indices,3) = currentarray(voltage_indices,3).*(cur_channel_voltages<=currentarray(voltage_indices,3)) + ...
%         cur_channel_voltages.*(cur_channel_voltages>currentarray(voltage_indices,3));
    
    %convert currents to channel voltages
    currentarray(channel_indices,3) = seqdata.analogchannels(transport_channels(i)).voltagefunc{2}(currentarray(channel_indices,3).*overallscale*coil_scale_factors(i)).*(currentarray(channel_indices,3)~=nullval)+...
        currentarray(channel_indices,3).*(currentarray(channel_indices,3)==nullval);
    
    %check the voltages are in range
    if sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)>seqdata.analogchannels(transport_channels(i)).maxvoltage))||...
            sum((currentarray(channel_indices,3)~=nullval).*(currentarray(channel_indices,3)<seqdata.analogchannels(transport_channels(i)).minvoltage))
        error(['Voltage out of range when computing transport Channel:' num2str(transport_channels(i))]);
    end

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
                 MOTvoltage = 10/4;
                 
                 %ramp up and down for the push
                 maxpushvoltage = 21/4;
                 startpushramp = 10;
                 pushramppeak = 40;
                 endpushramp = 60;
                 
                 %steady voltage for horizontal transfer stage
                 horizontalvoltage = 8/4;
                 
                 %ramp up and down for the last horiz transport coil
                 maxhorizvoltage = 10/4;
                 starthorizramp = 260;
                 peakhorizramp = 350;  %350
                 endhorizramp = 360; %380
                 
                 %steady voltage for beginning of vertical transfer
                 beginningverticalvoltage = 11/4; %10/4
                 
                 %ramp up vertical transport coil
                 maxverticalvoltage = 11/4;
                 startverticalrampup = 360;
                 endverticalrampup = 360.1; %380
                 
                 %ramp down vertical transport coil
                 startverticalrampdown = 470;
                 endverticalrampdown = 534; %380
                 
                 %steady voltage for end of vertical transfer
                 endverticalvoltage = 11/4; %10/4
                 %------------------------
                 
                 y(ind) = y(ind) + MOTvoltage.*(pos(ind)<startpushramp);
                 
                 y(ind) = y(ind) + ((maxpushvoltage-MOTvoltage)/(pushramppeak-startpushramp).*(pos(ind)-startpushramp)+MOTvoltage).*(pos(ind)>=startpushramp).*(pos(ind)<pushramppeak);
                 
                 y(ind) = y(ind) + ((horizontalvoltage-maxpushvoltage)/(endpushramp-pushramppeak).*(pos(ind)-pushramppeak)+maxpushvoltage).*(pos(ind)<endpushramp).*(pos(ind)>=pushramppeak);
                 
                 y(ind) = y(ind) + horizontalvoltage.*(pos(ind)>=endpushramp).*(pos(ind)<starthorizramp);
                 
                 y(ind) = y(ind) + ((maxhorizvoltage-horizontalvoltage)/(peakhorizramp-starthorizramp).*(pos(ind)-starthorizramp)+horizontalvoltage).*(pos(ind)>=starthorizramp).*(pos(ind)<peakhorizramp);
                 
                 y(ind) = y(ind) + ((beginningverticalvoltage-maxhorizvoltage)/(endhorizramp-peakhorizramp).*(pos(ind)-peakhorizramp)+maxhorizvoltage).*(pos(ind)<endhorizramp).*(pos(ind)>=peakhorizramp);
                 
                 y(ind) = y(ind) + beginningverticalvoltage.*(pos(ind)<startverticalrampup).*(pos(ind)>=endhorizramp);
                 
                 %------------------------
                   
                 y(ind) = y(ind) + ((maxverticalvoltage-beginningverticalvoltage)/(endverticalrampup-startverticalrampup).*(pos(ind)-startverticalrampup)+beginningverticalvoltage).*(pos(ind)>=startverticalrampup).*(pos(ind)<endverticalrampup);
                 
                 y(ind) = y(ind) + maxverticalvoltage.*(pos(ind)<startverticalrampdown).*(pos(ind)>=endverticalrampup);
                 
                 y(ind) = y(ind) + ((endverticalvoltage-maxverticalvoltage)/(endverticalrampdown-startverticalrampdown).*(pos(ind)-startverticalrampdown)+maxverticalvoltage).*(pos(ind)>=startverticalrampdown).*(pos(ind)<endverticalrampdown);
                 
                 y(ind) = y(ind) + endverticalvoltage.*(pos(ind)<535).*(pos(ind)>=endverticalrampdown);
          
                 
            case 2 %push    
                
                y(ind) = y(ind) + (x<0).*(x>=-30).*...
                    (0.365494*(x+30)+0.0393257*(x+30).^2);
                
                y(ind) = y(ind) + (x<14).*(x>=0).*...
                    (46.2416-2.25861*(x+1)+3.51015*(x+1).^2-1.19336*(x+1).^3+0.216452*(x+1).^4-0.0216174*(x+1).^5+...
                    0.0011149*(x+1).^6-0.0000235111*(x+1).^7);
                
                y(ind) = y(ind);
                 
                                  
            case 3 %MOT 
                            
                y(ind) = y(ind) + (x<0).*(x>=-41).*...
                    (18.8132-0.0252293*(x+41)+0.0139316*(x+41).^2-0.00160342*(x+41).^3+0.0000582156*(x+41).^4-6.93292E-7*(x+41).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<5).*...
                    (29.0516-31.1518*(x+1)+24.0873*(x+1).^2-8.28676*(x+1).^3+0.942994*(x+1).^4+0.0997906*(x+1).^5-0.0302388*(x+1).^6+0.00179111*(x+1).^7);
                
                y(ind) = y(ind) + (x>=5).*(x<27).*...
                    (8.31257-0.299131*(x-4)-0.00130763*(x-4).^2-0.000860555*(x-4).^3+0.0000347087*(x-4).^4);
              
                
                
               case 4 %1st transport coil
                
                 
                y(ind) = y(ind) + (x<0).*(x>=-43).*...
                    (5.86264*(x+43)-0.276793*(x+43).^2+0.00705393*(x+43).^3-0.00010412*(x+43).^4+8.06799E-7*(x+43).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<6).*...
                    (59.1092+5.02669*(x+1)+0.663354*(x+1).^2-0.771293*(x+1).^3+0.139931*(x+1).^4-0.00786621*(x+1).^5);
                
                y(ind) = y(ind) + (x>=6).*(x<59).*...
                    (65.6381-0.144979*(x-5)-0.0525976*(x-5).^2+0.00109299*(x-5).^3-0.0000170024*(x-5).^4+1.48227E-7*(x-5).^5);
              
                
                               
            case 5 %2nd transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-42).*...
                    (2.08226*(x+42)-0.0857661*(x+42).^2+0.00390637*(x+42).^3-0.0000944415*(x+42).^4+7.95421E-7*(x+42).^5);
                
                y(ind) = y(ind) + (x>=0).*(x<43).*...
                    (35.5106+0.14955*(x+3)-0.03984449*(x+3).^2+0.000328995*(x+3).^3+2.12379E-6*(x+3).^4);
                
                    %interpolate position array
                   
                     %y(ind) = interp1(space,I2,x_interpolate);


            case 6 %3rd transport coil
                
              y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
               
              
            case 7 %4th transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                
                  
            
            case 8 %5th transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
                
            
            case 9 %6th transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                
               
            
            case 10 %7th transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-50).*...
                    (0.691446*(x+50)+0.0404464*(x+50).^2-0.000503235*(x+50).^3-2.09404E-6*(x+50).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (59.6443+0.182434*(x+2)-0.0709798*(x+2).^2+0.00104891*(x+2).^3-3.59099E-6*(x+2).^4);
                
                
            
            case 11 %8th transport coil
                
                y(ind) = y(ind) + (x<0).*(x>=-46).*...
                    (0.357822*(x+46)+0.0499669*(x+46).^2-0.00120938*(x+46).^3+7.00372E-6*(x+46).^4);
                
                y(ind) = y(ind) + (x>=0).*(x<49).*...
                    (35.6771+0.105056*(x+2)-0.0289143*(x+2).^2-0.0000894782*(x+2).^3+6.72509E-6*(x+2).^4);
                 
            case 12 %9th transport coil (last pure horizontal coil)
                
                 y(ind) = y(ind) + (x<0).*(x>=-81).*...
                    (-1.399576152198809 + 0.6128959132776826*(x+81) + 0.05818092411674249*(x+81).^2 - 0.0020273894601591496*(x+81).^3 +...
                    0.00006390066486350164*(x+81).^4 - 1.576426225114415E-6*(x+81).^5 + 1.9412239479883187E-8*(x+81).^6 - 8.747493861499982E-11*(x+81).^7);

                 y(ind) = y(ind) + (x>0).*(x<=23).*...
                    (87.68973301076208 + 0.17258405557431836*(x) - 0.02392088676738215*(x).^2 - 0.006588669866824533*(x).^3 +...
                    0.0000614116598770041*(x).^4);
                
                
            case 13 %1st vert transport coil
              
%                  y(ind) = y(ind) + (x<=0).*(x>=-69).*...
%                     (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
%                     0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);
%                 
%                 %this curve connects the horizontal and vertical currents
%                 y(ind) = y(ind) + (x>0).*(x<=0.1).*...
%                       (-5.213642/0.1*x + 19.0519);
%                 
% %                %minus signs below may need to be fixed
%                 y(ind) = y(ind) + (x>0.1).*(x<=20).*...
%                     -(-13.838258411267354+0.05947239838899692*(x-0.1)-0.07100519794104734*(x-0.1).^2+0.0018251714087331981*(x-0.1).^3);
%                 
%                  %smoother curve
% %                 y(ind) = y(ind) + (x>0).*(x<=20).*...
% %                     -(-19.06+(0.05947239838899692*x-0.07100519794104734*x.^2+0.0018251714087331981*x.^3)*0.55);
%                 
%                 
%                 %minus signs below may need to be fixed
%                 y(ind) = y(ind) + (x>20).*(x<=66).*...
%                     -(-25.94202900068819-1.2330684828778178*(x-20)+0.24761537415091986*(x-20).^2-0.011758456767792856*(x-20).^3+0.00023179910227504207*(x-20).^4-1.61647924389463E-6*(x-20).^5);
                
                
                %*************
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
                %********************


            case 14 %2nd vert transport coil
                
%                 y(ind) = y(ind) + (x<=0).*(x>=-69).*...
%                     (-0.24894053840627586 + 0.21549342441239006*(x+69) + 0.010610913626239617*(x+69).^2 - 0.0011035186372974687*(x+69).^3 +...
%                     0.00005994384121982444*(x+69).^4 - 1.4556975877409068E-6*(x+69).^5 +  1.615819365079346E-8*(x+69).^6 - 6.840008875660139E-11*(x+69).^7);
% 
%                 %this curve connects the horizontal and vertical currents
%                 y(ind) = y(ind) + (x>0).*(x<=0.1).*...
%                       (-2.091/0.1*x + 19.0519);
%                   
% %                 %minus signs below may need to be fixed
%                 y(ind) = y(ind) + (x>0.1).*(x<=59).*...
%                     (16.960938781084813 -1.6740512977777005*(x-0.1)+0.1596506794975819*(x-0.1).^2-0.01106184280319563*(x-0.1).^3+0.00036306990649827845*(x-0.1).^4-...
%                         5.537722308312364E-6*(x-0.1).^5+3.1403594860980533E-8*(x-0.1).^6);
%                     
%                     %smoother curve
% %                 y(ind) = y(ind) + (x>0).*(x<=59).*...
% %                     (19.06 -1.6740512977777005*x+0.1596506794975819*x.^2-0.01106184280319563*x.^3+0.00036306990649827845*x.^4-...
% %                         5.537722308312364E-6*x.^5+3.1403594860980533E-8*x.^6);
%                     
%                 %minus signs below may need to be fixed
%                 y(ind) = y(ind) + (x>59).*(x<=92).*...  
%                     (-33.374078751779564-0.4354378184557704*(x-59)+0.09912738144033928*(x-59).^2-0.0016851950599533617*(x-59).^3);

                
                %********************
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

                
            case 15 %3rd vert transport coil
                
%                 %this curve connects the horizontal and vertical currents
%                 y(ind) = y(ind) + (x>0).*(x<=0.1).*...
%                       (14.035113352825304/0.1*x + 0);
%                 
%                 y(ind) = y(ind) + (x>=0.1).*(x<=28).*...  
%                     (14.035113352825304 -0.1629088948989349*(x-0.1)+0.08300820420415693*(x-0.1).^2-0.002196443032212637*(x-0.1).^3);
%                 
%                 %smooth curve
% %                 y(ind) = y(ind) + (x>=0).*(x<=28).*...  
% %                     (-0.1629088948989349*x+0.08300820420415693*x.^2-0.002196443032212637*x.^3)*2.15;
%                 
%                 
%                 y(ind) = y(ind) + (x>28).*(x<=100).*... 
%                     (26.57914422544793 -1.114628270812311*(x-28)-0.03140520264627124*(x-28).^2+0.006020772968931128*(x-28).^3-0.00028532386557755546*(x-28).^4+...
%                         6.2150178590944775E-6*(x-28).^5-6.557536075206112E-8*(x-28).^6+2.709367015136489E-10*(x-28).^7);
%                     
%                 y(ind) = y(ind) + (x>100).*(x<=145).*...    
%                     (-29.27906767092452+0.08512921151928889*(x-100)+0.15113776915766508*(x-100).^2-0.008452909182811094*(x-100).^3+0.0001796339300691302*(x-100).^4-...
%                         1.340528229129355E-6*(x-100).^5);
                
                %*****************************
                
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

                
            case 16 %4th vert transport coil
                
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
                
            case 17 %bottom qp coil
                
                %this is the negative of the current in the 
                %bottom coil where positive current direction is when 
                %these two coils are in anti-helmholtz                
                
                y(ind) = y(ind) - qp_currents(x,0);
                
            case 18 %top qp coil
               
                %this is just the current in the top coil
                
                 y(ind) = y(ind) + qp_currents(x,1);
                 
            case 19 %kitten
               
                %this is the current of the top coil minus the current in
                %the bottom coil
                y(ind) = y(ind) + qp_currents(x,1)+qp_currents(x,0);
                
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
                y = y + (x>=92).*(x<=138).*... 
                    (-1.3933048433956314+1.9170339866332295*(x-92)-0.08741203724647845*(x-92).^2+0.0009440722200383801*(x-92).^3+0.00002519895538810482*(x-92).^4-...
                        3.9420176937309534E-7*(x-92).^5);
                 
                 y = y + (x>138).*(x<=174).*...
                    (25.380015360377875 +0.8270816166519087*(x-138)+0.004130396345414532*(x-138).^2-0.010226492418791576*(x-138).^3+0.0005905332132747151*(x-138).^4-...
                     0.000013184801422214478*(x-138).^5+1.0714734735744564E-7*(x-138).^6);
                 
                 
            elseif index==0
                
                y = y + (x>=67).*(x<=99).*...
                    (-0.5242843400416173+1.347537639897927*(x-67)-0.07659789635587849*(x-67).^2+0.004452547880334847*(x-67).^3-0.00007723202546822751*(x-67).^4);
  
                y = y + (x>99).*(x<=174).*...
                    (28.756390124608473 +0.29977790350549016*(x-99)-0.22879972905714865*(x-99).^2+0.015074078677112161*(x-99).^3-0.000456931051691088*(x-99).^4+...
                        7.205528701427198E-6*(x-99).^5-5.733395769127594E-8*(x-99).^6+1.8186535177502566E-10*(x-99).^7);
            else
                error('QP Current called with incorrect index')
            end
            
        end
        
    end



end