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

%Ambient field cancelling values (ramp to these at end of XDT loading)
% seqdata.params. shim_zero = [(0.1585-0.0160+0.005), (-0.0432-0.022-0.005), (-0.0865-0.015+0.005)];  %Bipolar shim values (x,y,z) which zero the ambient field (found using uWave spectroscopy on May 9th, 2014)
seqdata.params. shim_zero = [(0.1585-0.0160), (-0.0432-0.022), (-0.0865-0.015)];
% seqdata.params. shim_zero = [0,0,0];


%Shim values that align the plugged-QP trap (these are non-zero, since the
%centre of the imaging window is different from the natural QP centre)
% seqdata.params. plug_shims = [(seqdata.params. shim_zero(1)-1-0.04), (seqdata.params. shim_zero(2)+0.125+0.04), (seqdata.params. shim_zero(3)+ 0.35-0.015)];%.46 -1.7 0.022
% seqdata.params. plug_shims = [(seqdata.params. shim_zero(1)-0.5), (seqdata.params. shim_zero(2)+0.125), (seqdata.params. shim_zero(3)+ 0.35 + 0.3)];%+.35+.35
% seqdata.params. plug_shims = [(seqdata.params. shim_zero(1)-1-0.04-0.4), (seqdata.params. shim_zero(2)+0.125), (seqdata.params. shim_zero(3)+ 0.35 + 0.35 + 0.20)];%0.35 + 0.55)];
seqdata.params. plug_shims = [(seqdata.params. shim_zero(1)-1-0.04-0.3),...
    (seqdata.params. shim_zero(2)+0.125), ...
    (seqdata.params. shim_zero(3)+ 0.35 + 0.35 + 0.20)];%0.35 + 0.55)];
% seqdata.params. plug_shims = [0,0,0];


%-1.000
% seqdata.params. plug_shims = [seqdata.params. shim_zero(1)+0.025
% seqdata.params. shim_zero(2)+0.00 seqdata.params. shim_zero(3)+0.07];
%Parameters that gave the coldest clouds after RF Stage 1b.
% seqdata.params. plug_shims = [seqdata.params. shim_zero(1)-0.04 seqdata.params. shim_zero(2)+0.00 seqdata.params. shim_zero(3)-0.10];

seqdata.params. shim_val = [0 0 0]; %Current shim values (x,y,z)- reset to zero

hold_list = [500];
seqdata.params. molasses_time = getScanParameter(hold_list,...
    seqdata.scancycle,seqdata.randcyclelist,'hold_list');%192.5;
addOutputParam('molasses_hold_list',seqdata.params. molasses_time); 
       
% Dipole trap and lattice beam parameters 
seqdata.params. XDT_area_ratio = 1; % DT2 with respect to DT1

% Rb Probe Beam AOM Order
seqdata.flags.Rb_Probe_Order = 1;   %1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                    %2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT

seqdata.flags. in_trap_OP = 0; 
seqdata.flags. plane_selection_after_D1 = 0;
seqdata.flags. lattice_img_molasses = 0;
seqdata.flags. SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB
        
kHz = 1E3;
MHz = 1E6;
GHz = 1E9;

%% Initialize channes

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
    seqdata.flags.rb_vert_insitu_image = 0; 
    %take a vertical in-situ image of BEC in XDT to centre the microscope objective
    
    seqdata.flags.controlled_load = 0; %do a specific load time
    controlled_load_time = 20000;

    % Imaging
    seqdata.flags.image_type = 0; 
    %0: absorption image, 1: recapture, 2:fluor, 
    %3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 
    %6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses 
    %8: iXon fluorescence + Pixelfly absorption
        iXon_movie = 1; %Take a multiple frame movie?
    seqdata.flags.image_atomtype = 1;%  0= Rb, 1 = K, 2 = Rb+K
    seqdata.flags.image_loc = 1; %0: `+-+MOT cell, 1: science chamber    
    seqdata.flags.img_direction = 1; 
    %1 = x direction (Sci) / MOT, 2 = y direction (Sci), 
    %3 = vertical direction, 4 = x direc tion (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
    seqdata.flags.do_stern_gerlach = 0; %1: Do a gradient pulse at the beginning of ToF
    seqdata.flags.iXon = 0; % use iXon camera to take an absorption image (only vertical)
    seqdata.flags.do_F1_pulse = 1; % repump Rb F=1 before/during imaging
    seqdata.flags.In_Trap_imaging = 0;
    seqdata.flags.High_Field_Imaging = 0;
    %1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
    %3 = make sure shim are off for D1 molasses (should be removed)
    seqdata.flags.K_D2_gray_molasses = 0;
    seqdata.params.tof =  5;  % 45 for rough alignment, 20 for K-D diffraction
    seqdata.params.UV_on_time = 10000; %UV on time + savingtime + wait time = real wait time between cycles%
    % usually 15s for non XDT
    
    
    % Transport curves
    seqdata.flags.hor_transport_type = 1; 
    %0: min jerk curves, 1: slow down in middle section curves, 2: none
    seqdata.flags.ver_transport_type = 3; 
    %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear, 4: triple min jerk

    % For debugging: enable only certain coils during the transport
    % sequence (and only during the transport sequence!)
    % seqdata.coil_enable = ones(1,23); % can comment these lines for normal operation
    % seqdata.coil_enable(8) = 0; %coil 7
    % List of channels as they are ordered in transport_coil_currents*.m:
    % 1:a18, 2:a7, 3:a8 4:a9, 5:a10, 6:a11, 7:a12, 8:a13, 9:a14, 10:a15,
    % 11:a16, 12:a17, 13:a9, 14:a22, 15:a23, 16:a24, 17:a20, 18:a21, 19:a6,
    % 20:a3, 21:a17, 22:d22, 23:d28
    % use this order with the boolean enable array!

    % Use stage1  = 2 to evaporate fast for transport benchmarking
    % Use stage1b = 2 to do microwave evaporation in the plugged QP trap
    seqdata.flags.compress_QP = 1; % compress QP after transport
    seqdata.flags.RF_evap_stages = [1,1,1]; %[stage1, decomp/transport, stage1b] %Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.
    rf_evap_time_scale = [1.0 1.2];[0.8 1.2];[1.0 1.2]; %[0.9 1] little improvement; [0.2 1.2] small clouds but fast [0.7, 1.6]
    RF_1B_Final_Frequency = 0.45;
    seqdata.flags.do_plug = 1;    % ramp on plug after transfer to window
    seqdata.flags.lower_atoms_after_evap = 0; % lower hot cloud after evap to get clean TOF signal

    % Dipole trap
    seqdata.flags.do_dipole_trap = 0; % 1: dipole trap loading, 2: dipole trap pulse, 3: pulse on dipole trap during evaporation
    seqdata.flags.CDT_evap = 0;        % 1: exp. evap, 2: fast lin. rampdown to test depth, 3: piecewise lin. evap 
    seqdata.flags.K_RF_sweep = 0;    %sweep 40K into |9/2,-9/2>; %create mixture in XDT, go to dipole-transfer,  40K RF Sweep, set second_sweep to 1    
    seqdata.flags.init_K_RF_sweep = 0; %sweep 40K into |9/2,-9/2>; %create mixture in XDT before evap, go to dipole-transfer,  40K RF Sweep, set second_sweep to 1  
    seqdata.flags.compensation_in_modulation = 0; %turn on a compensation beam

    % Optical lattice
    seqdata.flags.load_lattice = 0; % set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
    seqdata.flags.pulse_lattice_for_alignment = 0; % 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
    seqdata.flags.pulse_zlattice_for_alignment = 0; % 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)

    if (seqdata.flags.do_dipole_trap ~= 0 || seqdata.flags.load_lattice ~= 0)
        seqdata.flags.QP_imaging = 0;
    else
        seqdata.flags.QP_imaging = 1;
    end
    
    %Imaging Molasses
    seqdata.flags.do_imaging_molasses = 0; % 1: In Lattice or XDT, 2: Free space after QP, 3: Free Space after XDT
    seqdata.flags.evap_away_Rb_in_QP = 0; %Evaporate to 0.4MHz in QP+XDT to kill Rb and load lots of K (only works when loading XDT)
    seqdata.flags.pulse_raman_beams = 0; % pulse on D2 raman beams for testing / alignment

    %Recap molasses
    recap_molasses = 0; %1 D1 molasses, 2 rb_molasses

    scope_trigger = 'Load lattices'; 
%   exclude_trigger = 'all';

%% Set switches for predefined scenarios

    if seqdata.flags.rb_vert_insitu_image
        %Necessary flags to switch from K fluorescence images to Rb abs
        %with iXon
        seqdata.flags. image_atomtype = 0;
        seqdata.flags. image_type = 0;
        seqdata.flags. iXon = 1;
        seqdata.params. tof = 0.2;
        
        seqdata.flags. CDT_evap = 1;
        seqdata.flags. load_lattice = 0;
        seqdata.flags. do_imaging_molasses = 0;
    end

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
% If the cloud moves up, the voltage must increase to refocus
%  (as the experiment warms up, selected plane tends to move up a bit)
    
    obj_piezo_V_List = [4.6];
    % 0.1V = 700 nm, must be larger than 0. larger value means farther away from the window.
    obj_piezo_V = getScanParameter(obj_piezo_V_List, seqdata.scancycle, seqdata.randcyclelist, 'Objective_Piezo_Z');%5
    % obj_piezo_V = 6.8;
    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);
    addOutputParam('objpzt',obj_piezo_V);
    
    
% Set 4-Pass Frequency
%Don't want to do this with every cycle since it drops the connection
%sometimes and doesn't turn on correctly
% 
% detuning_list = [0];[0];300;
% df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
% DDSFreq = 324.20625*MHz + df*kHz/4;
% DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
% addOutputParam('DDSFreq',DDSFreq);


% %Set the frequency of the first DP AOM 
% D1_FM_List = [222.5];
% D1_FM = getScanParameter(D1_FM_List, seqdata.scancycle, seqdata.randcyclelist);%5
% setAnalogChannel(calctime(curtime,0),'D1 FM',D1_FM);
% addOutputParam('D1_DP_FM',D1_FM);

%% Make sure dipole and lattice traps are off and adjust XDT piezo mirrors
%% and initialize repump imaging.

    %Initialize modulation ramp to off.
    setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0);

    %Initialize the Raman VVA to on.
    setAnalogChannel(calctime(curtime,0),'Raman VVA',9.9);

    %close all RF and uWave switches
    setDigitalChannel(calctime(curtime,0),'RF TTL',0);
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
    setAnalogChannel(calctime(curtime,0),'uWave VVA',10);
    
    %Set both transfer switches back to initial positions
    setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0); %0 = RF
    setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); %1 = Rb
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler
    
    %Reset Feschbach coil regulation
    setDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);  %Integrator disabled
%     setDigitalChannel(calctime(curtime,0),'FB sensitivity select',0);   %Low sensitivity
    setDigitalChannel(calctime(curtime,0),'FB offset select',0);        %No offset voltage
    
    %turn off dipole trap beams
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.5,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    setDigitalChannel(calctime(curtime,10),'XDT Direct Control',1);
    
    %turn off lattice beams
    setAnalogChannel(calctime(curtime,0),'xLattice',-0.1,1);
    setAnalogChannel(calctime(curtime,0),'yLattice',-9.9,1);
    setAnalogChannel(calctime(curtime,0),'zLattice',-0.1,1);
    
%     setDigitalChannel(calctime(curtime,0),'xLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
    
    %set rotating waveplate back to full dipole power
    AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);
    
    %set uWave Generator Selection back to SRS A by default
    setDigitalChannel(curtime,'K uWave Source',0);
    
    % Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
    CDT_piezo_X = 0;
    CDT_piezo_Y = 0;
    CDT_piezo_Z = 0;
    setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X);
    setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y);
    setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z);
%     addOutputParam('piezoX',CDT_piezo_X);

    %Close science cell repump shutter
    setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
    setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed
        
    %Kill beam AOM on to keep warm.
    setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
    setDigitalChannel(curtime,'Downwards D2 Shutter',0);
    
    %Pulsed beams on to keep warm.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
    
    %Set Raman AOM TTL to open.
    %Turn off Raman shutter with TTL.
    setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
    setDigitalChannel(calctime(curtime,0),'Raman TTL',1);
    
    %Set 'D1' Raman AOMs to open, shutter closed.
    setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
    setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);
    
    %Set TTL to keep F-pump and mF-pump warm.
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
    setAnalogChannel(calctime(curtime,0),'F Pump',9.99);
    
    %Set dimple trap regulation off.
%     setDigitalChannel(calctime(curtime,0),'Dimple TTL',1);
%     setAnalogChannel(calctime(curtime,0),'Dimple Pwr',0);
%     setDigitalChannel(calctime(curtime,0),'Dimple Shutter',0);
    
    %Plug beam
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on##################################

    %Compensation beams
%     setAnalogChannel(calctime(curtime,0),'Compensation Power',9.9,1);
%     setDigitalChannel(calctime(curtime,0),'Compensation Direct',1); %0: off, 1: on
   
    %High-field imaging
    setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
    setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);

    
%% Make sure Shim supply relay is on

%Turn on MOT Shim Supply Relay
    setDigitalChannel(calctime(curtime,0),33,1);

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

% set SRS A, in order to generate a coherent source for the K trap single
% pass AOM 2018-03-14
% % % % % % addGPIBCommand(27,'FREQ 321.4 MHz; AMPR 1.05 dBm; MODL 0; DISP 2; ENBR 1;');

curtime = Prepare_MOT_for_MagTrap(curtime);
   
    %Open other AOMS to keep them warm. Why ever turn them off for long
    %when we have shutters to do our dirty work?
    setDigitalChannel(calctime(curtime,10),'K Trap TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Trap AM',0.8);
    
    setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',0);    
    setAnalogChannel(calctime(curtime,10),'Rb Trap AM',0.7);

    setDigitalChannel(calctime(curtime,10),'K Repump TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Repump AM',0.45);
    
    setAnalogChannel(calctime(curtime,10),'Rb Repump AM',0.9);

%% Load into Magnetic Trap

    if ~( MOT_abs_image || seqdata.flags.image_type==4 )

    %     %same as molasses (assume this zero's external fields)

        yshim2 = 0.25;%0.25; %0.9
        xshim2 = 0.25;%0.2; %0.1
        zshim2 = 0.05;%0.05; %0.3  0.0 Dec 4th 2013

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

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_after_trans(curtime, seqdata.flags.compress_QP);

%     ScopeTriggerPulse(calctime(curtime,-3000),'Ramp QP');
    
    %Shim Values to Turn On To: (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
    y_shim_val = seqdata.params. plug_shims(2); %0*0.5
    x_shim_val = seqdata.params. plug_shims(1); %0*1.6
    z_shim_val = seqdata.params. plug_shims(3); %0*0.8
%     z_shim_val = -0.40; %0*0.8
       
%     x_shim_val = -0.100;    %-0.125 2014-06-03 %(-0.15 2014-05-05): to optimize plug evaporation (temporarily)
%     y_shim_val = 0.00;      % 0.00 2014-06-03
%     z_shim_val = -0.2;      %-0.05 2014-06-03
    
    %turn on shims
    AnalogFuncTo(calctime(curtime,0),'Y Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,y_shim_val,4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,x_shim_val,3); 
curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,z_shim_val,3); 
%     setAnalogChannel(calctime(curtime,0),'Y Shim',y_shim_val,4); %0 %1 %0.5 (!! will be different value for bipolar supply)
%     setAnalogChannel(calctime(curtime,0),'X Shim',x_shim_val,3); %1.5 %2 %1.6 (!! will be different value for bipolar supply)
%     setAnalogChannel(calctime(curtime,0),'Z Shim',z_shim_val,3); %1.05 %0.95 %0.8 (!! will be different value for bipolar supply)
    
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
         cut_freq = 100;
         start_freq = 42;42;%42
%         
%         freqs_1 = [start_freq 30 15 10]*MHz; %7.5
%         RF_gain_1 = [9 9 9]*(5)/9*0.75; %9 9 9
%         sweep_times_1 = [17000 8000 4000 ]; %1500
%     

%         %this worked well with 0.6 kitten
        freqs_1 = [ start_freq 28 20 12]*MHz; %7.5 %[ start_freq 28 20 12]*MHz before 2018-03-06 12MHz
%         RF_gain_1 = [7 7 7 7]*(7)/9 * 0.75; %9 9 9 (5)/9*0.75
         RF_gain_1 = 0.5*[-4.1 -4.1 -4.1 -4.1]*(9)/9*1;1*[-4.1 -4.1 -4.1 -4.1]*(9)/9*1;%1*[ 9 9 9 9]*(9)/9*1;1*[-5.93 -5.93 -5.93 -5.93];  %9 9 9 (5)/9*0.75
%         sweep_times_1 = [0.5*16000 8000 3000].*rf_evap_speed(1);
        sweep_times_1 = [ 14000 6000 2000].*rf_evap_time_scale(1);%[ 12000 5000 1500].*rf_evap_speed(1);%[ 14000 6000 2000].*rf_evap_speed(1); before 2017-05-02
        %sweep_times_1 = [16000 6000 2000].*rf_evap_speed(1); % %[17000 8000 3000]  [16000 8000 3000].*1*.95; Dec 7 2013, [16000 8000 3000].*1*.65; Seemed as good or better for Rb only evap
                                            %can shrink to 0.5 without
                                            %losing rb number
      %
% %         %fast evap
%          freqs_1 = [start_freq 6]*MHz; %7.5
%         RF_gain_1 = [9]*(5)/9*0.75; %9 9 9
%         sweep_times_1 = [15000]; % %[17000 8000 3000]
% 


        %hold before evap
curtime = calctime(curtime,pre_hold_time);

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) == 0));

    %hold after evap to measure heating
% curtime = calctime(curtime,hold_time1);

    elseif ~(mag_trap_MOT || MOT_abs_image)
curtime = calctime(curtime,0); %changed from 100ms to 0ms   
    end

    %This does a fast evaporation to benchmark the transport
    if ( seqdata.flags.RF_evap_stages(1) == 2 )

         fake_sweep = 1;

         hold_time = 100;

         %Jan 2019
         start_freq = 42;%42

        %this worked well with 0.6 kitten
        freqs_1 = [start_freq 10]*MHz; %7.5
        RF_gain_1 = [9]*(5)/9*0.75;%[9]*(5)/9*0.75; %9 9 9
        sweep_times_1 = [15000]; 

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
            RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) ~= 0));

    end
    
    %Get rid of Rb afterwards (used for loading dilute 40K into lattice)
    kill_Rb_after_RFStage1 = 0;
    
    if kill_Rb_after_RFStage1
        kill_pulse_time = 5; %5

        %open shutter
            %probe
            setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
%             %repump
%             setDigitalChannel(calctime(curtime,-10),5,1);
        %open analog
            %probe
            setAnalogChannel(calctime(curtime,-10),36,0.7);
            %repump (keep off since no TTL)
            
        %set TTL
            %probe
            setDigitalChannel(calctime(curtime,-10),24,1);
            %repump doesn't have one
            
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);

        %pulse beam with TTL 
            %TTL probe pulse
            curtime = DigitalPulse(calctime(curtime,0),24,kill_pulse_time,0);
%             %repump pulse
%             setAnalogChannel(calctime(curtime,0),2,0.7); %0.7
%             curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),2,0.0);
        
        %close shutter
        curtime = setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
%         curtime = setDigitalChannel(calctime(curtime,0),5,0);
        
        curtime=calctime(curtime,5);
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
   
%     plugpwr =170; %20170124%1*1000E-3 %% changed to a controlable value (Nov 2013)
%     
%     %set plug on time from end of evap       
     plug_offset = -500; % -200
%     
%     if plug_offset < -500
%         error('Plug turns on before atoms arrive at imaging position!');
%     end
%     
%     %turn off plug AOM, breaking thermal stabilization
%     setAnalogChannel(calctime(curtime,plug_offset-100),'Plug Beam',0);%20170124
%     setDigitalChannel(calctime(curtime,plug_offset-100),'Plug TTL',1);
% %     setDigitalchannel(calctime(curtime,plug_offset-110),'Plug Mode Switch',0); %set plug ALPS to auto mode
%         
%     %open plug shutter
%     setDigitalChannel(calctime(curtime,plug_offset-10),'Plug Shutter',0);
%     setDigitalChannel(calctime(curtime,plug_offset),'Plug TTL',0);
%     %ramp on plug beam   
%     AnalogFuncTo(calctime(curtime,plug_offset),'Plug Beam',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,plugpwr);
%     %AnalogFunc(calctime(curtime,plug_offset+1),33,@(t,tt,pwr)(pwr*t/tt),100,100,plugpwr);
%     setAnalogChannel(calctime(curtime,plug_offset+55),'Plug Beam',plugpwr);
%     ScopeTriggerPulse(calctime(curtime,plug_offset+55),'Plug')
%     
% curtime = calctime(curtime,700);%700

    %USE CODE ABOVE WHEN SWITCHING BACK
    %open plug shutter
    setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',1); %0: OFF; 1: ON
%     setDigitalChannel(calctime(curtime,plug_offset),'Compensation Shutter',1);%1: on  ; 0:off
    
% Lazy code to use 'compensation beam' instead.    
%     setDigitalChannel(calctime(curtime,plug_offset-10),'Compensation Shutter',0);
%     setDigitalChannel(calctime(curtime,0),'Plug TTL',0);
%     setAnalogChannel(curtime,60,10);

%     curtime = calctime(curtime,700);
    
%     a_list = [300 400]; %560
%     apara = getmultiScanParameter(a_list,seqdata.scancycle,'apara',1,2);
%     
%     b_list = [200:100:apara]; %560
%     bpara = getmultiScanParameter(b_list,seqdata.scancycle,'bpara',1,1);
%     



 
end

%% ramp on dipole trap during last evaporation stage

if ( seqdata.flags.do_dipole_trap == 3 )
    
    dipole1_power = 0;
    dipole2_power = 0;
    
    setDigitalChannel(calctime(curtime,-700),'XDT TTL',0);
    
    %dipole 1
    setAnalogChannel(calctime(curtime,-700),'dipoleTrap1',dipole1_power); %-20
    %dipole 2
    setAnalogChannel(calctime(curtime,-700),'dipoleTrap2',dipole2_power);
     
end
%% Evaporation Stage 1b
% At the imaging position

if ( seqdata.flags.RF_evap_stages(3) == 1 )
%% RF 1b
    fake_sweep = 0;
    rf_gain_1b_list= -4;[-6.3];[-4]; %-6.3;
        rf_1b_gain=getScanParameter(rf_gain_1b_list,seqdata.scancycle,seqdata.randcyclelist,'rf_1b_gain');
% %     USUAL SETTINGS    
%     Evaporate to 0.7MHz to load into ODT (0.8MHz to look at Rb)
    freqs_1b = [freqs_1(end)/MHz*1.0 4 RF_1B_Final_Frequency 2]*MHz;
%     RF_gain_1b = [4 4 1 1]; %[-4 -4 -7 -7] prior to June 1 2015
    RF_gain_1b = [-5.5 -5.5 rf_1b_gain rf_1b_gain];[-6.74 -6.74 -7.0 -7.0];[-5.5 -5.5 rf_1b_gain rf_1b_gain];[-6.74 -6.74 -7.0 -7.0];[-6.74 -6.74 -7.0 -7.0];[-5.5 -5.5 -6.3 -6.3];[4 4 1 1];[-6.74 -6.74 -7.26 -7.26];   % 8 8 5 5
    sweep_times_1b = [3000 2000 10]*rf_evap_time_scale(2); [3000 2000 10];%[3000 2500 10]*rf_evap_speed(2);

if seqdata.flags. evap_away_Rb_in_QP == 1
    %Evaporate lower to clear out the Rb, leaving only K in the XDT
    freqs_1b = [freqs_1(end)/MHz*0.8 4 0.35 1]*MHz;
    RF_gain_1b = [4 4 1 1]; %-4
    sweep_times_1b = [3000 2500 10]*rf_evap_speed(2); %1500
else
end
%

curtime = do_evap_stage(curtime, fake_sweep, freqs_1b, sweep_times_1b, RF_gain_1b, 0, 1);

%Get rid of Rb afterwards (used for loading dilute 40K into lattice)
    kill_Rb_after_RFStage1b = 0;
    
    if kill_Rb_after_RFStage1b
        kill_pulse_time = 5; %5

        %open shutter
            %probe
            setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
%             %repump
%             setDigitalChannel(calctime(curtime,-10),5,1);
        %open analog
            %probe
            setAnalogChannel(calctime(curtime,-10),36,0.7);
            %repump (keep off since no TTL)
            
        %set TTL
            %probe
            setDigitalChannel(calctime(curtime,-10),24,1);
            %repump doesn't have one
            
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);

        %pulse beam with TTL 
            %TTL probe pulse
            curtime = DigitalPulse(calctime(curtime,0),24,kill_pulse_time,0);
%             %repump pulse
%             setAnalogChannel(calctime(curtime,0),2,0.7); %0.7
%             curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),2,0.0);
        
        %close shutter
        curtime = setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
%         curtime = setDigitalChannel(calctime(curtime,0),5,0);
        
        curtime=calctime(curtime,5);
    end
    
%% Post RF1b Tasks

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
    curtime = calctime(curtime,250); %3000
    
   
% Microwave evaporation instead of RF    
elseif ( seqdata.flags.RF_evap_stages(3) == 2 )
%% uWave Evap
 
    freqs_1b = [freqs_1(end)/MHz*0.6 4 1.0 ]*MHz; 
    RF_gain_1b = [-4 -4 -7]; 
    sweep_times_1b = [4000 3500 ]*6/6;
    
    %Do uWave evaporation
    curtime = do_uwave_evap_stage(curtime, fake_sweep, freqs_1b*3, sweep_times_1b, 0);
end

%% Post QP Evap Tasks
if ( seqdata.flags.do_dipole_trap == 2 )
    
    dipole1_power = 0;
    dipole2_power = 2;
    
    %If we haven't done RF Stage 1b, need to make a fake sweep time
    if ~exist('sweep_times_1b','var')
        sweep_times_1b = [0];
    else
    end
    
    %dipole 1
    setAnalogChannel(calctime(curtime,-1*sum(sweep_times_1b)-30),'dipoleTrap1',dipole1_power); %-20
    %dipole 2
    setAnalogChannel(calctime(curtime,-1*sum(sweep_times_1b)-30),'dipoleTrap2',dipole2_power);
     
end

%*************align molasses beam to QP
if ( seqdata.flags.do_imaging_molasses == 2 )
   
    
    
    seqdata.params. molasses_drop_time = 0.5;
    
    imaging_molasses(calctime(curtime,seqdata.params. molasses_drop_time));
    
else
end
%************************

%turn plug off
if ( seqdata.flags.do_plug == 1)
    hold_time_list = [0];
    hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_QPcoils');
    curtime = calctime(curtime,hold_time);   
    plug_offset = -2.5;175;%0 for experiment, -10 to align for in trap image
    
    if ( seqdata.flags.do_dipole_trap ~= 1 )%20170124
%         AnalogFuncTo(calctime(curtime,plug_offset-200),'Plug Beam',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 200, 200,-10);
%         setAnalogChannel(calctime(curtime,plug_offset-0),'Plug Beam',-10);
%         setDigitalChannel(calctime(curtime,plug_offset-2),'Plug TTL',1);
%         setDigitalChannel(calctime(curtime,plug_offset-2),'Plug Shutter',1);
%         %for thermal stabilization
%         setAnalogChannel(calctime(curtime,plug_offset-0+200),'Plug Beam',80);
%         setDigitalChannel(calctime(curtime,plug_offset-2+200),'Plug TTL',0);
%         % set to manual mode
%         setDigitalChannel(calctime(curtime, plug_offset+199),'Plug Mode Switch',1);

    setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',0);% 0:OFF; 1: ON
    
%     setDigitalChannel(calctime(curtime,-10),'Compensation Shutter',0); %-10
%     setDigitalChannel(calctime(curtime,0),'Plug TTL',1);

    ScopeTriggerPulse(calctime(curtime,0),'plug test');
    end    
    
end

QPTrap_Kill_Beam_Alignment = 0;
if QPTrap_Kill_Beam_Alignment
    
    kill_time = 10;
    pulse_offset_time = 0;
    
    %open K probe shutter
    setDigitalChannel(calctime(curtime,pulse_offset_time-10),'Downwards D2 Shutter',1); %0=closed, 1=open

    %set TTL off initially
    setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',0);

    %pulse beam with TTL
    DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);

    %close K probe shutter
    setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),'Downwards D2 Shutter',0);

    %set kill AOM back on
curtime = setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 5),'Kill TTL',1);
    
end
%% Dipole trap ramp on (and QP rampdown)
if ( seqdata.flags.do_dipole_trap == 1 )

    dipole_on_time = 10; %500
    

    [curtime I_QP V_QP P_dip dip_holdtime] = dipole_transfer(curtime, I_QP, V_QP);
    
    %[curtime I_QP V_QP P_dip] = single_dipole_transfer(curtime, I_QP, V_QP, 1);
 
    %curtime = calctime(curtime, dipole_on_time);
    
  
    
end

curtime=calctime(curtime,0);

%% Pulse Dimple Trap

%     DigitalPulse(calctime(curtime,-5),'Dimple TTL',20,0);


%% Pulse lattice after releasing from dipole trap

if ( seqdata.flags.pulse_lattice_for_alignment ~= 0 )
    
     curtime = Pulse_Lattice(curtime,seqdata.flags.pulse_lattice_for_alignment);

end


%% Load Lattice

if ( seqdata.flags.load_lattice ~= 0 )

    [curtime P_dip P_Xlattice P_Ylattice P_Zlattice P_RotWave]= Load_Lattice(curtime);
else
    
end

%% Pulse Z Lattice after ramping up other lattices to align

if (seqdata.flags. pulse_zlattice_for_alignment == 1 )
    
    curtime = Pulse_Lattice(curtime,4);
    
else
    
end

%% Deep Lattice For Imaging (includes molasses function)

if ( seqdata.flags.load_lattice == 2 )
    
    curtime = Deep_Lattice(curtime, P_dip,P_Xlattice,P_Ylattice,P_Zlattice,P_RotWave);
else
    
end


%% Imaging Molasses

 if ( seqdata.flags.do_imaging_molasses == 1 || seqdata.flags.do_imaging_molasses == 3 )
      
    [curtime,molasses_offset] = imaging_molasses(calctime(curtime,0));%0.5  
 end


%% lower atoms from window for clean TOF release

    if ( seqdata.flags.lower_atoms_after_evap == 1 )

        %100ms, 15A works well for RF_stage_2
        lower_transfer_time = 100;
    curtime = AnalogFunc(curtime,1,@(t,tt,dt)(dt*t/tt+I_QP),lower_transfer_time,lower_transfer_time,15-I_QP);
        
    end


%% Turn off coils and traps.  


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
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end

    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
    
        
%     if ( seqdata.flags.do_dipole_trap == 1 )
%         
%         if ramp_fesh_slowly == 0;
%             %set Feshbach field to 0
%             setDigitalChannel(calctime(curtime,0),31,0); %fast switch
%             setAnalogChannel(calctime(curtime,0),37,-0.1,1);%0
%         elseif ramp_fesh_slowly == 1;
%             fesh_ramptime = 15;
%             setDigitalChannel(calctime(curtime,0),31,0); %fast switch
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
        setDigitalChannel(calctime(curtime,25),'XDT TTL',1);
        %turn off dipole trap 1
        setAnalogChannel(calctime(curtime,25),40,0,1);
        %turn off dipole trap 2
        setAnalogChannel(calctime(curtime,25),38,0,1);
        
    end
        
    if seqdata.flags. do_dipole_trap == 1
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
        %turn off dipole trap 1
        setAnalogChannel(calctime(curtime,0),40,-0.5,1);
        %turn off dipole trap 2
        setAnalogChannel(calctime(curtime,0),38,0,1);
        setDigitalChannel(calctime(curtime,2),'XDT Direct Control',1);
    end
    
    
    if seqdata.flags. do_dipole_trap == 3
    
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
        %turn off dipole trap 1
        setAnalogChannel(calctime(curtime,0),40,0,1);
        %turn off dipole trap 2
        setAnalogChannel(calctime(curtime,0),38,0,1);
        
    end
          
end

if ( seqdata.flags.load_lattice ~= 0 )
%turn lattice beams off (leave a bit of time for the rotating waveplate to
%                           get back to zero)


    %Z lattice
    setAnalogChannel(calctime(curtime,0),'zLattice',-0.1,1);%0
    %Y lattice
    setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%0
    %X lattice
    setAnalogChannel(calctime(curtime,0),'xLattice',-0.1,1);%0
    
    %set rotating waveplate back to full dipole power
%     setAnalogChannel(curtime,'latticeWaveplate',0.0,3); %
end

% if compensation beam on
if (seqdata.flags.compensation_in_modulation == 1)
       %turn off compensation AOM
       setDigitalChannel(calctime(curtime,0),'Plug TTL',1); %0: on, 1: off
       %set compensation AOM power to 0
       setAnalogChannel(calctime(curtime,0),'Compensation Power',-5);
       %turn off compensation Shutter
       setDigitalChannel(calctime(curtime,0),'Compensation Shutter',1); %0: on, 1: off
       %turn on compensation AOM
       setDigitalChannel(calctime(curtime,1000),'Plug TTL',0); %0: on, 1: off 
       %set compensation AOM power 50mW for thermalization
       setAnalogChannel(calctime(curtime,200),'Compensation Power',9.9,1);
       %AOM direct control on
       setDigitalChannel(calctime(curtime,200),'Compensation Direct',1); %0: off, 1: on
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
    
    curtime = lattice_fluor_image(calctime(curtime,0.0),molasses_offset); 
    
elseif seqdata.flags.image_type == 8 %Try to use the iXon and a Pixelfly camera simultaneously for absorption and fluorescence imaging.
    
    absorption_image(calctime(curtime,0.0));
    
%     curtime = lattice_fluor_image(calctime(curtime,0.0),molasses_offset);  

    if (iXon_movie)
    %     AnalogFuncTo(calctime(curtime,0),'objective Piezo Z',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),45000,45000,4,1);
    FrameTime = 2500;   
    ExposureTime = 2100;
%     SidebandHeight = 2.4;
%     EMGain = 300;
    addOutputParam('FrameTime',FrameTime);
    addOutputParam('ExposureTime',ExposureTime);
%     addOutputParam('SidebandHeight',SidebandHeight);
%     addOutputParam('EMGain',EMGain);

        curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',0, ...
            'NumFrames',2,'FrameTime',FrameTime,'ExposureTime',ExposureTime,'DoPostFlush',1); % taking a "movie"
    else
        curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',1,'ExposureTime',5000);
    end
    
elseif seqdata.flags.image_type == 99 %no image (if a camera trigger has been inserted elsewhere for testing)
    
else
    error('Undefined imaging type');
end
%% post-sequence: rotate diople trap waveplate to default value
do_wp_default = 1;
if (do_wp_default == 1)
    %Rotate waveplate to divert all power to dipole traps.
    P_RotWave = 0;
    AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_RotWave,0); 
end

%% Post-sequence -- e.g. do controlled field ramps, heating pulses, etc.
do_demag_pulses = 0;
ramp_fesh_between_cycles = 1;

if do_demag_pulses
    
curtime = pulse_Bfield(calctime(curtime,150));

end

if ramp_fesh_between_cycles
    % This is meant to leave material near the atoms with the same
    % magnetization at the beginning of a new cycle, irrespective whether
    % some strong field was pulsed/snapped off or not during the cycle that
    % just ends. We do not have any positive observation that this helps,
    % but we leave it in just in case (total 1.3s extra).
    fesh_ramptime = 100;
    fesh_final = 20;
    fesh_ontime = 1000;
    setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
end


%% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

%% Set/Reset Pulses for Remote Field Sensor (after the sensor in the bucket)
%
curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);

%% Reset analog and digital channels to default values

curtime = Reset_Channels(calctime(curtime,0));

%% Pulse on XDTs for 100ms and trigger pyKraken for measurement

DigitalPulse(calctime(curtime,0),'RaspPi Trig',1000,1) % trigger pulse for pyKraken
measure_XDT_pointing = 0;
if (measure_XDT_pointing)
    %pulse XDTs on
    setDigitalChannel(calctime(curtime,1),'XDT TTL',0);
    setDigitalChannel(calctime(curtime,0),'XDT Direct Control',0);
    setAnalogChannel(calctime(curtime,1),'dipoleTrap1',0.2);
    setAnalogChannel(calctime(curtime,1),'dipoleTrap2',0.2);
    %turn XDTs off
    setAnalogChannel(calctime(curtime,5001),'dipoleTrap2',0,1);
    setDigitalChannel(calctime(curtime,5001),'XDT TTL',1);
    setAnalogChannel(calctime(curtime,5001),'dipoleTrap1',-0.5,1);
    setDigitalChannel(calctime(curtime,5002),'XDT Direct Control',1);
end

%% Load MOT
% 
    rb_mot_det_List=32;[32];30;
    %32 before 2019.1.1
    rb_MOT_detuning=getScanParameter(rb_mot_det_List,seqdata.scancycle,seqdata.randcyclelist,'rb_MOT_detuning');
%  rb_MOT_detuning = 28; %before2016-11-25:33
%  k_MOT_detuning_list =[ 22]; 20; %before2016-11-25:20 %20
 
k_MOT_detuning_list = [22];% before 2018-02-14: 18
k_MOT_detuning = getScanParameter(k_MOT_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_MOT_detuning');        
 
%  addOutputParam('k_MOT_detuning',k_MOT_detuning);
k_repump_shift = 0;  %before2016-11-25:0 %0
addOutputParam('k_repump_shift',k_repump_shift);
 mot_wait_time = 50;
  
 if seqdata.flags.image_type==5
     mot_wait_time = 0;
 end
        
%call Load_MOT function
curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);
        
setAnalogChannel(curtime,'K Repump FM',k_repump_shift,2)
      
if ( seqdata.flags.do_dipole_trap == 1 )
        curtime = calctime(curtime,dip_holdtime);
        
    elseif mag_trap_MOT || MOT_abs_image

        curtime = calctime(curtime,100);
        
    else
        curtime = calctime(curtime,1*500);%25000
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

%% Create a time-stamp (serial date number without the year); 
addOutputParam('timestamp',datenum(datevec(now).*[0 1 1 1 1 1]));

%% Timeout

timeout = curtime;

if (((timeout - timein)*(seqdata.deltat/seqdata.timeunit))>100000)
    error('Cycle time greater than 100s! Is this correct?')
end



end