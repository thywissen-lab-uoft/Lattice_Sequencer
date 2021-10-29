%------
%Author: Stefan ( Ctrl-C/Ctrl-V )
%Created: Feb 2013
%Summary:   Loading the lattice -- intentionally left without parameters.
%           Rampup times and everything that is done in the lattice should
%           be specified in here.
%           Typically called after evaporation in ODT
%------

function [timeout,P_dip,P_Xlattice,P_Ylattice,P_Zlattice,P_RotWave] = Load_Lattice(varargin)
global seqdata;

timein = varargin{1};
lattice_flags(timein);

if nargin > 1
    Imaging_Time = varargin{2};
else
    Imaging_Time = 1*5000+50;
end

curtime = timein;
lattices = {'xLattice','yLattice','zLattice'};
seqdata.params. XDT_area_ratio = 1; %RHYS - Why is this defined here again?


%% Lattice Flags    
% These are the lattice flags sorted roughly chronologically.

ramp_fields_after_lattice_loading = 0;  % (416,503)     keep : Ramp on the fesbhach field after lattice load
get_rid_of_Rb_in_lattice = 0;           % (523)         keep : Blow away Rb after lattice load
spin_mixture_in_lattice_before_plane_selection = 0; % (668)             keep : Make a -9/2,-7/2 spin mixture.   
Dimple_Trap_Before_Plane_Selection = 0; % (716)         keep : turn on the dimple, leave this option: note that the turning off code was deleted
do_optical_pumping = 0;                 % (1426) keep : optical pumping in lattice    
remove_one_spin_state = 0;              % (1657)        keep : An attempt to remove only |9/2,-9/2> atoms while keeping |9/2,-7/2> so that plane selection could work

oldLoad=0;
newLoad=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Waveplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags control how the XDT/Lattice waveplate behaves.
rotate_waveplate_init = 1;              % (345) initially rotate the WP to put 90% the power to the lattice
rotate_waveplate = 0;                   % (4637):  Turn Rotating Waveplate to Shift Power to Lattice Beams

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
Drop_From_XDT = 0;                      %  (97,5187,5257) May need to add code to rotate waveplate back here.
do_lattice_mod = 0;                     %  (4547)        apply AM Spectroscopy                 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conductivity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags are associated with the conducitivity experiment
conductivity_without_dimple = 0;       % (747-1536) keep: the real conductivity experiment happens here 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RF/uWave Spectroscopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_K_uwave_spectroscopy2 = 0;           % (3497)
do_K_uwave_spectroscopy = 0;            % (3786) keep
do_Rb_uwave_spectroscopy = 0;           % (3929)
do_RF_spectroscopy = 0;                 % (3952,4970)
do_K_raman_spectroscopy = 0;            % (3989) under development

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DMD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dimple Beam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags are associated with the now defunct dimple beam
Dimple_Mod = 0;                     % (4185) keep: Used to calibrate dimple trap depth

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection, Raman Transfers, and Fluorescence Imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
do_plane_selection = 0;                             % (2082-3285) Primary Flag    
fast_plane_selection = 0;                           % (1406)            keep : under development; could be the future of plane selection code for cleaner control
kill_pulses = 0;                                    % (1917,2561,2847)  keep :D2 Kill F=9/2
second_plane_selection = 0;                         % (2755)            copy 
eliminate_planes_with_QP = 0;                       % (2933)            keep : QP vacuum cleaner. In 2nd time plane selection section
do_plane_selection_horizontally = 0;                % (3077,3111,3144)  keep : generalized for Raman cooling %1: use new version of the code, 2: use old messy code, 3: DOUBLE SELECTION! 
Dimple_Trap_After_Plane_Selection = 0;              % (4155,4209)       delete (?) : turn on dimple trap %Rhys suggested to delete?
do_lattice_ramp_after_spectroscopy = 0;             % (4658)            keep : Ramp lattice for fluorescence image

% Actual fluorsence image flag
Raman_transfers = 0;                                % (4727)            keep : apply fluorescence imaging light

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        


%% Other parameters
% To be consolidated and simplified.

% Lattice Hold. This should be removed and/or made simpler.
if seqdata.flags.High_Field_Imaging
    lattice_holdtime = 0; %no extra hold time if HF is ramped before lattice loading
    
else
   lattice_holdtime_list =[150]; [0]; %150 sept28
   lattice_holdtime = getScanParameter(lattice_holdtime_list,seqdata.scancycle,seqdata.randcyclelist,'latt_holdtime','ms');%maximum is 4
 
end

if Drop_From_XDT
    lattice_rampdown = 50;
else
    lattice_rampdown = 2; %Whether to down a rampdown for bandmapping (1) or snap off (0) - number is also time for rampdown
end

% Parameters for lattice loading, section used for lattice alignment
Depth_List = [100];
ZLD = getScanParameter(Depth_List,seqdata.scancycle,seqdata.randcyclelist,'zld');

%% Load Lattice from XDT Settings

if newLoad
    % Hold in lattice
    latt_hold_time_list = [50];
    latt_hold_time = getScanParameter(latt_hold_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time','ms');
    % Lattice depth and ramp times
    L0=seqdata.params.lattice_zero;    
    % Get the optical evaporation ending power
    dip_endpower = 1.0*getChannelValue(seqdata,'dipoleTrap1',1,0);
    zld = 60;
    
    % Ramp Mode
    rampMode=0;
    do_DMD=0;
    %
    % 0 : Ramp only the lattice
    % 1 : Ramp lattice,XDT,and DMD
   
    %initial lattice depth
    initial_latt_depth_list = [10];
    init_depth = getScanParameter(initial_latt_depth_list,...
        seqdata.scancycle,seqdata.randcyclelist,'initial_latt_depth','ms');
    switch rampMode
        case 0 % Ramp only the lattice
            %%% Lattice %%%
            latt_depth=...
                [init_depth init_depth zld zld;     % X lattice
                 init_depth init_depth zld zld;     % Y lattice
                 init_depth init_depth zld zld];    % Z Lattice 
             latt_ramp_time_list = [150];
             latt_ramp_time = getScanParameter(latt_ramp_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_ramp_time','ms');
%             latt_times=[150 50 0.2 50];
            latt_times=[latt_ramp_time 50 0.2 50];
            
            %%% XDT is fixed%%%
            dip_pow=dip_endpower;
%             dip_times=[1];
            
            dip_pow=[dip_endpower,dip_endpower,0.1, 0.1];
            dip_pow=[dip_endpower,dip_endpower,dip_endpower,dip_endpower];

            dip_times=latt_times;  

            %%% DMD is fixed %%%
            dmd_pow=0;
            dmd_times=[1];
        case 1 % Ramp everything
            %%% Lattice %%%
            latt_depth=...
                 [L0(1) L0(1)
                  L0(2) L0(2);    % y lattice
                 100 100];    % Z Lattice
            latt_times=[100 latt_hold_time];
            
            latt_XDT_pow_list = [1.0];
            latt_XDT_pow = getScanParameter(latt_XDT_pow_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_XDT_pow','V');
            %%% XDT %%%
            dip_pow=[latt_XDT_pow latt_XDT_pow];
            dip_times=[150 50];   
     
            %%% DMD %%%
            
            DMD_power_val_list = [1.25]; %2V is roughly the max now 
            DMD_power_val = getScanParameter(DMD_power_val_list,...
                seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val','V');

            dmd_pow=[DMD_power_val DMD_power_val 0];
            dmd_times=[100 50 50];
        case 2 % Simple square ramp
            
%             latt_depth=...
%                  [L0(1) L0(1);     % X lattice
%                  L0(2) L0(2);     % Y lattice
%                  L0(3) L0(3)];    % Z Lattice
             latt_depth=...
                 [L0(1) L0(1); % X lattice
                 100 100;  % Y lattice
                 L0(3) L0(3)];    % Z Lattice
%             latt_times=[1 latt_hold_time];
            latt_ramp_time_list = [150];
             latt_ramp_time = getScanParameter(latt_ramp_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_ramp_time','ms');
%             latt_times=[150 50 0.2 50];
            latt_times=[latt_ramp_time latt_hold_time];
            
            latt_XDT_pow_list = [0.0];
            latt_XDT_pow = getScanParameter(latt_XDT_pow_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_XDT_pow','V');
            %%% XDT %%%
            dip_pow=[dip_endpower latt_XDT_pow];
            dip_times=[50 50];   
            
             %%% DMD is fixed %%%
            dmd_pow=[];
            dmd_times=[];
     
            
            
    end
    
    % Duration of each ramp
    T_latt=sum(latt_times);
    T_dip=sum(dip_times);
    T_dmd=sum(dmd_times);
    T_load_tot = max([T_latt T_dip do_DMD*T_dmd]);
    
    %%%% Add output params %%%
    addOutputParam('latt_depth_load',latt_depth);
    addOutputParam('latt_depth_times',latt_times);    
    addOutputParam('latt_dip_pow_load',dip_pow);
    addOutputParam('latt_dip_pow_times',dip_times);    
    addOutputParam('latt_dmd_pow_load',dmd_pow);
    addOutputParam('latt_dmd_pow_times',dmd_times);
    seqdata.flags.dmd_enable=do_DMD;
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % Error checking
    if (length(latt_times) ~= size(latt_depth,2)) || ...
            (size(latt_depth,1)~=3)
        error('Invalid ramp specification for lattice loading!');
    end
    if (length(dip_times) ~= size(dip_pow,2))
        error('Invalid ramp specification for xdt lattice loading!');
    end
    
    if (length(dmd_times) ~= size(dmd_pow,2))
        error('Invalid ramp specification for dmd lattice loading!');
    end
end

%% LOADING SEQ BELOW CAN BE USED FOR DMD rough alignment

if oldLoad
    % % Lattice Ramp up depths
    lat_rampup_depth = 1*[1*[10 10 30 30 ZLD  ZLD];
                          1*[10 10 30 30 ZLD  ZLD];
                          1*[10 10 30 30 ZLD  ZLD]];   

    % DMD Stuff
    DMD_on_time_list = [200];
    DMD_on_time = getScanParameter(DMD_on_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time','ms');

    DMD_ramp_time = 100; %10
    lat_hold_time_list = 50;%50 sept28
    lat_hold_time = getScanParameter(lat_hold_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time');%maximum is 4
    % 
    % %     lat_rampup_time = 1*[50,DMD_on_time+DMD_ramp_time-70,100,2,50,lat_hold_time]; 
    % % % %     lat_rampup_time = 1*[50,2+DMD_on_time+DMD_ramp_time,10,2,50,lat_hold_time];
    % 
    % 
    
    lat_rampup_time = 1*[20,30,30,10,50,lat_hold_time]; 

    % Ramp the DMD power up
    if do_DMD
        z_latt_list = [0];
        z_latt = getScanParameter(z_latt_list,...
            seqdata.scancycle,seqdata.randcyclelist,'z_latt_init','Er');
        lat_rampup_depth = 1*[1*[-25 -25 30 30 ZLD  ZLD];
                              1*[-25 -25 30 30 ZLD  ZLD];
                              1*[z_latt z_latt 30 30 ZLD  ZLD]];   

        lat_rampup_time = 1*[50,DMD_on_time+DMD_ramp_time-70,100,2,50,lat_hold_time]; 
        offset_time = 40;
        DMD_power_val_list = [0.1:0.2:1.9]; %2V is roughly the max now 
        DMD_power_val = getScanParameter(DMD_power_val_list,...
            seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val','V');

        setAnalogChannel(calctime(curtime,-1000),'DMD Power',2);
        setDigitalChannel(calctime(curtime,-10 +offset_time),'DMD Shutter',0);%0 on 1 off
        setDigitalChannel(calctime(curtime,-200+offset_time),'DMD TTL',0);
        setDigitalChannel(calctime(curtime,-100+offset_time),'DMD TTL',1);
        setDigitalChannel(calctime(curtime,-20+offset_time),'DMD AOM TTL',0);
        setDigitalChannel(calctime(curtime,-20+offset_time),'DMD PID holder',1);
        AnalogFuncTo(calctime(curtime,-30+offset_time),'DMD Power',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1, 1, 0);
        setDigitalChannel(calctime(curtime,0+offset_time),'DMD AOM TTL',1);%1 on 0 off
        setDigitalChannel(calctime(curtime,0+offset_time),'DMD PID holder',0);
        AnalogFuncTo(calctime(curtime,0+offset_time),'DMD Power',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);

        % curtime = calctime(curtime,DMD_on_time + DMD_ramp_time);
        % curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',...
        %     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, -0.1);
        % setAnalogChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+offset_time),'DMD Power',-0.1);
        AnalogFuncTo(calctime(curtime,0+DMD_on_time+DMD_ramp_time+offset_time),'DMD Power',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, -0.1);
        setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+offset_time+DMD_ramp_time),'DMD AOM TTL',0);
        setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+10+offset_time+DMD_ramp_time),'DMD Shutter',1);
        setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+20+offset_time+DMD_ramp_time),'DMD AOM TTL',1);
        setAnalogChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+20+offset_time+DMD_ramp_time),'DMD Power',2);

    end

    % Check that number of times and depths match up
    if (length(lat_rampup_time) ~= size(lat_rampup_depth,2)) || ...
            (size(lat_rampup_depth,1)~=length(lattices))
        error('Invalid ramp specification for lattice loading!');
    end
end
    
%% Other DMD stuff
% % % % %%%%%%%%%%%%%   

%RHYS - DMD stuff above and below. Write a module rather than commenting
%out70

%%%%%%%%DENSITY PROPAGATION
% % First, ramp up box
% DMD_On_Time = 50;
% DMD_Ramp_Time = 50;   
% DMD_Power = 3.5;
% First_image_on_time = 200;% = DMD_On_Time + DMD_Ramp_Time + Lat_Ramp_Time + Lat_Hold_Time first
% DMD_Image_Change_Delay = 5.7;
% setDigitalChannel(calctime(curtime,First_image_on_time-1000),'DMD TTL',0); %1 off 0 on %1000ms is set on DMD gui
% setDigitalChannel(calctime(curtime,First_image_on_time-1000+200),'DMD TTL',1); %pulse time should be short for two triggers
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);%0 off 1 on 
% AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_Ramp_Time, DMD_Ramp_Time, DMD_Power);
% % Then, ramp up lattice
% Exp_Depth_x = 0;
% Exp_Depth_y = 0;
% Exp_Depth_z = 10;
% Pin_Depth = 200;
% lat_rampup_depth = 1*[1*[0.0 0.0 Exp_Depth_x Exp_Depth_x Pin_Depth Pin_Depth] * 10.75/10.0 - 6.0;
%                       1*[0.0 0.0 Exp_Depth_y Exp_Depth_y Pin_Depth Pin_Depth] * 12.6/10.0;
%                       1*[0.0 0.0 Exp_Depth_z Exp_Depth_z Pin_Depth Pin_Depth] * 12.3/10.0]/atomscale;   
% Lat_Ramp_Time = 50;
% %Turn of the XDTs after tubes are loaded.
% % XDT_Ramp_Time = 50;
% % AnalogFuncTo(calctime(curtime,DMD_Ramp_Time + DMD_On_Time + Lat_Ramp_Time),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),XDT_Ramp_Time,XDT_Ramp_Time,0.0,1);
% % AnalogFuncTo(calctime(curtime,DMD_Ramp_Time + DMD_On_Time + Lat_Ramp_Time),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),XDT_Ramp_Time,XDT_Ramp_Time,0.0,1);
% 
% AC_Conductivity = 1;
% if(~AC_Conductivity)
%     %Shine a second image with a sinusoid. Optionally vary AOM power.
%     % setAnalogChannel(calctime(curtime,First_image_on_time + DMD_Image_Change_Delay),'DMD Power',1.4);
%     Second_image_on_time_list =0; [(0:0.1:1) 1.2 1.4 1.6];[1.4:0.2:4];
%     Second_image_on_time = getScanParameter(Second_image_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'Second_image_on_time');
%     Lat_Hold_Time_List = 50 + DMD_Image_Change_Delay + Second_image_on_time;%5.7 is due to some delay in DMD changing pattern, might need to clibrate more carefully
%     Lat_Hold_Time = getScanParameter(Lat_Hold_Time_List,seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time');%maximum is 4
%     Lat_Pin_Time = 0.1;
%     Pin_Hold_Time = 50;%DMD shine time ends 50ms after lattice pin happened
%     Total_Time = DMD_Ramp_Time + DMD_On_Time + Lat_Ramp_Time + Lat_Hold_Time + Lat_Pin_Time + Pin_Hold_Time;
%     lat_rampup_time = 1*[DMD_Ramp_Time,DMD_On_Time,Lat_Ramp_Time,Lat_Hold_Time,Lat_Pin_Time,Pin_Hold_Time]; 
%     % Turn off DMD
%     setAnalogChannel(calctime(curtime,Total_Time),'DMD Power',-5);
%     setDigitalChannel(calctime(curtime,Total_Time),'DMD AOM TTL',0);%0 off 1 on
% else
% 
%     %Parameters for linearly-polarized conductivity modulation.
%     freq_list = [2000]; %was 120
%     mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%     time_list = [0.0:0.2:3.0]*(1000/mod_freq);
%     mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%     addOutputParam('mod_time',mod_time);
%     amp_list = [1.0]; %displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%     mod_amp = 1.0*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp1');
%     mod_dev_chn1 = mod_amp;
%     mod_offset1 = mod_amp/2.0;
%     mod_phase1 = 270;
% 
%     %Provides modulation.
%     %-------------------------set Rigol DG4162 ---------
%     str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
%     str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
%     str131=sprintf(':SOUR1:PHAS:INIT;');
%     str2=[str112,str111,str131];
%     addVISACommand(4, str2);
% 
%     %-------------------------end:set Rigol-------------        
%     %ramp the modulation amplitude
%     mod_ramp_time_list = [5];%150 sept28
%     mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
% 
%     final_mod_amp = 1;
%     addOutputParam('mod_amp',mod_amp*final_mod_amp);
%     setAnalogChannel(calctime(curtime,First_image_on_time + DMD_Image_Change_Delay),'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%     ScopeTriggerPulse(calctime(curtime, First_image_on_time + DMD_Image_Change_Delay),'conductivity_modulation');
%     setDigitalChannel(calctime(curtime,First_image_on_time + DMD_Image_Change_Delay),'Lattice FM',1);  %send trigger to Rigol for modulation
%     %====================================
% 
%     AnalogFuncTo(calctime(curtime,First_image_on_time + DMD_Image_Change_Delay),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
% 
%     %Shine a second image with a sinusoid. Optionally vary AOM power.
%     % setAnalogChannel(calctime(curtime,First_image_on_time + DMD_Image_Change_Delay),'DMD Power',1.4);
%     Second_image_on_time_list = mod_time + mod_ramp_time;[1.4:0.2:4];
%     Second_image_on_time = getScanParameter(Second_image_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'Second_image_on_time');
%     Lat_Hold_Time_List = 50 + DMD_Image_Change_Delay + Second_image_on_time;%5.7 is due to some delay in DMD changing pattern, might need to clibrate more carefully
%     Lat_Hold_Time = getScanParameter(Lat_Hold_Time_List,seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time');%maximum is 4
%     Lat_Pin_Time = 0.01;
%     Pin_Hold_Time = 50;%DMD shine time ends 50ms after lattice pin happened
%     Total_Time = DMD_Ramp_Time + DMD_On_Time + Lat_Ramp_Time + Lat_Hold_Time + Lat_Pin_Time + Pin_Hold_Time;
%     lat_rampup_time = 1*[DMD_Ramp_Time,DMD_On_Time,Lat_Ramp_Time,Lat_Hold_Time,Lat_Pin_Time,Pin_Hold_Time]; 
%     % Turn off DMD
%     setAnalogChannel(calctime(curtime,Total_Time),'DMD Power',-5);
%     setDigitalChannel(calctime(curtime,Total_Time),'DMD AOM TTL',0);%0 off 1 on
% 
%     setDigitalChannel(calctime(curtime,Total_Time),'Lattice FM',0);   
%     setAnalogChannel(calctime(curtime,Total_Time),'Modulation Ramp',0);
%             
% end

%% What happens to ODT after lattice loading
if oldLoad

    %Additional parameters and flags for this sequence    
    %RHYS - Parameter determining how dipole trap behaves should be with
    %the rest of the lattice ramp parameters.
    dipole_trap_off_after_lattice_on = 0; 
    % 0 - use ramp parameters below; 
    % 1 - snap off after 1st lattice ramp;
    % 2 - ramp off after 1st lattice ramp;
    % 3 - snap off after all initial lattice ramps
    % 4 - ramp off after all initial lattice ramps
    % 5 - evaporate (i.e. ramp off slowly)
    % 6 - do nothing
    % Parameters for ramping the dipole trap, e.g. to decompress during loading
    dip_endpower = 1.0*getChannelValue(seqdata,'dipoleTrap1',1,0);     % where to end the ramp
    % dip_ramptime = 0.4*250;     % how long to ramp (note: this has to be shorter or equal to the lattice ramptime)
    % dip_rampstart = 0.6*250;      % when to ramp the ODTs, relative to timein        
    dip_ramptime = 1;
    dip_rampstart = lat_rampup_time(1)+lat_rampup_time(2);      % when to ramp the ODTs, relative to timein
    % dip_rampstart = lat_rampup_time(1) ; 
    % Make sure that the ODT is not on after lattice turns off
    dip_ramptime = min(dip_ramptime,sum(lat_rampup_time)+lattice_holdtime-dip_rampstart);
     
% add ouput parameters to save along with images    
%     addOutputParam('lattice_holdtime',lattice_holdtime);
%     addOutputParam('lattice_ramptime',lat_rampup_time(2));
    addOutputParam('lattice_depth',lat_rampup_depth(1,end));
end
%% Rotate waveplate to shift power to lattice beams
% This piece of code rotates the rotatable wavepalte to shift the optical
% power to the lattices.
%
% CF : Shouldn't this appear int he beginning of the code?
if rotate_waveplate_init
    dispLineStr('Rotating waveplate',curtime);
    %Start with a little power towards lattice beams, and increase power to
    %max only after ramping on the lattice
    
    %Turn rotating waveplate to shift a little power to the lattice beams
    wp_Trot1 = 600; % Rotation time during XDT
    wp_Trot2 = 150; % gets added as a wait time after lattice rampup  
    
    P_RotWave_I = 0.8;
    P_RotWave_II = 0.99;
    
    disp(['     Rotation Time 1 : ' num2str(wp_Trot1) ' ms']);
    disp(['     Rotation Time 2 : ' num2str(wp_Trot1) ' ms']);
    disp(['     Power 1         : ' num2str(100*P_RotWave_I) '%']);
    disp(['     Power 2         : ' num2str(100*P_RotWave_II) '%']);

    P_RotWave = P_RotWave_I; %output argument    
    AnalogFunc(calctime(curtime,-100-wp_Trot1),'latticeWaveplate',...
        @(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),...
        wp_Trot1,wp_Trot1,P_RotWave);
% % else
%     %Start with all power towards lattice beams
%     rotation_time = 1000;   % The time to rotate the waveplate
%     P_RotWave = 0.5;%0.9       % The fraction of power that will be transmitted 
%                             % through the PBS to lattice beams
%                             % 0 = dipole, 1 = lattice
%     curtime = AnalogFunc(calctime(curtime,-100-rotation_time),'latticeWaveplate',...
%         @(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),...
%         rotation_time,rotation_time,P_RotWave);    
end

%% Load Lattice from XDT Ramps
if newLoad
    seqdata.times.lattice_start_time = curtime;
    ScopeTriggerPulse(curtime,'Load lattices');
    
    dispLineStr('Ramping lattices.',curtime);
    disp(['     Ramp Mode            : ' num2str(rampMode)]);
    disp(' ');
    disp(['     Ramp Times      (ms) : ' mat2str(latt_times) ]);
    disp(['     xLattice       (ErK) : ' mat2str(latt_depth(1,:))]);
    disp(['     yLattice       (ErK) : ' mat2str(latt_depth(2,:))]);
    disp(['     zLattice       (ErK) : ' mat2str(latt_depth(3,:))]);
    disp(' ');
    disp(['     Dip Ramp Times  (ms) : ' mat2str(dip_times)]);
    disp(['     Dip Power        (W) : ' mat2str(dip_pow)]);
    disp(' ');
    disp(['     doDMD                : ' mat2str(do_DMD)]);
    disp(['     DMD Ramp Times  (ms) : ' mat2str(dmd_times)]);
    disp(['     DMD Dipole Power (V) : ' mat2str(dmd_pow)]);
    disp(['     Total Load Time (ms) : ' num2str(T_load_tot)]);       

    % Send request powers to low (if not already set)
    setAnalogChannel(calctime(curtime,-60),'xLattice',L0(1));
    setAnalogChannel(calctime(curtime,-60),'yLattice',L0(2));
    setAnalogChannel(calctime(curtime,-60),'zLattice',L0(3));

    % Enable rf output on ALPS3 (fast rf-switch and enable integrator)
    setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off
    setDigitalChannel(calctime(curtime,-100),'Lattice Direct Control',0); % 0 : Int on; 1 : int hold    

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Lattice Ramps %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % First ramp from zero value to first value
    T0=0;
    AnalogFuncTo(calctime(curtime,T0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(1,1));   
    AnalogFuncTo(calctime(curtime,T0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(2,1));   
    AnalogFuncTo(calctime(curtime,T0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(3,1));   
    T0=latt_times(1);

    % Rest of ramps
    for jj=2:length(latt_times)        
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            latt_times(jj), latt_times(jj), latt_depth(1,jj)); 
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            latt_times(jj), latt_times(jj), latt_depth(2,jj));
        AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            latt_times(jj), latt_times(jj), latt_depth(3,jj));    
        T0=T0+latt_times(jj);        
    end  
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% XDT Ramps %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % First ramp from zero value to first value
    T0=0;
    AnalogFuncTo(calctime(curtime,T0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        dip_times(1), dip_times(1), dip_pow(1));   
    T0=0;
    AnalogFuncTo(calctime(curtime,T0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        dip_times(1), dip_times(1), dip_pow(1));   
    T0=dip_times(1);

    % Rest of ramp
    for jj=2:length(dip_times)        
        AnalogFuncTo(calctime(curtime,T0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_times(jj), dip_times(jj), dip_pow(jj)); 
        AnalogFuncTo(calctime(curtime,T0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_times(jj), dip_times(jj), dip_pow(jj));
        T0=T0+dip_times(jj);
    end      
        
    % Stupid error handling
    dipole_trap_off_after_lattice_on=0;
    dip_endpower=dip_pow(end);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% DMD Ramps %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if do_DMD
        T0=0;
        
        setAnalogChannel(calctime(curtime,-1000),'DMD Power',2);
        setDigitalChannel(calctime(curtime,-10 +T0),'DMD Shutter',0);%0 on 1 off
        setDigitalChannel(calctime(curtime,-200+T0),'DMD TTL',0);
        setDigitalChannel(calctime(curtime,-100+T0),'DMD TTL',1);
        setDigitalChannel(calctime(curtime,-20+T0),'DMD AOM TTL',0);
        setDigitalChannel(calctime(curtime,-20+T0),'DMD PID holder',1);
        AnalogFuncTo(calctime(curtime,-30+T0),'DMD Power',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1, 1, 0);
        setDigitalChannel(calctime(curtime,T0),'DMD AOM TTL',1);%1 on 0 off
        setDigitalChannel(calctime(curtime,T0),'DMD PID holder',0);
        
%         AnalogFuncTo(calctime(curtime,T0+offset_time),'DMD Power',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);

        
        % First DMD Power ramp
        AnalogFuncTo(calctime(curtime,T0),'DMD Power',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dmd_times(1), dmd_times(1), dmd_pow(1));   
        T0= dmd_times(1);

        % Rest of ramps
        for jj=2:length(dmd_times)        
            AnalogFuncTo(calctime(curtime,T0),'DMD Power',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
                dmd_times(jj), dmd_times(jj), dmd_pow(jj));   
            T0=T0+dmd_times(jj);        
        end
        
        % Turn DMD off and reset it's power to high for thermalization
        setDigitalChannel(calctime(curtime,T0),'DMD AOM TTL',0);
        setDigitalChannel(calctime(curtime,T0+10),'DMD Shutter',1);
        setDigitalChannel(calctime(curtime,T0+20),'DMD AOM TTL',1);
        setAnalogChannel(calctime(curtime,T0+20),'DMD Power',2);

    end

    curtime=calctime(curtime,T_load_tot);   
end

%% Ramp up lattice
%Ramp up the lattices     

if oldLoad

    dispLineStr('Ramping up lattices.',curtime);
    disp(['     Ramp Times    (ms) : ' mat2str(lat_rampup_time) ]);
    disp(['     xLattice     (ErK) : ' mat2str(lat_rampup_depth(1,:))]);
    disp(['     yLattice     (ErK) : ' mat2str(lat_rampup_depth(2,:))]);
    disp(['     zLattice     (ErK) : ' mat2str(lat_rampup_depth(3,:))]);

    seqdata.times.lattice_start_time = curtime;
    ScopeTriggerPulse(curtime,'Load lattices');
    
    % set lattice ALPS to zero in the beginning (in case they haven't been)
%     setAnalogChannel(calctime(curtime,-60),'xLattice',-0.1,1);
%     setAnalogChannel(calctime(curtime,-60),'yLattice',-0.1,1);
%     setAnalogChannel(calctime(curtime,-60),'zLattice',-0.1,1);
    
    % Send request powers to low 
    
    setAnalogChannel(calctime(curtime,-60),'xLattice',-25);%-25); % -22
    setAnalogChannel(calctime(curtime,-60),'yLattice',-25);%-25); % -19
    setAnalogChannel(calctime(curtime,-60),'zLattice',-19);%-19); %-19
    
    % Enable rf output on ALPS3 (fast rf-switch and enable integrator)
    setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off
    setDigitalChannel(calctime(curtime,-100),'Lattice Direct Control',0); % 0 : Int on; 1 : int hold    
  
    % 1st lattice rampup segment
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(1,1));
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(2,1));
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(3,1));

    %Ramp up feshbach field after 1st lattice ramp. 
    %RHYS - Can ramp the FB field up high here during lattice loading to
    %try to make a Mott-insulator or some such.
    if (ramp_fields_after_lattice_loading==1) % if a coil value is not set, this coil will not be changed from its current value
        % shim settings for spectroscopy
        clear('ramp');
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero
        
        %Give ramp shim values if we want to do spectroscopy using the
        %shims instead of FB coil. If nothing set here, then
        %ramp_bias_fields just takes the getChannelValue (which is set to
%         %field zeroing values)
        ramp.xshim_final = getChannelValue(seqdata,27,1,0);
        ramp.yshim_final = getChannelValue(seqdata,19,1,0);%1.61;
        ramp.zshim_final = getChannelValue(seqdata,28,1,0);
        
        % FB coil settings for spectroscopy
        fesh_field_list = [20]; 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = getScanParameter(fesh_field_list,seqdata.scancycle,seqdata.randcyclelist,'Field_Value');%125;%before 2017-1-6 2*22.6; %1.08962 converts field in G to desired Adwin setpoint
        ramp.settling_time = 100;
    
 curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
%        ScopeTriggerPulse(curtime,'b_ramp_for_calibration');
    
    end
    
    %RHYS - This could be better handled using 'case' for the six cases.
    %turn off ODTs if demanded
    if (dipole_trap_off_after_lattice_on == 1) % '__' = 1: snap off after 1st lattice ramp;
        disp(' Snapping off XDTs after first lattice ramp.');
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0,1);
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    end
    
    if (dipole_trap_off_after_lattice_on == 2) % '__' = 2: ramp off after 1st lattice ramp;
       xdt_end_power = 0;
       xdt_ramp_time1 = 50;
       AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), xdt_ramp_time1,xdt_ramp_time1,xdt_end_power);
       AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), xdt_ramp_time1,xdt_ramp_time1,seqdata.params. XDT_area_ratio*xdt_end_power);
curtime = setDigitalChannel(calctime(curtime,xdt_ramp_time1),'XDT TTL',1);
    end    

    
    %RHYS - The actual lattice ramps.
    % further lattice rampup segments
    if length(lat_rampup_time) > 1
        for j = 2:length(lat_rampup_time) 
            for k = 1:length(lattices)         
                if lat_rampup_depth(k,j) ~= lat_rampup_depth(k,j-1) % only do a minjerk ramp if there is a change in depth
                    AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(j), lat_rampup_time(j), lat_rampup_depth(k,j));
                end
            end
curtime =   calctime(curtime,lat_rampup_time(j));
        end
    end  
    
    if (dipole_trap_off_after_lattice_on == 3)  %'__' = 3:dipole trap snap off after all initial lattice ramps
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0,1);
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);  
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    end
    
    
    if (dipole_trap_off_after_lattice_on == 4)  %'__' = 4:dipole trap ramp off after all initial lattice ramps
       xdt_end_power = 0;
       xdt_ramp_time1 = 50;
       AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), xdt_ramp_time1,xdt_ramp_time1,xdt_end_power,1);
       AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), xdt_ramp_time1,xdt_ramp_time1,seqdata.params. XDT_area_ratio*xdt_end_power,1);
curtime = setDigitalChannel(calctime(curtime,xdt_ramp_time1),'XDT TTL',1);
    end
    
    if (dipole_trap_off_after_lattice_on == 5)  %'__' = 5:dipole trap evaporation after initial lattice ramps
       evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    
       exp_evap_time = 10000; 
       exp_evap_total_time = 15000;
       exp_tau = exp_evap_total_time/7; %exp_evap_time/7
       xdt_end_power = 0.32;
       % exponential evaporation ramps (ramping down XDT beams)
       AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_total_time,exp_tau,xdt_end_power);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_total_time,exp_tau,seqdata.params.XDT_area_ratio*xdt_end_power);
       setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    end
    
    ScopeTriggerPulse(calctime(curtime,-100),'lattice ramp');

    %Ramp the feshbach field back down after atoms are pinned. 
    if (ramp_fields_after_lattice_loading==1)
        clear('ramp');

        % Ramp FB back to 20G in case it was ramped up for lattice loading.
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20.98111;%before 2017-1-6 100*1.08962; %22.6
        ramp.settling_time = 200;  

curtime = ramp_bias_fields(calctime(curtime,0), ramp); 
    end

end
%% Get rid of Rb by doing repump and probe pulse
    %Only do this if evaporation has happened
%RHYS - If attempting to evaporate in lattice with Rb as well. Never been useful, could delete.    

% CORA - Can we delete this? (Should Rb be blown away at the end of dipole
% transfer?)

if (get_rid_of_Rb_in_lattice && seqdata.flags. CDT_evap == 1)
    dispLineStr('Removing Rb in lattice.',curtime);

        %repump atoms from F=1 to F=2, and blow away these F=2 atoms with
        %the probe
        %open shutter
            %probe
            setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
            %repump
            setDigitalChannel(calctime(curtime,-10),5,1);
        %open analog
            %probe
            setAnalogChannel(calctime(curtime,-10),36,0.7);
            %repump (keep off since no TTL)
            
        %set TTL
            %probe
            setDigitalChannel(calctime(curtime,-10),24,1);
            %repump doesn't have one
            
        %set detuning (Make sure that the laser is not coming from OP
        %resonance... it will take ~75ms to reach the cycling transition)
        setAnalogChannel(calctime(curtime,-10),34,6590-237);

        %pulse beam with TTL 
            %TTL probe pulse
            DigitalPulse(calctime(curtime,0),24,5,0);
            %repump pulse
            setAnalogChannel(calctime(curtime,0),2,0.7);
curtime = setAnalogChannel(calctime(curtime,5),2,0.0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
curtime = setDigitalChannel(calctime(curtime,0),5,0);
        
curtime=calctime(curtime,50);
end


%% Ramp down HF used for loading lattice (this flag is in dipole transfer)

if seqdata.flags.ramp_up_FB_for_lattice
    
    seqdata.params.time_out_HF = curtime;
    if (((seqdata.params.time_out_HF - seqdata.params.time_in_HF)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
    end
    
     clear('ramp');

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 150;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;%before 2017-1-6 100*1.08962; %22.6
        ramp.settling_time = 100;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    
end

       
%% Do Physics Things in Lattice (holding, further ramps, modulation, physics ...)
% CORA - This code doesn't seem useful and/or redundant. Can we delete?

    %RHYS - Not sure why we would want to set it to 0. Could imagine
    %ramping it down if high, but that might happen later regardless.
    turn_off_feshbach = 0;

    if turn_off_feshbach      
        %Turn off Feshbach coil
        %set time
        curtime=calctime(curtime,-15);  % NECESSARY? RAMP ALREADY DONE ramptime-5 AHEAD

        %Set Feshbach field
        ramptime = 15;
        fesh_final = 0;

        AnalogFuncTo(calctime(curtime,-ramptime-5),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramptime,ramptime,fesh_final);
        if fesh_final == 0 %Turn off Feshbach coils with fast switch
            setDigitalChannel(calctime(curtime,-3),31,0);
        end
        seqdata.params. feshbach_val = fesh_final;
    end
    
    %Get rid of any leftover Rb atoms
    kill_Rb_in_lattice = 0;
    %RHYS - Kill leftover Rb if some was kept around for evaporating in a
    %lattice perhaps. Unlikely to find use. Delete.
    if kill_Rb_in_lattice
        
        kill_pulse_time = 5; %5
    
        %repump atoms from F=1 to F=2, and blow away these F=2 atoms with the probe
        %open shutter
            %probe
            setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
            %repump
            setDigitalChannel(calctime(curtime,-10),5,1);
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
            DigitalPulse(calctime(curtime,0),24,kill_pulse_time,0);
            %repump pulse
            setAnalogChannel(calctime(curtime,0),2,0.7); %0.7
curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),2,0.0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
curtime = setDigitalChannel(calctime(curtime,0),5,0);
        
curtime=calctime(curtime,2);
    end
    

    %Second set of lattice ramps
    lattice_ramp_II = 0;
    %RHYS - Is this useful for ramping lattices after FB/DMD manipulations?
    %Not sure. Either delete, or at least move the flag up to the top so
    %someone knows this is a possibility.
    if lattice_ramp_II
        %Define ramp parameters
        xLatDepth = 15; %380
        yLatDepth = 15; %500
        zLatDepth = lat_rampup_depth(3); %270
        
        lat_rampupII_depth = [xLatDepth; yLatDepth; zLatDepth];  %[100 650 650;100 650 650;100 900 900]
        lat_rampupII_time = [200];

        if (length(lat_rampupII_time) ~= size(lat_rampupII_depth,2)) || ...
                (size(lat_rampupII_depth,1)~=length(lattices))
            error('Invalid ramp specification for lattice loading!');
        end
        
        %lattice rampup segments
        for j = 1:length(lat_rampupII_time)
            for k = 1:length(lattices)
                if j==1
                    if lat_rampupII_depth(k,j) ~= lat_rampup_depth(k,end) % only do a minjerk ramp if there is a change in depth
                        AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampupII_time(j), lat_rampupII_time(j), lat_rampupII_depth(k,j));
                    end
                else
                    if lat_rampupII_depth(k,j) ~= lat_rampupII_depth(k,j-1) % only do a minjerk ramp if there is a change in depth
                        AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampupII_time(j), lat_rampupII_time(j), lat_rampupII_depth(k,j));
                    end
                end
            end
curtime = calctime(curtime,lat_rampupII_time(j));
        end
    end

%% Make a -9/2,-7/2 spin mixture.
% RHYS - Should do what it promises. Usually the mixture already exists, so
% this option could be stripped out of here.

if spin_mixture_in_lattice_before_plane_selection
    dispLineStr('RF sweeps to make K spin mixture');
    
    %Ramp FB Field
    clear('ramp');
    
    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 20.98111;%before 2017-1-6 1*22.6; %22.6
    ramp.settling_time = 100;
    
 curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    %Do RF Sweep
    clear('sweep');
%         sweep_pars.freq = 6.07; %MHz
%         sweep_pars.power = -2;   %-9
%         sweep_pars.delta_freq = +0.05; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 0.6; % also is sweep length  0.5

    sweep_pars.freq = 6.28; %6.07 MHz
    sweep_pars.power = -1;   %-7.7
    sweep_pars.delta_freq = 0.02; % end_frequency - start_frequency   0.01
    sweep_pars.pulse_length = 0.2; % also is sweep length  0.5

        
        addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
% 
        %Multiple sweeps to drive the mixture towards 50/50
curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);

curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);

        curtime = calctime(curtime,50);

end

%% Dimple before plane selecting
%RHYS - Code for turning on the dimple (850nm beam). Never really worked
%for making things colder. Could keep the option.

if (Dimple_Trap_Before_Plane_Selection)      
    
    Dimple_Power_List = [2.0];
    Dimple_Power = getScanParameter(Dimple_Power_List,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Power');%maximum is 4
    Dimple_Ramp_Time_list = [50]; %50
    Dimple_Ramp_Time = getScanParameter(Dimple_Ramp_Time_list,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Ramp_Time')*1;
    Dimple_Wait_Time_List = [50];%[50];
    Dimple_Wait_Time = getScanParameter(Dimple_Wait_Time_List,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Wait_Time')*1;
    
    setDigitalChannel(calctime(curtime,-10),'Dimple Shutter',1);
    setDigitalChannel(calctime(curtime,0),'Dimple TTL',0);%0
curtime = AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, Dimple_Power); 
    
% %     Next, go to 1D z-lattice, with 2 steps
% %     1st step, goes to 2 Er
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 2/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 2/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 10/atomscale);    
% % %     2nd step, goes to 0 Er    
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale);
%   
curtime = calctime(curtime, Dimple_Wait_Time);

end

%% conductivity modulation without dimple
%RHYS - This is the code for the conductivity experiment. Should probably
%keep for now, just clean up. A very long code: make its own module, delete
%all the commented crap.

if (conductivity_without_dimple == 1 )
    time_in_cond = curtime;
    Post_Mod_Lat_Ramp = 0;
    Lattices_to_Pin = 1;
    ramp_up_FB_after_evap = 0;
    ramp_up_FB_during_mod_ramp = 0;
    ramp_up_FB_after_latt_loading = 0;
    do_RF_spectroscopy_in_lattice = 0;         %do spectroscopy with DDS after lattice loading
    DMD_on = 1;
    enable_modulation = 0;
    kick_lattice = 0;
    
    adiabatic_ramp_down = 0;
%     compensation_in_modulation = 0;   
    

% ramp FB field up to conductivity modulation
    if ramp_up_FB_after_evap
        clear('ramp');      
        ramp.xshim_final_list = 0.1585; %0.1585;
        ramp.xshim_final = getScanParameter(ramp.xshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'xshim');
        ramp.yshim_final_list = -0.0432;  %-0.0432;
        ramp.yshim_final = getScanParameter(ramp.yshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'yshim');
        ramp.zshim_final_list = -0.1354;-0.0865;  %-0.0865;
        ramp.zshim_final = getScanParameter(ramp.zshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'zshim');     
        
        shiftfb_list = [200];%[0,20,60,100,140,180,200];
        shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        

        FB_Ramp_Time_List = [250];
        FB_Ramp_Time = getScanParameter(FB_Ramp_Time_List,seqdata.scancycle,seqdata.randcyclelist,'FB_Ramp_Time');
        ramp.fesh_ramptime = FB_Ramp_Time; %150
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = shiftfb-0.06;                
        ramp.settling_time = 50;
        ramp.QP_ramptime = FB_Ramp_Time;
        ramp.QP_ramp_delay = -0;
        QP_final_val_list = [0.15];
        ramp.QP_final =  getScanParameter(QP_final_val_list,seqdata.scancycle,seqdata.randcyclelist,'QP_final_val'); 
%         ramp.settling_time = 0; %200    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
%         clear('rampdown');
%         rampdown.QP_ramptime = 50;
%         rampdown.QP_ramp_delay = -0;
%         rampdown.QP_final = 0;      
%         rampdown.settling_time = 0;
% curtime = ramp_bias_fields(calctime(curtime,-100), rampdown);


% % 
% %         conductivityfb_list = [200];
% %         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
% %         clear('ramp');
% %         ramp.xshim_final = 0.1585;
% %         ramp.yshim_final = -0.0432;
% %         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
% %         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
% %         ramp.fesh_ramptime = 0.2;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = conductivityfb-0.06;
% %         ramp.settling_time = 10;
% % curtime = ramp_bias_fields(calctime(curtime,0), ramp);

%=============================================== rf transfer
%        curtime=calctime(curtime,100);
      
%        Do RF Pulse
%        clear('pulse')
%        rf_list =  [41.003:0.006:41.03]; 
%        pulse_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%        rf_power_list = [-7];
%        pulse_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  
%        rf_pulse_length_list = [0.06];
%        pulse_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');
        
% %        Do RF Sweep
%        clear('sweep');
%        rf_list = [41.015];
%        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%        rf_power_list = [0];
%        sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%        delta_freq = 0.03;
%        sweep_pars.delta_freq = delta_freq;  -0.2; % end_frequency - start_frequency   0.01
%        rf_pulse_length_list = [15];
%        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
%        addOutputParam('RF_Pulse_Length',sweep_pars.freq);        
% % %        
%        acync_time_start = curtime;
% ScopeTriggerPulse(curtime,'rf_pulse_test');
%     
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),4,pulse_pars);%3: sweeps, 4: pulse
% total_pulse_length = 50;
% 
%             do_ACync_plane_selection = 1;
%             if do_ACync_plane_selection
%                 ACync_start_time = calctime(acync_time_start,-80);
%                 ACync_end_time = calctime(curtime,total_pulse_length+40);
%                 setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
%                 setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
%             end

%==========================================================================
    end

    %prepare xdt and lattice    
    xdtdepth_list = [0.20];%0.05
    xdtdepth = getScanParameter(xdtdepth_list,seqdata.scancycle,seqdata.randcyclelist,'xdtdepth');%maximum is 4
%   XDT2_Power = (((sqrt(XDT1_Power)*83.07717-0.8481)+3.54799)/159.3128)^2
    XDT1_Power = xdtdepth;
    XDT2_Power = (sqrt(81966+1136.6*(21.6611-(-119.75576*XDT1_Power^2+159.16306*XDT1_Power+13.0019)))-286.29766)/2/(-284.1555);%(((sqrt(XDT1_Power)*83.07717-0.8481)+3.54799)/159.3128)^2;%
    addOutputParam('xdt1power',XDT1_Power);
    addOutputParam('xdt2power',XDT2_Power);
    
    latdepth_list = 20; 
    latdepthx = getScanParameter(latdepth_list,seqdata.scancycle,seqdata.randcyclelist,'latdepx');%maximum is 4 
%     Comp_Ramptime = 50;
%     Comp_Power = 0;%unit is mW
    lat_ramp_time_list = 150;%150 sept28
    lat_ramp_time = getScanParameter(lat_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_ramp_time');
    xdt_ramp_time = lat_ramp_time;
    lat_ramp_tau = lat_ramp_time/3;40; %40 sept28 20 sep29        addOutputParam('lat_ramp_tau',lat_ramp_tau);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     X_Lattice_Depth =0;20; 20;10.76;10.76;2.5;0.5;          1.04; 2.5;0.3;%2.50;0
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     Y_Lattice_Depth =0;20; 20;0.23;0.23;2.77;11.1;      1.0;  2.77;10.16;%2.77;10.16
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     Z_Lattice_Depth =0;20; 20;11.57;11.57;2.44;2.45;9.6;       0.95; 2.44;9.49;%2.44;9.49
    X_Lattice_Depth = 2;-2.7;2.6; %2.5Er: 2.6; 15Er_15.7;  no ramp at the moment
    Y_Lattice_Depth = 2;2.32; %1Er_0.82;2.5Er_2.32;15Er_14.35;
    Z_Lattice_Depth = 2;2.2; %1Er_0.87;2.5Er_2.2;15Er_13.4;
%     X_Lattice_Depth2 = 0;60; %2.5Er: 3.15; 15Er_15.7;
%     Y_Lattice_Depth2 = 0;60;%1Er_0.82;2.5Er_2.3;15Er_14.35;
%     Z_Lattice_Depth2 = 0;60; %1Er_0.87;2.5Er_2.2;15Er_13.4;
%     lat_ramp_time2 = 0.5;
    %2.5Er: 2.50 2.77 2.44
    %3Er: 3.175 3.3 2.9
    %3.5Er: 3.7 3.85 3.4
    %4Er: 4.25 4.38 3.9
% % % % % % %     X_Lattice_Depth = 0;2.65;%2.65;%1.04;%2.65;%2.07;%3.63;%4.13;%3.09;   %2.65;    %2.07 2.16 1.88
% % % % % % %     Y_Lattice_Depth =0; 2.6;%2.6;%1.0;%2.6;%2.16;%3.66;%4.14;%3.08;  %2.6;     %
% % % % % % %     Z_Lattice_Depth =0; 2.38;%2.38;%0.95;%2.38;%1.88;%3.33;%3.79;%2.82;  %2.38;    %
    
%       setDigitalChannel(calctime(curtime,-50),34,1);% turn lattice TTL ON; 0: ON; 1: OFF
if (kick_lattice == 1)
    temp_kick_latdepth_list = [5.5];
    temp_kick_latdepth = getScanParameter(temp_kick_latdepth_list,seqdata.scancycle,seqdata.randcyclelist,'temp_kick_latdepth');
    temp_kick_latdepth=temp_kick_latdepth;
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,temp_kick_latdepth); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1,0.1,temp_kick_latdepth)
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,temp_kick_latdepth);
curtime=calctime(curtime,1);    
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,0); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1,0.1,0)
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,0);
curtime=calctime(curtime,100);    
end

    AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, XDT1_Power);
curtime =  AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, XDT2_Power);
curtime=calctime(curtime,5);    
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,Z_Lattice_Depth2/atomscale);
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,X_Lattice_Depth2/atomscale);
% curtime=    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,Y_Lattice_Depth2/atomscale);

if ramp_up_FB_after_latt_loading
        clear('ramp');
        
        clear('ramp');
        ramp.fesh_ramptime = 100;%50 %THIS LONG?
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 150;                
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
% holdtime = 1000;
% curtime = calctime(curtime,holdtime);

%         conductivityfb_list = [205];
%         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
%         clear('ramp');
%         ramp.xshim_final = 0.1585;
%         ramp.yshim_final = -0.0432;
%         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
%         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
%         ramp.fesh_ramptime = 0.2;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = conductivityfb;
%         ramp.settling_time = 10;
% curtime = ramp_bias_fields(calctime(curtime,0), ramp);
curtime=calctime(curtime,300);    
    end

    

    Comp_Ramptime = 50;
    Comp_Power = 15;%unit is mW
    if seqdata.flags.compensation_in_modulation == 1
       %AOM direct control off
       setDigitalChannel(calctime(curtime,-50),'Compensation Direct',0); %0: off, 1: on
       %turn off compensation AOM initailly
       setDigitalChannel(calctime(curtime,-20),'Plug TTL',1); %0: on, 1: off
       %set compensation AOM power to 0
       setAnalogChannel(calctime(curtime,-10),'Compensation Power',-1);
       %turn On compensation Shutter
       setDigitalChannel(calctime(curtime,-5),'Compensation Shutter',0); %0: on, 1: off
       %turn on compensation AOM
       setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off       
       %ramp up compensation beam
curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, Comp_Power);
    end  %compensation_in_modulation == 1
    
    
%         setDigitalChannel(curtime,'XDT TTL',1);%0: ON; 1: OFF
% curtime=calctime(curtime,100);
% ramp compensate beam power
% curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),Comp_Ramptime,Comp_Ramptime,Comp_Power);
%%curtime=calctime(curtime,1000);    
%%curtime = calctime(curtime, max(xdt_ramp_time,lat_ramp_time+20));

% %Apply force in the rotating frame.
%     if enable_modulation
%         %Parameters for rotation-induced effective B field.
%         rot_freq_list = [1];
%         rot_freq = getScanParameter(rot_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rot_freq');
%         rot_amp_list = [2];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         rot_amp = 1*getScanParameter(rot_amp_list,seqdata.scancycle,seqdata.randcyclelist,'rot_amp');
%         rot_offset_list = [0];
%         rot_offset = getScanParameter(rot_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rot_offset');
%         rot_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         %These amplitudes and angles probably need to be tweaked!
%         rot_dev_chn1 = rot_amp;
%         rot_dev_chn2 = rot_amp*16.95/13.942;
%         rot_offset1 = rot_offset;
%         rot_offset2 = rot_offset*16.95/13.942;
%         rot_phase1 = 0;
%         rot_phase2 = 90;
%         
%         %Parameters for linearly-polarized conductivity modulation. This
%         %needs to rotate in time.
%         freq_list = [30];
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [0:200/mod_freq:2000/rot_freq];%[0:160/mod_freq:2000/mod_freq];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [1]; %Should probably be less than rot_amp.
%         mod_amp = 1*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         offset_list = [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         
%         mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_dev_chn1*16.95/13.942;%modulate along x_lat direction,when mod_angle=30
% %         mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;% %modulate along y_lat directio
%         mod_offset1 = mod_offset;
%         mod_offset2 = mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;%modulate along x_lat direction
% %       mod_offset2 =-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%modulate along y_lat direction
% 
%         mod_phase1 = 0;
%         mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
% 
%   
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn1,rot_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',rot_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn2,rot_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',rot_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);
% %         %-------------------------set Rigol DG1022 ---------
% %         str211=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
% %         str212=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
% %         str221=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
% %         str222=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
% %         str231=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
% %         str3=[str212,str211,str221,str222,str231];
% %         addVISACommand(3, str3);
%         
%         %-------------------------end:set Rigol-------------       
%         
%         %ramp the modulation amplitude
%         mod_ramp_time_list = [150];%150 sept28
%         mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         mod_wait_time = 50;
%         offset = 5; %XDT piezo offset
%                 
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity_modulation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
%         
%         %Need to use Adwin to generate linear modulation.
%         %Need to use Adwin to generate linear modulation.
%         XDT1_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * cos(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))) .* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         XDT2_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * sin(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))).* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         Drive_Time = mod_time+mod_ramp_time+mod_wait_time;
%         AnalogFunc(calctime(curtime,0),'XDT1 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT1_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn1,rot_freq/1000,mod_dev_chn1,mod_freq/1000,0,1,mod_ramp_time,offset);
%         AnalogFunc(calctime(curtime,0),'XDT2 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT2_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn2,rot_freq/1000,mod_dev_chn2,mod_freq/1000,0,1,mod_ramp_time,offset);
% 
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
% 
% curtime = calctime(curtime,mod_wait_time);
% 
% curtime = calctime(curtime,mod_time);
%         setAnalogChannel(curtime,'XDT1 Piezo',5);
%         setAnalogChannel(curtime,'XDT2 Piezo',5);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT
%         post_mod_wait_time_list = [0];  
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
%     end

% Modified to work with two rigols, modulation and rotation. Modulation
% parts are mostly the same as previous.

    if (DMD_on == 1)   
        if enable_modulation == 1
            DMD_power_val_list = 1.3;[1:0.05:1.5]; %Do not exceed 1.5 here
            DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
            DMD_ramp_time = 10;
            setAnalogChannel(calctime(curtime,-1),'DMD Power',0.3);
            setDigitalChannel(calctime(curtime,-1-220),'DMD TTL',0);%1 off 0 on
            setDigitalChannel(calctime(curtime,-1-100),'DMD TTL',1); %pulse time does not matter
            setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1); %0 off 1 on
            AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
            %     setDigitalChannel(calctime(curtime,50+DMD_on_time),'DMD AOM TTL',1);
        else
            DMD_power_val_list = 3.5;[1:0.05:1.5]; %Do not exceed 1.5 here
            DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
            DMD_ramp_time = 100;
%             setAnalogChannel(calctime(curtime,-1),'DMD Power',0.3);
            setDigitalChannel(calctime(curtime,-1-220-100),'DMD TTL',0);%1 off 0 on
            setDigitalChannel(calctime(curtime,-1-100-100),'DMD TTL',1); %pulse time does not matter
            setDigitalChannel(calctime(curtime,0-100),'DMD AOM TTL',1); %0 off 1 on
            AnalogFuncTo(calctime(curtime,0-100),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%             setAnalogChannel(calctime(curtime,0-100),'DMD Power',DMD_power_val);
            DMD_on_time_list = [0]; %Do not exceed 1.5 here
            DMD_on_time = getScanParameter(DMD_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time');
            setAnalogChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD Power',-5);
             setDigitalChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD AOM TTL',0); %0 off 1 on
    %         setAnalogChannel(calctime(curtime,1),'DMD Power',-5);
        end
    end

if enable_modulation
%         %Parameters for rotation-induced effective B field.
%         rot_freq_list = [120];
%         rot_freq = getScanParameter(rot_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rot_freq');
%         rot_amp_list = [1];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         rot_amp = 1*getScanParameter(rot_amp_list,seqdata.scancycle,seqdata.randcyclelist,'rot_amp');
%         rot_offset_list = [0];
%         rot_offset = getScanParameter(rot_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rot_offset');
%         rot_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         %These amplitudes and angles probably need to be tweaked!
%         rot_dev_chn1 = rot_amp;
%         rot_dev_chn2 = rot_amp*16.95/13.942;
%         rot_offset1 = rot_offset;
%         rot_offset2 = rot_offset*16.95/13.942;
%         rot_phase1 = 0;
%         rot_phase2 = 90;
%         if DMD_on == 1
%             DMD_power_val_list = 1.3;[1:0.05:1.5]; %Do not exceed 1.5 here
%             DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
%             DMD_ramp_time = 10;
%             setAnalogChannel(calctime(curtime,59),'DMD Power',0.3);
%             setDigitalChannel(calctime(curtime,59-220),'DMD TTL',0);%1 off 0 on
%             setDigitalChannel(calctime(curtime,59-100),'DMD TTL',1); %pulse time does not matter
%             setDigitalChannel(calctime(curtime,60),'DMD AOM TTL',1); %0 off 1 on
%             AnalogFuncTo(calctime(curtime,60),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%             %     setDigitalChannel(calctime(curtime,50+DMD_on_time),'DMD AOM TTL',1);
%         end
        %Parameters for linearly-polarized conductivity modulation.
        freq_list = [0.01]; %was 120
        mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
        time_list = [100];[0:160/mod_freq:2000/mod_freq];
        mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
        addOutputParam('mod_time',mod_time);
        amp_list = [0]; %displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
        mod_amp = 1.0*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp1');
        offset_list = [0];
        mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
        mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
        mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_amp*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85;16.95/13.942;%modulate along x_lat direction,when mod_angle=30
        mod_dev_chn2 = mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*0.85;  16.95/13.942;% %modulate along y_lat directio
        mod_offset1 = 0;mod_offset;
        %mod_offset2 = mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85; 16.95;16.95/13.942;%modulate along x_lat direction
        mod_offset2 = 0;-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*0.85;16.95/13.942;%modulate along y_lat direction
        mod_phase1 = 0;
        mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction

        %Provides modulation.
        %-------------------------set Rigol DG4162 ---------
        str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
        str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
        str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
        str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
        str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
        str2=[str112,str111,str121,str122,str131];
        addVISACommand(4, str2);


%         %Could provide rotation if desired.
%         %-------------------------set Rigol DG1022 ---------
%         str211=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn1,rot_offset1);
%         str212=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',rot_phase1);
%         str221=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn2,rot_offset2);
%         str222=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',rot_phase2);
%         str231=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str3=[str212,str211,str221,str222,str231];
%         addVISACommand(3, str3);
        
        %-------------------------end:set Rigol-------------        
        %ramp the modulation amplitude
        mod_ramp_time_list = [150];%150 sept28
        mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
%         mod_ramp_time = mod_ramp_time/3*2;
        final_mod_amp = 1;
        addOutputParam('mod_amp',mod_amp*final_mod_amp);
        setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
curtime = calctime(curtime,10);
ScopeTriggerPulse(curtime,'conductivity_modulation');
        setDigitalChannel(curtime,'ScopeTrigger',1);
        setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',1);  %send trigger to Rigol for modulation
        %====================================
if ramp_up_FB_during_mod_ramp == 1
        clear('ramp');       
        ramp.xshim_final_list = 0.1585; %0.1585;
        ramp.xshim_final = getScanParameter(ramp.xshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'xshim');
        ramp.yshim_final_list = -0.0432;  %-0.0432;
        ramp.yshim_final = getScanParameter(ramp.yshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'yshim');
        ramp.zshim_final_list = -0.0865;  %-0.0865;
        ramp.zshim_final = getScanParameter(ramp.zshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'zshim');     
        
        shiftfb_list = 200;%[0,20,60,100,140,180,200];
        shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        

        ramp.fesh_ramptime = mod_ramp_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = shiftfb-0.06;                
        ramp.settling_time = 40;
        ramp_bias_fields(calctime(curtime,0), ramp);
end   
        %====================================

curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
        mod_wait_time =0;50;

        
        
DMD_start_time = curtime;
curtime = calctime(curtime,mod_wait_time);

curtime = calctime(curtime,mod_time);


        if (adiabatic_ramp_down == 1)%ramp down lattice and ramp down modulation to test the adibatic loading
            %ramp down the modulation
curtime = calctime(curtime,mod_wait_time);
curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, 0); 
            %ramp down the lattice
            
curtime = calctime(curtime,3000-2*lat_ramp_time);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, 0.15);
curtime =  AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, 0.062);

    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);      
    AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);

curtime = calctime(curtime,100);
        end

        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
        setAnalogChannel(curtime,'Modulation Ramp',0);
%         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT

% if (DMD_on_during_modulation==1)
%     DMD_end_time = curtime;
%     setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
%     DMD_shine_time = (DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit)
%     
%     if (((DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit))>1000)
%         error('DMD MAY BE ON FOR TOO LONG')
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        post_mod_wait_time_list = 50;[0:5:60];
        post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        addOutputParam('post_mod_wait_time',post_mod_wait_time);
curtime = calctime(curtime,post_mod_wait_time);
    
end


%%turn off DMD
if (DMD_on == 1)
    if (enable_modulation == 0)
        DMD_start_time = curtime;
curtime = calctime(curtime,DMD_on_time+DMD_ramp_time-20);
    end
    if enable_modulation == 1
        setAnalogChannel(calctime(curtime,0),'DMD Power',-10);
        setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
    end
%     setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
    DMD_end_time = curtime;
    DMD_shine_time = DMD_ramp_time + (DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit)
    
    if (((DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit))>1000)
        error('DMD MAY BE ON FOR TOO LONG')
    end
end



    if Post_Mod_Lat_Ramp
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
curtime=AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);    
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);
curtime=AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);    
curtime = calctime(curtime,1);
    end

% % 	ramp up pin lattice
    if Lattices_to_Pin
        setDigitalChannel(calctime(curtime,-0.5),'yLatticeOFF',0);%0: ON
        AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60); 
        AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60)
curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60);
%     ramp down xdt
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
    end  
    
    
   % ramp up pin lattice with expansion
%     if Lattices_to_Pin
%         setDigitalChannel(calctime(curtime,-0.5),'Z Lattice TTL',0);%0: ON
%         AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 00/atomscale); 
%         AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 30/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 00/atomscale);
%         Expansion_hold_time_list = [50];
%         Expansion_hold_time = getScanParameter(Expansion_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'Expansion_hold_time');
% curtime=calctime(curtime,Expansion_hold_time);
%         AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale); 
%         AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale);
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
%     end  
    
    %turn off compensate beam
    if seqdata.flags.compensation_in_modulation == 1
       Comp_Ramptime = 50;
       %ramp down compensation beam
       AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, 0);

       %turn off compensation AOM
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Plug TTL',1); %0: on, 1: off
       %set compensation AOM power to 0
       setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',-5);
       %turn off compensation Shutter
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Shutter',1); %0: on, 1: off
       %turn on compensation AOM
       setDigitalChannel(calctime(curtime,Comp_Ramptime+2000),'Plug TTL',0); %0: on, 1: off 
       %set compensation AOM power to max for thermalization
       setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',9.9,1);
       %AOM direct control on
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Direct',1); %0: off, 1: on
    end  %compensation_in_modulation == 1   
    
         %====================================
% if ramp_up_FB_during_mod_ramp == 1
%         clear('ramp');       
%         ramp.xshim_final = 0.1585; %0.1585;
%         ramp.yshim_final = -0.0432;  %-0.0432;
%         ramp.zshim_final = -0.0865;  %-0.0865;
%         
%         shiftfb_list = 5;%[0,20,60,100,140,180,200];
%         shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        
% 
%         ramp.fesh_ramptime = mod_ramp_time;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = shiftfb-0.06;                
%         ramp.settling_time = 200;
%         ramp_bias_fields(calctime(curtime,0), ramp);
%         
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, 0);         
%         
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);      
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% 
%         
%         
% end   
        %====================================
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);      
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);

%     ramp down 
    if ((ramp_up_FB_after_evap == 1 || ramp_up_FB_after_latt_loading ==1 ||ramp_up_FB_during_mod_ramp == 1 ) && (do_plane_selection == 0))
curtime = calctime(curtime,20);
     % Turn the FB up to 20G before loading the lattice, so that large field
        % ramps in the lattice can be done more quickly
%         clear('ramp');
%         % FB coil settings for spectroscopy
%         ramp.xshim_final = 0.1585;
%         ramp.yshim_final = -0.0432; 
%         ramp.zshim_final = -0.0865;
%         
%         ramp.fesh_ramptime = 0.1;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 180;%before 2017-1-6 0.25*22.6; %22.6
%         ramp.settling_time = 10;
%         addOutputParam('FB_Scale',ramp.fesh_final)
%      curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        clear('ramp');
            % FB coil settings for spectroscopy
            ramp.xshim_final = 0.1585;
            ramp.yshim_final = -0.0432; 
            ramp.zshim_final = -0.0865;
            ramp.QP_final = 0;
            ramp.fesh_ramptime = 50;%100
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 20;%before 2017-1-6 0.25*22.6; %22.6
            ramp.settling_time = 10;
            addOutputParam('FB_Scale',ramp.fesh_final)
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
     holdtime = 500;
curtime = calctime(curtime,holdtime);  
    end
    
    time_out_cond = curtime;
    if (((time_out_cond - time_in_cond)*(seqdata.deltat/seqdata.timeunit))>3000)
        error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
    end
    
end

%% Do Plane Selection
%RHYS - Graham started to condense some of the plane selection code here.
%Not sure if it works. Probably a good starting point for making a
%more-organized plane-selection module.

if fast_plane_selection
    
    plane_select_params.Fake_Pulse = 0;
    plane_select_params.Selection__Frequency = 1388.375;
    plane_select_params.Selection_Range = 400/1000;
    plane_select_params.Resonant_Light_Removal = 1;
    plane_select_params.Final_Transfer = 1;
    
    addOutputParam('freq_val',plane_select_params.Selection__Frequency)
    
curtime = do_fast_plane_selection(curtime, plane_select_params);
    
end


%% Optically pump atoms
% flag is "do_optical_pumping"
%RHYS - This code works and is useful.

if ( do_optical_pumping == 1)
    
    doPinForOP = 0; 
    if doPinForOP 
        %ramp up lattice beams for optical pumping
        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60); 
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60);
        curtime= AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60);
        curtime = calctime(curtime,10);%10 ms for the system to be stablized
    end
    
    % OP pulse length
    op_time_list = [3];%3
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'latt_op_time','ms');
    % OP repump power
    repump_power_list = [0.5];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'latt_op_repump_pwr');     
    % OP power
    D1op_pwr_list = [5]; %min: 0, max:10 %5
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'latt_D1op_pwr'); 
    
    % Determine the requested frequency offset from zero-field resonance
    frequency_shift = (4)*2.4889;(4)*2.4889;
    Selection_Angle = 62.0;
    addOutputParam('Selection_Angle',Selection_Angle)

    %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
    Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to

    %Determine how much to turn on the X and Y shims to get this frequency
    %shift at the requested angle
    X_Shim_Value = frequency_shift * cosd(Selection_Angle) / Shim_Calibration_Values(1);
    Y_Shim_Value = frequency_shift * sind(Selection_Angle) / Shim_Calibration_Values(2);
    X_Shim_Offset = 0;
    Y_Shim_Offset = 0;
    Z_Shim_Offset = 0.055;0.055;

    %Ramp the magnetic fields so that we are spin-polarized.
    newramp = struct('ShimValues',seqdata.params.shim_zero + [X_Shim_Value+X_Shim_Offset, Y_Shim_Value+Y_Shim_Offset, Z_Shim_Offset],...
            'FeshValue',0.01,'QPValue',0,'SettlingTime',100);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);   

    % Close EIT Probe Shutter
    setDigitalChannel(calctime(curtime,-20),'EIT Shutter',0);
    
    % Break the thermal stabilzation of AOMs by turning them off
    setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);
    setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
    setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);    
    setAnalogChannel(calctime(curtime,-10),'D1 AM',D1op_pwr); 

    
    % Open D1 shutter (FPUMP + OPT PUMP)
    setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1);%1: turn on laser; 0: turn off laser
        
    % Open optical pumping AOMS (allow light) and regulate F-pump
    setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
    setAnalogChannel(calctime(curtime,0),'F Pump',repump_power);
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);   %1:on 
    
    %Optical pumping time
curtime = calctime(curtime,optical_pump_time);
    
    % Turn off OP before F-pump so atoms repumped back to -9/2.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);

    op_repump_extra_time = 2; %additional time for which repump beams are on
    % Close optical pumping AOMS (no light)
    setDigitalChannel(calctime(curtime,op_repump_extra_time),'F Pump TTL',1);%1
    setAnalogChannel(calctime(curtime,op_repump_extra_time),'F Pump',-1);%1
    setDigitalChannel(calctime(curtime,op_repump_extra_time),'FPump Direct',1);
    
    % Close D1 shutter shutter
    setDigitalChannel(calctime(curtime,5),'D1 Shutter', 0);%2
    
    %After optical pumping, turn on all AOMs for thermal stabilzation
    
    setDigitalChannel(calctime(curtime,10),'D1 TTL',1);
    setDigitalChannel(calctime(curtime,10),'F Pump TTL',0);
%     setAnalogChannel(calctime(curtime,10),'D1 AM',10); 

curtime =  setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);    


% ramp the field back to vertical FB
clear('ramp');

        % Ramp the bias fields
newramp = struct('ShimValues',seqdata.params.shim_zero,...
            'FeshValue',10,'QPValue',0,'SettlingTime',100);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);   
    

curtime = calctime(curtime,50);

%     op_time_list = [10];[20];
%     optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle, seqdata.randcyclelist, 'op_time'); %optical pumping pulse length
%     repump_power = 1.5;1.0;
%     D1op_pwr = 10; %min: 0, max:10 
%     
%     %Determine the requested frequency offset from zero-field resonance
%     frequency_shift = (4)*2.4889;(4)*2.4889;
%     Selection_Angle = 62.0;
%     addOutputParam('Selection_Angle',Selection_Angle)
% 
%     %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
%     Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to
% 
%     %Determine how much to turn on the X and Y shims to get this frequency
%     %shift at the requested angle
%     X_Shim_Value = frequency_shift * cosd(Selection_Angle) / Shim_Calibration_Values(1);
%     Y_Shim_Value = frequency_shift * sind(Selection_Angle) / Shim_Calibration_Values(2);
%     X_Shim_Offset = 0;
%     Y_Shim_Offset = 0;
%     Z_Shim_Offset = 0.055;0.055;
% 
%     %Ramp the magnetic fields so that we are spin-polarized.
%     newramp = struct('ShimValues',seqdata.params.shim_zero + [X_Shim_Value+X_Shim_Offset, Y_Shim_Value+Y_Shim_Offset, Z_Shim_Offset],...
%             'FeshValue',0.01,'QPValue',0,'SettlingTime',100);
% 
% %RHYS - rampMagneticFields used here. This module was designed to replace
% %ramp_bias_fields, as it has a more friendly structural syntax.
% curtime = rampMagneticFields(calctime(curtime,0), newramp);
%     
% 
% 
% 
%     setDigitalChannel(calctime(curtime,-10),'EIT Shutter',0);
%     %Break the thermal stabilzation of AOMs by turning them off
%     setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);
%     setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
%     setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);
%     setAnalogChannel(calctime(curtime,-10),'D1 AM',D1op_pwr); 
% 
%     
% 
%     %Open shutter
%     setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1);%1: turn on laser; 0: turn off laser
%     
%     
%     %Open optical pumping AOMS and regulate F-pump
%     setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
%     setAnalogChannel(calctime(curtime,0),'F Pump',repump_power);
%     setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
%     setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1); %0:off 1:on
%     
%     %Optical pumping time
% curtime = calctime(curtime,optical_pump_time);
%     
%     %Turn off OP before F-pump so atoms repumped back to -9/2.
%     setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);
% 
%     %Close optical pumping AOMS
%     setDigitalChannel(calctime(curtime,5),'F Pump TTL',1);%1
%     setAnalogChannel(calctime(curtime,5),'F Pump',-1);%1
%     setDigitalChannel(calctime(curtime,5),'FPump Direct',1);
%     %Close shutter
%     setDigitalChannel(calctime(curtime,5),'D1 Shutter', 0);%2
%     
%     %After optical pumping, turn on all AOMs for thermal stabilzation
%     
%     setDigitalChannel(calctime(curtime,10),'D1 TTL',1);
%     setDigitalChannel(calctime(curtime,10),'F Pump TTL',0);
%     setAnalogChannel(calctime(curtime,10),'D1 AM',10); 
% 
% curtime =  setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);    
    
end

%% Remove |9/2,-9/2> atoms from the lattice prior to selecting a plane.
%RHYS - An attempt to remove only |9/2,-9/2> atoms while keeping |9/2,-7/2>
%so that plane selection could work. Always removed more atoms than
%expected. Later, optical pumping was just done instead. This code might be
%okay to keep for now, since there were open questions about this. It is
%also very similar to plane selection code, so could perhaps be an option
%for a more general selection code.

if remove_one_spin_state
    
    %Set magnetic field and field gradient strengths.
    ramp_fields = 1;
    FB_init = getChannelValue(seqdata,37,1,0);
    if ramp_fields
        clear('ramp');

        ramp.xshim_final = seqdata.params. shim_zero(1);
        ramp.yshim_final = seqdata.params. shim_zero(2);
        ramp.zshim_final = seqdata.params. shim_zero(3);
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = -0;
        
        fb_list = 138.625;125.6544;    %before 2017-1-6 [6.6135]*22.6;125.6544;
        fb_val = getScanParameter(fb_list,seqdata.scancycle,seqdata.randcyclelist,'fb_val');  
        ramp.fesh_final = fb_val;
        fb_gauss_val = fb_val; %before 2017-1-6 (fb_val*0.0333-0.001)* 27.86561+0.03939;
        
%         ramp.fesh_final = 5.9925*22.6; %5.9925*22.6; %22.6     %6.6135 ~138.694G
        %b_field = 0.3643  + 20.9163 * reference_voltage
        %default value of ramp.fesh_final is 6*22.6, for plane
        addOutputParam('PSelect_FB',ramp.fesh_final)

        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 100;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  0*1.78;         %7

        ramp.settling_time = 200; %200
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
       
    %Parameters for the transfer of atoms in the one spin state. 
    
    %Extra Parameters for the plane selecting pulse
    spect_pars.fake_pulse = 0;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
    spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
    spect_pars.SRS_select = 1; %0: Use SRS A, 1: Use SRS B
    
    %-(BreitRabiK(B,9/2,9/2) - BreitRabiK(B,9/2,7/2))/6.6260755e-34
    ff_val =abs( -(BreitRabiK(fb_gauss_val,9/2,-7/2) - BreitRabiK(fb_gauss_val,7/2,-7/2))/6.6260755e-34 )/1000000;
    freq_list = [ff_val];
%      freq_list = 1606.68-[25 75]/1000;
%     %unit is kHz. Have to tunning the frequency everyday.
    %freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
    freq_offset = 1606.75;
    spect_pars.freq = freq_offset;%1499.7;%1606.75; %Transfer frequency for |9/2,-7/2> to |7/2,-7/2>
    spect_pars.power = 14; 
    spect_pars.delta_freq = 1500/1000;
    spect_pars.mod_dev = spect_pars.delta_freq/2; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
    %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
    Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
    addOutputParam('delta_freq',spect_pars.delta_freq)
    %Quick little addition to start at freq_val instead.
    if(~Cycle_About_Freq_Val)
        spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
    end
    
    time1_list=[0.01];
    time1=getScanParameter(time1_list,seqdata.scancycle,seqdata.randcyclelist,'time1');
    %2ms per 10kHz        
    spect_pars.pulse_length = 0.2* spect_pars.delta_freq * 1000 / 10 * 2; % also is sweep length 
    spect_pars.uwave_delay = 0; %wait time before starting pulse
    spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)
    spect_type = 1; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps
    
    %Options for spect_type = 1:
    sweep_field = 0; %0 to sweep with SRS, 1 to sweep with z Shim
    %Options for spect_type = 2:
    spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk          
    spect_pars.AM_ramp_time = 2; %This elongates length of pulse when using pulse_type = 1.
    
    %Sweep fields or frequencies to transfer atoms. 
    ScopeTriggerPulse(curtime,'State Transfer');
        
    if (sweep_field == 0) %Sweeping frequency of SRS

        %Plane select atoms by sweeping frequency
        addOutputParam('delta_freq',spect_pars.delta_freq)
        spect_pars.fake_pulse = 0;
        spect_pars.SRS_select = 1; %0: Use SRS A, 1: Use SRS B
        if spect_pars.SRS_select == 1
            %Programming second generator, may set different power,
            %mod_dev, etc...
            spect_pars.power = spect_pars.power;
            spect_pars.mod_dev = spect_pars.delta_freq;
        end
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % second sweep (actual plane selection)


        
    elseif (sweep_field == 1) %Sweeping field with z Shim, SRS frequency is fixed
            
        %SRS in pulsed mode with amplitude modulation
        spect_type = 2;

        %Take frequency range in MHz, convert to shim range in Amps
        %  (-5.714 MHz/A on Jan 29th 2015)
        if (seqdata.flags. K_RF_sweep==1)
            %In -ve mF state, frequency increases with field
            dBz = spect_pars.delta_freq / (5.714);
        else 
            %In +ve mF state, frequency decreases with field
            dBz = spect_pars.delta_freq / (-5.714);
        end

        addOutputParam('delta_freq',spect_pars.delta_freq)
        addOutputParam('current_range',dBz)

        field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
        field_shift_settle = 40; % settling time after initial and final field shifts

        if (Cycle_About_Freq_Val)
            %Shift field down and up by half of the desired width
            z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
        else %Start at current field and ramp up
            z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
            z_shim_sweep_start = z_shim_sweep_center;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz;
        end

        % synchronizing this plane-selection sweep
        do_ACync_plane_selection = 1;
        if do_ACync_plane_selection
            dispLineStr('enabling acync',curtime);
%             % Enable ACync right after ramping up to start field
%             ACync_start_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time);
%             % Disable ACync right before ramping back to initial field value
%             ACync_end_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time + ...
%                 2*field_shift_settle + spect_pars.pulse_length);

            % Enable ACync right after ramping up to start field
            ACync_start_time = calctime(curtime,spect_pars.uwave_delay - field_shift_settle);
            % Disable ACync right before ramping back to initial field value
            ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                field_shift_settle + spect_pars.pulse_length);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end    

        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_start;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim during uwave pulse to transfer atoms
        %from |9/2,-7/2> to |7/2,-7/2>
        ramp.shim_ramptime = spect_pars.pulse_length;
        ramp.shim_ramp_delay = spect_pars.uwave_delay;
        ramp.zshim_final = z_shim_sweep_final;

        ramp_bias_fields(calctime(curtime,0), ramp);
   
  %%%%%%%% start of holding sometime then transfer atoms back to |9/2,-7/2> %%%%%%%%%%%%%%%%%%%%%%%
   
        holding_then_transfer_back = 0;        
        %holding sometime then transfer atoms back to |9/2,-7/2>
        if holding_then_transfer_back == 1
            shim_holding_list = [1];
            shim_holding_time = getScanParameter(shim_holding_list,seqdata.scancycle,seqdata.randcyclelist ,'shim_holding_time');
            setDigitalChannel(calctime(curtime,spect_pars.pulse_length),'K uWave TTL',0);  %switch off uWave TTL during holding
            setDigitalChannel(calctime(curtime,spect_pars.pulse_length + shim_holding_time),'K uWave TTL',1); %switch on uWave TTL after holding for next sweep
        
            %Ramp shim during uwave pulse to transfer atoms
            %from |7/2,-7/2> to |9/2,-7/2>
            clear('ramp');
            ramp.shim_ramptime = spect_pars.pulse_length;
            ramp.shim_ramp_delay = spect_pars.uwave_delay + spect_pars.pulse_length + shim_holding_time + spect_pars.uwave_delay
            ramp.zshim_final = z_shim_sweep_start;
            ramp_bias_fields(calctime(curtime,0), ramp);
        
            %do transfer pulse            
            pulse_length_with_holding = 2 * spect_pars.pulse_length + shim_holding_time;
            ramp_shim_back_delay = spect_pars.uwave_delay + 2* spect_pars.pulse_length + field_shift_settle + shim_holding_time;
        end
  %%%%%%%%%%end of holding sometime then transfer atoms back to |9/2,-7/2>%%%%%%%%%%%%%%%%%%%%%%%     
  
        %Ramp shim back to initial value after pulse is complete
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay + spect_pars.pulse_length + field_shift_settle; %offset from the beginning of uwave pulse
        if holding_then_transfer_back == 1
            ramp.shim_ramp_delay = ramp_shim_back_delay;
        end
        ramp.zshim_final = z_shim_sweep_center;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Do plane selection pulse
        if holding_then_transfer_back == 1
            spect_pars.pulse_length = pulse_length_with_holding;
        end
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     


            %Wait for shim field to return to initial value
% curtime = calctime(curtime,field_shift_settle+field_shift_time);
curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway
            
    end

       do_RF_tranfer_to_kill = 0;
    
    if ( do_RF_tranfer_to_kill) % does an rf sweep to transfer atoms from |9/2,-7/2> to |9/2,-9/2>
    

       curtime=calctime(curtime,50);
        
       %Do RF Sweep
       clear('sweep');
       rf_list = [31.3524]; 
       sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%         sweep_pars.freq = 31.37;44.4247; %Sweeps -9/2 to -7/2 at 207.6G.
       rf_power_list = [-8];
       sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
       delta_freq = -0.5;
       sweep_pars.delta_freq = delta_freq;  -0.2; % end_frequency - start_frequency   0.01
       rf_pulse_length_list = [10];
       sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
%        sweep_pars.multiple_sweep = 1;
%        sweep_pars.multiple_sweep_list = [34.1583];
       addOutputParam('RF_Pulse_Length',sweep_pars.freq);
       acync_time_start = curtime;
%       trigger    
        ScopeTriggerPulse(curtime,'rf_pulse_test');
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
total_pulse_length = sweep_pars.pulse_length+50;


            do_ACync_plane_selection = 1;
            if do_ACync_plane_selection
                ACync_start_time = calctime(acync_time_start,-80);
                ACync_end_time = calctime(curtime,total_pulse_length+40);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
            
    end
curtime=calctime(curtime,50);
            
            
    %%%%Kill beam 
    %----------------------------------------------
    Downwards_D2 = 0;% turn on the kill beam
    if Downwards_D2
        %Should be plenty of time to do optical removal without
        %updating curtime, due to the shim field settling time above

        if kill_pulses==1
            %Resonant light pulse to remove any untransferred atoms from F=9/2
            kill_probe_pwr = 1;
            kill_time_list = 50; 5 %10
            kill_time = getScanParameter(kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'kill_time');
            kill_detuning = 30;39; %27 for 80G
            addOutputParam('kill_detuning',kill_detuning);
%             addOutputParam('kill_time',kill_time);

            pulse_offset_time = -5; %Need to step back in time a bit to do the kill pulse
                                      % directly after transfer, not after the subsequent wait times

%             %set probe detuning
%             setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Probe/OP FM',170); %195
            %set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Trap FM',kill_detuning); %54.5

            %open K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time-4),'Downwards D2 Shutter',1); %0=closed, 1=open
            %turn up analog
%             setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
            %set TTL off initially
            setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',0);
ScopeTriggerPulse(calctime(curtime,pulse_offset_time+kill_time),'kill_test_pulse');
            %pulse beam with TTL
            DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);
%             setDigitalChannel(calctime(curtime,pulse_offset_time),'Kill TTL',1);
%             setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time),'Kill TTL',0);
            %close K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 2),'Downwards D2 Shutter',0);%1: On; 0: OFF

            %set kill AOM back on
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 500),'Kill TTL',1);
            kill_w_time_list=[150];
            kill_w_time = getScanParameter(kill_w_time_list,seqdata.scancycle,seqdata.randcyclelist,'kill_w_time');
curtime = calctime(curtime,kill_time+kill_w_time);
        end
    end    
    
    
%     spect_pars.delta_freq = -500/1000;
%     curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % second sweep (actual plane selection)

 %%%%%%%transfer atoms from |7/2,-7/2> back to |9/2,-9/2> for plane selection%%%%%%%%%%%%%%%%
    initial_transfer = 1;%%transfer atoms from |7/2,-7/2> back to |9/2,-9/2> for plane selection
    if initial_transfer
    
        % FB coil settings for spectroscopy
        clear('ramp')
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 125.6544;%before 2017-1-6 5.9925*22.6;% 5.9925  
        ramp.settling_time = 200; %200  
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

        %Save pulse settings for plane selection
        selection_pulse_length = spect_pars.pulse_length;
        selection_delta_freq = spect_pars.delta_freq;

        if (sweep_field == 0)
            %Transfer all atoms to F=7/2 first
            spect_pars.mod_dev = 1800/1000; %Mod dev needs to be big enough for a wide initial sweep   1800
            spect_pars.delta_freq = 2000/1000;
            spect_pars.pulse_length = 200;
            spect_pars.fake_pulse = 0;

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % first sweep (note: this one moves with the center frequency!)

curtime = calctime(curtime,200); % wait to allow SRS to settle at new frequency

        elseif (sweep_field == 1)
                
            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;

            %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
            dBz = spect_pars.delta_freq / (-5.714); % sweeping over a large range (equiv to 1800kHz) to transfer the full cloud.
            selection_pulse_length = spect_pars.pulse_length;
%             spect_pars.pulse_length = 100;
            spect_pars.SRS_select = 1; %Use SRS B for the global sweep

            init_sweep_time = 20; %80
            field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = 40; % settling time after initial and final field shifts

            z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;

            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = init_sweep_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;

            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;

            ramp_bias_fields(calctime(curtime,0), ramp);

            %Do plane selection pulse (initial transfer)
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
            
            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
curtime = calctime(curtime,100);
        end
        
    end    
      
   %Lattices to pin.  
   pin_lattice_on = 0;
   if pin_lattice_on == 1
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40); 
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40)
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40);
   end % if pin_lattice_on
    
    % Ramp gradient and FB back down
    clear('ramp');

    ramp.xshim_final = seqdata.params. shim_zero(1);
    ramp.yshim_final = seqdata.params. shim_zero(2);
    ramp.shim_ramptime = 50;
    ramp.shim_ramp_delay = -10;

    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = FB_init; %18

    % QP coil settings for spectroscopy
    ramp.QP_ramptime = 50;
    ramp.QP_ramp_delay = -0;
    ramp.QP_final =  0; %7

    ramp.settling_time = 200; %200  
    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

end

%% Plane selection

%%Remove atoms in undesired vertical planes from the lattice.
%RHYS - This code is a doozy of a mess. See Graham's
%do_fast_plane_selection for ideals of modularizing. Should definitely be a
%separate module at the least. 

if do_plane_selection
    dispLineStr('Plane Selection',curtime);
    %Ramp up gradient and Feshbach field    
    
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 40/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 40/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 40/atomscale);

Lattices_to_Pin_plane_selection = 0;    

    if Lattices_to_Pin_plane_selection
        disp('Ramping lattices and dipole traps.');
        setDigitalChannel(calctime(curtime,-0.1),'yLatticeOFF',0);%0: ON
        
        % Ramp Lattices
        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5,60); 
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60); %30?
        
        % Ramp dipole traps
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
    end    
    
    ramp_fields = 1;
    FB_init = getChannelValue(seqdata,37,1,0);
    if ramp_fields
        % Ramp the SHIMs, QP, and FB to the appropriate level  
        disp('Ramping fields');
        clear('ramp');       
        
        xshimdlist = -0.257;
        yshimdlist = 0.125;
        zshimd = -1;
        
        xshimd = getScanParameter(xshimdlist,seqdata.scancycle,...
            seqdata.randcyclelist,'xshimd','A');
        yshimd = getScanParameter(yshimdlist,seqdata.scancycle,...
            seqdata.randcyclelist,'yshimd','A');
        
        %Both these x and y values can be large and negative. Draw from the
        %'positive' shim supply when negative. Just don't fry the shim.
        ramp.xshim_final = seqdata.params. shim_zero(1)-2.548 + xshimd;% -0.7 @ 40/7, (0.46-0.008-.05-0.75)*1+0.25 @ 40/14
        ramp.yshim_final = seqdata.params. shim_zero(2)-0.276 + yshimd;
        ramp.zshim_final = seqdata.params. shim_zero(3)+zshimd; %Plane selection uses this shim to sweep... make its value larger?
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero
        
        addOutputParam('PSelect_xShim',ramp.xshim_final)
        addOutputParam('PSelect_yShim',ramp.yshim_final)
        addOutputParam('PSelect_zShim',ramp.zshim_final)

%         addOutputParam('xshimd',xshimd);
%         addOutputParam('yshimd',yshimd);
        addOutputParam('zshimd',zshimd,'A');

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = -0;
        fb_shift_list = [0.60];[0.56];%0.2 for 0.7xdt power
        fb_shift = getScanParameter(fb_shift_list,seqdata.scancycle,...
            seqdata.randcyclelist,'fb_shift');
        ramp.fesh_final = 128-fb_shift;125.829-fb_shift; %before 2017-1-6 6*22.6; %22.6% smaller b field means farther away from the window
        %default value of ramp.fesh_final is 6*22.6, for plane
        %selection
%         addOutputParam('fb_shift',ramp..00f2.b_shift)

        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 100;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  14*1.78; %7 %210G/cm
        ramp.settling_time = 300; %200
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
    
    
%     sweep_field = 0;
%     if sweep_field ==1
                
        %Do you want to fake the plane selection sweep?
        fake_the_plane_selection_sweep = 0; %0=No, 1=Yes, no plane selection but remove all atoms.

        % When cloud moves up, field is smaller, so frequency goes down (|9/2,-9/2>)
%         freq_list = [-490]/1000;
        %unit is kHz. Have to tunning the frequency everyday.
%         freq_val = -0/1000 + getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');  % |9/2,-9/2> %2094 at 105G/cm, 3460 at 210G/cm
        %spect_pars.freq = 1186.107 +freq_val; %MHz (1186.107 for 2*22.6 FB)  % |9/2,9/2>
%         addOutputParam('freq_val',freq_val)
        planeselect_freq = 1606.75;%1498.30 + freq_val;%1386.5 +freq_val;  1186.107 + freq_val
%         planeselect_freq = 1364.658; %select atoms in |9/2,-7/2> to |7/2,-5/2>
        spect_pars.freq = planeselect_freq;   % |9/2,-9/2>
        spect_pars.power = 15;15;%6.5; %-15 %uncalibrated "gain" for rf
        ffscan_list = [7]/1000;%frequency sweep width
        ffscan = getScanParameter(ffscan_list,seqdata.scancycle,seqdata.randcyclelist,'ffscan');
        planeselect_sweep_width = ffscan;%500/1000;
        spect_pars.delta_freq = planeselect_sweep_width; %300
        spect_pars.mod_dev = planeselect_sweep_width; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
        %spect_pars.mod_dev = 80/1000; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
        Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
        %addOutputParam('delta_freq',spect_pars.delta_freq)
        %Quick little addition to start at freq_val instead.
        if(~Cycle_About_Freq_Val)
            spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
        end
        
        planeselect_pulse_length = planeselect_sweep_width * 1000 / 10 * 2; %2ms per 10kHz        
        spect_pars.pulse_length = planeselect_pulse_length; % also is sweep length (max is Keithley time - 20ms)       1*16.7
        spect_pars.uwave_delay = 0; %wait time before starting pulse
        spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)
        spect_type = 2; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps
        sweep_field = 0; %0 to sweep with SRS, 1 to sweep with z Shim
        %Options for spect_type = 1
        spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk  
                
        spect_pars.AM_ramp_time = 2;9;  
%                 spect_pars.AM_ramp_time = 9; %Used for pulse_type = 1      2*16.7
                       
        %Determine the frequency to plane select |9/2,-7/2> atoms
        freq2 = DoublePlaneSelectionFrequency(spect_pars.freq, [9/2,-9/2],[7/2,-7/2],[9/2,-7/2],[7/2,-5/2]);
%     end 
    
%spectroscopy2
disp('spectroscopy2');
    use_ACSync = 0;

    % Define the SRS frequency
    freq_list = 0;[-300];-90       
    
    % 2021/06/22 CF
    % Use this when Xshimd=3, zshimd=-1 and you vary yshimd
%     freq_list=interp1([-3 0.27 3],[100 -200 -500],yshimd);

    % use this when yshimd=3, zshim3=-1 an dyou vary xshimd
    % freq_list=interp1([-3 0 3],[-200 -400 -500],xshimd);

    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_freq_offset','kHz from 1606.75 MHz');
    
    disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);
    
    % SRS settings (may be overwritten later)
    uWave_opts=struct;
    uWave_opts.Address=28;                        % K uWave ("SRS B");
    uWave_opts.Frequency=1606.75+freq_offset*1E-3;% Frequency in MHz
    uWave_opts.Power= 15;%15                      % Power in dBm
    uWave_opts.Enable=1;                          % Enable SRS output    

    addOutputParam('uwave_pwr',uWave_opts.Power)
    addOutputParam('uwave_frequency',uWave_opts.Frequency);    
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
    
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);

    % RF Switch for K SRS depreciated? (1:B, 0:A)
    setDigitalChannel(calctime(curtime,-20),'K uWave Source',1);  
 

%% Transfer atoms to |7/2,-7/2> initially.
% CORA - Is this historical, can we delete it? Accroding to VV
        initial_transfer = 0;
        
        if initial_transfer
            
            %Save pulse settings for plane selection
            selection_pulse_length = spect_pars.pulse_length;
            selection_delta_freq = spect_pars.delta_freq;
            
            if (sweep_field == 0)
            %Transfer all atoms to F=7/2 first
            spect_pars.mod_dev = 1800/1000; %Mod dev needs to be big enough for a wide initial sweep   1800
            spect_pars.delta_freq = 3600/1000;
            spect_pars.pulse_length = 200;
            spect_pars.fake_pulse = 0;
        
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % first sweep (note: this one moves with the center frequency!)

curtime = calctime(curtime,200); % wait to allow SRS to settle at new frequency

            elseif (sweep_field == 1)
                
                %SRS in pulsed mode with amplitude modulation
                spect_type = 2;
                
                %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
                dBz = 3.00 / (-5.714); % sweeping over a large range (equiv to 1800kHz) to transfer the full cloud.
                selection_pulse_length = spect_pars.pulse_length;
                spect_pars.pulse_length = 100;
                spect_pars.SRS_select = 0; %Use SRS A for the global sweep
                
                init_sweep_time = 80;
                field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
                field_shift_settle = 40; % settling time after initial and final field shifts

                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

                %Ramp shim to start value before generator turns on
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_start;

                ramp_bias_fields(calctime(curtime,0), ramp);

                %Ramp shim during uwave pulse to transfer atoms
                ramp.shim_ramptime = init_sweep_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay;
                ramp.zshim_final = z_shim_sweep_final;

                ramp_bias_fields(calctime(curtime,0), ramp);

                %Ramp shim back to initial value after pulse is complete
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_center;

                ramp_bias_fields(calctime(curtime,0), ramp);
            
            
            %Do plane selection pulse (initial transfer)
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
            
            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
curtime = calctime(curtime,100);

            end % end initial transfer

            clean_up_pulse = 0;
            if clean_up_pulse
                %Resonant light pulse to remove any untransferred atoms from F=9/2
                kill_probe_pwr = 1;
                kill_time = 0.2;
                kill_detuning = 90; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field            
                
                pulse_offset_time = -100; %Need to step back in time a bit to do the kill pulse
                                          % directly after transfer, not after the subsequent wait times
                
                %set probe detuning
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
                %set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5
                
                %open K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time-10),30,1); %0=closed, 1=open
                %turn up analog
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
                %set TTL off initially
                setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);
                
                %pulse beam with TTL
                DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);
                
                %close K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),30,0);
            end
            

            %Reset pulse settings for plane selection
            spect_pars.pulse_length = selection_pulse_length;
            spect_pars.delta_freq = selection_delta_freq;
            
            
        end
       
%% Actual plane selection happens here.
ScopeTriggerPulse(curtime,'Plane Select');
        
if (sweep_field == 0) %Sweeping frequency of SRS
            disp('Using SRS to plane select');

%             %Plane sel ect atoms by sweeping frequency
%             addOutputParam('delta_freq',spect_pars.delta_freq)
%             spect_pars.fake_pulse = 0;
%             spect_pars.SRS_select = 0; %0: Use SRS A, 1: Use SRS B
%                 if spect_pars.SRS_select == 1
%                     %Programming second generator, may set different power,
%                     %mod_dev, etc...
%                     spect_pars.power = -35;
%                     spect_pars.mod_dev = 100/1000;
%                 end
%             
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % second sweep (actual plane selection)
        
        disp('HS1 Sweep Pulse');
        
        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta',beta);
        
        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp',env_amp);


        % Determine the range of the sweep
        uWave_delta_freq_list= [75] /1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq');
        
        
        uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        % Set uWave power to low
        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);
         
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);
        
        % Sweep the VVA (use voltage func 2 to invert the vva transfer
        % curve (normalized 0 to 10
        AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp,2);
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',0);-1;
        
        % Reset the ACync
        setDigitalChannel(calctime(curtime,100),'ACync Master',0);
        
        % Program the SRS
        programSRS(uWave_opts); 
curtime = calctime(curtime,75);

        elseif (sweep_field == 1) %Sweeping field with z Shim, SRS frequency is fixed
            disp('Using Z shim to plane select');

            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;
    
            %Take frequency range in MHz, convert to shim range in Amps
            %  (-5.714 MHz/A on Jan 29th 2015)
            if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. init_K_RF_sweep==1)
                %In -ve mF state, frequency increases with field
                dBz = spect_pars.delta_freq / (5.714);
            else 
                %In +ve mF state, frequency decreases with field
                dBz = spect_pars.delta_freq / (-5.714);
            end
            
            field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = 60; % settling time after initial and final field shifts
            
            if (Cycle_About_Freq_Val)
                %Shift field down and up by half of the desired width
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
            else %Start at current field and ramp up
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz;
            end
            
            % synchronizing this plane-selection sweep
            do_ACync_plane_selection = 1;
            if do_ACync_plane_selection
                  dispLineStr('enabling acync',curtime);

%                 % Enable ACync right after ramping up to start field
%                 ACync_start_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time);
%                 % Disable ACync right before ramping back to initial field value
%                 ACync_end_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time + ...
%                     2*field_shift_settle + spect_pars.pulse_length);
                
                % Enable ACync right after ramping up to start field
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay - field_shift_settle);
                % Disable ACync right before ramping back to initial field value
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    field_shift_settle + spect_pars.pulse_length);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
            
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = spect_pars.pulse_length;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Extra Parameters for the plane selecting pulse
            spect_pars.fake_pulse = fake_the_plane_selection_sweep;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
            spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
            
            %Do plane selection pulse
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
% curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway
            
        end

        Downwards_D2 = 1;% turn on the kill beam
        if Downwards_D2            
        % Vertical *upwards* D2 kill beam to kill untransfered atoms            
            %Should be plenty of time to do optical removal without
            %updating curtime, due to the shim field settling time above
            
            if kill_pulses==1
            dispLineStr('Vertical D2 Kill Pulse',curtime);

            %Resonant light pulse to remove any untransferred atoms from
            %F=9/2
            kill_time_list = [2];2
            kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
                seqdata.randcyclelist,'kill_time','ms'); %10 
            kill_detuning_list = [42.7];[54];40;39;
            kill_detuning = getScanParameter(kill_detuning_list,...
                seqdata.scancycle,seqdata.randcyclelist,'kill_det');
%             kill_detuning = 39;   40;   %27 for 80G       %43 @ 2018-02-22
%             addOutputParam('kill_det',kill_detuning);
%             addOutputParam('kill_time',kill_time);

            
            %Kill SP AOM 
            mod_freq =  (120)*1E6;
            mod_amp = 0.05;0.05;0.1;
            mod_offset =0;
            str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
            addVISACommand(8, str);  %Device 8 is the new kill beam Rigol changed on July 10, 2021
            
            % Display update about
            disp(' D2 Kill pulse');
            disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
            disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
            disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
            disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 



            pulse_offset_time = -5; %Need to step back in time a bit to do the kill pulse
                                      % directly after transfer, not after the subsequent wait times
                                      
%             %set probe detuning
%             setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Probe/OP FM',170); %195
            % Set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Trap FM',kill_detuning); %54.5

            % open K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time-5),'Downwards D2 Shutter',1); %0=closed, 1=open
            
            % Set TTL off initially
            setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',0);%0= off, 1=on
            
%             kill_lat_ramp_time = 3;
%             AnalogFuncTo(calctime(curtime,pulse_offset_time-kill_lat_ramp_time),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), kill_lat_ramp_time, kill_lat_ramp_time, 60/atomscale); %30?                                      
            
            %pulse beam with TTL
            DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);
            
%             AnalogFuncTo(calctime(curtime,pulse_offset_time+kill_time),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), kill_lat_ramp_time, kill_lat_ramp_time, 60/atomscale); %30?                                      

            %close K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+2),'Downwards D2 Shutter',0);

            %set kill AOM back on
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 5),'Kill TTL',1);

            end
        end
        
        Horizontal_D2 = 0;
        if Horizontal_D2
            dispLineStr('Horizontal D2 Kill Pulse',curtime);

            
            %Should be plenty of time to do optical removal without
            %updating curtime, due to the shim field settling time above
            
            
            %Resonant light pulse to remove any untransferred atoms from F=9/2
            kill_probe_pwr = 0.5;
            kill_time = 15;
            kill_detuning = 110; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field
                                 %110 MHz to be resonant with |9/2,-9/2> -> |11/2,-11/2> transition in 40G field
            addOutputParam('kill_detuning',kill_detuning);

            pulse_offset_time = -5; %Need to step back in time a bit to do the kill pulse
                                      % directly after transfer, not after the subsequent wait times

            %set probe detuning
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
            %set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5

            %open K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP shutter',1); %0=closed, 1=open
            %turn up analog
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
            %set TTL off initially
            setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);

            %pulse beam with TTL
            DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);

            %close K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),'K Probe/OP shutter',0);
        end
        
        
        
        transfer_back_to_9half = 0;% transfer back to -9/2
        if transfer_back_to_9half
            % Transfer the |7,-7> back to |9,-9>.  This sweep can be broad
            % because everything else is dead (nominally). This step is
            % also somewhat uncessary because the Raman beams during
            % imaging Rabi oscillates between the two
            
            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
            curtime = calctime(curtime,65);
                
            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;

            %Take frequency range in MHz, convert to shim range in Amps
            %(-5.714 MHz/A on Jan 29th 2015)
            
            final_transfer_range = 2; %MHz
            back_transfer_range = 1;
            if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. init_K_RF_sweep==1)

                %In -ve mF state, frequency increases with field
                dBz = back_transfer_range*final_transfer_range / (5.714);
            else 
                %In +ve mF state, frequency decreases with field
                dBz = back_transfer_range*final_transfer_range / (-5.714);
            end

            spect_pars.pulse_length = 100*final_transfer_range; %Seems to give good LZ transfer for power = -12dBm peak

            final_sweep_time = back_transfer_range*spect_pars.pulse_length;
            field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = spect_pars.AM_ramp_time + 10; % settling time after initial and final field shifts

            z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = final_sweep_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim back to initial value after pulse is complete
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            ramp_bias_fields(calctime(curtime,0), ramp);
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time); 

            followup_repump_pulse = 1;1;%remove mF = -7/2 atoms
            if (followup_repump_pulse || do_plane_selection_horizontally==0)
                %Ensure atoms are all returned to F=9/2 with repump light
                % (do this during the shim field wait time above)
                % (would be great to use FM to get the repump to resonance in the 40G field)
                
                %Pulse on repump beam to try to remove any atoms left in F=7/2
                repump_pulse_time = 5;
                repump_pulse_power = 0.7;

                %Open Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),3,1);
                %turn repump back up
                setAnalogChannel(calctime(curtime,-field_shift_settle-10),25,repump_pulse_power);
                %repump TTL
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),7,1);

                %Repump pulse
                DigitalPulse(calctime(curtime,-field_shift_settle),7,repump_pulse_time,0);

                %Close Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle+repump_pulse_time+5),3,0);
            end
            
        end
        
%% Plane select a second time
        %RHYS - This is a crazy copy of basically just everything above.
        %Why this needs to be a module.
        if (second_plane_selection == 1)
            %Select the desired plane again in order to increase the
            %efficiency of the optical kill pulse
            
curtime = calctime(curtime,100);
            
            %Plane Selection Pulse
            %---------------------
            
                %SRS in pulsed mode with amplitude modulation
                spect_type = 2;
                spect_pars.pulse_length = planeselect_pulse_length;
                spect_pars.delta_freq = planeselect_sweep_width;
                
                field_drift = 0/1000; %Change in resonance due to thermal effects in QP/FB Coils 750?

                %Take frequency range in MHz, convert to shim range in Amps
                %  (-5.714 MHz/A on Jan 29th 2015)
                if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. init_K_RF_sweep==1)
                    %In -ve mF state, frequency increases with field
                    dBz = (spect_pars.delta_freq) / (5.714);
                    dBz_drift = field_drift / (5.714);
                else 
                    %In +ve mF state, frequency decreases with field
                    dBz = (spect_pars.delta_freq) / (-5.714);
                    dBz_drift = field_drift / (-5.714);
                end
            field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = 40; % settling time after initial and final field shifts
            
            if (Cycle_About_Freq_Val)
                %Shift field down and up by half of the desired width
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center+dBz_drift-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+dBz_drift+1*dBz/2;
            else %Start at current field and ramp up
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center+dBz_drift;
                z_shim_sweep_final = z_shim_sweep_center+dBz_drift+1*dBz;
            end
            
            % synchronizing this plane-selection sweep
            do_ACync_plane_selection = 1;
            if do_ACync_plane_selection
                dispLineStr('enabling ACync',curtime);
                % Enable ACync right after ramping up to start field
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay - field_shift_settle);
                % Disable ACync right before ramping back to initial field value
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    field_shift_settle + spect_pars.pulse_length);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
            
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = spect_pars.pulse_length;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Extra Parameters for the plane selecting pulse
            spect_pars.fake_pulse = fake_the_plane_selection_sweep;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
            spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
            
            %Do plane selection pulse
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     
                %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway

            %D2 Kill Pulse
            %-------------  
            if Downwards_D2
                %Should be plenty of time to do optical removal without
                %updating curtime, due to the shim field settling time above

                if kill_pulses==1
                %Resonant light pulse to remove any untransferred atoms from
                %F=9/2

    %             %set probe detuning
    %             setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Probe/OP FM',170); %195
                %set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Trap FM',kill_detuning); %54.5

                %open K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time-10),'Downwards D2 Shutter',1); %0=closed, 1=open
                %set TTL off initially
                setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',0);%0= off, 1=on

%                 AnalogFuncTo(calctime(curtime,pulse_offset_time-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 10/atomscale); %30?                                      

                %pulse beam with TTL
                DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);

%                 AnalogFuncTo(calctime(curtime,pulse_offset_time+kill_time),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale); %30?                                      

                %close K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time),'Downwards D2 Shutter',0);

                %set kill AOM back on
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 5),'Kill TTL',1);

                end
            end
             
            Transfer_Back_Again = 0;
            if (Transfer_Back_Again)
%             %Transfer Back
%             %-------------             
curtime = calctime(curtime,65); %Wait time to finish shim ramps

                %SRS in pulsed mode with amplitude modulation
                spect_type = 2;

                final_transfer_range = 2; %MHz
                if (seqdata.flags. K_RF_sweep==1)
                    %In -ve mF state, frequency increases with field
                    dBz = final_transfer_range / (5.714);
                else 
                    %In +ve mF state, frequency decreases with field
                    dBz = final_transfer_range / (-5.714);
                end

                spect_pars.pulse_length = 100*final_transfer_range; %Seems to give good LZ transfer for power = -12dBm peak
                spect_pars.SRS_select = 0; %Use SRS A for the global sweep
%                 spect_pars.AM_ramp_time = 9;

                final_sweep_time = spect_pars.pulse_length;
                field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
                field_shift_settle = spect_pars.AM_ramp_time + 10; % settling time after initial and final field shifts

                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center+dBz_drift-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+dBz_drift+1*dBz/2;

                %Ramp shim to start value, then sweep for transfer, then ramp to final value
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_start;
                ramp_bias_fields(calctime(curtime,0), ramp);

                ramp.shim_ramptime = final_sweep_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay;
                ramp.zshim_final = z_shim_sweep_final;
                ramp_bias_fields(calctime(curtime,0), ramp);

                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_center;
                ramp_bias_fields(calctime(curtime,0), ramp);
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); 
            end

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time); 

        end
        
        %RHYS - QP vacuum cleaner. Will never be used again.
        if (eliminate_planes_with_QP)
            
            %Reduce QP before relaxing from 3D confinement
            % (ramp happens during the 'field settling time')
%             clear('ramp');
%             ramp.QP_ramptime = 50;
%             ramp.QP_ramp_delay = -50;
%             ramp.QP_final =  0.0*1.78; %4
%             
%             ramp.fesh_final = FB_init;
%             ramp.fesh_ramptime = 50;
%             ramp.fesh_ramp_delay = -50;
%             
%             ramp_bias_fields(curtime, ramp);
            
            
            
            % Note: only works ok in a very narrow range of parameters;
            % always kills some atoms in 9/2 as well. Optimal parameters
            % may change with lattice alignment.     
       
            QP_kill_time = 80; % time with lowered lattices and strong gradient

            lat_psel_ramp_depth = [[0 0 20 20];[0 0 20 20];[20 20 20 20]]; % lattice depths in Er
            lat_psel_ramp_time = [150 NaN 50 50]; % sum of the last two ramp times is effectively the field settling time
            
            clear('ramp');

        % Field Ramps for Gradient Kill
            % Reduce FB coil so that the transverse gradient is significant
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 0.10431;%before 2017-1-6 0.1; %0.05
            % Ramp X and Y shims to center the QP gradient around the trap axis
            ramp.shim_ramptime = 50;
            ramp.shim_ramp_delay = 0;
            ramp.xshim_final = getChannelValue(seqdata,27,1,0)-0.050; %-0.050 previously.
            ramp.yshim_final = getChannelValue(seqdata,19,1,0)+0.090;
            ramp.zshim_final = getChannelValue(seqdata,28,1,0)-0.10;
            % QP coil settings for gradient killing
            ramp.QP_ramptime = 50;
            ramp.QP_ramp_delay = 00;
            ramp.QP_final =  3.5*1.78; %4
            % no settling time (being rough here) -- lattice rampup time plus additional hold time are used instead
            ramp.settling_time = 0;

        %Lattice Ramps for Gradient Kill
            % first field ramp (happens once the horizontal lattice is ramped down)
            ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)), ramp); % check ramp_bias_fields to see what struct ramp may contain
            
            % second field ramp (happens before the horizontal lattice is ramped back up)
            clear('ramp');
            
            ramp.fesh_final = FB_init;
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = 0;
            
            ramp.QP_final =  0*1.78; 
            ramp.QP_ramptime = 50;
%             ramp.QP_ramp_delay = 25;
%             ramp.QP_FF_ramp_delay = ramp.QP_ramp_delay;
%             ramp.QP_FF_ramptime = ramp.QP_ramptime+10;
            
            ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)+ramp.fesh_ramptime+QP_kill_time), ramp); % check ramp_bias_fields to see what struct ramp may contain
 
            % wait with lowered horizontal lattice until FB field is ramped up again and gradient is removed
            lat_psel_ramp_time(2) = 2*ramp.fesh_ramptime+QP_kill_time;
            
            
            if (length(lat_psel_ramp_time) ~= size(lat_psel_ramp_depth,2)) || ...
                    (size(lat_psel_ramp_depth,1)~=length(lattices)) || ...
                    isnan(sum(sum(lat_psel_ramp_depth)))
                error('Invalid ramp specification for lattice loading!');
            end
            
        % execute lattice ramps (advances curtime)
            if length(lat_psel_ramp_time) >= 1
                for j = 1:length(lat_psel_ramp_time)
                    for k = 1:length(lattices)
                        curr_val = getChannelValue(seqdata,lattices{k},1);
                        if lat_psel_ramp_depth(k,j) ~= curr_val % only do a minjerk ramp if there is a change in depth
                            AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_psel_ramp_time(j), lat_psel_ramp_time(j), lat_psel_ramp_depth(k,j));
                        end
                    end
curtime =   calctime(curtime,lat_psel_ramp_time(j));
                end
            end
        else
    
            % Ramp gradient and FB back down
            clear('ramp');
            
            ramp.xshim_final = seqdata.params. shim_zero(1);
            ramp.yshim_final = seqdata.params. shim_zero(2);
            ramp.shim_ramptime = 50;
            ramp.shim_ramp_delay = -10;

            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = FB_init; %18

            % QP coil settings for spectroscopy
            ramp.QP_ramptime = 50;
            ramp.QP_ramp_delay = -0;
            ramp.QP_final =  0; %7

            ramp.settling_time = 200; %200
       
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
        end

        
        final_repump_pulse = 0;
        if final_repump_pulse
            %Pulse on repump beam to try to remove any atoms left in F=7/2
            repump_pulse_time = 5;
            repump_pulse_power = 0.7;
            
            %Open Repump Shutter
            setDigitalChannel(calctime(curtime,-10),3,1);
            %turn repump back up
            setAnalogChannel(calctime(curtime,-10),25,repump_pulse_power);
            %repump TTL
            setDigitalChannel(calctime(curtime,-10),7,1);
            
            %Repump pulse
            DigitalPulse(calctime(curtime,0),7,repump_pulse_time,0);
            
            %Close Repump Shutter
            setDigitalChannel(calctime(curtime,repump_pulse_time+5),3,0);
        end
        
        
end


%% Horizontal Selection
%RHYS - Can make a stripe of atoms using this code. The DMD kind of makes
%the patterning irrelevant. However, this code would enable spin
%patterning, so worht keeping around for that potential purpose. Also,
%'do_horizontal_plane_selection' was generalized to also give Raman/EIT
%cooling, because they both use horizontal fields. Not exactly an
%appropriate generalization. 
if do_plane_selection_horizontally == 1
    
    clear('horizontal_plane_select_params')
    horizontal_plane_select_params.Fake_Pulse = 0;
    horizontal_plane_select_params.Offset_Field = 3.9;
    horizontal_plane_select_params.Selection__Frequency = 1285.8+11.25 ; %10.55 for -90deg, 11.25 for 66.5deg (FIX THIS)
    horizontal_plane_select_params.Microwave_Or_Raman = 2;
    %RHYS - Oh yeah, this was tried with Raman beams for the
    %horizontal-plane dependent spin flips. Kind of worked.
    
    Raman_power_list = 1.7;%[0.3:0.2:1.7];
    horizontal_plane_select_params.Raman_Power = getScanParameter(Raman_power_list,seqdata.scancycle,seqdata.randcyclelist,'Raman_power1');
 %  horizontal_plane_select_params.Raman_Power = 0.9;%1.7;
    horizontal_plane_select_params.Raman_AOM_Frequency = 110;
    
    %addOutputParam('Raman_power',horizontal_plane_select_params.Raman_Power);
        
    horizontal_plane_select_params.Rigol_Mode = 'Sweep';
    horizontal_plane_select_params.Modulation_Time = 0.501;
    horizontal_plane_select_params.Selection_Range = 50/1000; %150
    horizontal_plane_select_params.Microwave_Pulse_Length = 0.5; %50
    horizontal_plane_select_params.Sweep_About_Central_Frequency = 1;
    horizontal_plane_select_params.Resonant_Light_Removal = 1;
    horizontal_plane_select_params.Final_Transfer = 1;
    horizontal_plane_select_params.Resonant_Light_Removal = kill_pulses;
    horizontal_plane_select_params.Selection_Angle = 66.5; %-30 for vertical, +60 for horizontal (iXon axes)
        %Kill pulse uses the shim fields for quantization, atom removal may
        %be poor for angles much different from -90deg!!
    
    addOutputParam('H_selection_freq',horizontal_plane_select_params.Selection__Frequency - 1285.8);
    
    %Currently modified to use Raman beams!!!
curtime = do_horizontal_plane_selection_mod(curtime, horizontal_plane_select_params);
    
elseif do_plane_selection_horizontally == 3
    %Do horizontal selection twice to make a box
    % FIRST SELECTION DISABLED IN THE CODE FOR NOW!! (kill beam shutter
    % never opens)
    
%     df_list = [-300:100:300];
%     df = getScanParameter(df_list, seqdata.scancycle, seqdata.randcyclelist, 'H_selection_freq');
%     dB_list = [-0.100:0.05:0.100];
%     dB = getScanParameter(dB_list, seqdata.scancycle, seqdata.randcyclelist, 'X_Offset');
    clear('horizontal_plane_select_params')    
    horizontal_plane_select_params.Fake_Pulse = 0;
    horizontal_plane_select_params.Fake_Pulse_B = 0;
    horizontal_plane_select_params.Selection__Frequency = 1285.8+10.85; %11.550
    horizontal_plane_select_params.Microwave_Or_Raman = 1;
    horizontal_plane_select_params.Double_Selection = 1;
    horizontal_plane_select_params.Selection_Range = 200/1000; %260
    horizontal_plane_select_params.Selection_Range_B = 200/1000; %260
    horizontal_plane_select_params.Microwave_Pulse_Length = 5; %50
    horizontal_plane_select_params.Sweep_About_Central_Frequency = 1;
    horizontal_plane_select_params.Selection_Angle = 180;
    horizontal_plane_select_params.Selection_Angle_B = -90; %Second selection should be at -90 deg for good kill pulses
    horizontal_plane_select_params.Field_Shift = 0*0.06; %Shift (in G) to move the box around (+/- 0.05G or 0.1G to move around the field of view)
    horizontal_plane_select_params.Field_Shift_B = 1*0.06; %0.06 = side length of 150kHz wide box
    horizontal_plane_select_params.Resonant_Light_Removal = 1;
    
    addOutputParam('H_selection_freq',horizontal_plane_select_params.Selection__Frequency - 1285.8);
    addOutputParam('Y_Offset',horizontal_plane_select_params.Field_Shift);
    addOutputParam('X_Offset',horizontal_plane_select_params.Field_Shift_B);
    
curtime = do_horizontal_plane_selection(curtime, horizontal_plane_select_params);
    
    
%RHYS - Not sure what the use of this is. Delete?
elseif do_plane_selection_horizontally == 2
    
    eliminate_horizontal_with_QP = 1;   %Kill unselected planes with gradient + 2D lattice of tubes
    eliminate_by_collisions = 0;        %Kill 7/2 atoms by holding in 2D lattice of tubes
    final_horizontal_kill_pulse = 0;    %Tidy up any atoms not killed by the gradient with optical pulse
    
        ramp_fields = 1;
        FB_init = getChannelValue(seqdata,37,1,0);
        if ramp_fields 
            
            x_shim_offset = 2; %
            y_shim_offset = 0;
            
            fieldramp = struct('ShimValues',seqdata.params.shim_zero + [-0.05+x_shim_offset, +0.09+y_shim_offset, -0.2], ...
                       'FeshValue',0.0208,'QPValue',7*1.78,'SettlingTime',200);
                   %before 2017-1-6 FeshValue is 0.01;
                   
curtime = rampMagneticFields(calctime(curtime,0), fieldramp);
        
        end

        % Do uWave sweep to transfer plane(s)
        freq_offset = -11075/1000; % -10535kHz for X Shim = 2, Gradient = 0, Offsets (-0.05,0.09,-0.2), FB=0.01;
                                % -11035kHz for X Shim = 2, Gradient = 0, Offsets (-0.05,0.09,-0.2), FB=0.01, |9/2,9/2>;
                                % +11035kHz for X Shim = 2, Gradient = 0, Offsets (-0.05,0.09,-0.2), FB=0.01, |9/2,-9/2>;
        sweep_freq = 1285.8 +freq_offset; %MHz (1186.107 for 2*22.6 FB)
        sweep_range = +100/1000; %300
        
        sweep_duration = 2*16.7; % also is sweep length (max is Keithley time - 20ms)
        
        addOutputParam('HS_freq_val',freq_offset)
   
        initial_transfer = 1;
        if initial_transfer
            %Sweep all atoms to F=7/2
curtime = applyMicrowave(curtime,sweep_freq,-20,10*16.6,...
                        'Type','SWEEP','Device',28,'FrequencyRange',1100/1000,...
                        'FMDeviation',600/1000);  
            % some wait time        
curtime = calctime(curtime,100);
        end
      
%RHYS - Oh, this looks like a neater version of the microwave part of the
%rf_uwave_spectroscopy function! This would be a great place to start for a
%better fully general version. 
curtime = applyMicrowave(curtime,sweep_freq,-20,sweep_duration,...
                        'Type','SWEEP','Device',28,'FrequencyRange',sweep_range,...
                        'ScopeTrigger','Horizontal Selection',...
                        'FMDeviation',600/1000,'Disable',0);    
        


            if (eliminate_horizontal_with_QP)
                % Note: only works ok in a very narrow range of parameters;
                % always kills some atoms in 9/2 as well. Optimal parameters
                % may change with lattice alignment.     
        
                QP_kill_time = 50; % time with lowered lattices and strong gradient

                %Go to tubes oriented perpendicular to the horizontal gradient to maintin atom distribution
                % !!! Note that "Y" shim points along X Lattice currently, so X<->Y Switch !!!
                lat_psel_ramp_depth = [[0 0 20 20];[10 10 20 20];[10 10 20 20]]; % lattice depths in Er
                lat_psel_ramp_time = [150 NaN 150 50]; % sum of the last two ramp times is effectively the field settling time

                clear('ramp');

            % Field Ramps for Gradient Kill
                % Reduce FB coil so that the transverse gradient is significant
                ramp.fesh_ramptime = 55;
                ramp.fesh_ramp_delay = 50; %-100??
                ramp.fesh_final = 0.0208;%before 2017-1-6 0.01; %0.05
                % Ramp X, Y, Z shims to center the QP gradient around the trap axis
                ramp.shim_ramptime = 50;
                ramp.shim_ramp_delay = -0;
                ramp.xshim_final = seqdata.params. shim_zero(1)-0.050 + 0.1;
                ramp.yshim_final = seqdata.params. shim_zero(2)+0.090 +0.1;
                ramp.zshim_final = seqdata.params. shim_zero(3)-0.2;
                % QP coil settings for gradient killing
                ramp.QP_ramptime = 50;
                ramp.QP_ramp_delay = -0;
                ramp.QP_final =  7*1.78; %4
                % no settling time (being rough here) -- lattice rampup time plus additional hold time are used instead
                ramp.settling_time = 0;

                % first field ramp (happens once the horizontal lattice is ramped down)
                ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)), ramp); % check ramp_bias_fields to see what struct ramp may contain

                % second field ramp (happens before the horizontal lattice is ramped back up)
                ramp.fesh_final = FB_init;
                ramp.QP_final =  0*1.78;          
                ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)+ramp.fesh_ramptime+QP_kill_time), ramp); % check ramp_bias_fields to see what struct ramp may contain

            %Lattice Ramps for Gradient Kill
                % wait with lowered horizontal lattice until FB field is ramped up again and gradient is removed
                lat_psel_ramp_time(2) = 2*ramp.fesh_ramptime+QP_kill_time;

                if (length(lat_psel_ramp_time) ~= size(lat_psel_ramp_depth,2)) || ...
                        (size(lat_psel_ramp_depth,1)~=length(lattices)) || ...
                        isnan(sum(sum(lat_psel_ramp_depth)))
                    error('Invalid ramp specification for lattice loading!');
                end
            
                %execute lattice ramps (advances curtime)
                if length(lat_psel_ramp_time) >= 1
                    for j = 1:length(lat_psel_ramp_time)
                        for k = 1:length(lattices)
                            curr_val = getChannelValue(seqdata,lattices{k},1);
                            if lat_psel_ramp_depth(k,j) ~= curr_val % only do a minjerk ramp if there is a change in depth
                                AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_psel_ramp_time(j), lat_psel_ramp_time(j), lat_psel_ramp_depth(k,j));
                            end
                        end
curtime = calctime(curtime,lat_psel_ramp_time(j));
                    end
                end
                    
            else %No gradient kill, just turn gradient off
                
    
                % Ramp gradient and FB back down
                clear('ramp');
                
                %Step forward in time to make sure that fields do not ramp
                %during spectroscopy
                curtime = calctime(curtime,15);
                
                %Shim settings to center QP gradient
                ramp.shim_ramptime = 50;
                ramp.shim_ramp_delay = -10;
                ramp.xshim_final = seqdata.params. shim_zero(1);
                ramp.yshim_final = seqdata.params. shim_zero(2);
                ramp.zshim_final = seqdata.params. shim_zero(3);

                % FB coil settings for spectroscopy
                ramp.fesh_ramptime = 50;
                ramp.fesh_ramp_delay = -0;
                ramp.fesh_final = FB_init; %18

                % QP coil settings for spectroscopy
                ramp.QP_ramptime = 50;
                ramp.QP_ramp_delay = -0;
                ramp.QP_final =  0; %7

                ramp.settling_time = 200; %200
       
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
            
            
            end
            
            if (eliminate_by_collisions)
        
                tube_kill_time = 100; % time with lowered lattices

                %Go to tubes oriented perpendicular to the horizontal gradient to maintin atom distribution
                % !!! Note that "Y" shim points along X Lattice currently, so X<->Y Switch !!!
                lat_psel_ramp_depth = [[0 0 20 20];[30 30 20 20];[30 30 20 20]]; % lattice depths in Er
                lat_psel_ramp_time = [150 tube_kill_time 150 50]; % sum of the last two ramp times is effectively the field settling time

                if (length(lat_psel_ramp_time) ~= size(lat_psel_ramp_depth,2)) || ...
                        (size(lat_psel_ramp_depth,1)~=length(lattices)) || ...
                        isnan(sum(sum(lat_psel_ramp_depth)))
                    error('Invalid ramp specification for lattice loading!');
                end
            
                %execute lattice ramps (advances curtime)
                if length(lat_psel_ramp_time) >= 1
                    for j = 1:length(lat_psel_ramp_time)
                        for k = 1:length(lattices)
                            curr_val = getChannelValue(seqdata,lattices{k},1);
                            if lat_psel_ramp_depth(k,j) ~= curr_val % only do a minjerk ramp if there is a change in depth
                                AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_psel_ramp_time(j), lat_psel_ramp_time(j), lat_psel_ramp_depth(k,j));
                            end
                        end
curtime = calctime(curtime,lat_psel_ramp_time(j));
                    end
                end
            end
            
            %Final Kill Pulse to clear atoms from F = 9/2
            if final_horizontal_kill_pulse
                
                if (seqdata.flags. K_RF_sweep == 1 || initial_RF_sweep == 1)
                    %Atoms to be killed are in |9/2,-9/2>
                    kill_detuning = 51; %Similar to parameters for imaging |9/2,-9/2>
                    kill_quant_shim = -1;
                else
                    %Atoms to be killed are in |9/2,+9/2>
                    kill_detuning = 42; %Similar to parameters for imaging |9/2,+9/2>
                    kill_quant_shim = 2.45;
                end
                
                
                
                % Ramp on Quantizing Field
                    clear('ramp');

                    %First, ramp on a quantizing shim.
                    ramp.shim_ramptime = 50;
                    ramp.shim_ramp_delay = -10;
                    ramp.xshim_final = getChannelValue(seqdata,27,1,0);
                    y_shim_init = getChannelValue(seqdata,19,1,0);
                    ramp.yshim_final = kill_quant_shim;%1.61;
                    ramp.zshim_final = getChannelValue(seqdata,28,1,0);

                    % Ramp down Feshbach concurrently.
                    ramp.fesh_ramptime = 50;
                    ramp.fesh_ramp_delay = -0;
                    fb_init = getChannelValue(seqdata,37,1,0);
                    ramp.fesh_final = 0.0115; %before 2017-1-6 0.0*22.6; %18

curtime = ramp_bias_fields(calctime(curtime,0), ramp);
                         
                
                %Resonant light pulse to remove any untransferred atoms from F=9/2
                    kill_probe_pwr = 0.7;
                    kill_time = 2;

                    pulse_offset_time = 0;

                    %set probe detuning
                    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
                    %set trap AOM detuning to change probe
                    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5

                    %open K probe shutter
                    setDigitalChannel(calctime(curtime,pulse_offset_time-10),30,1); %0=closed, 1=open
                    %turn up analog
                    setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
                    %set TTL off initially
                    setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);

                    %pulse beam with TTL
                    DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);

                    %close K probe shutter
                    setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),30,0);
                    
                    %Add extra time to avoid accidental overlap with
                    %absorption imaging code
curtime = calctime(curtime,12);
                
                    
                %Ramp Quantizing Field Off
                    %Ramp shim fields back 
                    clear('ramp');
                    
                    %First, ramp on a quantizing shim.
                    ramp.shim_ramptime = 50;
                    ramp.shim_ramp_delay = -10;
                    ramp.xshim_final = getChannelValue(seqdata,27,1,0);
                    ramp.yshim_final = y_shim_init;%0.6;
                    ramp.zshim_final = getChannelValue(seqdata,28,1,0);
                    
                    % Ramp down Feshbach concurrently.
                    ramp.fesh_ramptime = 50;
                    ramp.fesh_ramp_delay = -0;
                    ramp.fesh_final = fb_init; %18
                    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
                    
                    
            end
            


end

%% Field Ramps BEFORE uWave/RF Spectroscopy
% This code prepares the magnetic fields for uWave and RF spectroscopy

% Shim values for zero field found via spectroscopy
%          x_Bzero = 0.115; %0.03 minimizes field
%          y_Bzero = -0.0925; %-0.075  -0.07 minimizes field
%          z_Bzero = -0.145;% Z BIPOLAR PARAM, -0.075 minimizes the field
%          (May 20th, 2013)

%RHYS - Spectroscopy sections for calibration. Comments about lack of code
%generality from dipole_transfer apply here too: clean and generalize!

if ( do_K_uwave_spectroscopy2 || do_K_uwave_spectroscopy || ...
        do_Rb_uwave_spectroscopy || do_RF_spectroscopy)
    dispLineStr('Ramping magnetic fields BEFORE RF/uwave spectroscopy',curtime);
    ramp_fields = 1; % do a field ramp for spectroscopy
    
    if ramp_fields
        clear('ramp');
%         ramp.shim_ramptime = 50;
%         ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero
%        
%         getChannelValue(seqdata,27,1,0)
%         getChannelValue(seqdata,19,1,0)
%         getChannelValue(seqdata,28,1,0)

%         %First, ramp on a quantizing shim.
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -0;
        
        ramp.xshim_final = 0.1585; getChannelValue(seqdata,27,1,0);
        ramp.yshim_final = -0.0432; getChannelValue(seqdata,19,1,0);%1.61;
        ramp.zshim_final = -0.0865; getChannelValue(seqdata,28,1,0);%getChannelValue(seqdata,28,1,0); %0.065 for -1MHz   getChannelValue(seqdata,28,1,0)
        addOutputParam('shim_value',ramp.zshim_final - getChannelValue(seqdata,28,1,0))
        %Give ramp shim values if we want to do spectroscopy using the
        %shims instead of FB coil. If nothing set here, then
        %ramp_bias_fields just takes the getChannelValue (which is set to
        %field zeroing values)
        %ramp.xshim_final = getChannelValue(seqdata,27,1,0);
%         ramp.yshim_final = 1;
        %ramp.zshim_final = getChannelValue(seqdata,28,1,0);
        
%         % FB coil settings for spectroscopy
%         ramp.fesh_ramptime = 50;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 1.0105*2*22.6; %1.0077*2*22.6 for same transfer as plane selection
        
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_off_delay = 0;
%         B_List = [199.6 200.6 201 202.3 202.6 201.3:0.05:202.2];
%         B = getScanParameter(B_List,seqdata.scancycle,seqdata.randcyclelist,'B_Field');
       
        ramp.fesh_final = 20.98111;5;20.98111;%before 2017-1-6 2*22.6; %6*22.6*1.0068 - Current values for optimal stub-tuning near 120G.
        
        ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
        
% %         % QP coil settings for spectroscopy
%         ramp.QP_ramptime = 50;
%         ramp.QP_ramp_delay = -0;
%         ramp.QP_final =  0*1.78; %7
        ramp.settling_time = 200;200;     
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

% %ramp again
%         ramp.fesh_ramptime = 50;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_off_delay = 0; 
%         ramp.fesh_final = 20; 
%         ramp.use_fesh_switch = 1; 
%         ramp.settling_time = 500;     
% curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain



    end
    
end

%% K uWave Manipulations
% This code performs K uWave manipulations such as Rabi Oscillations,
% Landau Zener Sweeps, and HS1 Sweeps This is the newer version of the code
% that programs the SRS.

if do_K_uwave_spectroscopy2
    dispLineStr('Performing K uWave Spectroscopy',curtime);

%     uWaveMode='rabi';
%     uWaveMode='sweep_field';
%     uWaveMode='sweep_frequency_chirp';
      uWaveMode='sweep_frequency_HS1';

    use_ACSync = 1;
    
    % Get the initial magnetic field value
    Bzc = getChannelValue(seqdata,'Z Shim',1,0);

    % Define the SRS frequency
    freq_list = [10]/1000; %[10]/1000;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_freq_offset');
    
    disp(['     Freq Offset  : ' num2str(freq_offset*1000) ' kHz']);
    
    % SRS settings (may be overwritten later)
    uWave_opts=struct;
    uWave_opts.Address=28;                       % K uWave ("SRS B");
    uWave_opts.Frequency=1335.845+2.5+freq_offset;   % Frequency in MHz
    uWave_opts.Power=15;%12 15                      % Power in dBm
    uWave_opts.Enable=1;                         % Enable SRS output    

    addOutputParam('uwave_pwr',uWave_opts.Power)
    addOutputParam('uwave_frequency',uWave_opts.Frequency);    
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
    
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);

    % RF Switch for K SRS depreciated? (1:B, 0:A)
    setDigitalChannel(calctime(curtime,-20),'K uWave Source',1);  
    
    
switch uWaveMode
    case 'rabi'
        disp(' uWave Rabi Oscillations');
        
        % Disable the frquency sweep
        uWave_opts.EnableSweep=0;                    
        uWave_opts.SweepRange=1;  
        
        % Time to have uWaves on
        uwave_time_list=[1.42:0.02:1.7];
        uwave_time = getScanParameter(uwave_time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'uwave_pulse_time');
 
        % Set uWave power (func1: V, fucn2: normalized)
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',10,1);    
        %setAnalogChannel(calctime(curtime,-10),'uWave VVA',1,2);     %
        %func2: 0 : 0 rabi, 1 : max rabi

        % Set modulation to none (should be ignored regardless)
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',0);
        
        % Turn on ACync
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end       
        
        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        % Wait
        curtime = calctime(curtime,uwave_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
    case 'sweep_field'
        % THIS HAS NOT BEEN TESTED YET
        disp(' Landau-Zener Sweep B-Field');
        uWave_opts.EnableSweep=0;                    
        uWave_opts.SweepRange=1;                   

        % Set uWave power
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',10);
        
        % Sweep the magnetic field to perform Landau-Zener sweep
        
        % Define sweep range (MHz)
        delta_freq_list=[20/1000];[500/1000];  
        delta_freq=getScanParameter(delta_freq_list,seqdata.scancycle,seqdata.randcyclelist,'delta_freq');
        
        % Define sweep time (ms)
         sweep_time_list =[delta_freq*1000/5]; 
%         sweep_time_list =[6 7 8 9]; 
        sweep_time = getScanParameter(sweep_time_list,seqdata.scancycle,seqdata.randcyclelist,'sweep_time');
        
        % Convert sweep range to current of z shim
        dBz = delta_freq/(-5.714); % -5.714 MHz/A for Z shim (2015/01/29)         

        % Define the magnetic field sweep
        Bzc = getChannelValue(seqdata,'Z Shim',1,0);
        Bzi = Bzc-dBz/2;
        Bzf = Bzc+dBz/2;
        
        % Time to shift shims to intial/final values
        field_shift_time=5;      
       
        % Time wait after ramping shims (for field settling);
        field_shift_offset = 15;     
        
        % Display summary
        disp(['     Field Shift (kHz) : ' num2str(1E3*delta_freq)]);
        disp(['     Ramp Time   (ms)  : ' num2str(sweep_time)]);
        
        % Ramp Z Shim to initial field of sweep before uWave        
        ramp=struct;
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = -field_shift_offset; 
        ramp.zshim_final = Bzi;
        ramp_bias_fields(calctime(curtime,0), ramp);

        % Ramp Z Shim to final field of sweep during uWave
        ramp=struct;
        ramp.shim_ramptime = sweep_time;
        ramp.shim_ramp_delay = 0;                   
        ramp.zshim_final = Bzf;
        ramp_bias_fields(calctime(curtime,0), ramp);

        % Ramp Z Shim back to original field after uWave
        clear('ramp');
        ramp=struct;
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = sweep_time+field_shift_offset;
        ramp.zshim_final = Bzc;            
        ramp_bias_fields(calctime(curtime,0), ramp);
        
        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1); 
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
        
    case 'sweep_frequency_chirp'
        disp(' Landau-Zener Sweep uWave Frequency');
        
        
        uWave_delta_freq_list=[50]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq');
        
        uwave_sweep_time_list =[50]; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        % Set uWave power
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',2.5);
        
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        
        % Ramp the SRS modulation 
        % At +-1V input for +- full deviation
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',@(t,T) -1+2*t/T,sweep_time,sweep_time);
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
        
    case 'sweep_frequency_HS1'
        disp('HS1 Sweep Pulse');
        
        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta',beta);
        
        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp',env_amp);


        % Determine the range of the sweep
        uWave_delta_freq_list=[30]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq');
        
        
        uwave_sweep_time_list =[30]; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        % Set uWave power to low
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',0);
         
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);
        
        % Sweep the VVA (use voltage func 2 to invert the vva transfer
        % curve (normalized 0 to 10
        AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp,2);
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
    
    otherwise
        error('Invalid uwave flag request. (you fucked up)');    
end

% Turn ACync off 20 ms after pulses
if use_ACSync
    setDigitalChannel(calctime(curtime,20),'ACync Master',0);
end

% Program the SRS
programSRS(uWave_opts); 
    
% Wait a bit for future pieces of code (should get rid of this)
curtime = calctime(curtime,20);  
end

%% K uWave Spectroscopy (OLD)
% This code performs K uWave manipulations such as Rabi Oscillations,
% Landau Zener Sweeps. It is hoped that this code is deprecated and will no
% longer be used.

if do_K_uwave_spectroscopy
    dispLineStr('Performing K uWave Spectroscopy',curtime);
    clear('spect_pars');

    freq_list = [-7]/1000;[150]/1000;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'freq_val');

    %Currently 1390.75 for 2*22.6.
    spect_pars.freq = 1335.845 +2.5+ freq_offset;
        %1298.3 + freq_offset;1335.845 + freq_offset; %Optimal stub-tuning frequency. Center of a sweep (~1390.75 for 2*22.6 and -9/2; ~1498.25 for 4*22.6 and -9/2)

    uwavepower_list = [15];%15
    uwavepower_val = getScanParameter(uwavepower_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwavepower_val');

    spect_pars.power = uwavepower_val; % 15 %dBm
    spect_pars.delta_freq = 50/1000;50/1000;% end_frequency - start_frequency (in
    spect_pars.mod_dev = spect_pars.delta_freq;

%         spect_pars.pulse_length = t0*10^(-1.5)/10^(pwr/10); % also is sweep length (max is Keithley time - 20ms)
    pulse_time_list =[20];[spect_pars.delta_freq*1000/5]; %Keep fixed at 5kHz/ms.
    spect_pars.pulse_length = getScanParameter(pulse_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_pulse_time');
    spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp up and down with min-jerk
    spect_pars.AM_ramp_time = 0;5;
    spect_pars.fake_pulse = 0;
    spect_pars.uwave_delay = 0; %wait time before starting pulse
    spect_pars.uwave_window = 0; % time to wait during 60Hz sync pulse (Keithley time +20ms)
    spect_type = 2; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps 9: field sweep
    spect_pars.SRS_select = 1;

%         addOutputParam('uwave_pwr',pwr)
    addOutputParam('sweep_time',spect_pars.pulse_length);
    addOutputParam('sweep_range',spect_pars.delta_freq);
    addOutputParam('freq_val',freq_offset);
    
        do_field_sweep = 1;
        if do_field_sweep
            %Take frequency range in MHz, convert to shim range in Amps
            %  (-5.714 MHz/A on Jan 29th 2015)
            dBz = spect_pars.delta_freq / (-5.714); 
            
            field_shift_offset = 25;
            field_shift_time = 5;
            
            z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
            z_shim_sweep_start = z_shim_sweep_center-dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+dBz/2;
            
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_offset; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = spect_pars.pulse_length;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_offset; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
        end
        
        use_ACSync = 1;
        if use_ACSync
                % Enable ACync 10ms before pulse
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay-15);
                % Disable ACync 150ms after pulse
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    spect_pars.pulse_length + 150);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            
        end
% 
        if ( seqdata.flags.pulse_raman_beams ~= 0)
            
            Raman_On_Delay = 0.0;
            Raman_On_Time = spect_pars.pulse_length;
            Raman_Ramp_Time = 0.00 * Raman_On_Time;
%             %Ramp VVA to open.
%             AnalogFuncTo(calctime(curtime,-Raman_Ramp_Time-Raman_On_Delay),52,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Raman_Ramp_Time,Raman_Ramp_Time,9.9);
            %Pulse Raman beams on.
curtime = DigitalPulse(calctime(curtime,-Raman_Ramp_Time-Raman_On_Delay),'Raman TTL',Raman_On_Time+2*Raman_Ramp_Time+2*Raman_On_Delay,1);
%             %Ramp VVA to closed.
%             AnalogFuncTo(calctime(curtime,-Raman_Ramp_Time),52,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Raman_Ramp_Time,Raman_Ramp_Time,0);
        %     pulse_time_list = [100];
        %     pulse_time = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_time');
        %     curtime = Pulse_RamanBeams(curtime,pulse_time,'MOTLightSource',2);
%             curtime = calctime(curtime,Raman_On_Time); 
        end
        
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
%change curtime for testing F pump
curtime = calctime(curtime,20);

ScopeTriggerPulse(curtime,'K uWave Spectroscopy');
    Raman_Back = 0;

    if Raman_Back
        %advance by waittime
        waittime = 500;
curtime = calctime(curtime,waittime);
        
        freq_list = [150]/1000;
        freq_offset = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
        %Currently 1390.75 for 2*22.6.
        spect_pars.freq = 1292.3 + freq_offset; %Center of a sweep (~1390.75 for 2*22.6 and -9/2; ~1498.25 for 4*22.6 and -9/2)
        spect_pars.power = -3; %dBm
        spect_pars.delta_freq = 1000/1000; % end_frequency - start_frequency
        spect_pars.mod_dev = 1000/1000;
        
        spect_pars.SRS_select = 1;
        spect_pars.pulse_length = 2000; % also is sweep length
        spect_type = 1; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps
        
        addOutputParam('freq_val',freq_offset)
        
%         if ( seqdata.flags.pulse_raman_beams ~= 0)
% 
%             Raman_On_Time = spect_pars.pulse_length;
%             DigitalPulse(curtime,'D1 TTL',Raman_On_Time,1);
%         %     pulse_time_list = [100];
%         %     pulse_time = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_time');
%         %     curtime = Pulse_RamanBeams(curtime,pulse_time,'MOTLightSource',2);
%         % %     curtime = calctime(curtime,25); 
%         end
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
    end


    elseif ( do_Rb_uwave_spectroscopy ) % does a uwave pulse or sweep for spectroscopy
        dispLineStr('Rb_uwave_spectroscopy.',curtime);

%         freq_list = [-20:0.8:-12]/1000;%
%         freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
        freq_offset = 0.0;
        spect_pars.freq = 6894.0+freq_offset; %MHz (6876MHz for FB = 22.6)
    %     power_list = [8.6 7 5 3 1 0];
    %     spect_pars.power = getScanParameter(power_list,seqdata.scancycle,seqdata.randcyclelist,'uwave_power');
        spect_pars.power = 8.6; %dBm
        spect_pars.delta_freq = 5; % end_frequency - start_frequency
        spect_pars.pulse_length = 100; % also is sweep length

        spect_type = 5; %5: sweeps, 6: pulse

        addOutputParam('freq_val',freq_offset)

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % check rf_uwave_spectroscopy to see what struct spect_pars may contain

    end
    

%% RF Spectroscopy

if do_RF_spectroscopy
        dispLineStr('RF spectroscopy.',curtime);

        
        %Do RF Sweep
        clear('sweep');
        B = 5;
        sweep_pars.freq = 1.5;-0.025 + (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6; %Sweeps -9/2 to -7/2 at 207.6G.
        sweep_pars.power = 5;2.7; %-7.7
        sweep_pars.delta_freq = -0.5;-0.3; % end_frequency - start_frequency   0.01
        sweep_pars.pulse_length = 30; % also is sweep length  0.5
        sweep_pars.fake_pulse = 0;

        addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
curtime = calctime(curtime, 10);

        reverse_sweep = 0;
        if reverse_sweep
            clear('ramp')
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 5;
            ramp.fesh_ramp_delay = 5;
            B_2 = 199.6;
            ramp.fesh_final = (B_2-0.1)*1.08962;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
            ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
            ramp.settling_time = 5;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
            sweep_pars.freq = (BreitRabiK(B_2,9/2,-5/2) - BreitRabiK(B_2,9/2,-7/2))/6.6260755e-34/1E6; 
            sweep_pars.delta_freq = -sweep_pars.delta_freq;
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
        end
    
end
    
%% K Raman Spectroscopy
if do_K_raman_spectroscopy

%ramp fields
    ramp_fields = 0;
    if ramp_fields
            clear('ramp');
            %First, ramp on a quantizing shim.
            ramp.shim_ramptime = 50;
            ramp.shim_ramp_delay = -0;

            ramp.xshim_final = 0.1585; getChannelValue(seqdata,27,1,0);
            ramp.yshim_final = -0.0432; getChannelValue(seqdata,19,1,0);%1.61;
            ramp.zshim_final = -0.0865; getChannelValue(seqdata,28,1,0);%getChannelValue(seqdata,28,1,0); %0.065 for -1MHz   getChannelValue(seqdata,28,1,0)
            addOutputParam('shim_value',ramp.zshim_final - getChannelValue(seqdata,28,1,0))
           
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_off_delay = 0;
            B_List = [195];
            B = getScanParameter(B_List,seqdata.scancycle,seqdata.randcyclelist,'B_Field');

            ramp.fesh_final = B;
            ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
            ramp.settling_time = 200;200;     
            curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
        
    Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
    Raman_AOM3_freq =  (60)*1E6;
    Raman_AOM3_pwr = 0.3;
    RamanspecMode = 'sweep'
%     RamanspecMode = 'pulse'

    
    %R3 beam settings
    switch RamanspecMode
        case 'sweep'
            Sweep_Range = 100/1000;  %in MHz
            Sweep_Time = 50; %in ms
            str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
            Raman_on_time = Sweep_Time;
        
        case 'pulse'
            Raman_on_time = 50; %ms
            str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                Raman_AOM3_freq, Raman_AOM3_pwr);
    end 
    addVISACommand(Device_id, str);

    %R2 beam settings
    if ~Raman_transfers     %Rigol cannot be programmed more than once in a sequence
    Device_id = 1;
    Raman_AOM2_freq = 80*1E6;
    Raman_AOM2_pwr = 0.6;
    Raman_AOM2_offset = 0;
    str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);
    
    addVISACommand(Device_id, str);

    end 
    
    
    
    %Raman spectroscopy AOM-shutter sequence
    %we have three TTLs to independatly control R1, R2 and R3
            
    setDigitalChannel(calctime(curtime,-150),'Raman TTL 1',0); %turn off R1
    DigitalPulse(calctime(curtime,-150),'Raman TTL 2',150,0); %turn off R2 temporarily for shutter
    DigitalPulse(calctime(curtime,-150),'Raman TTL 3',150,0); %turn off R3 temporarily for shutter

    
    DigitalPulse(calctime(curtime,-100),'Raman Shutter',Raman_on_time+100+100,1);% open shutter 100ms before and close 100ms after the sweep

    DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',150,0); %turn off R2 after the sweep and turn on 150ms later
    DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',150,0); %turn off R3 after the sweep and turn on 150ms later
    setDigitalChannel(calctime(curtime,Raman_on_time+ 150),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended


    
          


end


    
%% Field Ramps AFTER uWave/RF Spectroscopy

% Shim values for zero field found via spectroscopy
%          x_Bzero = 0.115; %0.03 minimizes field
%          y_Bzero = -0.0925; %-0.075  -0.07 minimizes field
%          z_Bzero = -0.145;% Z BIPOLAR PARAM, -0.075 minimizes the field
%          (May 20th, 2013)

if ( do_K_uwave_spectroscopy2 || do_K_uwave_spectroscopy || ...
        do_Rb_uwave_spectroscopy || do_RF_spectroscopy ...
        )
    
    dispLineStr('Ramping magnetic fields AFTER RF/uwave spectroscopy',curtime);
    ramp_fields = 1; % do a field ramp for spectroscopy
    
    if ramp_fields
curtime = calctime(curtime,100);
        
        clear('ramp');
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -100; % ramp earlier than FB field if FB field is ramped to zero
       
        getChannelValue(seqdata,27,1,0);
        getChannelValue(seqdata,19,1,0);
        getChannelValue(seqdata,28,1,0);
        
        %Give ramp shim values if we want to do spectroscopy using the
        %shims instead of FB coil. If nothing set here, then
        %ramp_bias_fields just takes the getChannelValue (which is set to
        %field zeroing values)
        ramp.xshim_final = getChannelValue(seqdata,27,1,0);
        ramp.yshim_final = getChannelValue(seqdata,19,1,0);
        ramp.zshim_final = getChannelValue(seqdata,28,1,0);
        
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 50;
        ramp.fesh_final = 5.253923;%before 2017-1-6 0.25*22.6; %18 %0.25
        
        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 50;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  0; %18
        ramp.settling_time = 200;
      
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
    
end
    
%% Turn off Gradient
%RHYS - Turns off the QP. Still don't like the structure here, seems it
%should just be contained to each spectroscopy module.

if (do_K_uwave_spectroscopy2 ||do_K_uwave_spectroscopy || ...
        do_Rb_uwave_spectroscopy || do_RF_spectroscopy  ...
        )
    
    if isfield(ramp,'QP_final')
        if ramp.QP_final ~=0
            clear('ramp');
            %If QP gradient was turned on for spectroscopy/plane selection, turn it
            %off before releasing from lattice

            % QP coil settings for spectroscopy
            rampdown.QP_ramptime = 100;
            rampdown.QP_ramp_delay = -0;
            rampdown.QP_final =  0*1.78;

            rampdown.settling_time = 50;
                
curtime = ramp_bias_fields(calctime(curtime,0), rampdown); % check ramp_bias_fields to see what struct ramp may contain
        end
    end
end

%% Dimple on later
%RHYS - More dimple stuff that will never be used. Delete.
if (Dimple_Trap_After_Plane_Selection)
      
    Dimple_Power_List = [1.5];
    Dimple_Power = getScanParameter(Dimple_Power_List,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Power');%maximum is 4
    Dimple_Ramp_Time_list = [50]; %50
    Dimple_Ramp_Time = getScanParameter(Dimple_Ramp_Time_list,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Ramp_Time')*1;
    Dimple_Wait_Time_List = [50];%[50];
    Dimple_Wait_Time = getScanParameter(Dimple_Wait_Time_List,seqdata.scancycle,seqdata.randcyclelist,'Dimple_Wait_Time')*1;
    
    setDigitalChannel(calctime(curtime,-10),'Dimple Shutter',1);
    setDigitalChannel(calctime(curtime,0),'Dimple TTL',0);%0
curtime = AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, Dimple_Power); 
    
%     Next, go to 1D z-lattice, with 2 steps
%     1st step, goes to 2 Er
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 2); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 2);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 10);    
%     2nd step, goes to 0 Er    
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 10);
%   
curtime = calctime(curtime, Dimple_Wait_Time);

end

%% Modulate Dimple Trap
%RHYS - Used to calibrate dimple trap depth. Make into a module, stick
%somewhere. 
if (Dimple_Mod)
    A_mod = 0.5;
    Frequency_List = [100:100:2000];
    f_mod = getScanParameter(Frequency_List,seqdata.scancycle,seqdata.randcyclelist,'Modulation_Frequency')*10^(-3);
    Dimple_Sweeptime = 100;
    Dimple_Power_Sweep = 0.00;

% curtime = AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),Dimple_Sweeptime,Dimple_Sweeptime,Dimple_Power-Dimple_Power_Sweep/2);
    
    ScopeTriggerPulse(calctime(curtime,0),'Dimple Mod');
    
    AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk_mod(t,tt,y1,y2,A_mod/2,f_mod)),Dimple_Sweeptime,Dimple_Sweeptime,Dimple_Power+Dimple_Power_Sweep/2);
       %Lattices back to 60Er.    
%     AnalogFuncTo(calctime(curtime,Dimple_Sweeptime),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0.6*111); 
%     AnalogFuncTo(calctime(curtime,Dimple_Sweeptime),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0.6*80)
curtime = AnalogFuncTo(calctime(curtime,Dimple_Sweeptime),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0.6*20);


end

 %% Dimple Trap Off
%RHYS - The second part of that dimple after plane select code, where the
%dimple turns off. Probably delete.

if (Dimple_Trap_After_Plane_Selection)
    %Lattices to some set depth and XDT to some power for modulating.
    Lattices_to_Pin = 1;
    XDT1_Power = 0.5;
    XDT2_Power = (((sqrt(XDT1_Power)*102.013-8.1515)+2.36569)/134.842)^2;
    addOutputParam('xdt1power',XDT1_Power);
    addOutputParam('xdt2power',XDT2_Power);
    
    Trap_Ramp_Time = 50;
    XY_Lattice_Depth = 3;
    Z_Lattice_Depth = 3;
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT1_Power);
curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT2_Power);
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth);
% curtime =
% AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth);
curtime = calctime(curtime,50);

    Dimple_Ramp_Time = 100;%50
  %%turn off dimple before loading into lattice  
    AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, 0.0);
curtime = setDigitalChannel(calctime(curtime,Dimple_Ramp_Time),'Dimple TTL',1);
% curtime = AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 0); %0
    setDigitalChannel(calctime(curtime,0),'Dimple Shutter',0);    
 
    ramp_up_FB_after_evap = 0;
    if ramp_up_FB_after_evap
               
%         %Flip atoms in -7/2 to -5/2 at low field.
%         clear('sweep')
%         
%         sweep_pars.freq = 6.044; %6.07 MHz
%         sweep_pars.power = -7;   %-7.7
%         sweep_pars.delta_freq = 0.03; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 10; 
%         % change to 5 for sweep all atoms to |9/2,-7/2>;
%  
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
               
        %Ramp up the feshbach field to this value after dimple evaporation.
        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 195;%before 2017-1-6 200*1.08962; %22.6
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        conductivityfb_list = [204];       
        conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 0.2;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = conductivityfb;%before 2017-1-6 200*1.08962; %22.6
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    end 
   

    
%     Trap_Ramp_Time = 50;
%     XY_Lattice_Depth = 3;
%     Z_Lattice_Depth = 3;
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale);
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth/atomscale);
%     AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT1_Power);
% curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT2_Power);
% curtime = calctime(curtime,100);

% 
%     if ramp_up_FB_after_evap
%         %Flip atoms in -5/2 back to -7/2 after crossing p-wave resonance.
%         clear('sweep')
%         High_Field_RF = -(BreitRabiK(conductivityfb,9/2,-7/2) - BreitRabiK(conductivityfb,9/2,-5/2))/6.6260755e-34/1E6; %Resonance in MHz.
%         sweep_pars.freq = High_Field_RF; %6.07 MHz
%         sweep_pars.power = 0;   %-7.7
%         sweep_pars.delta_freq = 0.100; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 10; 
%         % change to 5 for sweep all atoms to |9/2,-7/2>;
%  
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars); 
%     end

    %---------measure xdt beam displacement v.s. shear mod AOMs' frequence    
%     freq1_list = [40]*1e6;
%     freq2_list = [40]*1e6;
%     xdt1_freq=getScanParameter(freq1_list,seqdata.scancycle,seqdata.randcyclelist,'xdt1_freq');
%     xdt2_freq=getScanParameter(freq2_list,seqdata.scancycle,seqdata.randcyclelist,'xdt2_freq');
%     str1 = sprintf('SOUR2:FREQ %g;SOUR1:FREQ %g;',xdt1_freq,xdt2_freq);   
%     addVISACommand(2, str1);  
    %--end of measure xdt beam displacement v.s. shear mod AOMs' frequence
    %-------- trap frequency measurement by displace one XDT beam
    measure_trap_frequency_flag = 0;
    if (measure_trap_frequency_flag==1)
        %This is gets overwritten - already programmed above.
%         str1 = sprintf('SOUR2:FREQ %g;SOUR1:FREQ %g;',40e6,40e6);%reset the rf source of the 2 shear mode AOMs;
%         addVISACommand(2, str1);
        setAnalogChannel(calctime(curtime,-10),'Modulation Ramp',0);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);%turn on the modulation
ScopeTriggerPulse(calctime(curtime,0),'trapfreq');
curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, 1); 
        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);%turn off the modulation
        setAnalogChannel(calctime(curtime,10),'Modulation Ramp',0);
%         setDigitalChannel(calctime(curtime,0),'XDT TTL',1);%turn off the XDT beams
%         time_list = [0:2.5:30];
        holdtime=getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'holdtime');
%         holdtime = getmultiScanParameter(time_list,seqdata.scancycle,'holdtime',1,1);
curtime = calctime(curtime,holdtime);        
    end
%     %-------- end of trap frequency measurement by displace one XDT beam
    
    if conductivity_modulation
        freq_list = [70];       
        mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
        time_list = [0];
        mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
        addOutputParam('mod_time',mod_time);
        amp_list = [1];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
        mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
        mod_angle = 30;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
        offset_list = [0];
        mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
        mod_offset2 = 2*cosd(mod_angle);
%         mod_dev_chn1 = mod_amp/(cosd(180+118.6-mod_angle)-cosd(32-mod_angle)*sind(180+118.6-mod_angle)/sind(32-mod_angle));
%         mod_dev_chn2 = -mod_dev_chn1*sind(180+118.6-mod_angle)/sind(32-mod_angle);
%         fm_dev_chn1 = abs(mod_dev_chn1)/0.2273;%unit is kHz;
%         fm_dev_chn2 = abs(mod_dev_chn2)/0.2265;%unit is kHz;
%         fm_dev_chn1 = mod_amp/0.2394;%unit is kHz;
%         fm_dev_chn2 = mod_amp/0.2394;
%         fm_dev_chn1=30;
        phase1 = 0;
        phase2 = 0;
        
%         if mod_dev_chn1<0
%             phase1 = 180;
%         else
%             phase1 = 0;
%         end
%         if mod_dev_chn2<0;
%             phase2 = 180;
%         else
%             phase2 = 0;
%         end

        %-------------------------set Rigol DG1022Z---------
        str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,mod_amp,mod_offset,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
        str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
%         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,mod_amp,mod_offset2,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
%         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
        str1=[str011, str012];
        addVISACommand(3,str1);  
        %-------------------------set Rigol DG4162 ---------
% %         str111=sprintf(':SOUR1:APPL:SIN 40MHz,0.8,0,0;');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
% %         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%         str121=sprintf(':SOUR2:APPL:SIN 40MHz,1.4,0,0;');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn2, FM modulation, external,deviation is xxx
% %         str2=[str112,str111,str122,str121];
%         str2=[str121,str122];
%         addVISACommand(2, str2);              
        %-------------------------end:set Rigol-------------
        
        %ramp the modulation amplitude
        mod_ramp_time = 150; %how fast to ramp up the modulation amplitude
        final_mod_amp = 1;
        setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
curtime = calctime(curtime,10);
ScopeTriggerPulse(curtime,'conductivity modulation');
        setDigitalChannel(curtime,'Lattice FM',1);
curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
        mod_wait_time = 50;
curtime = calctime(curtime,mod_wait_time);
curtime = calctime(curtime,mod_time);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
        setAnalogChannel(curtime,'Modulation Ramp',0);
        post_mod_wait_time_list = [0];  
        post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
        addOutputParam('post_mod_wait_time',post_mod_wait_time);
curtime = calctime(curtime,post_mod_wait_time);

    end
    
%Lattices to pin. 
    if Lattices_to_Pin
        AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60); 
        AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60)
curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60);
    
%     ramp down xdt
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, -0.2);
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, -0.2);
    end

%     if ramp_up_FB_after_evap
%         %Flip atoms in -7/2 back to -5/2 before lowering field.
%         clear('sweep')
%         High_Field_RF = -(BreitRabiK(conductivityfb,9/2,-7/2) - BreitRabiK(conductivityfb,9/2,-5/2))/6.6260755e-34/1E6; %Resonance in MHz.
%         sweep_pars.freq = High_Field_RF; %6.07 MHz
%         sweep_pars.power = 0;   %-7.7
%         sweep_pars.delta_freq = 0.100; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 10; 
%         % change to 5 for sweep all atoms to |9/2,-7/2>;
%  
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars); 
%     end
    
%     if modulate_XDT_after_dimple
%             
%         freq_list = [100]; %560
%         mod_freq = getmultiScanParameter(freq_list,seqdata.scancycle,'lat_mod_freq',1,2);
% %         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'Forcing_Freq');
% 
%         time_list = [100:50:600]%[150:125/mod_freq:150+2000/mod_freq];
%         mod_time = getmultiScanParameter(time_list,seqdata.scancycle,'lat_mod_time',1,1);
% %         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'Forcing_Time');
% 
%         mod_amp = 1;
%         mod_wait_time = 0;
%         
%         mod_offset = 0;
% %         final_mod_amp_ref_list = [4];
% %         final_mod_amp_ref = final_mod_amp_ref_list(freq_list == mod_freq);
%         final_mod_amp_ref = 4;
%         addOutputParam('mod_amp',final_mod_amp_ref);
%         mod_ramp_time = 50; %1000/mod_freq*2
%         AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp_ref); 
%         
%         %%%%--------------------set Rigol DG1022Z----------
% %         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
% %         str01=[str011, str012,str021,str022,str031];
% %         addVISACommand(3,str01);
%         %%%%--------------------set Rigol DG4162Z----------
%         %%%%--------------------set Rigol DG4162Z----------
%         
%         
%     % Apply the lattice modulation   
% curtime = applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_offset, mod_time, ...
%         'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod');
% curtime = calctime(curtime,-0.1);
% 
% % %%%%%%%%%%%%%%%%%trap isotropy measurement%%%%%%%%%%%%%%%%%%%%
% % 
% %         freq_list = [39.8:0.1:40.2]*1e6;
% %         xdt2_freq=getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'xdt2_freq');
% %         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% %         mod_amp=0.01;
% %         pzt_ref_xdt1_list= [ 1 2 ];
% % %         pzt_ref_xdt2_list= [10];
% %         pzt_xdt1_ref = getScanParameter(pzt_ref_xdt1_list,seqdata.scancycle,seqdata.randcyclelist,'pzt_xdt1_ref')-mod_amp/2;
% % %         pzt_xdt2_ref = getScanParameter(pzt_ref_xdt2_list,seqdata.scancycle,seqdata.randcyclelist,'pzt_xdt2_ref')-mod_amp/2;
% % %         pzt_xdt2_ref = sqrt(25-(pzt_xdt1_ref-5)^2)+5;
% % %         addOutputParam('pzt_xdt2_ref',pzt_xdt2_ref);
% %         str1 = sprintf('SOUR2:FREQ %g;',xdt2_freq);   
% %         str1 = sprintf('SOUR1:APPL:SQUare;SOUR1:FREQ %g;SOUR1:VOLT %g;SOUR1:VOLT:OFFS %g;',mod_freq, mod_amp, pzt_xdt1_ref);   
% % %       str1 = sprintf('SOUR1:APPL:SQUare;SOUR1:FREQ %g;SOUR1:VOLT %g;SOUR1:VOLT:OFFS %g;SOUR2:APPL:SQUare;SOUR2:FREQ %g;SOUR2:VOLT %g;SOUR2:VOLT:OFFS %g;',mod_freq, mod_amp, pzt_xdt1_ref,mod_freq, mod_amp, pzt_xdt2_ref);
% %         addVISACommand(2, str1);       
% %         ScopeTriggerPulse(curtime,'ttl_test');
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
% %         curtime = calctime(curtime,500);
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);
% %         curtime = calctime(curtime,-0.5);
% % %%%%%%%%%%%%%%%%end of trap isotropy measurement%%%%%%%%%%%%%%%%%%%%%
% 
% 
% % %%%%%%%%%%%%%%%%
% %         freq_list = [50]; 
% %         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% % 
% %         time_list = [50];
% %         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_time');
% %         mod_amp = 1;
% %         addOutputParam('mod_amp',mod_amp);
% %         mod_wait_time = 0;
% %         
% %         mod_offset_list = 0;%[0.5]- mod_amp/2;
% %         mod_offset = getScanParameter(mod_offset_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_offset1');
% %         addOutputParam('mod_offset',mod_offset + mod_amp/2);
% % %         mod_offset = mod_amp/2;
% % 
% %         str = sprintf('SOUR1:APPL:SQUare;SOUR1:FREQ %g;SOUR1:VOLT %g;SOUR1:VOLT:OFFS %g;',mod_freq, mod_amp, mod_offset);
% %         addVISACommand(2, str);
% %         
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
% %         AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 100, 100, 10);
% %         curtime = calctime(curtime,100);
% %         curtime = calctime(curtime,mod_time);
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   % 
% % %%%%%%%%%%%%%%%%
% 
%     end

%     wait_list = [0.5];
%     oscillation_wait_time = getScanParameter(wait_list,seqdata.scancycle,seqdata.randcyclelist,'osc_wait_time');
%     
%     curtime = calctime(curtime, oscillation_wait_time);

    if ramp_up_FB_after_evap
curtime = calctime(curtime,20);
     % Turn the FB up to 20G before loading the lattice, so that large field
        % ramps in the lattice can be done more quickly
        clear('ramp');
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 0.1;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 180;%before 2017-1-6 0.25*22.6; %22.6
            ramp.settling_time = 10;
            addOutputParam('FB_Scale',ramp.fesh_final)
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
        
        clear('ramp');
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 100;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 20;%before 2017-1-6 0.25*22.6; %22.6
            ramp.settling_time = 10;
            addOutputParam('FB_Scale',ramp.fesh_final)
curtime = ramp_bias_fields(calctime(curtime,0), ramp);

    end      

end

%% Lattice Modulation; use bandstructure calculation for conversion into
% This code applies amplitude modulation to XYZ optical lattices.  This is
% done by programming a Rigol generator that goes into the sum input of the
% Newport regulation boxes.

if do_lattice_mod
    dispLineStr('Lattice amplitude modulation spectroscopy.',curtime);
    
    % Turn off ODTs before modulation (if not already off)
    switch_off_XDT_before_Lat_modulation = 0;
    if (switch_off_XDT_before_Lat_modulation == 1) 
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
curtime = calctime (curtime,50);
    end    
    
    freq_list = [247.5:5:267.5]*1e3;
%     freq_list = [35:5:125]*1e3; %560

    mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq','Hz');
    mod_time = 3;%0.2; %Closer to 100ms to kill atoms, 3ms for band excitations only.    
    % For Z Lattice
    mod_amp =  2*((1.1E-5)*(mod_freq/1000)^2-0.00092*(mod_freq/1000)+0.04);0.2;    
    % For Y Lattice
%     mod_amp =  (1.1E-5)*(80+mod_freq/1000)^2-0.00092*(80+mod_freq/1000)+0.04;    
%     mod_amp = ((1.1E-5)*(250+mod_freq/1000)^2-0.00092*(60+mod_freq/1000)+0.04);   
    
    addOutputParam('mod_amp',mod_amp);
  
    % We manually select which channel is modulatig via the Rigol channel
    % to the newport box
    % Program the Rigol
    addr=5;                     % Lattice modulation Rigol channel 2
    ch2=struct;
    ch2.FREQUENCY=mod_freq;     % Modulation Frequency
    ch2.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
    ch2.AMPLITUDE=mod_amp;      % Modulation amplitude
    ch2.SWEEP='OFF';
    ch2.MOD='OFF';
    ch2.BURST='ON';             % Burst MODE 
    ch2.BURST_MODE='GATED';     % Trig via the gate
    ch2.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
    ch2.BURST_TRIGGER='EXT';    % External trigger.
    
    
    
    programRigol(addr,[],ch2);
    
    % We leave the feedback on as it cannot keep up. This + the VVA will
    % make a frequency dependent drive.
    % Trigger and wait
    ScopeTriggerPulse(calctime(curtime,0),'Lattice_Mod');
    setDigitalChannel(calctime(curtime,0),'Lattice FM',1); 
    curtime = setDigitalChannel(calctime(curtime,mod_time),'Lattice FM',0);


    % OLD MODULATION
%       mod_wait_time = -50;
%     mod_offset = 0;
% Apply the lattice modulation   
% applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_offset, mod_time, ...
%     'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod');
% Wait for some time
% curtime = calctime(curtime,mod_time+mod_wait_time+50);

    do_excitation_swap = 0;
    if do_excitation_swap
        Vz_list = [600];
        ramptime_list = [0.01:0.01:0.09 0.25:0.5:2.75];
        Vz = getScanParameter(Vz_list,seqdata.scancycle,seqdata.randcyclelist,'Vz_swap');
        ramptime = getScanParameter(ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'ramptime');
        
curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.2, 0.2, Vz);            
        if(raman_coupling)
            pulse_time_list = [ramptime];
            pulse_time = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_time');
            Pulse_RamanBeams(curtime,pulse_time,'MOTLightSource',2)
        end
curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ramptime, ramptime, 400);    

curtime = calctime(curtime,ramptime);
    end
% curtime = calctime(curtime,50);
%     %Ramp lattices back to some constant value.
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60)
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60);

curtime = calctime(curtime,1);

end


%% Rotate power distribution waveplate again (if loading lattice from a strong dipole trap)
%RHYS - Remove comments, keep.
    if rotate_waveplate
        %Rotate waveplate again to divert the rest of the power to lattice beams
curtime = AnalogFunc(calctime(curtime,0),41,...
    @(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
    wp_Trot2,wp_Trot2,P_RotWave_I,P_RotWave_II); 
            
%Put back in if no need to rotate waveplate before plane selection.
%         if (do_plane_selection || do_plane_selection_horizontally)
%             %Doing plane selection, so there is plenty of time for the
%             %waveplate to turn
%             AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),rotation_time_II,rotation_time_II,P_RotWave_I,P_RotWave_II); 
%         else
%             %No plane selection, make sure rotation is finished before any
%             %further lattice ramps
%             curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),rotation_time_II,rotation_time_II,P_RotWave_I,P_RotWave_II); 
%         end
        
    end


%% Ramp lattice after spectroscopy/plane selection
%RHYS - Important, keep and clean.
if do_lattice_ramp_after_spectroscopy

    
imaging_depth_list = [600]; 
imaging_depth = getScanParameter(imaging_depth_list,seqdata.scancycle,seqdata.randcyclelist,'FI_latt_depth','Er'); 

    %Define ramp parameters
     xLatDepth = imaging_depth;
     yLatDepth = imaging_depth;
     zLatDepth = imaging_depth; 
     
     addOutputParam('xLatDepth',xLatDepth);
     addOutputParam('yLatDepth',yLatDepth);
     addOutputParam('zLatDepth',zLatDepth);


lat_rampup_imaging_depth = 1*[1*[xLatDepth xLatDepth];
                               1*[yLatDepth yLatDepth];
                               1*[zLatDepth zLatDepth]];  %[100 650 650;100 650 650;100 900 900]
     lat_rampup_imaging_time =       [20         5        ];
     
%      lat_rampup_imaging_depth = 1*[[0.00 0.00 0.02 0.02 0.10 0.10 0.60 0.60 xLatDepth xLatDepth];
%                                    [0.00 0.00 0.02 0.02 0.10 0.10 0.60 0.60 yLatDepth yLatDepth];
%                                    [ZLD2 ZLD2 ZLD2 ZLD2 ZLD2 ZLD2 ZLD2 ZLD2 zLatDepth zLatDepth]]*100/atomscale;  %[100 650 650;100 650 650;100 900 900]
%      lat_rampup_imaging_time =     [200   50   200  10   100  10   50   10   50        10       ];

    if (length(lat_rampup_imaging_time) ~= size(lat_rampup_imaging_depth,2)) || ...
            (size(lat_rampup_imaging_depth,1)~=length(lattices))
        error('Invalid ramp specification for lattice loading!');
    end

    %lattice rampup segments
    for j = 1:length(lat_rampup_imaging_time)
        for k = 1:length(lattices)
            if j==1
                if lat_rampup_imaging_depth(k,j) ~= latt_depth(k,end) % only do a minjerk ramp if there is a change in depth
                    AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_imaging_time(j), lat_rampup_imaging_time(j), lat_rampup_imaging_depth(k,j));
                end
            else
                if lat_rampup_imaging_depth(k,j) ~= lat_rampup_imaging_depth(k,j-1) % only do a minjerk ramp if there is a change in depth
                    AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_imaging_time(j), lat_rampup_imaging_time(j), lat_rampup_imaging_depth(k,j));
                end
            end
        end
curtime =   calctime(curtime,lat_rampup_imaging_time(j));
    end
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);

 dispLineStr('Deep lattices ramped at',curtime);

    
deep_latt_holdtime_list = [50];
deep_latt_holdtime = getScanParameter(deep_latt_holdtime_list,seqdata.scancycle,seqdata.randcyclelist,'deep_latt_holdtime'); 
curtime=calctime(curtime,deep_latt_holdtime);
    
end


%% Raman Transfers (Fluorescence Imaging)
%turn on raman beams for side band cooling
%RHYS - Important code for Raman/EIT cooling. Probably should not be a
%branch off horizontal plane selection though.
%

% Plane Selection (earlier)
%   - Apply FB + vertical gradient for selection
%   - Shelve a plane in the 7/2 manifold
%   - Kill untransfered 9/2 atoms
%   - Transfer shelved 7/2 back to 9/2

% Fluoresence Imaging
%   - Set quantiazation axis along FPUMP
%   - Set field for EIT condition and Raman detuning
%   - Apply EIT Pump (FPUMP) light, EIT probe light, Raman light
%   - Expose the Camera

% Raman/UWave Transfers
%   - Set quantiazation axis along FPUMP
%   - Set field for EIT condition, Raman detuning, uWave detuning
%   - Apply Raman/uWave light and sweep freq

if (Raman_transfers == 1)
    dispLineStr('Raman Transfer',curtime);

    %During imaging, generate about a 4.4G horizontal field. Both shims get
    %positive control voltages, but draw from the 'negative' shim supply. 
    clear('horizontal_plane_select_params');
    
    %%% Flags %%%
    horizontal_plane_select_params.Fake_Pulse = 0;
    horizontal_plane_select_params.Use_EIT_Beams = 1;    
    
    %%%% F Pump Power %%%
    F_Pump_List = [0.8];[1];[0.75];[1];%0.8 is optimized for 220 MHz. 1.1 is optimized for 210 MHz.
    horizontal_plane_select_params.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V'); %1.4;
    
    %%% Raman 1 Power %%%
    Raman_Power_List =[0.7];[0.5]; %Do not exceed 2V here. 1.2V is approximately max AOM deflection.
    horizontal_plane_select_params.Raman_Power1 = getScanParameter(Raman_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Power1','V'); 
    
    %%% Raman 2 Power %%%
    Raman_Power2_List =[0.6];horizontal_plane_select_params.Raman_Power1;
    horizontal_plane_select_params.Raman_Power2 = getScanParameter(Raman_Power2_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Power2','V');
%     horizontal_plane_select_params.Raman_Power2 = horizontal_plane_select_params.Raman_Power1;
        
    %%% Raman 1/2 (?) Frequency %%%
    Raman_List = [0];0;   %-30% : in kHz;
    horizontal_plane_select_params.Raman_AOM_Frequency = 110 + getScanParameter(Raman_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_Freq')/1000;

    Raman_On_Time_List =[2000];[4800];%2000ms for 1 images. [4800]= 2*2000+2*400, 400 is the dead time of EMCCD

    
    %%% uWave %%%
    % uWave settings (if Microwave_or_Raman==1)
    uwave_freq_list = [0]/1000;
    uwave_freq = getScanParameter(uwave_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uwave_freq');
    horizontal_plane_select_params.Selection__Frequency = 1285.8 + 11.025 +uwave_freq; %11.550
    horizontal_plane_select_params.Microwave_Power_For_Selection = 15; %dBm
    horizontal_plane_select_params.Microwave_Pulse_Length = ...
        getScanParameter(Raman_On_Time_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Time'); 

    
    %CHECK PERFORMANCE OF SWEEP IN BURST MODE. CURRENTLY USING BURST MODE
    %SINCE REMOVING ZASWA SWITCHES.
    horizontal_plane_select_params.Rigol_Mode = 'Pulse';  %'Sweep', 'Pulse', 'Modulate'
    Range_List = [50];%in kHz
    horizontal_plane_select_params.Selection_Range = getScanParameter(Range_List,seqdata.scancycle,seqdata.randcyclelist,'Sweep_Range')/1000; 
    
     
    horizontal_plane_select_params.Fluorescence_Image = 1;
    horizontal_plane_select_params.Num_Frames = 1; % 2 for 2 images
    Modulation_List = Raman_On_Time_List;
    horizontal_plane_select_params.Modulation_Time = getScanParameter(Modulation_List,seqdata.scancycle,seqdata.randcyclelist,'Modulation_Time');
    horizontal_plane_select_params.Microwave_Or_Raman = 2; %1: uwave, 2: Raman 3:Raman with field sweep
    horizontal_plane_select_params.Sweep_About_Central_Frequency = 1;
    horizontal_plane_select_params.Resonant_Light_Removal = 0;
    horizontal_plane_select_params.Final_Transfer = 0; 
    horizontal_plane_select_params.SRS_Selection = 1;
    horizontal_plane_select_params.QP_Selection_Gradient = 0;
    horizontal_plane_select_params.Ramp_Fields_Up = 1; % ramp B field down in the begining
    horizontal_plane_select_params.Ramp_Fields_Down = 0; 
    Field_Shift_List = [0.155]; %unit G 
    horizontal_plane_select_params.Field_Shift = getScanParameter(Field_Shift_List,seqdata.scancycle,seqdata.randcyclelist,'Field_Shift','G');
    horizontal_plane_select_params.X_Shim_Offset = 0;
    horizontal_plane_select_params.Y_Shim_Offset = 0;
    horizontal_plane_select_params.Z_Shim_Offset = 0.055;0.055;%b4:0.05;
    Angle_List = [62];
    Angle = getScanParameter(Angle_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_Angle');
    horizontal_plane_select_params.Selection_Angle = Angle;62;66.5; %-30 for vertical, +60 for horizontal (iXon axes)
    %Kill pulse uses the shim fields for quantization, atom removal may
    %be poor for angles much different from 0deg!!
    
    %break thermal stabilization by turn off AOM
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);
        
    ScopeTriggerPulse(curtime,'Raman Beams On');
      
curtime = do_horizontal_plane_selection(curtime, horizontal_plane_select_params);

 dispLineStr('do_horizontal_plane_selection execution finished at',curtime);

    %turn on optical pumping beam AOM for thermal stabilization
    setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);
    
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 20/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 20/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 20/atomscale); %30?
% 
%     lattice_hold_time_list = [0 10 20];%50 sept28
%     lhtime = getScanParameter(lattice_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'lhtime');
%     curtime = calctime(curtime,lhtime);

end





%% Moving on
    
%RHYS - Which hold time is this?
%Hold time in lattices

% Track this down and possibly delete if it is redunant or make the code
% more obvious because this is just  random line of code
curtime = calctime(curtime,lattice_holdtime);




%% High Field transfers + Imaging
if seqdata.flags.High_Field_Imaging
    dispLineStr('Ramping High Field in Lattice',curtime);

    if do_plane_selection   
        error('PLANE SELECTION AND HF IMAGING MAY MAKE THE FB COIL TOO HOT')
    end
    
    ScopeTriggerPulse(curtime,'Lattice HF');

    time_in_HF_imaging = curtime;
    HF_FeshValue_Initial = getChannelValue(seqdata,'FB current');
    seqdata.params.HF_probe_fb = HF_FeshValue_Initial;
    addOutputParam('HF_FeshValue_Initial_Lattice',HF_FeshValue_Initial,'G');
    zshim = 0;
    
    % Get the calibrated magnetic field
    Boff = 0.11;
    B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;       
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% High Field Flags %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    % Lattice ramps
    lattice_ramp_init               = 1;       % Initial lattice ramp
    lattice_ramp_2                  = 0;       % Secondary lattice ramp
    lattice_ramp_3                  = 0;       % between raman and rf spectroscopy

    % Feshbach field ramps
    field_ramp_init                 = 1;       % Ramp field away from initial  
    field_ramp_2                    = 0;       % ramp field after raman before rf spectroscopy
    field_ramp_img                  = 1;       % Ramp field for imaging

    % Apply a phatom Raman pulse to kill atoms
    do_raman_phantom                = 0;

    % RF Pre Flip 9<-->7
    rf_97_flip_init                 = 0;
    
    % Raman Spectroscopy
    do_raman_spectroscopy           = 1; 
    raman_short_sweep               = 0;
    do_raman_spectroscopy_post_rf   = 0;

    spin_flip_7_5                   = 0;   

    % RF Spectroscopy
    rf_rabi_manual                  = 0;
    do_rf_spectroscopy              = 0; 
    
    % Other RF Manipulations
    shift_reg_at_HF                 = 0;
    spin_flip_9_7_5                 = 0;
    spin_flip_9_7_post_spectroscopy = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare initial lattice, field, and spin %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Lattice ramp
    if lattice_ramp_init        
        
        % Select the depth to ramp
        HF_latt_depth_list = [200];
        HF_latt_depth = getScanParameter(HF_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_depth','Er');

        % How quickly to ramp
        HF_latt_ramptime_list = [50];
        HF_latt_ramptime = getScanParameter(HF_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_ramptime','ms');
        
        % Ramp the powers
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, 245);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, HF_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, 200); 
    end   
     
    % Feshbach ramp
    if field_ramp_init
        % Feshbach Field ramp
        HF_FeshValue_Initial_List =[201.1];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_Lattice','G');

        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_zshim_Initial_Lattice','A');

                  % Define the ramp structure
                ramp=struct;
                ramp.shim_ramptime = 150;
                ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
                ramp.xshim_final = seqdata.params.shim_zero(1); 
                ramp.yshim_final = seqdata.params.shim_zero(2);
                ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
                % FB coil 
                ramp.fesh_ramptime = 150;
                ramp.fesh_ramp_delay = 0;
                ramp.fesh_final = HF_FeshValue_Initial; %22.6
                ramp.settling_time = 50;    
    curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
            ScopeTriggerPulse(curtime,'FB_ramp');

        seqdata.params.HF_fb = HF_FeshValue_Initial;
        seqdata.params.HF_probe_fb = HF_FeshValue_Initial;

    end
        
    % Phantom raman pulse
    if do_raman_phantom

    Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

    % 
    B = HF_FeshValue_Initial_List;

    Raman_AOM3_freq_list =  [1]/2+(80+...
        abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6))/2; %-0.14239

    Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
    Raman_AOM3_pwr_list = [0.33];
    Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
%         RamanspecMode = 'sweep';
    RamanspecMode = 'pulse';
    RamanMode = RamanspecMode;


    %R3 beam settings
    switch RamanspecMode
        case 'sweep'
            Sweep_Range_list = [10]/1000;  %in MHz
            Sweep_Range = getScanParameter(Sweep_Range_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
            Sweep_Time_list = [1]; %1 in ms
            Sweep_Time = getScanParameter(Sweep_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

            str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
            Raman_on_time = Sweep_Time;

        case 'pulse'
            Pulse_Time_list = [0.1];
            Pulse_Time = getScanParameter(Pulse_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
            Raman_on_time = Pulse_Time; %ms
            str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                Raman_AOM3_freq, Raman_AOM3_pwr);
    end
    addVISACommand(Device_id, str);

    %R2 beam settings
    Device_id = 1;
    Raman_AOM2_freq = 80*1E6;

    Raman_AOM2_pwr_list = 0.4;
    Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

    Raman_AOM2_offset = 0;
    str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

    addVISACommand(Device_id, str);


    %Raman spectroscopy AOM-shutter sequence
    %we have three TTLs to independatly control R1, R2 and R3
    raman_buffer_time = 10;
    shutter_buffer_time = 5;

        if Pulse_Time == 0
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',...
                Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',...
                Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter

            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',...
                Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',...
                Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter

            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep
        else
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

            setDigitalChannel(calctime(curtime,Raman_on_time+ ...
                raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

        end
curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);

    end   

    % RF Sweep -9 to -7
    if rf_97_flip_init
        clear('sweep');
        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        rf_list =  [0.00] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF_pre_spec');
        sweep_pars.power =  [2.5];
        delta_freq =0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 100;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Display the sweep settings
        disp(['RF Transfer Freq Center    (MHz) : [' num2str(sweep_pars.freq) ']']);
        if (sweep_pars.freq < 1)
            error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end        
curtime = calctime(curtime,35);
    end

    % Lattice ramp
    if lattice_ramp_2
        HF_Raman_latt_depth_list = [50];
        HF_Raman_latt_depth = getScanParameter(HF_Raman_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_latt_depth','Er');

        HF_Raman_latt_ramptime_list = [50];
        HF_Raman_latt_ramptime = getScanParameter(HF_Raman_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_latt_ramptime','ms');
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, HF_Raman_latt_depth);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, HF_Raman_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, HF_Raman_latt_depth); 
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Perform Spectroscopy Measurements %%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Raman spectrscopy
    if do_raman_spectroscopy

        mF1=-9/2;   % Lower energy spin state
        mF2=-7/2;   % Higher energy spin state

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;

        Raman_AOM3_freq_list =  [0:5:110]*1e-3/2+(80+...   %-120 -162.5:2.5:-140  -180:5:-120
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; %-0.14239

        if (abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        Raman_AOM3_pwr_list = 0.36;
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
    
%           RamanspecMode = 'sweep';
        RamanspecMode = 'pulse';
        
        % R3 beam settings
        switch RamanspecMode
            case 'sweep'
                Sweep_Range_list = [10]/1000;  %in MHz
                Sweep_Range = getScanParameter(Sweep_Range_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
                Sweep_Time_list = [1]; %1 in ms
                Sweep_Time = getScanParameter(Sweep_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

                str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                    Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                Raman_on_time = Sweep_Time;
                Pulse_Time = Sweep_Time;

            case 'pulse'
                Pulse_Time_list =[0.06];
                Pulse_Time = getScanParameter(Pulse_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                Raman_on_time = Pulse_Time; %ms
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        end


        addVISACommand(Device_id, str);

        % R2 beam settings
        if ~Raman_transfers     %Rigol cannot be programmed more than once in a sequence
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list =0.50;
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
                seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
                Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

        end 

        raman_old= 1; 
        if raman_old
            %Raman spectroscopy AOM-shutter sequence
            %we have three TTLs to independatly control R1, R2 and R3
            raman_buffer_time = 10;
            shutter_buffer_time = 5;

            if Pulse_Time == 0
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter

                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter

                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep
            else
                setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                setDigitalChannel(calctime(curtime,Raman_on_time+ ...
                    raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

            end
curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);
    else

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
        raman_buffer_time = 10;
        shutter_buffer_time = 5;

        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2',0); %turn off R2 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',0); %turn off R2 AOM

        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3',0); %turn off R3 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',0); %turn off R3 AOM

        setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman Shutter',1); %turn on shutter

        setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %turn on R2
        setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1); %turn on R2

        setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %turn on R3
        setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1); %turn on R3


        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2a',0); %turn off R2

        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 3',0); %turn off R3 after pulse
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 3a',0); %turn off R3 after pulse

curtime = calctime(curtime, Raman_on_time);

        end
    
    
    end

    % Raman spectroscopy 2
    if raman_short_sweep
        %R2 beam settings
        Device_id = 1;
        Raman_AOM2_freq = 80*1E6;

        Raman_AOM2_pwr_list = 0.3;
        Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

        addVISACommand(Device_id, str);


        %R3 beam settings

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
        B = HF_FeshValue_Initial + 2.35*zshim;

        Raman_AOM3_freq_list =  [-10:5:140]*1e-3/2+(80+...
            abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6))/2; %-0.14239

        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        Raman_AOM3_pwr_list = [0.3];
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');



            Sweep_Range_list = [5]/1000;  %in MHz
            Sweep_Range = getScanParameter(Sweep_Range_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
            Sweep_Time_list = [0.1]; %in ms, resolution = 10us
            Sweep_Time = getScanParameter(Sweep_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

        if (Sweep_Time >=1)
            %Do the normal sweep if the sweep time is greater than or equal to
            %1
            str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
            Raman_on_time = Sweep_Time;


            addVISACommand(Device_id, str);


            %Raman spectroscopy AOM-shutter sequence
            %we have three TTLs to independatly control R1, R2 and R3
            raman_buffer_time = 10;
            shutter_buffer_time = 5;

            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

            setDigitalChannel(calctime(curtime,Raman_on_time+ ...
                raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

            curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);


        else 
            %TTL sequence for shorter sweep
            Rigol_sweep_time = 1;
            Rigol_sweep_range = Rigol_sweep_time/Sweep_Time*Sweep_Range;

           str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Rigol_sweep_time, Raman_AOM3_freq, Rigol_sweep_range, Raman_AOM3_pwr);


           addVISACommand(Device_id, str);


           AOM_start_time = (Rigol_sweep_time - Sweep_Time)/2;
           AOM_end_time = (Rigol_sweep_time + Sweep_Time)/2;


            %Raman spectroscopy AOM-shutter sequence
            %we have three TTLs to independatly control R1, R2 and R3
            raman_buffer_time = 10;
            shutter_buffer_time = 5;

            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1 AOM
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2',0); %turn off R2 AOM
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',0); %turn off R2 AOM
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3',0); %turn off R3 AOM
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',0); %turn off R3 AOM

            setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman Shutter',1); %turn on shutter

            setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %Trigger R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_start_time),'Raman TTL 2a',1); %turn on R2 AOM

            setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %Trigger R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_start_time),'Raman TTL 3a',1); %turn on R3


            setDigitalChannel(calctime(curtime,Rigol_sweep_time),'Raman TTL 2',0); %turn off R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_end_time),'Raman TTL 2a',0); %turn off R2

            setDigitalChannel(calctime(curtime,Rigol_sweep_time),'Raman TTL 3',0); %turn off R3 Rigol
            setDigitalChannel(calctime(curtime,AOM_end_time),'Raman TTL 3a',0); %turn off R3 after pulse

            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + shutter_buffer_time),'Raman Shutter',0); %turn off shutter

            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 1',1); %turn back on R1 AOM
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 2',1); %turn back on R2 AOM    
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 2a',1); %turn back on R2 AOM  
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 3',1); %turn back on R3 AOM
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 3a',1); %turn back on R3 AOM      

            curtime = calctime(curtime, Rigol_sweep_time+(raman_buffer_time)*2);

         end
    end

    % RF Rabi Oscillations
    if rf_rabi_manual
        mF1=-7/2;
        mF2=-5/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;            
        rf_list =[0]+...
            (BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6;
        rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];
        power_list =  [2.5];
        rabi.power = getScanParameter(power_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF','V');            
%             rf_pulse_length_list = [0.5]/15;

        if (rabi.freq < 10)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        rf_pulse_length_list = [0.035]; 

        rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               

        % Define the frequency
        dTP=0.1;
        DDS_ID=1; 
        sweep=[DDS_ID 1E6*rabi.freq 1E6*rabi.freq rabi.pulse_length+2];


        % Preset RF Power
        setAnalogChannel(calctime(curtime,-5),'RF Gain',rabi.power);         
        setDigitalChannel(calctime(curtime,-5),'RF/uWave Transfer',0);             

        % Enable the ACync
        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,1);
            ACync_end_time = calctime(curtime,1+rabi.pulse_length+35);
            curtime=setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);                
        end         

        % Apply the RF
        if rabi.pulse_length>0                
            % Trigger the DDS 1 ms ahead of time
            DigitalPulse(calctime(curtime,-1),'DDS ADWIN Trigger',dTP,1);  
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;     

            % Turn on RF
            setDigitalChannel(calctime(curtime,0),'RF TTL',1);      

            % Advance by pulse time
            curtime=calctime(curtime,rabi.pulse_length);

            % Turn off RF
            setDigitalChannel(curtime,'RF TTL',0);   
        end

        % Lower the power
        setAnalogChannel(calctime(curtime,1),'RF Gain',-10);             

        % Extra Wait Time
        curtime=calctime(curtime,35);  
    end       

    %Do rf transfer from -7/2 to -5/2
    if spin_flip_7_5
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;

        % Get the center frequency
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
        disp(sweep_pars.freq)

        sweep_pars.power =  [-7.5];
        delta_freq = 0.020; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 1;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
     HF5_wait_time_list = [5];
     HF5_wait_time = getScanParameter(HF5_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
     curtime = calctime(curtime,HF5_wait_time);
%          sweep_pars.delta_freq  = -delta_freq; 0.025;0.1;
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
    end
        
    % Feshbach field ramp Another
    if field_ramp_2
        clear('ramp');
        HF_FeshValue_Spectroscopy_List =[199.9];
        HF_FeshValue_Spectroscopy = getScanParameter(HF_FeshValue_Spectroscopy_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Spectroscopy','G');   
        HF_FeshValue_Initial = HF_FeshValue_Spectroscopy; %For use below in spectroscopy
        seqdata.params.HF_probe_fb = HF_FeshValue_Spectroscopy; %For imaging

        % Define the ramp structure
        ramp=struct;
        ramp.FeshRampTime = 50;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = HF_FeshValue_Spectroscopy;
        ramp.SettlingTime = 50;   

    % Ramp the magnetic Fields
curtime = rampMagneticFields(calctime(curtime,0), ramp);
        
    end     

    if lattice_ramp_3
        HF_spec_latt_depth_list = [200];
        HF_spec_latt_depth = getScanParameter(HF_spec_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_depth','Er');


        HF_spec_latt_ramptime_list = [50];
        HF_spec_latt_ramptime = getScanParameter(HF_spec_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_ramptime','ms');
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, 245);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, HF_spec_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, 200);

curtime = calctime(curtime,5);  %extra wait time
    end

    % RF Sweep Spectroscopy
    if do_rf_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-9/2;   % Higher energy spin state

        
        % Get the center frequency
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        rf_list =  [37.5]*1e-3 +... %-5 0 5 10 20 30 35 32.5 37.5 40 45 50 55 35 37.5 40 42.5 45 25
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        rf_freq_HF = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        % Define the sweep parameters
        delta_freq=.01; %0.02            
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

        % RF Pulse 
        rf_pulse_length_list =1;%1
        rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_pulse_length');

        freq_list=rf_freq_HF+[...
            -0.5*delta_freq ...
            -0.5*delta_freq ...
            0.5*delta_freq ...
            0.5*delta_freq];            
        pulse_list=[2 rf_pulse_length 2];

        % Max rabi frequency in volts (uncalibrated for now)
        off_voltage=-10;
        peak_voltage=2.5;

        % Display the sweep settings
        disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
        disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
        disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
        disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


        % Set RF gain to zero a little bit before
        setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

        % Turn on RF
        setDigitalChannel(curtime,'RF TTL',1);   

        % Set to RF
        setDigitalChannel(curtime,'RF/uWave Transfer',0);   

        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-30);
            ACync_end_time = calctime(curtime,sum(pulse_list)+30);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end

        % Trigger pulse duration
        dTP=0.1;
        DDS_ID=1;

        % Initialize "Sweep", ramp up power        
        sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
        DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
        curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            pulse_list(1),pulse_list(1),peak_voltage); 

        % Primary Sweep, constant power            
        sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
        DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
        curtime=calctime(curtime,pulse_list(2));

        % Final "Sweep", ramp down power
        sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
        DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
        curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            pulse_list(1),pulse_list(1),off_voltage); 

        % Turn off RF
        setDigitalChannel(curtime,'RF TTL',0);               

        % Extra Wait Time
        curtime=calctime(curtime,35);            
    end        
               
    if do_raman_spectroscopy_post_rf
        reset_rigol=0;
        if reset_rigol 

            Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        % 
            B = HF_FeshValue_Initial;

%         Raman_AOM3_freq_list =  [-1]/2+(80+...
%             abs((BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6))/2; %-0.14239

            Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
            Raman_AOM3_pwr_list = [0.5];
            Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
    %         RamanspecMode = 'sweep';
            RamanspecMode = 'pulse';


            %R3 beam settings
            switch RamanspecMode
                case 'sweep'
                    Sweep_Range_list = [10]/1000;  %in MHz
                    Sweep_Range = getScanParameter(Sweep_Range_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
                    Sweep_Time_list = [1]; %1 in ms
                    Sweep_Time = getScanParameter(Sweep_Time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

                    str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                    Raman_on_time = Sweep_Time;

                case 'pulse'
                    Pulse_Time_list = [0.020];
                    Pulse_Time = getScanParameter(Pulse_Time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                    Raman_on_time = Pulse_Time; %ms
                    str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                        Raman_AOM3_freq, Raman_AOM3_pwr);
            end


            addVISACommand(Device_id, str);

            %R2 beam settings
            if ~Raman_transfers     %Rigol cannot be programmed more than once in a sequence
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list = 0.4;
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

            end 

       end

%             Pulse_Time_2_list = [0.5];
%             Pulse_Time_2 = getScanParameter(Pulse_Time_2_list,...
%             seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time_2','ms');
        Raman_on_time_2 = Pulse_Time; %ms 

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
        raman_buffer_time = 10;
        shutter_buffer_time = 5;

%         setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1 AOM
%         setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2',0); %turn off R2 AOM
%         setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3',0); %turn off R3 AOM
%         setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman Shutter',1); %turn on shutter
        
        setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %turn on R2
        setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1); %turn on R2

        setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %turn on R3
        setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1); %turn on R3

        
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 2a',0); %turn off R2

        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 3',0); %turn off R3 after pulse
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 3a',0); %turn off R3 after pulse

        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + shutter_buffer_time),'Raman Shutter',0); %turn off shutter
        
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 1',1); %turn back on R1 AOM
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 2',1); %turn back on R2 AOM     
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 2a',1); %turn back on R2 AOM    
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 3',1); %turn back on R3 AOM
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 3a',1); %turn back on R3 AOM
        
curtime = calctime(curtime, Raman_on_time_2+(raman_buffer_time)*2);

        % Extra Wait Time
curtime=calctime(curtime,35);  
           
           
    end   

   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Post Spectropscy Operations %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % RF shift register
    if shift_reg_at_HF
        dispLineStr('Shift register high field in Lattice',curtime);
        clear('sweep');
        B = HF_FeshValue_Initial; 
        f1 = (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
        f2 = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        rf_list =(f1+f2)/2; 
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_SR');
        sweep_pars.power =  [0];
        delta_freq = +3;-3.5; 0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;[40]; 20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'shift_reg_length');  % also is sweep length  0.5               

        disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);
        disp([' Sweep Delta      (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp([' f_low      (MHz) : ' num2str(sweep_pars.freq-0.5*sweep_pars.delta_freq)]);
        disp([' f_high      (MHz) : ' num2str(sweep_pars.freq+0.5*sweep_pars.delta_freq)]);

        n_sweeps_list=[1];
        n_sweeps = getScanParameter(n_sweeps_list,...
            seqdata.scancycle,seqdata.randcyclelist,'n_sweeps');  % also is sweep length  0.5               

        % Perform any additional sweeps
        for kk=1:n_sweeps
            disp([' Sweep Number ' num2str(kk) ]);
            curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);%3: sweeps, 4: pulse
        end     

    end
        
    % RF Sweep flip 9 <-->7 then 7<-->5
    if spin_flip_9_7_5
        clear('sweep');
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF');
        sweep_pars.power =  [0];
        delta_freq =0.2; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        clear('sweep');
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF');
        sweep_pars.power =  [0];
        delta_freq =0.2; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,15),3,sweep_pars);%3: sweeps, 4: pulse
    end
                        
    % RF Sweep
    if spin_flip_9_7_post_spectroscopy
        mF1 = -7/2;
        mF2 = -9/2;
        
        clear('sweep');
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        rf_list =  [0.0] +...
            abs(BreitRabiK(B,9/2,mF1) - BreitRabiK(B,9/2,mF2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF_post_spec');
        sweep_pars.power =  [2.5];
        delta_freq =0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 1;100;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,10);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
    end

seqdata.params.HF_probe_fb = seqdata.params.HF_fb;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare for Imaging %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Feshbach Field Ramp (imaging)
    if field_ramp_img

        % Feshbach Field ramp Field ramp
        HF_FeshValue_Final_List = 195;
        HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_Lattice','G');

        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    end

        
    % Hold time in lattice before any RF
     HF_wait_time_list = [0];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');
    
curtime = calctime(curtime,HF_wait_time);


    time_out_HF_imaging = curtime;        
    if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
        error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
    end
end

%% Ramp HF and back
ramp_HF_and_back = 0;
if ramp_HF_and_back

    %lattice ramp
    HF_latt_depth_list = [300];
    HF_latt_depth = getScanParameter(HF_latt_depth_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_latt_depth','Er');
    
    
    HF_latt_ramptime_list = [50];
    HF_latt_ramptime = getScanParameter(HF_latt_ramptime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_latt_ramptime','ms');
    AnalogFuncTo(calctime(curtime,T0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        HF_latt_ramptime, HF_latt_ramptime, HF_latt_depth);   
    AnalogFuncTo(calctime(curtime,T0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        HF_latt_ramptime, HF_latt_ramptime, HF_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        HF_latt_ramptime, HF_latt_ramptime, HF_latt_depth); 
    
    
    
    
        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List =[201];[202.78];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
        ramp.FeshValue = HF_FeshValue_Initial;
        ramp.SettlingTime = 50;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);

wait_time = 50;
curtime = calctime(curtime,wait_time);


clear('ramp');
        %FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = 0;
        HF_FeshValue_final_list = [15];
        seqdata.HF_FeshValue_final = getScanParameter(HF_FeshValue_final_list,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_final');
        ramp.FeshValue = seqdata.HF_FeshValue_final;%before 2017-1-6 100*1.08962; %22.6
        ramp.SettlingTime = 150;
        curtime = rampMagneticFields(calctime(curtime,0), ramp);

end


%% Turn off lattices and dipole traps for ToF imaging, flag name: Drop from XDT

%RHYS - Definitely change this. Fudong's addition here was useful
%(pre_lat_off_code = 0 just turns off all traps immediately), but, the name
%of this flag is not good, nor should it be set all the way down here.
pre_lat_off_code = 1; % a method to disable previous lattice off code
if (pre_lat_off_code == 0)
    dispLineStr('Diabatic lattice and dipole turn off',curtime);
    
    %Lattice Power
    P_Xlattice = 0;
    P_Ylattice = 0;
    P_Zlattice = 0;
    P_dip = 0.2;
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    
    setAnalogChannel(calctime(curtime,0),'xLattice',0);
    setAnalogChannel(calctime(curtime,0),'yLattice',0);
    setAnalogChannel(calctime(curtime,0),'zLattice',0);
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);  %0: ON / 1: OFF,yLatticeOFF
else
lattice_off_delay = 10;

%seqdata.flags. load_lattice = 0: do not load lattice
%'__' = 1: load lattice
%'__' = 2: ramp to deep lattice at the end
 
%RHYS - Lattice turn off code (snap or bandmap). Could perhaps be more
%intuitive.
 if ( seqdata.flags.load_lattice == 1 ) %shut off lattice, keep dipole trap on
    
    % Parameters for ramping down the lattice (after things have been done)
    zlat_endpower = L0(3)-1;-19;-0.2;       % where to end the ramp
    ylat_endpower = L0(2)-1;-20;-0.2;       % where to end the ramp
    xlat_endpower = L0(1)-1;-22; -0.2;       % where to end the ramp
    lat_rampdowntime =lattice_rampdown*1; % how long to ramp (0: switch off)   %1ms
    lat_rampdowntau = 1*lattice_rampdown/5;    % time-constant for exponential rampdown (0: min-jerk)
    lat_post_waittime = 0*10 ;% whether to add a waittime after the lattice rampdown (adds to timeout)

    if(~Drop_From_XDT)
        % Ramp XDTs before the lattices
        dispLineStr('Ramping down XDTs',curtime);

        dip_rampstart = -15;
        dip_ramptime = 5;
        dip_endpower = -0.2;
        
        disp([' Ramp Start (ms) : ' num2str(dip_rampstart) ]);
        disp([' Ramp Time  (ms) : ' num2str(dip_ramptime) ]);
        disp([' End Power   (W) : ' num2str(dip_endpower)]);
        
        
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_ramptime,dip_ramptime,dip_endpower);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_ramptime,dip_ramptime,seqdata.params.XDT_area_ratio*dip_endpower);
        setDigitalChannel(calctime(curtime,dip_rampstart+dip_ramptime),'XDT TTL',1); %cut lattice power for bandmapping?    
    else
        power_list = [0.1]; %0.2 sept28 0.15 sep29
        DT1_power = getScanParameter(power_list,...
            seqdata.scancycle,seqdata.randcyclelist,'lat_power_val');
        DT2_power = DT1_power;(((sqrt(DT1_power)*83.07717-0.8481)+3.54799)/159.3128)^2; %sept28
        dipole_ramp_up_time = 50;
        
        %TURNED THIS OFF SINCE NO XDT RAMPS    sept28    
        setDigitalChannel(calctime(curtime,0),'XDT TTL',0);
        %ramp dipole 1 trap on
        AnalogFuncTo(calctime(curtime,0),40,@(t,tt,y1,y2) ...
            (ramp_linear(t,tt,y1,y2)),...
            dipole_ramp_up_time,dipole_ramp_up_time,DT1_power);
        %ramp dipole 2 trap on
curtime = AnalogFuncTo(calctime(curtime,0),38,@(t,tt,y1,y2) ...
        (ramp_linear(t,tt,y1,y2)),...
        dipole_ramp_up_time,dipole_ramp_up_time,DT2_power);
    end    
        
    if ( lat_rampdowntime > 0 )
        dispLineStr('Band mapping',curtime);
        
        disp([' Band Map Time (ms) : ' num2str(lat_rampdowntime)])
        disp([' xLattice End (Er)  : ' num2str(xlat_endpower)])
        disp([' yLattice End (Er)  : ' num2str(ylat_endpower)])
        disp([' zLattice End (Er)  : ' num2str(zlat_endpower)])

        ScopeTriggerPulse(curtime,'latoff');
        % ramp down lattice (min-jerk or exponential)
        if ( lat_rampdowntau == 0 )
            % Min-jerk ramp-down of lattices
            AnalogFuncTo(calctime(curtime,0),'xLattice',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                lat_rampdowntime,lat_rampdowntime,xlat_endpower);
            AnalogFuncTo(calctime(curtime,0),'yLattice',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                lat_rampdowntime,lat_rampdowntime,ylat_endpower);
curtime =   AnalogFuncTo(calctime(curtime,0),'zLattice', ...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                lat_rampdowntime,lat_rampdowntime,zlat_endpower);
        else
            AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,lat_rampdowntime,xlat_endpower);
            AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,lat_rampdowntime,ylat_endpower);
curtime =   AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,lat_rampdowntime,zlat_endpower);

            % exponential ramp-down of lattices            
%             AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),lat_rampdowntime,lat_rampdowntime,xlat_endpower,lat_rampdowntau);
%             AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),lat_rampdowntime,lat_rampdowntime,ylat_endpower,lat_rampdowntau);
% curtime =   AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),lat_rampdowntime,lat_rampdowntime,zlat_endpower,lat_rampdowntau);
        end
    end
    
    % Finish turning off lattices and dipole traps
%     setAnalogChannel(calctime(curtime,0),'xLattice',-0.1,1);
%     setAnalogChannel(calctime(curtime,0),'yLattice',-0.1,1);
%     setAnalogChannel(calctime(curtime,0),'zLattice',-0.1,1);
    
    %TTLs
    setDigitalChannel(calctime(curtime,0),11,1);  %0: ON / 1: OFF, XLatticeOFF         
    setDigitalChannel(calctime(curtime,0),34,1);  %0: ON / 1: OFF,yLatticeOFF
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1); % Added 2014-03-06 in order to avoid integrator wind-up
    
    XDT_Holding_time_list = [150];%holding time in XDT
    XDT_Holding_time = getScanParameter(XDT_Holding_time_list,seqdata.scancycle,seqdata.randcyclelist,'xdtht');%maximum is 4
      
    if ( Drop_From_XDT )%loaded back into XDT
        setAnalogChannel(calctime(curtime,XDT_Holding_time),'dipoleTrap1',0,1);
        setAnalogChannel(calctime(curtime,XDT_Holding_time),'dipoleTrap2',0,1);
curtime = setDigitalChannel(calctime(curtime,XDT_Holding_time),'XDT TTL',1);
    else
%         setAnalogChannel(calctime(curtime,0.0),'dipoleTrap1',0,1);
%         setAnalogChannel(calctime(curtime,0.0),'dipoleTrap2',0,1);
%         setDigitalChannel(calctime(curtime,0),'XDT TTL',1);        
    end
    
    
    
% % % % % % % % % % % %     %Rotate waveplate to divert all power to dipole traps.
% % % % % % % % % % % %     AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_RotWave,0); 
% % % % % % % % % % % %     P_RotWave = 0;
% % % % % % % % % % % %     
% % % % % % % % % % % %     % wait after lattice was ramped down (if lattice was ramped down)
% % % % % % % % % % % % curtime = calctime(curtime,lat_post_waittime);
    
% At the end of this sequence, the lattice should be off and ALPS3 disabled

% Optical powers to pass out of function
    %Dipole power
    if dipole_trap_off_after_lattice_on == 0;
        P_dip = dip_endpower;
    elseif dipole_trap_off_after_lattice_on == 1;
        P_dip = 0;
    elseif dipole_trap_off_after_lattice_on == 2;
        P_dip = 0;
    elseif dipole_trap_off_after_lattice_on == 3;
        P_dip = 0;
    elseif dipole_trap_off_after_lattice_on == 4;
        P_dip = 0;
    end
    %Lattice Power
    P_Xlattice = 0;
    P_Ylattice = 0;
    P_Zlattice = 0;

%RHYS - Not sure what these other options are good for.
elseif ( seqdata.flags.load_lattice == 2 ); %leave lattice and dipole trap on and pass powers out of function
    
        %Optical powers to pass out of function
        %Dipole power
        P_dip = dip_endpower;
        %Lattice Power
        P_Xlattice = getChannelValue(seqdata,'xLattice');
        P_Ylattice = getChannelValue(seqdata,'yLattice');
        P_Zlattice = getChannelValue(seqdata,'zLattice');
        
 elseif (seqdata.flags.load_lattice == 3)
        xdt_off_time=0;
        lattice_off_time=10;
        setAnalogChannel(calctime(curtime,xdt_off_time),'dipoleTrap1',0,1);
        setAnalogChannel(calctime(curtime,xdt_off_time),'dipoleTrap2',0,1);
        setDigitalChannel(calctime(curtime,xdt_off_time),'XDT TTL',1);

        setAnalogChannel(calctime(curtime,lattice_off_time),'xLattice',0);
        setAnalogChannel(calctime(curtime,lattice_off_time),'yLattice',0);
        setAnalogChannel(calctime(curtime,lattice_off_time),'yLattice',0);
        setDigitalChannel(calctime(curtime,lattice_off_time),'yLatticeOFF',0);
        curtime=calctime(curtime,lattice_off_time);
       
    
end
end
%% Output

seqdata.times.lattice_end_time = curtime;

timeout = curtime;

end