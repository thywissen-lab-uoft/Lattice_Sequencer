function timeout = Load_MagTrap_sequence(timein)
% Load_MagTrap_sequence
% 
% This is main sequence file of the experiment

curtime = timein;
disp(repmat('-',1,60));
dispLineStr('New Sequence',curtime);

%% Initialize seqdata
global seqdata;
initialize_channels();

% Number of DDS scans is zero
seqdata.numDDSsweeps = 0;
seqdata.scanindex = -1;

% "Useful" constants
kHz = 1E3;
MHz = 1E6;
GHz = 1E9;

%% Constants and Parameters

% % Ambient field cancelling values (ramp to these at end of XDT loading)
% seqdata.params.shim_zero = [(0.1585-0.0160), (-0.0432-0.022), (-0.0865-0.015)];
% 
% % Shim values that align the plugged-QP trap to the center of the 
% seqdata.params.plug_shims = [...
%     (seqdata.params.shim_zero(1)-1-0.04-0.3),...
%     (seqdata.params.shim_zero(2)+0.125), ...
%     (seqdata.params.shim_zero(3)+ 0.35)];

% Shim Zero (to eliminate all bkgd fields)
seqdata.params.shim_zero = [0.1425, -0.0652, -0.1015];

% Plug Zero (to move MT underneath sapphire window)
seqdata.params.plug_shims = seqdata.params.shim_zero + ...
    [-1.3400 +0.125 +0.35];

% Slope relation between shim and QP currents to keep field center fixed.
% Important for ramping QP at end of RF1B and during QP ramp down in ODT
Cx = -0.0507;
Cy = 0.0045;
Cz = 0.0115;

% Old values
% Cx = -0.0499;
% Cy = 0.0045;
% Cz = 0.0105;

seqdata.params.plug_shims_slopes = [Cx Cy Cz];

%Current shim values (x,y,z)- reset to zero
seqdata.params.shim_val = [0 0 0]; 

% Rb Probe Beam AOM Order
seqdata.flags.Rb_Probe_Order = 1;   % 1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                    % 2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT
seqdata.flags.SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB


%% Flags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.MOT_load_at_start = 0; %do a specific load time

seqdata.params.UV_on_time = 10000;
% UV on time + savingtime + wait time = real wait time between cycles%
% usually 15s for non XDT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RHYS - really don't need so many image types, and why is iXon_movie
%its own thing?

seqdata.flags.image_type = 0; 
%0: absorption image, 1: recapture, 2:fluor, 
%3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 
%6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses 
%8: iXon fluorescence + Pixelfly absorption
seqdata.flags.MOT_flour_image = 0;

iXon_movie = 0; %Take a multiple frame movie?
seqdata.flags.image_atomtype = 2;   % 0: Rb; 1:K; 2: K+Rb (double shutter)
seqdata.flags.image_loc = 1;        % 0: `+-+MOT cell, 1: science chamber    
seqdata.flags.img_direction = 0;    % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
seqdata.flags.do_stern_gerlach = 0; % 1: Do a gradient pulse at the beginning of ToF
seqdata.flags.iXon = 0;             % use iXon camera to take an absorption image (only vertical)
seqdata.flags.do_F1_pulse = 0;      % repump Rb F=1 before/during imaging

seqdata.flags.High_Field_Imaging = 0;
%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)

seqdata.flags.In_Trap_imaging =0; % Does this flag work for QP/XDT? Or only QP?

% Choose the time-of-flight time for absorption imaging
tof_list = [25]; %DFG 25ms ; RF1b Rb 15ms ; RF1b K 5ms; BM 15ms
seqdata.params.tof = getScanParameter(tof_list,...
    seqdata.scancycle,seqdata.randcyclelist,'tof','ms');

% For double shutter imaging, may delay imaging Rb after K
tof_krb_diff_list= [0];
seqdata.params.tof_krb_diff = getScanParameter(tof_krb_diff_list,...
    seqdata.scancycle,seqdata.randcyclelist,'tof_krb_diff','ms');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Mag Trap : TRANSPORT, RF1A, and RF1B %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Horizontal Transport Type
seqdata.flags.hor_transport_type = 1; 
%0: min jerk curves, 1: slow down in middle section curves, 2: none

% Vertical Transport Type
seqdata.flags.ver_transport_type = 3; 
% 0: min jerk curves, 1: slow down in middle section curves, 
% 2: none, 3: linear, 4: triple min jerk

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
seqdata.flags.mt_compress_after_transport = 1; % compress QP after transport
seqdata.flags.RF_evap_stages = [1, 1, 1]; %[stage1, decomp/transport, stage1b] %Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.

% Turn on plug beam during RF1B
seqdata.flags.mt_use_plug = 1;

% Lower cloud after evaporation before TOF (useful for hot clouds)
seqdata.flags.lower_atoms_after_evap = 0; 

% RF1A and RF1B timescales
RF_1B_time_scale_list = [0.8];0.8;
RF_1B_time_scale = getScanParameter(RF_1B_time_scale_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1B_time_scale');

rf_evap_time_scale = [0.6 RF_1B_time_scale];

% RF1A Ending Frequency
RF_1A_Final_Frequency_list = [16];%16
RF_1A_Final_Frequency = getScanParameter(RF_1A_Final_Frequency_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1A_finalfreq','MHz');

% RF1B Final Frequency
RF_1B_Final_Frequency_list = [.8];1;%0.8,0.4 1
RF_1B_Final_Frequency = getScanParameter(RF_1B_Final_Frequency_list,...
    seqdata.scancycle,seqdata.randcyclelist,'RF1B_finalfreq','MHz');

% Resonantly kill atoms after evaporation
seqdata.flags.mt_kill_Rb_after_evap = 0;    % Blow away Rb
seqdata.flags.mt_kill_K_after_evap = 0;     % Blow away K
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DIPOLE TRAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dipole trap
% 1: dipole trap loading, 2: dipole trap pulse, 3: pulse on dipole trap during evaporation
seqdata.flags.xdt = 1; 
seqdata.params.ODT_zeros = [-0.04,-0.04];

% MT to XDT State Transfer
seqdata.flags.xdt_Rb_21uwave_sweep_field = 1;   % Field Sweep Rb 2-->1
seqdata.flags.xdt_Rb_21uwave_sweep_freq = 0;    % uWave Frequency sweep Rb 2-->1
seqdata.flags.xdt_K_p2n_rf_sweep_freq = 1;      % RF Freq Sweep K +9-->-9  

% xdt_K_p2n_rf_sweep_freq

% State Manipulation Before Optical Evaporation 
seqdata.flags.xdt_d1op_start= 1;            % D1 pump to purify
seqdata.flags.xdt_rfmix_start = 1;          % RF Mixing -9-->-9+-7    
seqdata.flags.xdt_kill_Rb_before_evap = 0;  % optically remove Rb
seqdata.flags.xdt_kill_K7_before_evap = 0;  % optical remove 7/2 K after (untested)

% Optical Evaporation
% 1: exp 2: fast linear 3: piecewise linear
seqdata.flags.CDT_evap = 1;       

% State Manipulatoin After Optical Evaporation
seqdata.flags.xdt_d1op_end = 0;          % D1 optical pumping
seqdata.flags.xdt_rfmix_end = 0;         % RF Mixing -9-->-9+-7
seqdata.flags.xdt_kill_Rb_after_evap  = 0;   % optically remove Rb
seqdata.flags.xdt_kill_K7_after_evap  = 0;   % optical remove 7/2 K after (untested)

% XDT High Field Experiments
seqdata.flags.xdt_high_field_a = 0;

% Take a second PA pulse after absorption imaging to calibrate PA power
seqdata.flags.misc_calibrate_PA = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OPTICAL LATTICE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Optical lattice
seqdata.flags.load_lattice = 0; % set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
seqdata.flags.pulse_lattice_for_alignment = 0; % 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
seqdata.flags.pulse_zlattice_for_alignment = 0; % 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OTHER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (seqdata.flags.xdt ~= 0 || seqdata.flags.load_lattice ~= 0)
    seqdata.flags.QP_imaging = 0;
else
    seqdata.flags.QP_imaging = 1;
end

%% Scope Trigger
% Choose which scope trigger to use.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OPTICAL LATTICE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scope_trigger = 'rf_spectroscopy';
scope_trigger = 'Lattice_Mod';
% scope_trigger = 'FB_ramp';
% scope_trigger = 'lattice_ramp_1';
% scope_trigger = 'lattice_off';
% scope_trigger = 'Raman Beams On';
% scope_trigger = 'PA_Pulse';

%% Set switches for predefined scenarios


if seqdata.flags.image_loc == 0 %MOT cell imaging
    seqdata.flags.mt_use_plug = 0;
    seqdata.flags.mt_compress_after_transport = 0;
    seqdata.flags.RF_evap_stages = [0 0 0];
    seqdata.flags.xdt = 0;
    seqdata.flags.load_lattice = 0;  
    seqdata.flags.pulse_lattice_for_alignment = 0;
end

%% PA Laser Lock Detuning

dispLineStr('Updating PA Request',curtime);

% K D2 line
PA_resonance = 391016.821;

% Define the detuning list
% PA_detuning_list= -49.555; -49.578; -49.555;

PA_detuning_list = -49.539;

 % round to nearest kHz
PA_detuning_list=round(PA_detuning_list,6);

% Scan randomly
PA_detuning = getScanParameter(PA_detuning_list, ...
    seqdata.scancycle, seqdata.randcyclelist, 'PA_detuning','GHz');

% Convert detuning into laser frequency
PA_freq = PA_resonance + PA_detuning;
PA_freq = round(PA_freq,6); % round to nearest kHz

addOutputParam('PA_freq',PA_freq,'GHz');

lockSetFileName ='Y:\wavemeter_amar\lock_freq.txt';

isFreqUpdated = 0;


updateTime=0;
if exist(lockSetFileName)    
    disp(['writing PA freq to file ' num2str(PA_freq,12)]);
    tic;
    while ~isFreqUpdated && updateTime<2    
        try
            [fileID,errmsg] = fopen(lockSetFileName,'w');
            if ~isequal(fileID,-1)
               fprintf(fileID,'%s',num2str(PA_freq,12)); 
            end
            fclose(fileID);

            text = fileread(lockSetFileName);

            textNum = str2num(text);

            disp(textNum);

            if isequal(textNum,PA_freq)
                isFreqUpdated = 1;
                disp('Written frequency is the same as the text file');
            end
            disp(updateTime)
            updateTime = toc;
        end
    end
    if updateTime>=2
       warning('may have not updated the frequency'); 
    end
    disp('--------------------');
end
%% Set Objective Piezo VoltageS
% If the cloud moves up, the voltage must increase to refocus
%  (as the experiment warms up, selected plane tends to move up a bit)

obj_piezo_V_List = [3];[5];[4.6];
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
    
%% Four-Pass

% Set 4-Pass Frequency
detuning_list = [5];
df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
DDSFreq = 324.206*MHz + df*kHz/4;
addOutputParam('FourPassFrequency',DDSFreq*1e-6,'MHz');

doProgram4Pass = 0;
if doProgram4Pass
    DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
end

% %Set the frequency of the first DP AOM 
%     D1_FM_List = [222.5];
%     D1_FM = getScanParameter(D1_FM_List, seqdata.scancycle, seqdata.randcyclelist);%5
%     setAnalogChannel(calctime(curtime,0),'D1 FM',D1_FM);
%     addOutputParam('D1_DP_FM',D1_FM);

%% Initialize Voltage levels

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
setAnalogChannel(calctime(curtime,0),'Plug',2500); % Current in mA

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
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

%% Load the MOT
% Dump out the saved MOT and reload it

if (seqdata.flags.MOT_load_at_start == 1)
    % Load the MOT
    loadMOTSimple(curtime,1);
    
    controlled_load_time = 30000;
    
    % Wait for the MOT to load
curtime = calctime(curtime,controlled_load_time);
else
    curtime = calctime(curtime,750);
end   

%% Prepare to Load into the Magnetic Trap

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

if ~(seqdata.flags.image_type==4 )

    %same as molasses (assume this zero's external fields)

    yshim2 = 0.25;%0.25; %0.9
    xshim2 = 0.25;%0.2; %0.1
    zshim2 = 0.05;%0.05; %0.3  0.0 Dec 4th 2013

    %RHYS - Again, probably control these things within functions for
    %code readability. 

    %optimize shims for loading into mag trap
    setAnalogChannel(calctime(curtime,0.01),'Y MOT Shim',yshim2,3); %1.25
    setAnalogChannel(calctime(curtime,0.01),'X MOT Shim',xshim2,2); %0.3 
    setAnalogChannel(calctime(curtime,0.01),'Z MOT Shim',zshim2,2); %0.2

    %RHYS - the second important function, which loads the MOT into the magtrap. 

curtime = Load_MagTrap_from_MOT(curtime);

end

%**Should be set to zero volts to fully turn off the shims (use volt func 1)
%turn off shims
setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.0,3); %3
setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.0,2); %2
setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.0,2); %2

%% Transport 
% Use the CATS to mangetically transport the atoms from the MOT cell to the
% science chamber.

    dispLineStr('Magnetic Transport',curtime);

    % Open kitten relay
    curtime = setDigitalChannel(curtime,'Kitten Relay',1);
    
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
    %Turn Shims to Science cell zero values
    setAnalogChannel(calctime(curtime,1000),'X Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Z Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Y Shim',0,4); %4

    % Scope trigger
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
    
    %RHYS - the third imporant function. Transports cloud from MOT to science
    %chamber. All surrounding relevant code should be integrated into this.
    %Furthermore, note the significant calculation time due to spline
    %interpolation - this is likely unneccesary?
    
    disp('Start Calculating Transport')
curtime = Transport_Cloud(curtime, seqdata.flags.hor_transport_type,...
    seqdata.flags.ver_transport_type, seqdata.flags.image_loc);
    disp('End Calculating Transport')  

%% Ramp up QP
dispLineStr('Compression stage after transport to science cell.',curtime);

% Compression stage after the transport to the science cell

[curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_trans(curtime, ...
    seqdata.flags.mt_compress_after_transport);

%Shim Values to Turn On To: 
% (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
x_shim_val = seqdata.params.plug_shims(1); %0*1.6
y_shim_val = seqdata.params.plug_shims(2); %0*0.5
z_shim_val = seqdata.params.plug_shims(3); %0*0.8

%turn on shims
AnalogFuncTo(calctime(curtime,0),'Y Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,y_shim_val,4); 
AnalogFuncTo(calctime(curtime,0),'X Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,x_shim_val,3);
curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,z_shim_val,3); 

%% RF1A
if ( seqdata.flags.RF_evap_stages(1) == 1 )
    
    % |2,2>-->|2,1>=h*f ==> E = 2*h*f
    % 1 MHz == 48 uK
    
    dispLineStr('RF1A',curtime);

    fake_sweep = 0;             % do a fake RF sweep
    hold_time = 100;            % hold time after sweeps
    pre_hold_time =  100;       % Hold time before sweeps
    start_freq = 42;            % Beginning RF1A frequnecy 42 MHz 

    % Frequency points
    freqs_1 = [start_freq 28 20 RF_1A_Final_Frequency]*MHz;
    
    % Gains during each sweep
    RF_gain_1 = 0.5*[-4.1 -4.1 -4.1 -4.1]; 
    
    % Duration of each sweep interval
    sweep_times_1 =[14000 8000 4000].*rf_evap_time_scale(1);    
    
    disp(['     Times        (ms) : ' mat2str(sweep_times_1) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1*1E-6) ]);
    disp(['     Gains         (V) : ' mat2str(RF_gain_1) ]);

    % Hold before beginning evaporation
    curtime = calctime(curtime,pre_hold_time);

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

if  seqdata.flags.mt_use_plug==1       
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
    evap_end_gradient_factor_list = [1];.9; %0.75
    evap_end_gradient_factor = getScanParameter(evap_end_gradient_factor_list,...
        seqdata.scancycle,seqdata.randcyclelist,'evap_end_gradient_factor');
    currs_1b = [1 1 evap_end_gradient_factor evap_end_gradient_factor]*I_QP;
    freqs_1b = [freqs_1(end)/MHz*1.1 7 RF_1B_Final_Frequency 2]*MHz;
    
    rf_1b_gain_list = [-2];
    rf_1b_gain = getScanParameter(rf_1b_gain_list,...
        seqdata.scancycle,seqdata.randcyclelist,'RF1B_gain','V');
    
%     rf_1b_gain = -2;    
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
        % This is useful if you want to check the plug_shim_slopes
        % (lowering the field gradient should keep the MT field zero
        % constant if the plug shim slopes are appropriate)
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



if seqdata.flags.mt_kill_Rb_after_evap || seqdata.flags.mt_kill_K_after_evap
    dispLineStr('Blow away Rb or K',curtime);

    if seqdata.flags.mt_kill_Rb_after_evap
        
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
     
    if seqdata.flags.mt_kill_K_after_evap
          
        %open K probe shutter
         %0=closed, 1=open
        setDigitalChannel(calctime(curtime,K_blow_away_time-10),30,1);
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


%% Ramp Down Plug Power a little bit
seqdata.flags.mt_plug_ramp_end = 0;
if seqdata.flags.mt_plug_ramp_end
    plug_ramp_time = 200;
    
    plug_ramp_power_list = [1500];
    plug_ramp_power=getScanParameter(plug_ramp_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'plug_ramp_power','mA');

    
    curtime = AnalogFuncTo(calctime(curtime,0),'Plug',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        plug_ramp_time,plug_ramp_time,plug_ramp_power,3); 
    
    % Ramp back to full a while later
    AnalogFuncTo(calctime(curtime,2000),'Plug',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        plug_ramp_time,plug_ramp_time,2500,3); 
    
    curtime = calctime(curtime,500);
end

%% Post QP Evap Tasks

if ( seqdata.flags.mt_use_plug == 1)       
    hold_time_list = [0];
    hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_QPcoils');
    curtime = calctime(curtime,hold_time);   
    plug_offset = -2.5;%-2.5 for experiment, -10 to align for in trap image

    % Turn off the plug here if you are doing RF1B TOF.
    if (seqdata.flags.xdt ~= 1)
        % Dipole transfer has its own code for turning off the plug after
        % loading the XDTs
        dispLineStr('Turning off plug at',calctime(curtime,plug_offset));
        setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',0);% 0:OFF; 1: ON
        ScopeTriggerPulse(calctime(curtime,0),'plug test');
    end        
end


%% Dipole Trap
if ( seqdata.flags.xdt == 1 )
    dispLineStr('Caling dipole_transfer.m',curtime);   
    [curtime, I_QP, V_QP, P_dip, I_shim] = ...
        dipole_transfer(curtime, I_QP, V_QP, I_shim);
end

%% Pulse lattice after releasing from dipole trap

if ( seqdata.flags.pulse_lattice_for_alignment ~= 0 )
    %RHYS - how should these 'pulse lattice' alignment codes be
    %organized/called?
    curtime = Pulse_Lattice(curtime,...
        seqdata.flags.pulse_lattice_for_alignment);
end

%% Optical Lattice

if ( seqdata.flags.load_lattice ~= 0 )
    curtime = Load_Lattice(curtime);
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

%% Initiate Time of Flight  
dispLineStr('Turning off coils and traps.',curtime);
    
    % Turn off the MOT
    if ( seqdata.flags.image_type ~= 4 )
        setAnalogChannel(curtime,'MOT Coil',0,1);
    end
    
    % Turn off all transport Coils
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end   
    
    if ~seqdata.flags.High_Field_Imaging    
        % Turn off QP Coils (analog control)    
        setAnalogChannel(calctime(curtime,0),'Coil 15',0,1);            % C15
        curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1);  % C16
        curtime = setAnalogChannel(curtime,'kitten',0,1);               % Kitten    

        % MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
        qp_switch1_delay_time = 0;

        if I_kitt == 0
            %use fast switch
            setDigitalChannel(curtime,'Coil 16 TTL',1); % Turn off Coil 16
            setDigitalChannel(calctime(curtime,500),'Coil 16 TTL',0); % Turn on Coil 16
        else
            %Cannot use Coil 16 fast switch if atoms have not be transferred to
            %imaging direction!
        end

        % Turn off 15/16 switch (10 ms later)
        setDigitalChannel(calctime(curtime,qp_switch1_delay_time),'15/16 Switch',0);
    end
    
    % XDT TOF
    if seqdata.flags.xdt
        
        % Read XDT Powers right before tof
        P1 = getChannelValue(seqdata,'dipoleTrap1',1);
        P2 = getChannelValue(seqdata,'dipoleTrap2',1);

        addOutputParam('xdt1_final_power',P1,'W');
        addOutputParam('xdt2_final_power',P2,'W');

        % Turn off AOMs 
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);

        % XDT1 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',...
            seqdata.params.ODT_zeros(1));
        % XDT2 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
        % I think this channel is unused now
        setDigitalChannel(calctime(curtime,-1),'XDT Direct Control',1);
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
%         setDigitalChannel(curtime,'MOT TTL',1);    
    end


%% Imaging

    %RHYS - Imporant code, but could delete the scenarios that are no longer
    %used. Also, the iXon movie option under 8 could use some cleaning. 
    if seqdata.flags.image_type == 0 % Absorption Image
        dispLineStr('Absorption Imaging.',curtime);

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
    
%% Set the Science Shims to Zero Current (0V adwin signal)   

    % Set the shim values to zero
    setAnalogChannel(calctime(curtime,0),'X Shim',0,1);
    setAnalogChannel(calctime(curtime,0),'Y Shim',0,1);
    setAnalogChannel(calctime(curtime,0),'Z Shim',0,1);
    
%% Post-sequence: Pulse the PA laser again for labjack power measurement
    if seqdata.flags.misc_calibrate_PA == 1
    
       curtime = PA_pulse(curtime,2); 
    
    end

%% Post-sequence: rotate diople trap waveplate to default value

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

%{
dispLineStr('Loading MOT.',curtime);

rb_mot_det_List= 32;
rb_MOT_detuning=getScanParameter(rb_mot_det_List,...
    seqdata.scancycle,seqdata.randcyclelist,'rb_MOT_detuning');

k_MOT_detuning_list = 22;
k_MOT_detuning = getScanParameter(k_MOT_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'k_MOT_detuning');        

k_repump_shift = 0;
addOutputParam('k_repump_shift',k_repump_shift);
mot_wait_time = 50;

% Load the MOT
curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);

% Set the repump detuning
setAnalogChannel(curtime,'K Repump FM',k_repump_shift,2);
%}

% Load the MOT
dispLineStr('Load the MOT',curtime);
loadMOTSimple(curtime,0);

% Wait some additional time
if ~seqdata.flags.MOT_load_at_start
    curtime = calctime(curtime,seqdata.params.UV_on_time);
end
%% Transport Reset

% Reset transport relay (Coil 3 vs Coil 11)
curtime = setDigitalChannel(calctime(curtime,10),'Transport Relay',0);

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