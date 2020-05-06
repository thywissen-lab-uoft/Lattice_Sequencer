%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = Load_MagTrap_sequence(timein)

curtime = timein;

%% Initialize seqdata
global seqdata;

seqdata.numDDSsweeps = 0;
seqdata.scanindex = -1;

seqdata.params. shim_zero = [0.115 -0.0975 -0.145];  %Bipolar shim values (x,y,z) which zero the ambient field (found using uWave spectroscopy)

seqdata.params. shim_val = [0 0 0]; %Current shim values (x,y,z)- reset to zero

% Dipole trap and lattice beam parameters 
seqdata.params. XDT_area_ratio = 1; % DT2 with respect to DT1

% Rb Probe Beam AOM Order
seqdata.flags.Rb_Probe_Order = 1;   %1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                    %2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT

MHz = 1E6;
GHz = 1E9;

%%

initialize_channels();

%% Make sure Coil 16 fast switch is open

%fast switch is gone
%setAnalogChannel(calctime(curtime,0),31,6);


%% Switches

    %It's preferable to add a switch here than comment out code!

    %Special flags
    mag_trap_MOT = 0; %Absportion image of MOT after magnetic trapping
    MOT_abs_image = 0; %Absorption image of the MOT (no load in mag trap);
    transfer_recap_curve = 0; %Transport curve from MOT and back
    after_sci_cell_load = 0; %Abs image after loading into science cell
    bench_transport = 0; %special stage for benchmarking the transport
    bench_rf = 0; %special stage for benchmarking RF power making it to the atoms
    MOTmolasses_recap = 0; %Test molasses using recapture after RF stage 1
    RF_benchmark_evap = 0; % for benchmarking rf

    % Imaging
    seqdata.flags. image_type = 0; %0: absorption image, 1: recapture, 2:fluor, 3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses
    seqdata.flags. image_atomtype = 0;  % 0 = Rb, 1 = K, 2 = Rb+K
    seqdata.flags. image_loc = 1; %0: MOT cell, 1: science chamber    
    seqdata.flags. img_direction = 1; % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), 3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence
    seqdata.flags. do_stern_gerlach = 0; %1: Do a gradient pulse at the beginning of ToF
    seqdata.flags. iXon = 0; % use iXon camera to take an absorption image (only vertical)
    seqdata.flags. do_F1_pulse = 0; % repump Rb F=1 before/during imaging
    seqdata.flags. QP_imaging = 1; %1= image out of QP, 0=image K out of XDT , 2 = obsolete, 3 = make sure shim are off for D1 molasses (should be removed)
    seqdata.params. tof = 12;

    % Transport curves
    seqdata.flags. hor_transport_type = 1; %0: min jerk curves, 1: slow down in middle section curves, 2: none
    seqdata.flags. ver_transport_type = 3; %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear, 4: triple min jerk

    seqdata.flags. controlled_load = 0; %do a specific load time
    controlled_load_time = 20000;

    % Use stage1 = 2 to evaporate fast for transport benchmarking
    % Use stage1b = 2 to do microwave evaporation in the plugged QP trap
    seqdata.flags. compress_QP = 1; % compress QP after transport
    seqdata.flags. RF_evap_stages = [1,1,1]; %[stage1, decomp/transport, stage1b]
    seqdata.flags. do_plug = 1;     % ramp on plug after transfer to window
    seqdata.flags. lower_atoms_after_evap = 0; % lower hot cloud after evap to get clean TOF signal

    % Dipole trap
    seqdata.flags. do_dipole_trap = 0; % 1: dipole trap loading, 2: dipole trap pulse
    seqdata.flags. CDT_evap = 0;        % 1: exp. evap, 2: fast lin. rampdown to test depth, 3: piecewise lin. evap 
    
    % Optical lattice
    seqdata.flags. load_lattice = 0; % set to 2 to ramp to deep lattice at the end
    seqdata.flags. pulse_lattice_for_alignment = 0; % 1: pulse after XDT

    %Imaging Molasses
    seqdata.flags. do_imaging_molasses = 0; % 1: In Lattice or XDT, 2: Free space after QP, 3: Free Space after XDT
    
    %Recap molasses
    recap_molasses = 0; %1 D1 molasses, 2 rb_molasses
    
    scope_trigger = 'none';
    exclude_trigger = 'all';

%% Set switches for predefined scenarios

    if MOTmolasses_recap == 1
        %be extra sure that we aren't doing any further evap/trapping
        seqdata.flags.RF_evap_stages(3) = 0;
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;
        seqdata.flags.do_plug = 0;
        %image is taken in the MOT_molasses_recap routine, 
        %don't do a second image!
        seqdata.flags.image_type = 99;
    end

    if mag_trap_MOT || MOT_abs_image || transfer_recap_curve
        seqdata.flags.hor_transport_type = 2;
        seqdata.flags.ver_transport_type = 2;
        seqdata.flags.image_type = 0; %0: absorption image, 1: recapture, 2:fluor, 3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 6: MOT fluor with MOT off
        seqdata.flags.image_loc = 0;
        seqdata.flags.do_plug = 0;
        seqdata.flags.compress_QP = 0;
        seqdata.flags.RF_evap_stages = [0 0 0];
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;  
        seqdata.flags.pulse_lattice_for_alignment = 0;
        MOTmolasses_recap = 0;
    end

    if seqdata.flags.image_loc == 0
        seqdata.flags.do_plug = 0;
        seqdata.flags.compress_QP = 0;
        seqdata.flags.RF_evap_stages = [0 0 0];
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;  
        seqdata.flags.pulse_lattice_for_alignment = 0;
        MOTmolasses_recap = 0;
    end

    if transfer_recap_curve
        seqdata.flags.image_type = 6;
        seqdata.flags.hor_transport_type = 1;
        seqdata.flags.ver_transport_type = 3;
    end

    if after_sci_cell_load
        seqdata.flags.hor_transport_type = 1;
        seqdata.flags.ver_transport_type = 3;
        seqdata.flags.image_type = 0;
        seqdata.flags.image_loc = 1;
        seqdata.flags.compress_QP = 1;
        seqdata.flags.do_plug = 0;
        seqdata.flags.RF_evap_stages = [0 0 0];%[0 0 1] July 25, 2013
        seqdata.flags.do_dipole_trap = 0;
    end

    if bench_transport || bench_rf
        seqdata.flags.hor_transport_type = 1;
        seqdata.flags.ver_transport_type = 3;
        seqdata.flags.image_type = 0;
        seqdata.flags.image_loc = 1;
        seqdata.flags.compress_QP = 1;
        seqdata.flags.do_plug = 0;
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;

        if bench_transport
            seqdata.flags.RF_evap_stages = [2 1 0];
            RF_benchmark_evap = 0;
        else
            seqdata.flags.RF_evap_stages = [0 0 0];
            RF_benchmark_evap = 1;
        end

    end

    if seqdata.flags.image_type==4
        seqdata.flags.hor_transport_type = 2;
        seqdata.flags.ver_transport_type = 2;
    end

%% Consistency checks
    %Implement special flags
    if (mag_trap_MOT + MOT_abs_image + transfer_recap_curve + after_sci_cell_load)>1
        error('Too many special flags set');
    end

%% Set Objective Piezo Voltage

    obj_piezo_V = 0;%5

    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);

%% Make sure dipole and lattice traps are off and adjust XDT piezo mirrors
%% and initialize repump imaging.

    %close all RF and uWave switches
    setDigitalChannel(calctime(curtime,0),'RF TTL',0);
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
    
    %Set both transfer switches back to initial positions
    setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0); %0 = RF
    setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); %1 = Rb
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler
    
    %Reset Feschbach coil regulation
    SetDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);  %Integrator disabled
    SetDigitalChannel(calctime(curtime,0),'FB sensitivity select',0);   %Low sensitivity
    SetDigitalChannel(calctime(curtime,0),'FB offset select',0);        %No offset voltage
    
    %turn off dipole trap beams
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.3,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.3,1);
    
    %turn off lattice beams
    setAnalogChannel(calctime(curtime,0),'xLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'yLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'zLattice',0,2);
    
    setDigitalChannel(calctime(curtime,0),'xLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
    
    %set rotating waveplate back to full dipole power
    setAnalogChannel(curtime,'latticeWaveplate',0.0,3);
    
    % Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
    CDT_piezo_X = 0;
    CDT_piezo_Y = 0;
    CDT_piezo_Z = 0;
    setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X);
    setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y);
    setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z);
%     addOutputParam('piezoX',CDT_piezo_X);

    %Open Rb RP shutter to Probe/OP fibers (is already open from previous cycle, just initializing value in update table here).
    setDigitalChannel(calctime(curtime,0),'Rb Repump Imaging',1); %1 = open, 0 = closed
   
%% Make sure Shim supply relay is on

%Turn on MOT Shim Supply Relay
    SetDigitalChannel(calctime(curtime,0),33,1);

%Turn shim multiplexer to MOT shims    
    setDigitalChannel(calctime(curtime,0),37,0);    

%% Prepare to Load into the Magnetic Trap

    if ( seqdata.flags.controlled_load == 1 )

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

%     % %for MOT loading curve
%         setAnalogChannel(calctime(curtime,0),18,10); 
%         %CATS
%         curtime = setAnalogChannel(calctime(curtime,0),8,10); %load_MOT_tof
% 
%     %time with coils on
%         curtime = calctime(curtime,20000);
% 
% 
%     load_rb_detuning = 30;
%     %set rb detuning
%     setAnalogChannel(calctime(curtime,0),34,6590+load_rb_detuning); 
% 
%     %time with Rb on
%         curtime = calctime(curtime,10000);
%     %     
%     load_rb_detuning = -10;
%     %set rb detuning
%     setAnalogChannel(calctime(curtime,0),34,6590+load_rb_detuning); 
% 
%     %time with Rb off
%         curtime = calctime(curtime,10000);

curtime = Prepare_MOT_for_MagTrap(curtime);

    %Turn off extra repump light being coupled into MOT chamber.
    setDigitalChannel(calctime(curtime,0),'Rb Repump Imaging',0);

    %set Quantizing shim back after optical pumping
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.9);

%% Load into Magnetic Trap

    if ~( MOT_abs_image || seqdata.flags.image_type==4 )

    %     %same as molasses (assume this zero's external fields)

        yshim2 = 0.9; %0.9
        xshim2 = 0.1; %0.1
        zshim2 = 0.0; %0.3  0.0 Dec 4th 2013

        %optimize shims for loading into mag trap
        setAnalogChannel(calctime(curtime,0.01),'Y Shim',yshim2,3); %1.25
        setAnalogChannel(calctime(curtime,0.01),'X Shim',xshim2,2); %0.3 
        setAnalogChannel(calctime(curtime,0.01),'Z Shim',zshim2,2); %0.2
        


curtime = Load_MagTrap_from_MOT(curtime);


        if transfer_recap_curve && (seqdata.flags.hor_transport_type == 2)
curtime     = calctime(curtime,1000);
        end

    end
        
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.0,2); %2

    

%% Transport 

    %open kitten relay
curtime = setDigitalChannel(curtime,'Kitten Relay',1);

%Turn shim multiplexer to Science shims
    setDigitalChannel(calctime(curtime,1000),37,1); 
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
%Turn Shims to Science cell zero values
    setAnalogChannel(calctime(curtime,1000),27,0,3); %3
    setAnalogChannel(calctime(curtime,1000),28,0,3); %3
    setAnalogChannel(calctime(curtime,1000),19,0,4); %4

    %digital trigger
%     DigitalPulse(calctime(curtime,0),'ScopeTrigger',1,1);
    disp('Start Calculating Transport')
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
curtime = Transport_Cloud(curtime, seqdata.flags.hor_transport_type, seqdata.flags.ver_transport_type, seqdata.flags.image_loc);
    disp('End Calculating Transport')



%% Ramp up QP
% Compression stage after the transport to the science cell
% SHIM COILS !!!

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_after_trans(curtime, seqdata.flags.compress_QP);

    %set shim coils to the field cancelling values
    x_Bzero = 1*0.025; %0.025 minimizes field
    y_Bzero = 1*-0.075; %-0.075 minimizes field
    z_Bzero = 1*-0.13;%%-0.13 minimizes field

    z_shim_list = [-0.2:0.05:0.2];
    
    %Shim Values to Turn On To: (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
    y_shim_val = 0*y_Bzero; %0*0.5
    x_shim_val = 0*x_Bzero; %0*1.6
    z_shim_val = 0*z_Bzero; %0*0.8
    
    x_shim_val = -0.15; % 2014-05-05: to optimize plug evaporation (temporarily)
        
    
    %turn on shims
    setAnalogChannel(calctime(curtime,0),'Y Shim',y_shim_val,4); %0 %1 %0.5 (!! will be different value for bipolar supply)
    setAnalogChannel(calctime(curtime,0),'X Shim',x_shim_val,3); %1.5 %2 %1.6 (!! will be different value for bipolar supply)
    setAnalogChannel(calctime(curtime,0),'Z Shim',z_shim_val,3); %1.05 %0.95 %0.8 (!! will be different value for bipolar supply)
    
    %ramp up vertical shim
    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
     
    %v_shim_val = 0.28; %don't change!!! plug is referenced to this value
    %AnalogFunc(calctime(curtime,-200),28,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),200,200,v_shim_val,0.0);

%% RF Evaporation Knife (for benchmarking power)

    if RF_benchmark_evap

        max_knife_time = 5000;

        %turn RF on:
        setDigitalChannel(calctime(curtime,0),19,1);
        setAnalogChannel(curtime, 39, -2, 1);

        %list
        rf_knife_list= 0:100:1250;

        %Create Randomized list
        index=seqdata.randcyclelist(seqdata.cycle);

        knife_time = rf_knife_list(index);
        addOutputParam('knife_time',knife_time);

        if ~(knife_time == 0)
            curtime = DDS_sweep(calctime(curtime,10),1,20*1E6,20*1E6,knife_time);
        end

        %turn RF on:
        setDigitalChannel(calctime(curtime,0),19,0); 

        curtime = calctime(curtime,max_knife_time-knife_time);

    end

%% Evaporate in Tight QP Trap

    if ( seqdata.flags.RF_evap_stages(1) == 1 )

         fake_sweep = 0;

         hold_time = 100;
         pre_hold_time =  100;

         %BEC March 14
         start_freq = 42;%42 35
%         
%         freqs_1 = [start_freq 30 15 10]*MHz; %7.5
%         RF_gain_1 = [9 9 9]*(5)/9*0.75; %9 9 9
%         sweep_times_1 = [17000 8000 4000 ]; %1500
%     

        %this worked well with 0.6 kitten
        freqs_1 = [start_freq 28 15 12]*MHz; %7.5
        RF_gain_1 = [9 9 9 9]*(5)/9*0.75; %9 9 9 (5)/9*0.75
        sweep_times_1 = [16000 8000 3000].*1*.95; % %[17000 8000 3000]  [16000 8000 3000].*1*.95; Dec 7 2013, [16000 8000 3000].*1*.65; Seemed as good or better for Rb only evap
                                            %can shrink to 0.5 without
                                            %losing rb nymber
      
%         %fast evap
%          freqs_1 = [start_freq 15]*MHz; %7.5
%         RF_gain_1 = [9]*(5)/9*0.75; %9 9 9
%         sweep_times_1 = [15000]; % %[17000 8000 3000]
% % 


        %hold before evap
curtime = calctime(curtime,pre_hold_time);

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) ~= 0));

    %hold after evap to measure heating
% curtime = calctime(curtime,hold_time1);

    elseif ~(mag_trap_MOT || MOT_abs_image)
curtime = calctime(curtime,0); %changed from 100ms to 0ms   
    end

    %This does a fast evaporation to benchmark the transport
    if ( seqdata.flags.RF_evap_stages(1) == 2 )

         fake_sweep = 1;

         hold_time = 100;

         %BEC March 14
         start_freq = 42;%35

        %this worked well with 0.6 kitten
        freqs_1 = [start_freq 10]*MHz; %7.5
        RF_gain_1 = [9]*(5)/9*0.75; %9 9 9
        sweep_times_1 = [15000]; 

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
            RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) ~= 0));

    end


%% Ramp down QP and transfer to the window

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_before_transfer(curtime, seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);

%% Do Recapture MOT/molasses

    if MOTmolasses_recap ==1;

[curtime I_QP V_QP]= MOT_molasses_recap(curtime, I_QP, V_QP);

    end


%% Ramp on Plug
% ramped up once atoms arrived at imaging position (or a bit later, but not earlier)

if ( seqdata.flags.do_plug == 1 )
   
    plugpwr =1*1000E-3; %1*1000E-3 %% changed to a controlable value (Nov 2013)
    
    %set plug on time from end of evap       
    plug_offset = -200; % -200
    
    if plug_offset < -500
        error('Plug turns on before atoms arrive at imaging position!');
    end
        
    %open plug shutter
    setDigitalChannel(calctime(curtime,plug_offset),10,1);
    %ramp on plug beam
    %AnalogFunc(calctime(curtime,plug_offset+1),33,@(t,tt,pwr)(pwr*t/tt),100,100,plugpwr);
    setAnalogChannel(calctime(curtime,plug_offset+1),33,plugpwr);
    ScopeTriggerPulse(calctime(curtime,plug_offset+1),'Plug')
    
curtime = calctime(curtime,700);%700
 
end

%% Evaporation Stage 1b
% At the imaging position

if ( seqdata.flags.RF_evap_stages(3) == 1 )

    fake_sweep = 0;
    

%     
% %         %Make a small cloud for vertical imaging
%      freqs_1b = [freqs_1(end)/MHz*0.8 4 1 0.25]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [3000 1500 2500]; %1500
    
% %     Evaporate to 0.7MHz to load into ODT (0.8MHz to look at Rb)

% 
    freqs_1b = [freqs_1(end)/MHz*0.8 4 0.8 2]*MHz; %0.28 %0.315
    RF_gain_1b = [-4 -4 -7 -7]; %-4
    sweep_times_1b = [3000 2500 10]; %1500
% %     
%     %Evaporate lower to clear out the Rb, leaving only K in the XDT
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 0.4]*MHz;
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [3000 2500 ]; %1500
% % % %     
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 2 0.4]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [3000 2500 1000]; %1500
% %     
%     freqs_1b = [freqs_1(end)/MHz*0.8 5]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -7]; %-4
%     sweep_times_1b = [1500 ]; %1500
%     
%     %Evaporate to 0.7MHz to load into ODT
%     freqs_1b = [freqs_1(end)/MHz*0.8 4 2 0.7]*MHz; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -4]; %-4
%     sweep_times_1b = [2500 1500 100]; %1500

curtime = do_evap_stage(curtime, fake_sweep, freqs_1b, sweep_times_1b, RF_gain_1b, 0, 1);


    %setAnalogChannel(calctime(curtime,0),33,0);
    
%**************to test dimple effect****************
% ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
% 
% dipole_ramp_start_time = -3000; %-3000
% dipole_ramp_up_time = 1500; %500
% 
% CDT_power = 4; %4.5
% 
% dipole1_power = 0*CDT_power;
% dipole2_power = 0.75/0.75*CDT_power; %Voltage = 0.328 + 0.2375*dipole_power...about 4.2Watts/V when dipole 1 is off
%  
% %ramp dipole 1 trap on
% AnalogFunc(calctime(curtime,dipole_ramp_start_time),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole1_power,0);
% %ramp dipole 2 trap on
% AnalogFunc(calctime(curtime,dipole_ramp_start_time),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole2_power,0);
% 
% %shut off dipole 1
% setAnalogChannel(calctime(curtime,0),40,0,1);
% %shut off dipole 2
% setAnalogChannel(calctime(curtime,0),38,0,1);

%******************
 
    %AnalogFunc(calctime(curtime,-3000),33,@(t,tt,pwr1,pwr2)(pwr1+(pwr2-pwr1)*t/tt),300,300,plugpwr,plugpwr*0.95);
    
    
%     % scan list
%     hold_time_list = 0:1000:10000;
%     qp_hold = scan_parameter(hold_time_list,'qp_hold','random');
% 
% curtime = calctime(curtime,qp_hold); %3000
    
    %*************
    %blow-away Rb
    do_Rb_blow_away = 0;

   

    if do_Rb_blow_away
        
         %blow away any atoms left in F=2
        %open Rb probe shutter
        setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,-10),4,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,-10),24,1);
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);
        
        %pulse beam with TTL
        curtime = DigitalPulse(calctime(curtime,0),24,15,0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
        
    else
    end
    
     do_K_blow_away = 0;
    
     K_blow_away_time = -15; %1350
     
     if do_K_blow_away
          
        %open K probe shutter
        setDigitalChannel(calctime(curtime,K_blow_away_time-10),30,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,K_blow_away_time-10),29,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,K_blow_away_time-10),9,1);
        %set detuning
        setAnalogChannel(calctime(curtime,K_blow_away_time-10),5,0);
        
        %pulse beam with TTL
        DigitalPulse(calctime(curtime,K_blow_away_time),9,15,0);
        
        %close K probe shutter
        setDigitalChannel(calctime(curtime,K_blow_away_time+15),30,0);
        %%0=closed, 1=open
        
    else
    end
     
    %**************

    %hold at end of evap
    curtime = calctime(curtime,0); %3000
    
   
% Microwave evaporation instead of RF    
elseif ( seqdata.flags.RF_evap_stages(3) == 2 )
 
    freqs_1b = [freqs_1(end)/MHz*0.6 4 1.0 ]*MHz; 
    RF_gain_1b = [-4 -4 -7]; 
    sweep_times_1b = [4000 3500 ]*6/6;
    
    %Do uWave evaporation
    curtime = do_uwave_evap_stage(curtime, fake_sweep, freqs_1b*3, sweep_times_1b, 0);
    
    
end

%Pulse on the lattice beam after releasing from the QP trap
if ( seqdata.flags.pulse_lattice_for_alignment == 2 )
    
    tof_pulse = 0;
    
    if tof_pulse
    
        lattice_before_on_time = 5;
        %pulse the lattice on during TOF
        DigitalPulse(calctime(curtime,-lattice_before_on_time),11,lattice_before_on_time+30,0);

    else        
        lattice_pulse_time = 0.06+0.07;

        %pulse lattice
        DigitalPulse(calctime(curtime,-0.07),11,lattice_pulse_time,0);

%         DigitalPulse(calctime(curtime,0),'ScopeTrigger',0.1,1);
        
        curtime = calctime(curtime,lattice_pulse_time-0.065);        
    end
end


if ( seqdata.flags.do_dipole_trap == 2 )
    
    dipole1_power = 0;
    dipole2_power = 7;
    
    %If we haven't done RF Stage 1b, need to make a fake sweep time
    if ~exist('sweep_times_1b','var')
        sweep_times_1b = [0];
    else
    end
    
    %dipole 1
    setAnalogChannel(calctime(curtime,-1*sum(sweep_times_1b)-20),'dipoleTrap1',dipole1_power);
    %dipole 2
    setAnalogChannel(calctime(curtime,-1*sum(sweep_times_1b)-20),'dipoleTrap2',dipole2_power);
     
end

%*************align molasses beam to QP
if ( seqdata.flags.do_imaging_molasses == 2 )
   
    drop_time = 2;
    
    imaging_molasses(calctime(curtime,drop_time));
    
else
end
%************************

%turn plug off
if ( seqdata.flags.do_plug == 1)
    
    plug_offset = 0*-2.5; %0 for experiment, -10 to align for in trap image
    
    if ( seqdata.flags.do_dipole_trap ~= 1 )
        setAnalogChannel(calctime(curtime,plug_offset),33,0);
        setDigitalChannel(calctime(curtime,plug_offset-2),10,0);
    end    
    
end

%% Dipole trap ramp on (and QP rampdown)
if ( seqdata.flags.do_dipole_trap == 1 )

    dipole_on_time = 10; %500
    

    [curtime I_QP V_QP P_dip dip_holdtime] = dipole_transfer(curtime, I_QP, V_QP);
    
    %[curtime I_QP V_QP P_dip] = single_dipole_transfer(curtime, I_QP, V_QP, 1);
 
    %curtime = calctime(curtime, dipole_on_time);
    
  
    
end

curtime=calctime(curtime,0);


%% Pulse lattice after releasing from dipole trap

if ( seqdata.flags.pulse_lattice_for_alignment == 1 )
    
     curtime = Pulse_Lattice(curtime);

end

%% Load Lattice

if ( seqdata.flags.load_lattice ~= 0 )

    [curtime P_dip P_Xlattice P_Ylattice P_Zlattice P_RotWave]= Load_Lattice(curtime);
else
    
end

%% Deep Lattice For Imaging (includes molasses function)

if ( seqdata.flags.load_lattice == 2 )
    
    curtime = Deep_Lattice(curtime, P_dip,P_Xlattice,P_Ylattice,P_Zlattice,P_RotWave);
else
    
end


%% Imaging Molasses

 if ( seqdata.flags.do_imaging_molasses == 1 || seqdata.flags.do_imaging_molasses == 3 )
      
    [curtime,img_molasses_time] = imaging_molasses(calctime(curtime,0));%0.5  
 end


%% lower atoms from window for clean TOF release

    if ( seqdata.flags.lower_atoms_after_evap == 1 )

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
    
% %     %pulse z shim to induce SG
%     setAnalogChannel(calctime(curtime,-0.5),28,3,1);
%    setAnalogChannel(calctime(curtime,5),28,0.8,1);
   
   %
   
    %turn the Magnetic Trap off

    %set all transport coils to zero (except MOT)
    for i = [7 9:17 22:24] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end

    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
    
        
%     if ( seqdata.flags.do_dipole_trap == 1 )
%         
%         if ramp_fesh_slowly == 0;
%             %set Feshbach field to 0
%             SetDigitalChannel(calctime(curtime,0),31,0); %fast switch
%             setAnalogChannel(calctime(curtime,0),37,-0.1,1);%0
%         elseif ramp_fesh_slowly == 1;
%             fesh_ramptime = 15;
%             SetDigitalChannel(calctime(curtime,0),31,0); %fast switch
%             AnalogFunc(calctime(curtime,-fesh_ramptime),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_ramptime,fesh_ramptime,0,21.0);
%         end
%     end
    %ramp up science QP
    % AnalogFunc(calctime(curtime,0),18,@(t,tt)(10*(1+0.2/tt*t)),100,100);
    % curtime = AnalogFunc(calctime(curtime,0),1,@(t,tt)(11*(1+1/tt*t)),100,100);
    % 

    
    
    %Turn off QP Coils
    setAnalogChannel(calctime(curtime,0),21,0,1); %15
curtime = setAnalogChannel(calctime(curtime,0),1,0,1); %16
curtime = setAnalogChannel(curtime,3,0,1); %kitten
 
    
    %MOT
    if ( seqdata.flags.image_type ~= 4 )
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
    else
        %Cannot use Coil 16 fast switch if atoms have not be transferred to
        %imaging direction!
    end
    
    %turn off 15/16 switch (10 ms later)
    setDigitalChannel(calctime(curtime,qp_switch1_delay_time),22,0);


if ( seqdata.flags. do_dipole_trap ~= 0 )
   
    if seqdata.flags. do_dipole_trap == 2
    
        %Leave ODT on during 15ms TOF
        %turn off dipole trap 1
        setAnalogChannel(calctime(curtime,14.5),40,-0.3,1);
        %turn off dipole trap 2
        setAnalogChannel(calctime(curtime,14.5),38,-0.3,1);
        
    else
    
        %turn off dipole trap 1
        setAnalogChannel(calctime(curtime,0),40,-0.3,1);
        %turn off dipole trap 2
        setAnalogChannel(calctime(curtime,0),38,-0.3,1);
        
    end
          
end

if ( seqdata.flags.load_lattice ~= 0 )
%turn lattice beams off (leave a bit of time for the rotating waveplate to
%                           get back to zero)


    %Z lattice
    setAnalogChannel(calctime(curtime,0),43,-1,2);%0
    %Y lattice
    setAnalogChannel(calctime(curtime,0),44,-1,2);%0
    %X lattice
    setAnalogChannel(calctime(curtime,0),45,-1,2);%0
    
    %set rotating waveplate back to full dipole power
%     setAnalogChannel(curtime,'latticeWaveplate',0.0,3); %

end





if ~(seqdata.flags.image_type==1 || seqdata.flags.image_type==4)
    setDigitalChannel(curtime,16,1);    
end

%% Recap molasses

if recap_molasses ==1;
    
    curtime = recap_molasses(curtime);
    
    D1_Recap = 1 ;
    
     recap_cooling_time = 1; %0.7
    recap_start_time = -0.15;
    
    if D1_Recap == 0 
    

        %Turn on D2 beams
        %turn on trap
            %analog
            setAnalogChannel(calctime(curtime, recap_start_time),26,0.7,1);
            %TTL
            DigitalPulse(calctime(curtime, recap_start_time),6,recap_cooling_time-recap_start_time,0); %1 off, 0 on
            %Shutter
            DigitalPulse(calctime(curtime,-3+ recap_start_time),2,recap_cooling_time-recap_start_time,1);
        %turn on repump
            %analog
            setAnalogChannel(calctime(curtime,recap_start_time),25,0.7,1);
            %TTL
            DigitalPulse(calctime(curtime,recap_start_time),7,recap_cooling_time-recap_start_time,0);
            %Shutter
            DigitalPulse(calctime(curtime,-3+recap_start_time),3,recap_cooling_time-recap_start_time,1);
    
            curtime = calctime(curtime,recap_cooling_time);
            
             %Turn off D2 beams
        %turn off trap
            %analog
            setAnalogChannel(calctime(curtime,0),26,0.0,1);
        %turn off repump
            %analog
            setAnalogChannel(calctime(curtime,0),25,0.0,1);
            
            
    else
            
    D1_AM_control =1; %0 - TTL Pulse, 1 - AM Controlled Ramp
    
    recap_cooling_time = 0.8; %0.7
    recap_start_time = 3;
    
     %blow away any atoms left in F=2
        %open shutter
        setDigitalChannel(calctime(curtime,-11),25,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,-11),26,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,-11),24,1);
        %set detuning
        setAnalogChannel(calctime(curtime,-11),34,6590-237);

        %pulse beam with TTL 
        curtime = DigitalPulse(calctime(curtime,-10),24,10,0);
        
        %close shutter
        %setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
    

            
    %Turn on D1 beams
        if D1_AM_control == 0
        %Pulse beam with TTL Only
            %Set D1 Power
            setAnalogChannel(calctime(curtime,-10),47,0);
            %Shutter  
            DigitalPulse(calctime(curtime, recap_start_time-2),36,recap_cooling_time + recap_start_time + 2,1);
            %TTL
            DigitalPulse(calctime(curtime, recap_start_time),35,recap_cooling_time,1);
        elseif D1_AM_control == 1
        %Open TTL and then Ramp on Beam with AM
            %Shutter  
            %Opening the shutter 2ms before the TTL was clipping the
            %beam... changed to 3ms on Aug 8th - GE
            DigitalPulse(calctime(curtime, recap_start_time-3),36,recap_cooling_time + recap_start_time + 2,1);
            %Turn on TTL
            setDigitalChannel(calctime(curtime,recap_start_time),35,1);
            
            %Analog Ramp
            D1_startpower = 0;
            D1_endpower = 2.6;
            D1_ramptime = recap_cooling_time;
            Analogfunc(calctime(curtime,recap_start_time),47,@(t,tt,y0,y1)(y1*t/tt+y0),D1_ramptime,D1_ramptime,D1_startpower,D1_endpower);
            
            %Turn off TTL at end of ramp
            setDigitalChannel(calctime(curtime,recap_start_time + recap_cooling_time),35,0);
            %Turn AM Control Back Down
            setAnalogChannel(calctime(curtime,recap_start_time + recap_cooling_time),47,0,1);
        end

        curtime = calctime(curtime,recap_start_time+1);
        
    end
    
elseif recap_molasses ==2;
    
    %curtime = Rb_molasses(curtime);
    
    
end

%% Imaging


if seqdata.flags.image_type == 0 % Absorption Image
    curtime = absorption_image(calctime(curtime,0.0)); 
%     curtime = absorption_image_old-2014-03-26(calctime(curtime,0.0)); 
                    
elseif seqdata.flags.image_type == 1 %Recapture

    curtime = recap_image(curtime);

elseif seqdata.flags.image_type == 2 %fluorescence
        
    curtime = fluor_image(calctime(curtime,0.0)); 
    
elseif seqdata.flags.image_type == 3 %blue absorption image
    
    curtime = blue_absorption_image(calctime(curtime,0.0),seqdata.flags.image_loc); 

elseif seqdata.flags.image_type == 4 %MOT fluor image
    
    curtime = MOT_fluor_image(curtime);
    
elseif seqdata.flags.image_type == 5 %look at mot fluorescence recap with PD
    
elseif seqdata.flags.image_type == 6 %recapture with the exact mot sequence
            
    %setAnalogChannel(calctime(curtime,0),31,0);
    curtime = Load_MOT(calctime(curtime,0),30);
    curtime = MOT_fluor_image(calctime(curtime,50));
    addOutputParam('recap_wait', 50);  

elseif seqdata.flags.image_type == 7 %This takes two fluorescent images after do_imaging_molasses
    
    curtime = lattice_fluor_image(calctime(curtime,0.0),img_molasses_time); 
  
elseif seqdata.flags.image_type == 99 %no image (if a camera trigger has been inserted elsewhere for testing)
    
else
    error('Undefined imaging type');
end
%% Post-sequence -- e.g. do controlled field ramps, heating pulses, etc.
ramp_fesh_during_cycles = 0;
if ramp_fesh_during_cycles
    fesh_ramptime = 100;
    fesh_final = 22.6;
    fesh_ontime = 1000;
    SetDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);

%     SetDigitalChannel(calctime(curtime,50),31,0);
%     setAnalogChannel(calctime(curtime,50),37,22.6);
%     
%     DigitalPulse(calctime(curtime,60),31,5,1);
%     DigitalPulse(calctime(curtime,70),31,5,1);
%     DigitalPulse(calctime(curtime,80),31,5,1);
%     DigitalPulse(calctime(curtime,90),31,5,1);
    
    setAnalogChannel(calctime(curtime,100),37,0);
    
    curtime = demagnetize_chamber(calctime(curtime,150));
end


%% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

%% Reset analog and digital channels to default values

curtime = Reset_Channels(calctime(curtime,0));


%% Load MOT
% 

 rb_MOT_detuning = 33; %33  34
 k_MOT_detuning = 33; %33

 
 
 mot_wait_time = 50;
  
 if seqdata.flags.image_type==5
     mot_wait_time = 0;
 end
    
      

%call Load_MOT function
      curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);

      %Shutter
            %setDigitalChannel(calctime(curtime,0),2,0);
      
if ( seqdata.flags.do_dipole_trap == 1 )
        curtime = calctime(curtime,dip_holdtime);
        
    elseif mag_trap_MOT || MOT_abs_image

        curtime = calctime(curtime,100);
        
    else
        curtime = calctime(curtime,1*25000);%25000
end


%set relay back
curtime = setDigitalChannel(calctime(curtime,10),28,0);


% % %MOT stagger
%  K_MOT_before_RbMOT_time =5000;
% % 
%  curtime = calctime(curtime,K_MOT_before_RbMOT_time);




%% Put in Dark Spot

%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

%% Close Coil 16 fast switch

%setAnalogChannel(calctime(curtime,0),31,0);

%% Scope trigger selection

SelectScopeTrigger(scope_trigger);

%% Timeout

timeout = curtime;


end