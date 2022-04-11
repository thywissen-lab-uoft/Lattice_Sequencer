function timeout = Load_MagTrap_sequence(timein)
% Load_MagTrap_sequence
% 
% This is main sequence file of the experiment

curtime = timein;

%% Initialize seqdata
global seqdata;
initialize_channels();
seqdata.numDDSsweeps = 0;
seqdata.scanindex = -1;

% "Useful" constants
kHz = 1E3;
MHz = 1E6;
GHz = 1E9;

%% Constants and Parameters
% These are properties of the machine that are not changed. 

%Ambient field cancelling values (ramp to these at end of XDT loading)
seqdata.params. shim_zero = [(0.1585-0.0160), (-0.0432-0.022), (-0.0865-0.015)];

%Shim values that align the plugged-QP trap (these are non-zero, since the
%centre of the imaging window is different from the natural QP centre)
seqdata.params.plug_shims = [(seqdata.params. shim_zero(1)-1-0.04-0.3),...
    (seqdata.params. shim_zero(2)+0.125), ...
    (seqdata.params. shim_zero(3)+ 0.35)];%0.35 + 0.55)];

%Current shim values (x,y,z)- reset to zero
seqdata.params.shim_val = [0 0 0]; 

hold_list = [500];
seqdata.params. molasses_time = getScanParameter(hold_list,...
seqdata.scancycle,seqdata.randcyclelist,'hold_list');%192.5;
addOutputParam('molasses_hold_list',seqdata.params. molasses_time); 

% Dipole trap and lattice beam parameters 
seqdata.params. XDT_area_ratio = 1; % DT2 with respect to DT1


% Rb Probe Beam AOM Order
seqdata.flags.Rb_Probe_Order = 1;   %1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                %2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT
seqdata.flags.in_trap_OP = 0; 
seqdata.flags.SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB


%% Switches

%RHYS - these can be switched on for certain predefined sequences. It's
%a good idea, but I have never used them (except MOT_abs_image). They
%should be studied before considering deleting (transfer recap for
%instance was used for benchmarking transport system). 

%It's preferable to add a switch here than comment out code!
%Special flags
mag_trap_MOT = 0; %Absportion image of MOT after magnetic trapping
MOT_abs_image = 0; %Absorption image of the MOT (no load in mag trap);
transfer_recap_curve = 0; %Transport curve from MOT and back
after_sci_cell_load = 0; %Abs image after loading into science cell
bench_transport = 0; %special stage for benchmarking the transport
bench_rf = 0; %special stage for benchmarking RF power making it to the atoms
seqdata.flags.rb_vert_insitu_image = 0; 
%take a vertical in-situ image of BEC in XDT to centre the microscope objective

seqdata.flags.controlled_load = 0; %do a specific load time
controlled_load_time = 20000;

%RHYS - go through flags and remove obsolete options. PXU and VV should
%know most of what is and is not useful, but should still be done
%carefully. Obviously the code that would be called by the flag must
%also be modified. 

%RHYS - the flag system makes some sense, in that it is useful for
%specifying what parts of the sequence to run, whether to look at Rb or
%K, etc. Compared with the CHIP lab approach of running a different
%file for each possible sequence, this seems more natural. However, it
%should be streamlined: only a few flags are ever actually switched for
%controlling the sequence these days. The others are basically
%permanent, and thus should no longer be considered 'flags', but more
%like 'fixed properties'. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CF : These flags need to be cleaned up and make more sense

%RHYS - really don't need so many image types, and why is iXon_movie
%its own thing?

seqdata.flags.image_type = 0; 
%0: absorption image, 1: recapture, 2:fluor, 
%3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 
%6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses 
%8: iXon fluorescence + Pixelfly absorption
seqdata.flags.MOT_flour_image = 0;

iXon_movie = 0; %Take a multiple frame movie?
seqdata.flags.image_atomtype = 1;%  0:Rb; 1:K; 2: K+Rb (double shutter)
seqdata.flags.image_loc = 1; %0: `+-+MOT cell, 1: science chamber    
seqdata.flags.img_direction = 0; 
%1 = x direction (Sci) / MOT, 2 = y direction (Sci), 
%3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
seqdata.flags.do_stern_gerlach = 0; %1: Do a gradient pulse at the beginning of ToF
seqdata.flags.iXon = 0; % use iXon camera to take an absorption image (only vertical)
seqdata.flags.do_F1_pulse = 0; % repump Rb F=1 before/during imaging

seqdata.flags.High_Field_Imaging = 0;
%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)

% CF : D2 Gray molasses is worse than D1, we should delete this
seqdata.flags.K_D2_gray_molasses = 0; %RHYS - Irrelevant now. 

seqdata.flags.In_Trap_imaging = 0;
tof_list = [21];
seqdata.params.tof = getScanParameter(tof_list,...
    seqdata.scancycle,seqdata.randcyclelist,'tof','ms');

tof_krb_diff_list=[0];
seqdata.params.tof_krb_diff = getScanParameter(tof_krb_diff_list,...
    seqdata.scancycle,seqdata.randcyclelist,'tof_krb_diff','ms');


seqdata.params.UV_on_time = 10000; %UV on time + savingtime + wait time = real wait time between cycles%
% usually 15s for non XDT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TRANSPORT, RF1A, and RF1B %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
seqdata.flags.RF_evap_stages = [1, 1, 1]; %[stage1, decomp/transport, stage1b] %Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.


% RF1A and RF1B timescales
RF_1B_time_scale_list = [0.8];
RF_1B_time_scale = getScanParameter(RF_1B_time_scale_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1B_time_scale');

rf_evap_time_scale = [0.6 RF_1B_time_scale];[0.6 .9];[0.7 0.9];

% RF1A Ending Frequency
RF_1A_Final_Frequency_list = [16];%16
RF_1A_Final_Frequency = getScanParameter(RF_1A_Final_Frequency_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1A_finalfreq','MHz');

% RF1B Final Frequency
RF_1B_Final_Frequency_list = [1];%0.8,0.4 1
RF_1B_Final_Frequency = getScanParameter(RF_1B_Final_Frequency_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1B_finalfreq','MHz');


seqdata.flags.do_plug = 1;   % ramp on plug after transfer to window
seqdata.flags.lower_atoms_after_evap = 0; % lower hot cloud after evap to get clean TOF signal
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DIPOLE TRAP AND LATTICE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dipole trap
seqdata.flags.do_dipole_trap = 1; % 1: dipole trap loading, 2: dipole trap pulse, 3: pulse on dipole trap during evaporation
seqdata.params.ODT_zeros = [-0.04,-0.04];
seqdata.flags.do_Rb_uwave_transfer_in_ODT = 1;  % Field Sweep Rb 2-->1
seqdata.flags.do_Rb_uwave_transfer_in_ODT2 = 0; % uWave Frequency sweep Rb 2-->1
seqdata.flags.init_K_RF_sweep = 1;              % RF Freq Sweep K 9-->-9  
seqdata.flags.do_D1OP_before_evap= 1;           % D1 pump to purify
seqdata.flags.mix_at_beginning = 0;             % RF Mixing -9-->-9+-7
    
% Optical Evaporation
seqdata.flags.CDT_evap = 1;        % 1: exp. evap, 2: fast lin. rampdown to test depth, 3: piecewise lin. evap 

% High Field Evaporation
seqdata.flags.CDT_evap_2_high_field= 1;    

% After optical evaporation
seqdata.flags.do_D1OP_post_evap = 0;            % D1 pump
seqdata.flags.mix_at_end = 0;                   % RF Mixing -9-->-9+-7

% Optical lattice
seqdata.flags.load_lattice = 0; % set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
seqdata.flags.pulse_lattice_for_alignment = 0; % 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
seqdata.flags.pulse_zlattice_for_alignment = 0; % 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)

if (seqdata.flags.do_dipole_trap ~= 0 || seqdata.flags.load_lattice ~= 0)
    seqdata.flags.QP_imaging = 0;
else
    seqdata.flags.QP_imaging = 1;
end

%RHYS - these are kind of useless.
%VV - Although these are set to zero there are a bunch of occurrances of these flags in the this
%sequeence and other files. So keeping these for now. Will be deleted
%later
%Imaging Molasses
seqdata.flags.do_imaging_molasses = 0; % 1: In Lattice or XDT, 2: Free space after QP, 3: Free Space after XDT
seqdata.flags.evap_away_Rb_in_QP = 0; %Evaporate to 0.4MHz in QP+XDT to kill Rb and load lots of K (only works when loading XDT)
seqdata.flags.pulse_raman_beams = 0; % pulse on D2 raman beams for testing / alignment

%% Scope Trigger
% Choose which scope trigger to use.
% scope_trigger = 'Load lattices'; 
scope_trigger = 'Lattice_Mod';

%% Set switches for predefined scenarios

%RHYS - the predefined scenarios described before. These have not been
%used in years, so cannot verify whether they do or do not work. Useful
%idea though. 

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
end

if seqdata.flags.image_loc == 0 %MOT cell imaging
    seqdata.flags.do_plug = 0;
    seqdata.flags.compress_QP = 0;
    seqdata.flags.RF_evap_stages = [0 0 0];
    seqdata.flags.do_dipole_trap = 0;
    seqdata.flags.load_lattice = 0;  
    seqdata.flags.pulse_lattice_for_alignment = 0;
end

%% Consistency checks
%Implement special flags
if (mag_trap_MOT + MOT_abs_image + transfer_recap_curve + after_sci_cell_load)>1
    error('Too many special flags set');
end

%% Set Objective Piezo Voltage
% If the cloud moves up, the voltage must increase to refocus
%  (as the experiment warms up, selected plane tends to move up a bit)
    
    %RHYS - Setting some specific parameters for DDS and objective
    %position. Silly that this is here. 

    obj_piezo_V_List = 4.6;[5.4];[4.6];
    % 0.1V = 700 nm, must be larger than  larger value means farther away from the window.
%     obj_piezo_V = getScanParameter(obj_piezo_V_List, ...
%     seqdata.scancycle, 1, 'Objective_Piezo_Z','V');%5

    obj_piezo_V = getScanParameter(obj_piezo_V_List, ...
    seqdata.scancycle, 1:length(obj_piezo_V_List), 'Objective_Piezo_Z','V');%5

    % obj_piezo_V = 6.8;
    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);
    addOutputParam('objpzt',obj_piezo_V,'V');
    
    %VV - I plan to puth the below line of code into a seperate code just
    %for the purpose of initialization of the experiment. I don't think it
    %is a good practice to keep commented code here just like this.
    
    % Set 4-Pass Frequency
    %Don't want to do this with every cycle since it drops the connection
    %sometimes and doesn't turn on correctly
%  
%     detuning_list = [0];[0];300;
%     df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
%     DDSFreq = 324.20625*MHz + df*kHz/4;
%     DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
%     addOutputParam('DDSFreq',DDSFreq);
% % 

    % %Set the frequency of the first DP AOM 
%     D1_FM_List = [222.5];
%     D1_FM = getScanParameter(D1_FM_List, seqdata.scancycle, seqdata.randcyclelist);%5
%     setAnalogChannel(calctime(curtime,0),'D1 FM',D1_FM);
%     addOutputParam('D1_DP_FM',D1_FM);

%% Make sure dipole and lattice traps are off and adjust XDT piezo mirrors
% and initialize repump imaging.

    %RHYS - Initialization settings for a lot of channels. But, the 'reset
    %values' should already be set in initialize_channels, and, I think,
    %set at the end of the sequence. So, these should just be incorporated
    %into that function properly instead of defined here. 
    
    % Perhaps to be safe, we just have another call to @Reset_Channels?

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
    setDigitalChannel(calctime(curtime,0),'FB offset select',0);        %No offset voltage
    
    %turn off dipole trap beams
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.5,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',seqdata.params.ODT_zeros(1));
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-1,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);
    
    %turn off lattice beams
%     setAnalogChannel(calctime(curtime,0),'xLattice',seqdata.params.lattice_zero(1));%-0.1,1);
    setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);%-0.1,1);    
%     setAnalogChannel(calctime(curtime,0),'yLattice',seqdata.params.lattice_zero(2));%-0.1,1);
    setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%-0.1,1);

    setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);%-0.1,1);
    
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
    setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X,1);
    setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y,1);
    setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z,1);

    %Close science cell repump shutter
    setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
    setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed
        
    %Kill beam AOM on to keep warm.
    setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
    setDigitalChannel(curtime,'Downwards D2 Shutter',0);
    
    %Pulsed beams on to keep warm.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
    
    %Set Raman AOM TTL to open for AOM to stay warmed up
    %Turn off Raman shutter with TTL.
%     setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
    setDigitalChannel(calctime(curtime,5),'Raman Shutter',0); %2021/03/30 new shutter

    setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
    setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
    setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1);

    setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
    setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1);

    %Set 'D1' Raman AOMs to open, shutter closed.
    setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
    setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);
    
    %Set TTL to keep F-pump and mF-pump warm.
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
    setAnalogChannel(calctime(curtime,0),'F Pump',9.99);
    
    %Plug beam
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
   
    %High-field imaging
    setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
    setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);
    
    % Turn off Rigol modulation
    addr_mod_xy = 9; % ch1 x mod, ch2 y mod
    addr_z = 5; %ch1 z lat, ch2 z mod  
    ch_off = struct;
    ch_off.STATE = 'OFF';
    ch_off.AMPLITUDE = 0;
    ch_off.FREQUENCY = 1;
    
    programRigol(addr_mod_xy,ch_off,ch_off);   % Turn off xy mod
    programRigol(addr_z,[],ch_off);             % Turn off z mod

    
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
        %RHYS - which historic reasons? Is it important?        
        %this has been here for historic reasons
        curtime = calctime(curtime,1500);
    end   

curtime = Prepare_MOT_for_MagTrap(curtime);
    %RHYS - Should integrate the following lines into the above function. 

    %Open other AOMS to keep them warm. Why ever turn them off for long
    %when we have shutters to do our dirty work?
    setDigitalChannel(calctime(curtime,10),'K Trap TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Trap AM',0.8);
    
    setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',0);    
    setAnalogChannel(calctime(curtime,10),'Rb Trap AM',0.7);

    setDigitalChannel(calctime(curtime,10),'K Repump TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Repump AM',0.45);
    
    setAnalogChannel(calctime(curtime,10),'Rb Repump AM',0.9);

if ~seqdata.flags.MOT_flour_image
    
%% Load into Magnetic Trap

    %RHYS - One of the first examples of doing something based on a
    %confusing series of if statements and conditions. Works, but is highly
    %error prone and has become very convoluted over time as options have
    %been added and removed. 

    if ~( MOT_abs_image || seqdata.flags.image_type==4 )

        %same as molasses (assume this zero's external fields)

        yshim2 = 0.25;%0.25; %0.9
        xshim2 = 0.25;%0.2; %0.1
        zshim2 = 0.05;%0.05; %0.3  0.0 Dec 4th 2013
        
        %RHYS - Again, probably control these things within functions for
        %code readability. 
        
        %optimize shims for loading into mag trap
        setAnalogChannel(calctime(curtime,0.01),'Y Shim',yshim2,3); %1.25
        setAnalogChannel(calctime(curtime,0.01),'X Shim',xshim2,2); %0.3 
        setAnalogChannel(calctime(curtime,0.01),'Z Shim',zshim2,2); %0.2

        %RHYS - the second important function, which loads the MOT into the magtrap. 

curtime = Load_MagTrap_from_MOT(curtime);

        if transfer_recap_curve && (seqdata.flags.hor_transport_type == 2)
curtime = calctime(curtime,1000);
        end

    end
        
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.0,2); %2

%% Transport 
dispLineStr('Magnetic Transport',curtime);

    %open kitten relay
curtime = setDigitalChannel(curtime,'Kitten Relay',1);

    DigitalPulse(calctime(curtime,-500),'Transport LabJack Trigger',100,0);
    
    %Turn shim multiplexer to Science shims
    setDigitalChannel(calctime(curtime,1000),37,1); 
    
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
    %Turn Shims to Science cell zero values
    setAnalogChannel(calctime(curtime,1000),27,0,3); %3
    setAnalogChannel(calctime(curtime,1000),28,0,3); %3
    setAnalogChannel(calctime(curtime,1000),19,0,4); %4

    %digital trigger
    disp('Start Calculating Transport')
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
    
    %RHYS - the third imporant function. Transports cloud from MOT to science
    %chamber. All surrounding relevant code should be integrated into this.
    %Furthermore, note the significant calculation time due to spline
    %interpolation - this is likely unneccesary?
    
curtime = Transport_Cloud(curtime, seqdata.flags.hor_transport_type,...
    seqdata.flags.ver_transport_type, seqdata.flags.image_loc);
    disp('End Calculating Transport')  

%% Ramp up QP
dispLineStr('Compression stage after transport to science cell.',curtime);

    % Compression stage after the transport to the science cell

    %RHYS - a fourth important function. Makes a deep magnetic trap after
    %transport. The shims are set to their plug-evaporation values here, but
    %could be played with, since the actual values only move a big trap around
    %at this stage, and may be unhelpful/irrelevant. Also, integrate into the
    %function for cleanliness (I'm going to stop repeating this). 

[curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_trans(curtime, seqdata.flags.compress_QP);


    %Shim Values to Turn On To: (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
    y_shim_val = seqdata.params.plug_shims(2); %0*0.5
    x_shim_val = seqdata.params.plug_shims(1); %0*1.6
    z_shim_val = seqdata.params.plug_shims(3); %0*0.8
       
    
    %turn on shims
    AnalogFuncTo(calctime(curtime,0),'Y Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,y_shim_val,4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,x_shim_val,3); 
curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,z_shim_val,3); 

%% RF1A
if ( seqdata.flags.RF_evap_stages(1) == 1 )
    dispLineStr('RF1A',curtime);

    fake_sweep = 0;             % do a fake RF sweep
    hold_time = 100;            % hold time after sweeps
    pre_hold_time =  100;       % Hold time before sweeps
    start_freq = 42;            % Beginning RF1A frequnecy 42 MHz 

    % Frequency points
    freqs_1 = [ start_freq 28 20 RF_1A_Final_Frequency]*MHz;
    % Gains during each sweep
    RF_gain_1 = 0.5*[-4.1 -4.1 -4.1 -4.1]; 
    % Duration of each sweep interval
    sweep_times_1 =[14000 8000 4000].*rf_evap_time_scale(1);
    
    
    disp(['     Times        (ms) : ' mat2str(sweep_times_1) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1*1E-6) ]);
    disp(['     Gains         (V) : ' mat2str(RF_gain_1) ]);


    % Hold before beginning evaporation
    curtime = calctime(curtime,pre_hold_time);

    % Do a pulse of Rb repump to kill F=1
%     setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',1);
%     curtime = setDigitalChannel(calctime(curtime,1000),'Rb Sci Repump',0);

    % Do the RF evaporation
    curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) == 0));
end
    
%% RF1A Alternate : Fast RF for transport benchmark
% This does a fast evaporation to benchmark the transport
% CF : I don't konw what this is for?

if ( seqdata.flags.RF_evap_stages(1) == 2 )
    dispLineStr('Fast RF1A for transport benchmark',curtime);

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
    
%% Kill Rb after RF1A
%Get rid of Rb afterwards (used for loading dilute 40K into lattice)
kill_Rb_after_RFStage1 = 0;

if kill_Rb_after_RFStage1
    dispLineStr('Kill Rb after RF1A',curtime);
    kill_pulse_time = 5; %5

    %open shutter
    %probe
    setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
    %repump
    %setDigitalChannel(calctime(curtime,-10),5,1);
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
    %repump pulse
    %setAnalogChannel(calctime(curtime,0),2,0.7); %0.7
    %curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),2,0.0);

    %close shutter
    curtime = setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
    %curtime = setDigitalChannel(calctime(curtime,0),5,0);

    curtime=calctime(curtime,5);
end
    
%% Evaporation during compression
do_evap_during_compression = 0;
if (do_evap_during_compression && seqdata.flags.RF_evap_stages(2)==1)
    dispLineStr('Evaporate during compression',curtime);

    freqs_1 = [freqs_1(end)/MHz*1 25]*MHz;
    RF_gain_1 = [0.5 0.5]*[-4.1];
    sweep_times_1 = 560; %560 is maximum
    do_evap_stage(curtime,0, freqs_1, sweep_times_1, ...
            RF_gain_1, 0, (seqdata.flags.RF_evap_stages(3) == 0));

end
%% Ramp down QP and/or transfer to the window
% Decompress the QP trap and transpor the atoms closer to the window.

%This is only for testing the constituent spins of Rb after the RF1A stage.
%When ramp_wo_transfer flag is on, we do a gradient ramp without
%tansfering the atoms to near the window
ramp_wo_transfer = 0; 
ramp_after_transfer = 0;
if ramp_wo_transfer
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_wo_transfer(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
else
    dispLineStr('Decompressing and tranpsorting.',curtime);
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_before_transfer(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end

if ramp_after_transfer
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_transfer_test(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end

%% Turn on Plug Beam
% Turn on the plug beam.  We currently only have a shutter on the plug beam

if  seqdata.flags.do_plug==1       
    dispLineStr('Turning on the plug',curtime);
    plug_offset = -500; % -200
    setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',1); %0: CLOSED; 1: OPEN
end

ramp_after_plug=0;
if ramp_after_plug
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_transfer_test(curtime, seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end

%% Evaporation Stage 1b

if ( seqdata.flags.RF_evap_stages(3) == 1 )    
    dispLineStr('RF1B begins.',curtime);  
    
    % Define RF1B parameters (frequency, gain, timescale, gradient, etc)
    sweep_time_list = [3000];
    sweep_time = getScanParameter(sweep_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'RF1B_sweep_time');
    sweep_times_1b = [6000 3000 2]*rf_evap_time_scale(2); 2000;
    evap_end_gradient_factor_list = [0.9]; %0.75
    evap_end_gradient_factor = getScanParameter(evap_end_gradient_factor_list,...
        seqdata.scancycle,seqdata.randcyclelist,'evap_end_gradient_factor');
    currs_1b = [1 1 evap_end_gradient_factor evap_end_gradient_factor]*I_QP;
    freqs_1b = [freqs_1(end)/MHz*1.1 7 RF_1B_Final_Frequency 2]*MHz;
    rf_1b_gain = -2;    
    gains = ones(1,length(freqs_1b))*rf_1b_gain;
    
    % Create RF1B structure object
    RF1Bopts=struct;
    RF1Bopts.Freqs = freqs_1b;
    RF1Bopts.SweepTimes = sweep_times_1b;
    RF1Bopts.Gains = gains;
    RF1Bopts.RFEnable = ones(1,length(sweep_times_1b));
    RF1Bopts.QPCurrents = currs_1b;
    
    disp(['     Times        (ms) : ' mat2str(sweep_times_1b) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1b*1E-6) ]);
    disp(['     Currents      (A) : ' mat2str(currs_1b) ]);
    disp(['     Gains         (V) : ' mat2str(gains) ]);

    % Perform RF1B
    [curtime, I_QP, V_QP, I_shim] = MT_rfevaporation(curtime, RF1Bopts, I_QP, V_QP);
    
    % Turn off the RF
    setDigitalChannel(curtime,'RF TTL',0);% rf TTL

    dispLineStr('RF1B ends.',curtime);    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ramp_after_1B = 0;
    if ramp_after_1B
        dispLineStr('Ramp QP after RF1B',curtime);       

        [curtime, I_QP, I_kitt, V_QP, I_fesh] = ...
            ramp_QP_after_transfer_test(curtime, ...
            seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
    end

%     % Hold at the new ramp factor
%     hold_time_list = [100];
%     hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'QP_hold_time');
% %     setDigitalChannel(calctime(curtime,-2.5),'Plug Shutter',0);% 0:OFF; 1: ON
%     curtime = calctime(curtime,hold_time);  % This goes away if you want to keep knife on
% %     

% % % % 
% %     Keep RF on
%     RFgain=-2.05;
%     f_hold=2*MHz;
%     setDigitalChannel(calctime(curtime,0),17,0);    % RF switch
%     setDigitalChannel(calctime(curtime,0),19,1);    % swithing on
%     setAnalogChannel(calctime(curtime,0), 39,RFgain,1); % RF gain
% 
%     curtime = DDS_sweep(calctime(curtime,10),1,f_hold,f_hold,hold_time);
%     
% this has a "hold" built into it 
%     setDigitalChannel(calctime(curtime,0),19,0);    % swithing off
%     setAnalogChannel(calctime(curtime,0), 39,-10,1); % RF gain low

    %Get rid of Rb afterwards (used for loading dilute 40K into lattice)   
    kill_Rb_after_RFStage1b = 0;
    if kill_Rb_after_RFStage1b
        dispLineStr('Kill Rb after RF1B',curtime);        
        kill_pulse_time = 5; %5

        % Prepare probe beam
        setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %0=closed, 1=open
        setAnalogChannel(calctime(curtime,-10),'Rb Probe/OP AM',0.7); 
        setAnalogChannel(calctime(curtime,-10),'Rb Beat Note FM',6590-237);

        % Make sure that Rb probe is off
        setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);

        % Pulse the probe TTL
        curtime = DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',...
            kill_pulse_time,0);

        % Close the probe shutter
        curtime = setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); %0=closed, 1=open
        curtime=calctime(curtime,5);
    end    
end

%% Blow away Rb or K
% This code pulses resonant light with either Rb or K to purify the
% magnetic trap of atomic species

do_Rb_blow_away = 0;    % Blow away Rb
do_K_blow_away = 0;     % Blow away K

if do_Rb_blow_away || do_K_blow_away
    dispLineStr('Blow away Rb or K',curtime);

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
    end
    
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
    end
    %hold at end of evap
    curtime = calctime(curtime,250); %3000   
    
end

%% RF1B Alternate : uWave Evaporation
if ( seqdata.flags.RF_evap_stages(3) == 2 )
        dispLineStr('uWave Evaporation',curtime);

%RHYS - interesting option that I've never tried. Uses Rb microwaves for
    %evaporation (lower Rabi freq but possibly cleaner?)
    
        freqs_1b = [freqs_1(end)/MHz*0.6 4 1.0 ]*MHz; 
        RF_gain_1b = [-4 -4 -7]; 
        sweep_times_1b = [4000 3500 ]*6/6;
    
        %Do uWave evaporation
        curtime = do_uwave_evap_stage(curtime, fake_sweep, freqs_1b*3, sweep_times_1b, 0);
end

%% Post QP Evap Tasks
%RHYS - clean.
%turn plug off
if ( seqdata.flags.do_plug == 1)
    
    
    hold_time_list = [0];
    hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_QPcoils');
    curtime = calctime(curtime,hold_time);   
    plug_offset = -2.5;%-2.5 for experiment, -10 to align for in trap image

    % Turn off the plug here if you are doing RF1B TOF.
    if ( seqdata.flags.do_dipole_trap ~= 1 )
        % Dipole transfer has its own code for turning off the plug after
        % loading the XDTs
        dispLineStr('Turning off plug at',calctime(curtime,plug_offset));
        setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',0);% 0:OFF; 1: ON
        ScopeTriggerPulse(calctime(curtime,0),'plug test');
    end        
end
%% Dipole trap ramp on (and QP rampdown)
if ( seqdata.flags.do_dipole_trap == 1 )
    dispLineStr('Caling dipole_transfer.m',curtime);   
    [curtime, I_QP, V_QP, P_dip, dip_holdtime, I_shim] = ...
        dipole_transfer(curtime, I_QP, V_QP, I_shim);
end


%%%%%%%%%%%%%% CF: NEW DIPOLE TRANFER TESTING
% if seqdata.flags.do_dipole_trap
%     [curtime,I_QP,I_shim,P1,P2] = dipole_transfer2(curtime, I_QP, V_QP,I_shim);
% end


curtime=calctime(curtime,0);

%% Pulse lattice after releasing from dipole trap

if ( seqdata.flags.pulse_lattice_for_alignment ~= 0 )
    %RHYS - how should these 'pulse lattice' alignment codes be
    %organized/called?
    curtime = Pulse_Lattice(curtime,...
        seqdata.flags.pulse_lattice_for_alignment);
end

%% Load Lattice

if ( seqdata.flags.load_lattice ~= 0 )
%RHYS - loads the lattices and performs science/fluorescence imaging.
%Important. Code is probably way too bulky. 
    [curtime,P_dip,P_Xlattice,P_Ylattice,P_Zlattice,P_RotWave]= Load_Lattice(curtime);
end

%% Pulse Z Lattice after ramping up other lattices to align

if (seqdata.flags. pulse_zlattice_for_alignment == 1 )
    %RHYS - another alignment tool. 
    curtime = Pulse_Lattice(curtime,4);
end


%% lower atoms from window for clean TOF release

if ( seqdata.flags.lower_atoms_after_evap == 1 )
    dispLineStr('Lowering atoms from window',curtime);

    %RHYS - this is probably useful and we should use it more. Gets atoms
    %away from the window before dropping after RF1A. 
    %100ms, 15A works well for RF_stage_2
    lower_transfer_time = 100;
    curtime = AnalogFunc(curtime,...
        1,@(t,tt,dt)(dt*t/tt+I_QP),lower_transfer_time,lower_transfer_time,15-I_QP);
end


%% Turn off coils and traps.  
dispLineStr('Turning off coils and traps.',curtime);

    %RHYS - Makes sure all traps are off during TOF (actually initiates TOF for
    %mag trap and XDT). Clean up, could be its own function. Check that
    %procedures are not out of date. 
    
    %turn the Magnetic Trap off
    %set all transport coils to zero (except MOT)
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end    
    
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
            setAnalogChannel(calctime(curtime,0),'dipoleTrap1',seqdata.params.ODT_zeros(1));
            %turn off dipole trap 2
%             setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
            setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
            setDigitalChannel(calctime(curtime,-1),'XDT Direct Control',1);
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
        %turn lattice beams off (leave a bit of time for the rotating waveplate to get back to zero)

        %Z lattice
        setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);%-0.1,1);%0
        %Y lattice
%         setAnalogChannel(calctime(curtime,0),'yLattice',seqdata.params.lattice_zero(2));%-0.1,1);%0
        setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%-0.1,1);%0

        %X lattice
%         setAnalogChannel(calctime(curtime,0),'xLattice',seqdata.params.lattice_zero(1));%-0.1,1);%0
        setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);%-0.1,1);%0
    
    end

    if ~(seqdata.flags.image_type==1 || seqdata.flags.image_type==4)
        setDigitalChannel(curtime,16,1);    
    end


%% Imaging

    %RHYS - Imporant code, but could delete the scenarios that are no longer
    %used. Also, the iXon movie option under 8 could use some cleaning. 
    if seqdata.flags.image_type == 0 % Absorption Image
        dispLineStr('Absorption Imaging.',curtime);

        %curtime = absorption_image(calctime(curtime,0.0)); 
         curtime = absorption_image2(calctime(curtime,0.0)); 

    elseif seqdata.flags.image_type == 8 %Try to use the iXon and a Pixelfly camera simultaneously for absorption and fluorescence imaging.
    
absorption_image(calctime(curtime,0.0));
    
        if (iXon_movie)
            FrameTime = 2500;   
            ExposureTime = 2100;
            addOutputParam('FrameTime',FrameTime);
            addOutputParam('ExposureTime',ExposureTime);

curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',0, ...
            'NumFrames',2,'FrameTime',FrameTime,'ExposureTime',ExposureTime,'DoPostFlush',1); % taking a "movie"
        else
curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',1,'ExposureTime',5000);
        end
        
    else
        error('Undefined imaging type');
    end

    %RHYS - the next bits of post-sequence code are useful (well, if the
    %demagnetization stuff actually does anything). Could be wrapped into a
    %function. 

%% post-sequence: rotate diople trap waveplate to default value
    do_wp_default = 1;
    if (do_wp_default == 1)
        %Rotate waveplate to divert all power to dipole traps.
        P_RotWave = 0;
        AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_RotWave,0); 
    end

%% Post-sequence -- e.g. do controlled field ramps, heating pulses, etc.
% CF: This is probably not helpful and should just be removed.

    do_demag_pulses = 0;
    ramp_fesh_between_cycles = 1;

    if do_demag_pulses    
curtime = pulse_Bfield(calctime(curtime,150));
    end

    if ramp_fesh_between_cycles
        if seqdata.flags.High_Field_Imaging
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
        else 
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
        end
    end

% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

% Set/Reset Pulses for Remote Field Sensor (after the sensor in the bucket)
curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);

% Reset analog and digital channels (shouldn't this always happen?)
curtime = Reset_Channels(calctime(curtime,0));

end

%% Raman Shutter
%turn on the Raman shutter for frquuency monitoring

setDigitalChannel(calctime(curtime,0),'Raman Shutter',1);

%This is turned off in line 435 above


%% Load MOT
% CF : This should be it's own subfunction. No need to put it in the main
% code
dispLineStr('Loading MOT.',curtime);

    %RHYS - a lot of parameters and cleaning to do here. I've also always
    %thought it was odd that MOT loading happened at the end of the sequence,
    %and it makes it tricky to optimize the MOT. The reason is probably due to
    %the extra wait time spent saving files after the sequence completes... may
    %as well have a MOT loading while this happens. If that were fixed, this
    %could instead be the first thing in the sequence. 
    rb_mot_det_List= 32;[32];30;
    %32 before 2019.1.1
    rb_MOT_detuning=getScanParameter(rb_mot_det_List,seqdata.scancycle,seqdata.randcyclelist,'rb_MOT_detuning');
 
    k_MOT_detuning_list = [22];% before 2018-02-14: 18
    k_MOT_detuning = getScanParameter(k_MOT_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_MOT_detuning');        
 
    
    k_repump_shift = 0;  %before2016-11-25:0 %0
    addOutputParam('k_repump_shift',k_repump_shift);
    mot_wait_time = 50;
  
    if seqdata.flags.image_type==5
        mot_wait_time = 0;
    end
        
    %call Load_MOT function
    curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);
        
    setAnalogChannel(curtime,'K Repump FM',k_repump_shift,2);
      
    if ( seqdata.flags.do_dipole_trap == 1 )
%         curtime = calctime(curtime,dip_holdtime);        
    elseif mag_trap_MOT || MOT_abs_image    
        curtime = calctime(curtime,100);        
    else
        curtime = calctime(curtime,1*500);%25000
    end

    %set relay back
curtime = setDigitalChannel(calctime(curtime,10),28,0);

    %RHYS - Following is some irrelevant stuff and some quality of life stuff,
    %including an important check on overall cycle time. 
    
%% Scope trigger selection
SelectScopeTrigger(scope_trigger);

%% Timeout
timeout = curtime;

if (((timeout - timein)*(seqdata.deltat/seqdata.timeunit))>100000)
    error('Cycle time greater than 100s! Is this correct?')
end
    
disp(repmat('-',1,60));
dispLineStr('Sequence Complete.',curtime);
disp(repmat('-',1,60));
disp(repmat('-',1,60));


end