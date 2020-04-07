%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = Load_MagTrap_sequence(timein)

curtime = timein;
global seqdata;

seqdata.numDDSsweeps = 0;

MHz = 1E6;
GHz = 1E9;

initialize_channels()

%% Make sure Coil 16 fast switch is open

%fast switch is gone
%setAnalogChannel(calctime(curtime,0),31,6);

%% Switches

%It's preferable to add a switch here than comment out code!
image_type = 2; %0: absorption image, 1: recapture, 2:fluor, 3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 6: MOT fluor with MOT off
image_loc = 1; %0: MOT cell, 1: science chamber
hor_transport_type = 1; %0: min jerk curves, 1: slow down in middle section curves, 2: none
ver_transport_type = 3; %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear, 4: triple min jerk

%Special flags
mag_trap_MOT = 0; %Absportion image of MOT after magnetic trapping
MOT_abs_image = 1; %Absorption image of the MOT (no load in mag trap);
transfer_recap_curve = 0; %Transport curve from MOT and back

controlled_load = 0; %do a specific load time
controlled_load_time = 20000;

%addOutputParam('resonance',controlled_load_time); 

%plug options
do_plug = 0;

addOutputParam('doplug',do_plug); 

%ramp QP at end
ramp_QP = 1;
RF_stage_1 =0;
ramp_down_QP_before_transfer = 1; %ramp down after RF_stage 1, before QP transfer 
RF_stage_1b = 0;



QP_transfer = 0; %Transfer position of QP during evaporation
ramp_down_QP = 0; %ramps QP down after transfer
RF_stage_2 = 0; %Evap near window

%dipole trap
dipole_trap1 = 0;  %ramp on dipole trap while ramping off QP
dipole_trap2 = 0; %pulse dipole trap

if dipole_trap1 && dipole_trap2
    error('Both dipole trap procedures selected');
end


%Low atoms after evap for clean TOF signal
lower_atoms_after_evap = 0;


%Implement special flags
if (mag_trap_MOT + MOT_abs_image + transfer_recap_curve)>1
    error('Too many special flags set');
end

if mag_trap_MOT || MOT_abs_image || transfer_recap_curve
    hor_transport_type = 2;
    ver_transport_type = 2;
    image_type = 0;
    image_loc = 0;
    do_plug = 0;
    ramp_QP=0;
    RF_stage_1 =0;
    ramp_down_QP_before_transfer = 0; 
    RF_stage_1b = 0;
    QP_transfer = 0; 
    ramp_down_QP = 0; 
    RF_stage_2 = 0;
    dipole_trap = 0;
end

if transfer_recap_curve
    image_type = 6;
    hor_transport_type = 1;
    ver_transport_type = 3;
end

if image_type==4
    hor_transport_type = 2;
    ver_transport_type = 2;
end

%% Prepare to Load into the Magnetic Trap

if controlled_load
    
    %turn off trap
    setAnalogChannel(curtime,8,0);
    setDigitalChannel(curtime,4,0);
    
    %turn trap back on
    curtime = Load_MOT(calctime(curtime,500),30);
    
    %wait fixed amount of time
    curtime = calctime(curtime,controlled_load_time);
    
else

    %this has been here for historic reasons
    curtime = calctime(curtime,1500);
    
end
% 
% % %for MOT loading curve
%     setAnalogChannel(calctime(curtime,0),18,10); 
%     %CATS
%     curtime = setAnalogChannel(calctime(curtime,0),8,10); %load_MOT_tof
%     
% %time with coils on
%     curtime = calctime(curtime,1500);
% 
% 
% load_rb_detuning = 30;
% %set rb detuning
% setAnalogChannel(calctime(curtime,0),34,6590+load_rb_detuning); 
%     
% %time with Rb on
%     curtime = calctime(curtime,10000);
% %     
% load_rb_detuning = -10;
% %set rb detuning
% setAnalogChannel(calctime(curtime,0),34,6590+load_rb_detuning); 
% 
% %time with Rb off
%     curtime = calctime(curtime,10000);


curtime = Prepare_MOT_for_MagTrap(curtime, image_type, image_loc);  %second argument is for blue mot

%digital trigger
DigitalPulse(calctime(curtime,0),12,0.1,1);

%set Quantizing shim back after optical pumping
setAnalogChannel(calctime(curtime,0),19,0.9);

%% Load into Magnetic Trap


if ~(MOT_abs_image || image_type==4)

%     %same as molasses (assume this zero's external fields)
    
    yshim2 = 0.9; %0.9
    xshim2 = 0.1; %0.1
    zshim2 = 0.3; %0.3
        
    %optimize shims for loading into mag trap
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,0.01),19,yshim2); %1.25
    %turn on the X (left/right) shim
    setAnalogChannel(calctime(curtime,0.01),27,xshim2); %0.3 
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,0.01),28,zshim2); %0.2
     
    curtime = Load_MagTrap_from_MOT(curtime);
    
    if transfer_recap_curve && (hor_transport_type == 2)
        curtime = calctime(curtime,1000);
    end
    
end


%turn off shims
%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,0),19,0.0); 
%turn on the X (left/right) shim
setAnalogChannel(calctime(curtime,0),27,0.0); 
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0),28,0.0); 



%% Transport 

%open kitten relay
curtime = setDigitalChannel(curtime,29,1);

disp('Start Calculating Transport')
curtime = Transport_Cloud(curtime, hor_transport_type, ver_transport_type, image_loc);
disp('End Calculating Transport')

%DigitalPulse(calctime(curtime,0),12,10,1);

%% Ramp up QP

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_after_trans(curtime, ramp_QP);

%turn on shims
%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,0),19,0.5,1); %0 %1
%turn on the X (left/right) shim
setAnalogChannel(calctime(curtime,0),27,1.6,1); %1.5 %2
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0),28,0.8,1); %1.05 %0.95

 

%% Evaporate in Tight QP Trap

if RF_stage_1

     fake_sweep = 0;

     hold_time = 100;
     pre_hold_time =  100;

     %BEC March 14
     start_freq = 35;%42
    
    freqs_1 = [start_freq 30 15 10]*MHz; %7.5
    RF_gain_1 = [9 9 0]; %5
    sweep_times_1 = [17000 8000 3000 ]; %1500
    
    %this worked well with 0.6 kitten
     freqs_1 = [start_freq 30 15 10]*MHz; %7.5
    RF_gain_1 = [9 9 9]*(5)/9*0.75; %9 9 9
    sweep_times_1 = [12000 8000 3000]; %[17000 8000 3000]
    
%      freqs_1 = [start_freq 30 15 ]*MHz; %7.5
%     RF_gain_1 = [9 9 9]*(5)/9*0.75; %9 9 9
%     sweep_times_1 = [12000 8000 ]; %[17000 8000 3000]
%         
    %hold before evap
    curtime = calctime(curtime,pre_hold_time);
        
    curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, RF_gain_1, hold_time, ~(RF_stage_2 || RF_stage_1b));

    
elseif ~(mag_trap_MOT || MOT_abs_image)
    curtime = calctime(curtime,0); %changed from 100ms to 0ms   
end

%% Slowly transfer to window during RF stage 1

%[curtime I_QP I_kitt V_QP] = kitten_transfer_to_window(calctime(curtime,-23000), I_QP, I_kitt, V_QP);

% curtime = calctime(curtime,-sum(sweep_times_1));
% percent_ramp_down = [1 1-(freqs_1(1)-freqs_1(2:(end)))/(freqs_1(1)-freqs_1(end))*0.75];
% volt_ramp_percent = 0.04;
% for i = 1:length(sweep_times_1)
%     
%     %slightly ramp voltage up
%     AnalogFunc(curtime,18,@(t,tt,dt)(dt*t/tt+(1+volt_ramp_percent*(1-percent_ramp_down(i)))*V_QP),sweep_times_1(i),sweep_times_1(i),-volt_ramp_percent*(percent_ramp_down(i+1)-percent_ramp_down(i))*V_QP);
%     
%     %ramp kitten down
%     curtime = AnalogFunc(curtime,3,@(t,tt,dt)(dt*t/tt+percent_ramp_down(i)*I_kitt),sweep_times_1(i),sweep_times_1(i),(percent_ramp_down(i+1)-percent_ramp_down(i))*I_kitt);
% end
% 
% I_kitt = percent_ramp_down(end)*I_kitt*0;
% V_QP = (1+volt_ramp_percent*0.75)*V_QP;

%% Ramp down QP before transfer

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_before_transfer(curtime, ramp_down_QP_before_transfer, I_QP, I_kitt, V_QP, I_fesh);

curtime=calctime(curtime,0);

%% Ramp on Plug

if do_plug
   
     
    plugpwr = 1000E-3;
    
    %set plug on time from end of evap       
    plug_offset = -200; % -200
    
    if plug_offset < -500
        error('Plug turns on before atoms arrive at imaging position!');
    end
    
    
    %open plug shutter
    setDigitalChannel(calctime(curtime,plug_offset),10,1);
    %ramp on plug beam
    AnalogFunc(calctime(curtime,plug_offset+1),33,@(t,tt,pwr)(pwr*t/tt),100,100,plugpwr);
    
    curtime = calctime(curtime,700);
 
end

%% Evaporation Stage 1b



if RF_stage_1b

    fake_sweep = 0;

    freqs_1b = [freqs_1(end)/MHz*0.8 4 2]*MHz; %0.28 %0.315
    RF_gain_1b = [-4 -4 -7]; %-4
    sweep_times_1b = [3000 1500]; %1500
    
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 1 0.5]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [3000 1500 2500 ]; %5500
%     
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 0.6 ]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [3000 1500 ]; %1500
    
%     freqs_1b = [freqs_1(end)/MHz*0.8 3.25]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4]; %-4
%     sweep_times_1b = [3000]; %1500

% This seems to be good for dipole transfer
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 2]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4]; %-4
%     sweep_times_1b = [3000 1500]; %5500
          
    curtime = do_evap_stage(curtime, fake_sweep, freqs_1b, sweep_times_1b, RF_gain_1b, 0, ~RF_stage_2);

    curtime = calctime(curtime,0);
    
end

if dipole_trap2
    
    %AnalogFunc(calctime(curtime,1),40,@(t,tt,dt)(minimum_jerk(t,tt,dt)),5,5,2.5);
    setAnalogChannel(calctime(curtime,-1*sum(sweep_times_1b)-20),40,2.5,1);
   %setAnalogChannel(calctime(curtime,-0*sum(sweep_times_1b)/1 + 11),40,0,1);
   
   %AnalogFunc(calctime(curtime,1),40,@(t,tt,dt)(minimum_jerk(t,tt,dt)),5,5,2.5);
end

%push the RF far away
%DDS_sweep(calctime(curtime,10),1,50E6,50E6,100);

%% Do QP transfer and ramp down gradient

[curtime I_QP I_kitt V_QP] = transfer_to_window(curtime, I_QP, I_kitt, V_QP, QP_transfer, ramp_down_QP);

%% Do Second RF Evaporation in Weaker Trap for Plug

if RF_stage_2
    
    if ~RF_stage_1
        error('Cannot do stage 2 evaporation without stage 1 evaporation');
    end
  
    % Do RF
    fake_sweep = 0;
          
    if RF_stage_1b
        start_freq = freqs_1b(end)/MHz;
    else
        start_freq = freqs_1(end)/MHz;%*(RD_factor)^(2/3)+2.5;
    end    
    
    freqs_2 = [start_freq*0.8 4 1]*MHz;
    RF_gain_2 = [0 -4];
    sweep_times_2 = [3000 1500]; %2.5
        
    curtime = do_evap_stage(curtime, fake_sweep, freqs_2, sweep_times_2, RF_gain_2, 0, 1);
    
    
end



%************************comment above for MOT pic ***********************

%turn plug off
if do_plug 
    
    plug_offset = 0*-2.5; %0 for experiment, -10 to align for in trap image
    
    if ~dipole_trap1
        setAnalogChannel(calctime(curtime,plug_offset),33,0);
        setDigitalChannel(calctime(curtime,plug_offset-2),10,0);
    end
    
    
end

%% Dipole trap ramp on (and QP rampdown)

if dipole_trap1

    dipole_on_time = 10;
    
    [curtime I_QP V_QP P_dip] = dipole_transfer(curtime, I_QP, V_QP);

    curtime = calctime(curtime, dipole_on_time);
    
end



%% lower atoms from window for clean TOF release

if lower_atoms_after_evap

        %100ms, 15A works well for RF_stage_2
    
        lower_transfer_time = 100;
    
        curtime = AnalogFunc(curtime,1,@(t,tt,dt)(dt*t/tt+I_QP),lower_transfer_time,lower_transfer_time,15-I_QP);
        
end


%% Atoms are now just waiting in the magnetic trap.  




    %curtime = calctime(curtime,2000);

    %turn ON coil 14 a little to close switch in order to prevent an induced
    %current from the fast QP switch-off
    % setAnalogChannel(calctime(curtime,0),20,0.15,1);
    % setAnalogChannel(calctime(curtime,1.5),20,0.0,1);
   
    %turn the Magnetic Trap off

    %set all transport coils to zero (except MOT)
    for i = [7 9:17 22:24] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end

    %Feshbach off
    setAnalogChannel(calctime(curtime,0),38,0);

    %ramp up science QP
    % AnalogFunc(calctime(curtime,0),18,@(t,tt)(10*(1+0.2/tt*t)),100,100);
    % curtime = AnalogFunc(calctime(curtime,0),1,@(t,tt)(11*(1+1/tt*t)),100,100);
    % 

    %Science chamber Quadrupole trap
    setAnalogChannel(calctime(curtime,0),21,0,1);
    curtime = setAnalogChannel(calctime(curtime,0),1,0,1);%MOT channel = 8, QT channel = 21 (b), 1 (t)
    curtime = setAnalogChannel(curtime,3,0,1);%kitten
    curtime = setAnalogChannel(curtime,37,0,1);%bleed

    %MOT
    if image_type~=4
        setAnalogChannel(curtime,8,0,1);
    end

    %MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
    %Coil 16 fast switch
    %setDigitalChannel(curtime,21,1);
    qp_switch1_delay_time = 0;

    if I_kitt == 0



        %use fast switch
        setDigitalChannel(curtime,21,1);
        setDigitalChannel(calctime(curtime,500),21,0);

        %wait to close 15/16 switch
        qp_switch1_delay_time = 20;

    else
        %error('Can''t do fast switch if haven''t transferred atoms to imaging position')
    
    end

    %turn off 15/16 switch (10 ms later)
    setDigitalChannel(calctime(curtime,qp_switch1_delay_time),22,0);


if dipole_trap1 || dipole_trap2
   
    %turn off dipole trap
    setAnalogChannel(calctime(curtime,2),40,0,1);
    
end



if ~(image_type==1 || image_type==4)
    setDigitalChannel(curtime,16,1);    
end





if image_type == 0 % Absorption Image
        
    curtime = absorption_image(calctime(curtime,0.0),image_loc); 
                    
elseif image_type == 1 %Recapture

    curtime = recap_image(curtime,image_loc);

elseif image_type == 2 %fluorescence
        
    curtime = fluor_image(calctime(curtime,0.0)); 
    
elseif image_type == 3 %blue absorption image
    
    curtime = blue_absorption_image(calctime(curtime,0.0),image_loc); 

elseif image_type == 4 %MOT fluor image
    
    curtime = MOT_fluor_image(curtime);
    
elseif image_type == 5 %look at mot fluorescence recap with PD
    
elseif image_type == 6 %recapture with the exact mot sequence
            
    %setAnalogChannel(calctime(curtime,0),31,0);
    curtime = Load_MOT(calctime(curtime,0),30);
    %curtime = MOT_fluor_image(calctime(curtime,50));
    addOutputParam('recap_wait', 50);  
    
else
    error('Undefined imaging type');
end

%% Load MOT
% 
   %%list
%  MOT_detuning_list=[27:2:37 27:2:37 ];
% % 
% % %Create linear list
% %index=seqdata.cycle;
% % 
% % %Create Randomized list
% index=seqdata.randcyclelist(seqdata.cycle);
% % 
%  MOT_detuning = MOT_detuning_list(index)
%  addOutputParam('resonance',MOT_detuning);

 MOT_detuning = 26.0; %30

 mot_wait_time = 50;
 
 if image_type==5
     mot_wait_time = 0;
 end
 

%call Load_MOT function
curtime = Load_MOT(calctime(curtime,mot_wait_time),MOT_detuning);

%set relay back
curtime = setDigitalChannel(calctime(curtime,10),28,0);



%% Put in Dark Spot

%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

%% Close Coil 16 fast switch

%setAnalogChannel(calctime(curtime,0),31,0);

%% Timeout

timeout = curtime;


end