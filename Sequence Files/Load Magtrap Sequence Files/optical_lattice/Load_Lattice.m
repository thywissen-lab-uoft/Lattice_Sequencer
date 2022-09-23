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

spin_mixture_in_lattice_before_plane_selection = 0; % (668)             keep : Make a -9/2,-7/2 spin mixture.   
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lattice Ramps and Waveplates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_rotate_waveplate_1 = 1;        % First waveplate rotation for 90%
do_lattice_ramp_1 = 1;            % Load the lattices

do_lattice_mod = 0;               % Amplitude modulation spectroscopy             

do_rotate_waveplate_2 = 1;        % Second waveplate rotation 95% 
do_lattice_ramp_2 = 1;            % Secondary lattice ramp for fluorescence imaging

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
Drop_From_XDT = 0;                      %  (97,5187,5257) May need to add code to rotate waveplate back here.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conductivity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags are associated with the conducitivity experiment
do_conductivity = 0;       % (747-1536) keep: the real conductivity experiment happens here 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RF/uWave Spectroscopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_K_uwave_spectroscopy2 = 0;           % (3497)
do_K_uwave_spectroscopy = 0;            % (3786) keep
do_Rb_uwave_spectroscopy = 0;           % (3929)
do_RF_spectroscopy = 0;                 % (3952,4970)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DMD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection, Raman Transfers, and Fluorescence Imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
do_optical_pumping = 0;                 % (1426) keep : optical pumping in lattice  
do_plane_selection = 0;                             % Plane selection flag

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
   lattice_holdtime_list =[0]; [150];
   % Minimum value is stupidly set by the fact that the XDT ramp down go
   % backwards in time.  This should be changed.
   lattice_holdtime = getScanParameter(lattice_holdtime_list,...
       seqdata.scancycle,seqdata.randcyclelist,'latt_holdtime','ms');%maximum is 4
 
end

lattice_rampdown_list = [3]; %0 for snap off (for in-situ latice postions for alignment)
                             %3 for band mapping
if Drop_From_XDT
    lattice_rampdown = 50;
else
    lattice_rampdown = getScanParameter(lattice_rampdown_list,...
        seqdata.scancycle,seqdata.randcyclelist,'latt_rampdown_time','ms'); %Whether to down a rampdown for bandmapping (1) or snap off (0) - number is also time for rampdown
end

%% Rotate waveplate to shift power to lattice beams
% Rotate the waveplate to shift the optical power to the lattices.

if do_rotate_waveplate_1
    dispLineStr('Rotating waveplate',curtime);
    %Start with a little power towards lattice beams, and increase power to
    %max only after ramping on the lattice
    
    %Turn rotating waveplate to shift a little power to the lattice beams
    wp_Trot1 = 600; % Rotation time during XDT
    
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
end
%% Lattice Ramp 1
% Ramp the lattices up to the starting values.  The ramp procedue can
% either be multi step or single step.
if do_lattice_ramp_1    
    dispLineStr('Defining initial lattice and DMD ramps.',curtime);
    ScopeTriggerPulse(curtime,'lattice_ramp_1');

    % Lattice depth and ramp times
    L0=seqdata.params.lattice_zero;  
    
    % Get the optical evaporation ending power
    dip_endpower = 1.0*getChannelValue(seqdata,'dipoleTrap1',1,0);        
    
    % Ramp Mode
    rampMode=0;    
    % 0 : Ramp only the lattice
    % 1 : Ramp lattice,XDT,and DMD
    % 2 : Simple ramp used to measure the lattice alignment
   
    % DMD
    do_DMD=0;    

    switch rampMode
        case 0 
            % Ramp only the lattices in a multistep seqeunce.
            % This is the "typical" ramp sequence that we perform;
            % Typically this involves a ramp to a moderate depth followed
            % by a quick snap to a pinning lattice depth
            
            % Initial lattice depth
            initial_latt_depth_list = [10];%10;
            init_depth = getScanParameter(initial_latt_depth_list,...
                seqdata.scancycle,seqdata.randcyclelist,...
                'initial_latt_depth','Er');
            
            % Final lattice depth to ramp to
            U = 100;
            
            %%% Lattice %%%
            % Ramp the optical powers of the lattice
            latt_depth=...
                [init_depth init_depth U U;     % X lattice
                 init_depth init_depth U U;     % Y lattice
                 init_depth init_depth U U];    % Z Lattice 
             
             % Initial ramp on time
             latt_ramp_time_list = [150];
             latt_ramp_time = getScanParameter(latt_ramp_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_ramp_time','ms');

            latt_times=[latt_ramp_time 50 0.2 50];
            
            %%% XDT %%%
            % Keep the powers constant            
            dip_pow=dip_endpower;
%             dip_times=[1];            
            dip_pow=[dip_endpower,dip_endpower,dip_endpower,dip_endpower];
            dip_times=latt_times;  

            %%% DMD is fixed %%%
            dmd_pow=0;
            dmd_times=[1];
        case 1 % Ramp everything
                
            % Hold in lattice
            latt_hold_time_list = [50];
            latt_hold_time = getScanParameter(latt_hold_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,...
                'lattice_hold_time','ms');         
            
            %%% Lattice %%%
            latt_depth=...
                 [L0(1) L0(1);
                   L0(2) L0(2);   % y lattice
                   L0(3) L0(3)];    % Z Lattice
            latt_times=[100 latt_hold_time];
            
            latt_XDT_pow_list = [seqdata.params.ODT_zeros(1)];
            latt_XDT_pow = getScanParameter(latt_XDT_pow_list,...
                seqdata.scancycle,seqdata.randcyclelist,'latt_XDT_pow','V');
            %%% XDT %%%
            dip_pow=[dip_endpower latt_XDT_pow];
            dip_times=[150 50];   
     
            %%% DMD %%%
            
            DMD_power_val_list = [1.25]; %2V is roughly the max now 
            DMD_power_val = getScanParameter(DMD_power_val_list,...
                seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val','V');

            dmd_pow=[DMD_power_val DMD_power_val 0];
            dmd_times=[100 50 50];
        case 2 
            % For Alignment of the lattices
            % This ramp ramps the XDT powers down while ramping up only one
            % of the lattices.  Compare the XDT insitu position to the
            % insitu position measured here. (Use a TOF~0);
            % This also is used for lattice alignment with the ixon.
            
            U_align = 100; % Lattice depth to align to
            % Simple square ramp of only one lattice 
            
            %Select the lattice direction to load
%             direction = 'X';
%             direction = 'Y';
            direction = 'Z';
            switch direction
                case 'X'
                  latt_depth=...
                     [U_align U_align; % X lattice
                     L0(2) L0(2);  % Y lattice
                     L0(3) L0(3)];    % Z Lattice
                case 'Y'
                  latt_depth=...
                     [L0(1) L0(1); % X lattice
                     U_align U_align;  % Y lattice
                     L0(3) L0(3)];    % Z Lattice
                case 'Z'
                  latt_depth=...
                     [L0(1) L0(1); % X lattice
                     L0(2) L0(2);  % Y lattice
                     U_align U_align];    % Z Lattice
            end
            
            % Lattice Ramp Times
            latt_ramp_time_list = [150];
            latt_ramp_time = getScanParameter(latt_ramp_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,...
                'latt_ramp_time','ms');
            latt_times=[latt_ramp_time 150];
            
            % XDT Power
            latt_XDT_pow_list = [seqdata.params.ODT_zeros(1)];
            latt_XDT_pow = getScanParameter(latt_XDT_pow_list,...
                seqdata.scancycle,seqdata.randcyclelist,...
                'latt_XDT_pow','V');
            
            %%% XDT Power and Time Vector %%%
            dip_pow=[dip_endpower latt_XDT_pow];
            dip_times=[150 50];   
            
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Initialize PID Settings %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Preset analog and digital channels to prepare for lattice turn on
    

    % Set lattice feedback offset (double PD configuration)
    setAnalogChannel(calctime(curtime,-60),'Lattice Feedback Offset', -9.8,1);
    
    % Send request powers to -10V to rail the PID at the lower end
    setAnalogChannel(calctime(curtime,-60),'xLattice',-10,1);
    setAnalogChannel(calctime(curtime,-60),'yLattice',-10,1);
    setAnalogChannel(calctime(curtime,-60),'zLattice',-10,1);

    % Enable AOMs on the lattice beams
    setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off
    
    % Integrator hold is depreciated now?
    setDigitalChannel(calctime(curtime,-100),'Lattice Direct Control',0); % 0 : Int on; 1 : int hold    

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Lattice Ramps %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % The first ramp bring the lattices to an acceptable 0Er level which
    % the PID regulates in the first 20 ms
    
    % First ramp from zero value to first value
    T0=0;

    % Ramp xLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,T0-20),'xLattice',L0(1));
    AnalogFuncTo(calctime(curtime,T0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(1,1));
      
    % Ramp yLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,T0-20),'yLattice',L0(2));
    AnalogFuncTo(calctime(curtime,T0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(2,1));   
    
    % Ramp zLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,T0-20),'zLattice',L0(3));
    AnalogFuncTo(calctime(curtime,T0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        latt_times(1), latt_times(1), latt_depth(3,1));   
    
    T0=latt_times(1);
    
    % Perform the rest of the lattice ramps
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

    % Perform first dipole trap framp
    
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


%% Ramp down HF used for loading lattice (this flag is in dipole transfer)

if seqdata.flags.ramp_up_FB_for_lattice
dispLineStr('Ramping FB field (not sure why?).',curtime);

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

%% conductivity modulation without dimple
%RHYS - This is the code for the conductivity experiment. Should probably
%keep for now, just clean up. A very long code: make its own module, delete
%all the commented crap.

if (do_conductivity == 1 )
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
    if ((ramp_up_FB_after_evap == 1 || ...
            ramp_up_FB_after_latt_loading ==1 || ...
            ramp_up_FB_during_mod_ramp == 1 ) && ...
            (do_plane_selection == 0))
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



%% Optical Pumping
% Optical pumping

if (do_optical_pumping == 1)
    dispLineStr('Optical Pumping.',curtime);

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
    D1op_pwr_list = [10]; %min: 0, max:10 %5
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'latt_D1op_pwr'); 
    
    % Determine the requested frequency offset from zero-field resonance
    frequency_shift = (4)*2.4889;(4)*2.4889;
    Selection_Angle = 62.0;
    addOutputParam('Selection_Angle',Selection_Angle)

    %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
    Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  
    %Conversion from Shim Values (Amps) to frequency (MHz) to

    
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
end


%% Plane selection
% After loading the optical lattice, we want to elminate all atoms not in
% the desired plane. This is done by performing the following operations :
%
% (1) Ramp Field  : Apply a vertical gradient with the QP and FB coils
% (2) uWave Sweep : Transfer one plane to the 7/2 manifold
% (3) D2 Pulse    : Kill 9/2 atoms with resonant D2 light 
% (4) uWave Sweep : Transfer 7/2 plane back to 9/2 manifold
%
% The direction of the field gradient can also be accurately measured with
% by applying a small shim field and measuring the "stripes"
% 
% (Descriptions to follow)

%%Remove atoms in undesired vertical planes from the lattice.
%RHYS - This code is a doozy of a mess. See Graham's
%do_fast_plane_selection for ideals of modularizing. Should definitely be a
%separate module at the least. 

if do_plane_selection
    dispLineStr('Plane Selection',curtime);
    
    % Transfer atoms to |7/2,-7/2> initially. Do we need this??  
    initial_transfer = 0;   
    
    % Ramp up lattices for plane selection (typically unesasaary)
    planeselect_doPinLattices = 0; 
    
    % Establish field gradeint with QP, FB, and shim fields for plane selection
    ramp_fields = 1; 
    
    % Do you want to fake the plane selection sweep?
    %0=No, 1=Yes, no plane selection but remove all atoms.
    fake_the_plane_selection_sweep = 0; 
        
    % Pulse the vertical D2 kill beam to kill untransfered F=9/2
    planeselect_doVertKill = 1;

    % Transfer back to -9/2 via uwave transfer
    planeselect_doMicrowaveBack = 0;    
 
    % Pulse repump to remove leftover F=7/2
    planeselect_doFinalRepumpPulse = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply pinning lattice for plane selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Increase the lattice depth to pin the atoms
    % Typically unecessary as you have already pinned them
    if planeselect_doPinLattices
        disp('Ramping lattices and dipole traps.');
        setDigitalChannel(calctime(curtime,-0.1),'yLatticeOFF',0);
        
        % Ramp Lattices
        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5,60); 
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60); 
        
        % Ramp dipole traps
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ramp magnetic field for planes selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply a field gradient to make a spatially dependent Zeeman shift
    % that allows us to selectively choose a single plane.
    
    FB_init = getChannelValue(seqdata,37,1,0);
    if ramp_fields
        % Ramp the SHIMs, QP, and FB to the appropriate level  
        disp(' Ramping fields');
        clear('ramp');       
        
        xshimdlist = -0.257;
%         xshimdlist = 3;

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
        fb_shift_list = [.6];[0.6];[0.56];%0.2 for 0.7xdt power
        fb_shift = getScanParameter(fb_shift_list,seqdata.scancycle,...
            seqdata.randcyclelist,'fb_shift');
        ramp.fesh_final = 128-fb_shift;125.829-fb_shift; 
        
        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 100;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  14*1.78; %7 %210G/cm
        ramp.settling_time = 300; %200
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % uWave Settings for Plane Selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This should be cleaned up a lot, yes it should
    
    planeselect_freq = 1606.75;
    spect_pars.freq = planeselect_freq;   % |9/2,-9/2>
    spect_pars.power = 15;15;%6.5; %-15 %uncalibrated "gain" for rf
    
    ffscan_list = [100]/1000;%frequency sweep width
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
%  spect_pars.AM_ramp_time = 9; %Used for pulse_type = 1      2*16.7

    use_ACSync = 1;

    % Define the SRS frequency
    freq_list = [355];[340];[-300];       
    
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
    setDigitalChannel(calctime(curtime,-20),'SRS Source',1);  

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Transfer atoms to |7/2,-7/2> initially.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CORA - Is this historical, can we delete it? Accroding to VV

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
       
ScopeTriggerPulse(curtime,'Plane Select');
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plane select via uWave application
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply microwaves inconjuction with a frequency or magnetic field
    % sweep to transfer atoms from the F=9/2 manifold to the F=7/2 in a
    % specific plane.
    
    if (sweep_field == 0) %Sweeping frequency of SRS
        disp('Using SRS to plane select');
    
        disp('HS1 Sweep Pulse');
        
        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta',beta);
        
        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp',env_amp);


        % Determine the range of the sweep
        uWave_delta_freq_list= [130] /1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq','kHz');
        
        
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
        if  ~fake_the_plane_selection_sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        end
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);
        
        if  ~fake_the_plane_selection_sweep
        % Sweep the VVA (use voltage func 2 to invert the vva transfer
        % curve (normalized 0 to 10
        AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp,2);
        end
        
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

    elseif (sweep_field == 1) % Sweeping field with z Shim, SRS frequency is fixed
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Vertical Kill Beam Application
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
    % Apply a vertical *upwards* D2 beam resonant with the 9/2 manifold to 
    % remove any atoms not transfered to the F=7/2 manifold.

    if planeselect_doVertKill==1
        dispLineStr('Applying vertical D2 Kill Pulse',curtime);

        %Resonant light pulse to remove any untransferred atoms from
        %F=9/2
        kill_time_list = [1];2;
        kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'kill_time','ms'); %10 
        kill_detuning_list = [42.7];%42.7
        kill_detuning = getScanParameter(kill_detuning_list,...
            seqdata.scancycle,seqdata.randcyclelist,'kill_det');        

        %Kill SP AOM 
        mod_freq =  (120)*1E6;
        mod_amp = 1;0.05;0.1;
        mod_offset =0;
        str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
        addVISACommand(8, str);  %Device 8 is the new kill beam Rigol changed on July 10, 2021

        % Display update about
        disp(' D2 Kill pulse');
        disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
        disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
        disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
        disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 

        % Offset time of pulse (why?)
        pulse_offset_time = -5;       
                                  
        if kill_time>0
            % Set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,pulse_offset_time-50),...
                'K Trap FM',kill_detuning); %54.5

            % Turn off kill SP (0= off, 1=on)(we keep it on for thermal stability)
            setDigitalChannel(calctime(curtime,pulse_offset_time-20),...
                'Kill TTL',0);

            % Open K Kill shutter (0=closed, 1=open)
            setDigitalChannel(calctime(curtime,pulse_offset_time-5),...
                'Downwards D2 Shutter',1);     

            % Pulse K Kill AOM
            DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',...
                kill_time,1);

            % Close K Kill shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+2),...
                'Downwards D2 Shutter',0);

            % Turn on kill SP (thermal stability)
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+5),...
                'Kill TTL',1);
            
            % Advance Time
            curtime=calctime(curtime,pulse_offset_time+kill_time+5);
        end
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % uWave Transfer back to |9/2,-9/2>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    if planeselect_doMicrowaveBack
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
        if (followup_repump_pulse)
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Repump to kill F=7/2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    if planeselect_doFinalRepumpPulse
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
        
%       %First, ramp on a quantizing shim.
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -0;
        
        ramp.xshim_final = 0.1585; 
        ramp.yshim_final = -0.0432;
        ramp.zshim_final = -0.0865; 
        addOutputParam('shim_value',ramp.zshim_final - getChannelValue(seqdata,28,1,0))        

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_off_delay = 0;
        
        ramp.fesh_final = 20.98111;
        
        ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
        
% %         % QP coil settings for spectroscopy
%         ramp.QP_ramptime = 50;
%         ramp.QP_ramp_delay = -0;
%         ramp.QP_final =  0*1.78; %7
        ramp.settling_time = 200;200;     
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
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
    freq_list = [0] ;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_freq_offset','kHz');
    
    disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);
    
    % SRS settings (may be overwritten later)
    uWave_opts=struct;
    uWave_opts.Address=28;                       % K uWave ("SRS B");
    uWave_opts.Frequency=1338.345 + freq_offset/1000;   % Frequency in MHz

    % Need these shim and FB values
%   ramp.xshim_final = 0.1585; 
%   ramp.yshim_final = -0.0432;
%   ramp.zshim_final = -0.0865; 
%   ramp.fesh_final = 20.98111;
    
    uWave_opts.Power=15;%12 15                      % Power in dBm
    uWave_opts.Enable=1;                         % Enable SRS output    

    addOutputParam('uwave_pwr',uWave_opts.Power,'dBm')
    addOutputParam('uwave_frequency',uWave_opts.Frequency,'MHz');    
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
    
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);

    % RF Switch for K SRS depreciated?
    setDigitalChannel(calctime(curtime,-20),'K uWave Source',1);  
    
    
    setDigitalChannel(calctime(curtime,-20),'SRS Source',1);  
    
    % Set initial modulation
    setAnalogChannel(calctime(curtime,-50),'uWave FM/AM',-1);
    
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
        
        
        uWave_delta_freq_list=[50];
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq','kHz');
        
        uwave_sweep_time_list =[50]; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq*1e-3;   

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
        uWave_delta_freq_list=[10]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq');
        
        
        uwave_sweep_time_list =[50]; 
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

%           uwave_wait_list = [50 100 150 200 250 300 400 500];[200];
%             uwave_wait = getScanParameter(uwave_wait_list,seqdata.scancycle,...
%                 seqdata.randcyclelist,'uwave_wait');
%             
%             curtime = calctime(curtime,uwave_wait);
            
if do_K_uwave_spectroscopy
    dispLineStr('Performing K uWave Spectroscopy',curtime);
    clear('spect_pars');

    freq_list = [0]/1000;[20]/1000;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'freq_val');

    %Currently 1390.75 for 2*22.6.
    spect_pars.freq = 1335.845 +2.5+ freq_offset;

    uwavepower_list = [15];[15];%15
    uwavepower_val = getScanParameter(uwavepower_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwavepower_val','dBm');
    
    uwavedeltafreq_list = [200]/1000;[1000]/1000;
    uwavedeltafreq_val = getScanParameter(uwavedeltafreq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwavedeltafreq_val','MHz');

    spect_pars.power = uwavepower_val; % 15 %dBm
    spect_pars.delta_freq = uwavedeltafreq_val;  % 1000/1000;
    spect_pars.mod_dev = spect_pars.delta_freq;

    pulse_time_list =[30];40;[spect_pars.delta_freq*1000/5]; %Keep fixed at 5kHz/ms.
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
            field_shift_time = 5;5;
            
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

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
%change curtime for testing F pump
% curtime = calctime(curtime,20);

        do_second_sweep = 0;
        if do_second_sweep
            %Perform a second microwave sweep
            
            uwave_wait_list = [200];[200];
            uwave_wait = getScanParameter(uwave_wait_list,seqdata.scancycle,...
                seqdata.randcyclelist,'uwave_wait');
            
            curtime = calctime(curtime,uwave_wait);
            
            if do_field_sweep
                %Take frequency range in MHz, convert to shim range in Amps
                %  (-5.714 MHz/A on Jan 29th 2015)
                dBz = spect_pars.delta_freq / (-5.714); 

                field_shift_offset = 25;
                field_shift_time = 5;5;

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
        
        if use_ACSync
                % Enable ACync 10ms before pulse
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay-15);
                % Disable ACync 150ms after pulse
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    spect_pars.pulse_length + 150);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            
        end
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);

        end

ScopeTriggerPulse(curtime,'K uWave Spectroscopy');

curtime = calctime(curtime,25);

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
    ramp_fields = 0; % do a field ramp for spectroscopy
    
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
        ramp.fesh_final = 20;%before 2017-1-6 0.25*22.6; %18 %0.25
        
        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 50;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  0; %18
        ramp.settling_time = 200;
      
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
    
end
 
%% Amplitude Modulation Spectroscopy of Lattice
% This code applies amplitude modulation to XYZ optical lattices.  This is
% done by programming a Rigol generator that goes into the sum input of the
% Newport regulation boxes.

if do_lattice_mod
    if seqdata.flags.mix_at_beginning
        error('DONT DO AM SPEC WITH A SPIN MIXTURE!!')
    end
    
    dispLineStr('Amplitude Modulation Spectroscopy',curtime)
    
    lattice_ramp = 1; %if we need to ramp up the lattice for am spec
    if lattice_ramp
        AM_spec_latt_depth = paramGet('AM_spec_depth');
        AM_spec_direction = paramGet('AM_direction');
        
        AM_spec_latt_ramptime_list = [50];
        AM_spec_latt_ramptime = getScanParameter(AM_spec_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'AM_spec_latt_ramptime','ms');
 

 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth); 
        
            x_latt_voltage = getChannelValue(seqdata,'xLattice',1,1);
            y_latt_voltage = getChannelValue(seqdata,'yLattice',1,1);
            z_latt_voltage = getChannelValue(seqdata,'zLattice',1,1);    
            
            disp(x_latt_voltage);
            disp(y_latt_voltage);
            disp(z_latt_voltage);            
            
            addOutputParam('adwin_am_spec_X',x_latt_voltage);
            addOutputParam('adwin_am_spec_Y',y_latt_voltage);
            addOutputParam('adwin_am_spec_Z',z_latt_voltage);

curtime = calctime(curtime,50);  %extra wait time
    end
        
    % Turn off ODTs before modulation (if not already off)
    switch_off_XDT_before_Lat_modulation = 0;
    if (switch_off_XDT_before_Lat_modulation == 1) 
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
curtime = calctime (curtime,50);
    end 
 
    mod_freq = paramGet('AM_spec_freq');    
    mod_time = 3;%0.2; %Closer to 100ms to kill atoms, 3ms for band excitations only. 

    % OFF Channel settings
    ch_off = struct;
    ch_off.STATE = 'OFF';
    ch_off.AMPLITUDE = 0;
    ch_off.FREQUENCY = 1;

    % ON Channel Settings
    ch_on=struct;
    ch_on.FREQUENCY=mod_freq;     % Modulation Frequency
    ch_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
    ch_on.SWEEP='OFF';
    ch_on.MOD='OFF';
    ch_on.BURST='ON';             % Burst MODE 
    ch_on.BURST_MODE='GATED';     % Trig via the gate
    ch_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
    ch_on.BURST_TRIGGER='EXT';    % External trigger.    
    ch_on.STATE = 'ON';
    
    addr_mod_xy = 9; % ch1 x mod, ch2 y mod
    addr_z = 5; %ch1 z lat, ch2 z mod  
    switch AM_spec_direction    
        case 'X'            
            m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            X_prefactors =[
                50 112  0.17;
                100 165 0.275;
                200 240 0.44;
                300 297 0.52;];

            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(X_prefactors(:,1),X_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');

            % Shift for frequency dependence
            mod_amp = mod_amp+d_amp;            

  
            % Program the Rigols for modulation
            ch_on.AMPLITUDE = mod_amp;
            programRigol(addr_mod_xy,ch_on,ch_off); % turn on x mod, turn off y mod
            programRigol(addr_z,[],ch_off);         % Turn off z mod
        case 'Y'     
             m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            Y_prefactors =[
                50 112  0.17;
                100 165 0.275;
                200 240 0.44;
                300 297 0.52;];

            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(Y_prefactors(:,1),Y_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');

            % Shift for frequency dependence
            mod_amp = mod_amp+d_amp;
            
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_on);  % Turn off x mod, turn on y mod
            programRigol(addr_z,[],ch_off);          % Turn off z mod        
        case 'Z'
             m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            Z_prefactors =[
                50 112  0.3;
                100 165 0.5;
                200 240 0.7;
                300 297 1.05];
        
            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance in 100kHz
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(Z_prefactors(:,1),Z_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');
                        
            mod_amp = mod_amp+d_amp;
            
            mod_amp = mod_amp;
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_off);  % Turn off xy mod
            programRigol(addr_z,[],ch_on);            % Turn on z mod
    end
    
    addOutputParam('mod_amp',mod_amp);
   
    % We leave the feedback on as it cannot keep up. This + the VVA will
    % make a frequency dependent drive.
    % Trigger and wait
    setDigitalChannel(calctime(curtime,0),'Lattice FM',1); 
    curtime = setDigitalChannel(calctime(curtime,mod_time),'Lattice FM',0);
    ScopeTriggerPulse(calctime(curtime,0),'Lattice_Mod');


curtime = calctime(curtime,1);

end


%% Second Waveplate Rotation
% Rotate waveplate to distribute more power to the lattice

if do_rotate_waveplate_2
    wp_Trot2 = 150; 

    dispLineStr('Rotate waveplate again',curtime)    
        %Rotate waveplate again to divert the rest of the power to lattice beams
curtime = AnalogFunc(calctime(curtime,0),41,...
        @(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
        wp_Trot2,wp_Trot2,P_RotWave_I,P_RotWave_II);             
end

%% Ramp lattice after spectroscopy/plane selection

if do_lattice_ramp_2
    dispLineStr('Lattice Ramp 2',curtime)    
    ScopeTriggerPulse(curtime,'lattice_ramp_2');

    % 
    imaging_depth_list = [600]; 
    imaging_depth = getScanParameter(imaging_depth_list,seqdata.scancycle,...
        seqdata.randcyclelist,'FI_latt_depth','Er'); 

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
    lat_rampup_imaging_time =  [20 5 ];
     
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
    
    % Turn of dipole traps
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);


    deep_latt_holdtime_list = [50];
    deep_latt_holdtime = getScanParameter(deep_latt_holdtime_list,seqdata.scancycle,seqdata.randcyclelist,'deep_latt_holdtime'); 

curtime=calctime(curtime,deep_latt_holdtime);
    
end

%% Vortex Pulse

% curtime = PA_pulse(curtime);

%% Raman Spec

% curtime = lattice_FI(curtime);

%% Fluorescence Imaging


% Plane Selection (earlier)
%   - Apply FB + vertical gradient for selection
%   - Shelve a plane in the 7/2 manifold
%   - Kill untransfered 9/2 atoms
%   - Transfer shelved 7/2 back to 9/2

% Fluoresence Imaging
%   - Set quantiazation axis along FPUMP
%   - Set field for EIT condition and Raman detuning
%   - Apply light
%       - EIT Pump (FPUMP) light
%       - EIT probe light (2 horizontal beams)
%       - Raman beams (2 beams) 
%   - Expose the Camera

% Raman/UWave Transfers
%   - Set quantiazation axis along FPUMP
%   - Set field for EIT condition, Raman detuning, uWave detuning
%   - Apply Raman/uWave light and sweep freq
%
%
% EIT Probe and F-Pump alignment
%   - block all beams except the one that you want to align
%   - use SG to measure F ratios and also uWave spec.
%   - For Fpump want to first tranfser to F=7 manifold with uWave
%
%  - 2022/07/04 - EIT Probe 2 gets 60% transfer w 100us pulse time
%  - 2022/07/04 - EIT Prboe 1 gets 80% transfer w 100us pulse time
%  - 2022/07/04 - F pump gets 
%
% NOTES ON THE PHYSICS
%
% RAMAN :
% - For n->n tranfsers the ideal Raman two photon frequency depends only on
% the magnetic field. You can calibrate the n->n frequency by comparing to
% the uWave tranfsers.
% 
% EIT:
% The EIT imaging only works on n->n-1 at two photon resonance.  Thus the 
% ideal parmeters relate the (1) magnetic field (2) F-pump power (3) F-pump
% alignment (4) Single photon detuning

if (Raman_transfers == 1)
    dispLineStr('Raman Transfer',curtime);

    %During imaging, generate about a 4.4G horizontal field. Both shims get
    %positive control voltages, but draw from the 'negative' shim supply. 
    clear('horizontal_plane_select_params');
    
    horizontal_plane_select_params.Fake_Pulse = 0;
    
    
    Raman_On_Time_List =[1];[2000];[4800];%2000ms for 1 images. [4800]= 2*2000+2*400, 400 is the dead time of EMCCD

   % uWave or Raman Tranfers
   % 1: uwave, 2: Raman 3:Raman with field sweep
    horizontal_plane_select_params.Microwave_Or_Raman = 1; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% EIT Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Do you want the EIT beams to pulse?
    horizontal_plane_select_params.Use_EIT_Beams = 0;    
    
%     horizontal_plane_select_params.Enable_FPump = 0;
%     horizontal_plane_select_params.Enable_EITProbe = 0;
%     horizontal_plane_select_params.Enable_Raman = 0 ;
    
    %%%% F Pump Power %%%
    F_Pump_List = [0.6];[.7];[0.6];[1.1];1.1;[1.2];0.7;[0.8];[.9];
    horizontal_plane_select_params.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V'); %1.4; (1.2 is typically max)
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% RAMAN SETTINGS %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    V10 = 1.2;    % Max is 9.1 mW at 1.2 V, 0.44V is 2.6 mW
    V20 = 1.09;   % Max is 7.45 mW at 1.09 V, 0.47V is 2.56mW
    
 
    %%% Raman 1 Power (Vertical) %%%
    Raman_Power_List =V10*.365;[0.365];   
    horizontal_plane_select_params.Raman_Power1 = getScanParameter(Raman_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Power1','V');   

    %%% Raman 2 Power (Horizontal 1) %%%
    Raman_Power2_List =V20*.449;[0.43];
    horizontal_plane_select_params.Raman_Power2 = getScanParameter(Raman_Power2_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Power2','V');
    
    %%% Raman 1 Frequency (Vertical) %%%
    Raman_List = [-80];-80;   %-30% : in kHz;
    horizontal_plane_select_params.Raman_AOM_Frequency = 110 + ...
        getScanParameter(Raman_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_Freq','kHz')/1000;

    % Raman Rigol Mode
    horizontal_plane_select_params.Rigol_Mode = 'Sweep';  %'Sweep', 'Pulse', 'Modulate'

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% MICROWAVE SETTINGS %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Center frequency shift uWave settings
    uwave_freq_list = [0]/1000;
    uwave_freq = getScanParameter(uwave_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uwave_freq','kHz');
    
    % Center frequency of uWave Generator
    horizontal_plane_select_params.Selection_Frequency = 1285.8 + ...
        11.025 + uwave_freq; %11.550
    horizontal_plane_select_params.Microwave_Power_For_Selection = 15; %dBm
    
    % Pulse Time of uWave is the same as the Raman Time
    horizontal_plane_select_params.Microwave_Pulse_Length = ...
        getScanParameter(Raman_On_Time_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Time','ms');     
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Sweep Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    Range_List = [50];50;%in kHz
    horizontal_plane_select_params.Selection_Range = getScanParameter(Range_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Sweep_Range','kHz')/1000; 
%     
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Camera Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    horizontal_plane_select_params.Fluorescence_Image = 1;
    horizontal_plane_select_params.Num_Frames = 1; % 2 for 2 images    
    
    Modulation_List = Raman_On_Time_List;
    horizontal_plane_select_params.Modulation_Time = getScanParameter(Modulation_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Modulation_Time');
    
    horizontal_plane_select_params.Sweep_About_Central_Frequency = 1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Other Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    % Unclear what these settings are for
    horizontal_plane_select_params.Resonant_Light_Removal = 0;
    horizontal_plane_select_params.Final_Transfer = 0; 
    
    % Which SRS to use (in cause of uWave)
    horizontal_plane_select_params.SRS_Selection = 1;  %This used to be 1  
    
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Magnetic Field Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Use QP coils for plane selection (not relevant here)
    horizontal_plane_select_params.QP_Selection_Gradient = 0; 
    % Ramp fields up at the beginning
    horizontal_plane_select_params.Ramp_Fields_Up = 1;    
    % Ramp fields down at the end
    horizontal_plane_select_params.Ramp_Fields_Down = 0; 
    
    % Shim values for quantizing field
    % This affects Raman, Microwave, and EIT mechanisms.
    Field_Shift_List = [0.175];[0.155]; 0.155; %unit G 
    horizontal_plane_select_params.Field_Shift = getScanParameter(...
        Field_Shift_List,seqdata.scancycle,seqdata.randcyclelist,...
        'Field_Shift','G');    
    
    % Magnetic Field Offsets
    horizontal_plane_select_params.X_Shim_Offset = 0;
    horizontal_plane_select_params.Y_Shim_Offset = 0;
    horizontal_plane_select_params.Z_Shim_Offset = 0.055;
    Angle_List = [62];
    Angle = getScanParameter(Angle_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_Angle');
    horizontal_plane_select_params.Selection_Angle = Angle;62;66.5; %-30 for vertical, +60 for horizontal (iXon axes)
      
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% Run the Code!! %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    % Break thermal stabilization by turn off AOM
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);
        
    % Trigger the Scope
    ScopeTriggerPulse(curtime,'Raman Beams On');      

    % Run the fluoresnce imaging code
curtime = do_horizontal_plane_selection(curtime, ...
    horizontal_plane_select_params);


    % Turn on optical pumping beam AOM for thermal stabilization
    setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);  
    
    dispLineStr('do_horizontal_plane_selection execution finished at',curtime);
end


%% Hold the Lattice
% Unclear why this hold time is important or not

% curtime = calctime(curtime,lattice_holdtime);

%% High Field transfers + Imaging

if seqdata.flags.High_Field_Imaging
    % Typical Experimental Sequence
    % - Ramp lattices up to 200Er
    % - Ramp field up to 197G
    % - Create 99 doublons via Raman n-->n+1 pulse
    
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
    lattice_ramp_2                  = 0;       % Secondary lattice ramp before spectroscopy
    lattice_ramp_3                  = 0;       % between raman and rf spectroscopy

    % Feshbach field ramps
    field_ramp_init                 = 1;       % Ramp field away from initial  
    field_ramp_2                    = 0;       % ramp field after raman before rf spectroscopy
    field_ramp_img                  = 1;       % Ramp field for imaging

    % Apply a phatom Raman pulse to kill atoms
    do_raman_phantom                = 0;

    % RF Pre Flip 9<-->7data.params    
    rf_97_flip_init                 = 0;
    
    % Raman Spectroscopy
    pulse_raman                     = 0; %apply a Raman pulse with only the R2 beam
    do_raman_spectroscopy           = 0; 
    raman_short_sweep               = 0;
    do_raman_spectroscopy_post_rf   = 0;
    spin_flip_7_5                   = 0;   

    % RF Spectroscopy
    rf_rabi_manual                  = 0;
    do_rf_spectroscopy              = 0; 
    do_rf_post_spectroscopy         = 0;
    
    % Other RF Manipulations
    shift_reg_at_HF                 = 0;
    spin_flip_9_7_5                 = 0;
    spin_flip_9_7_post_spectroscopy = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare initial lattice, field, and spin %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Lattice ramp
    if lattice_ramp_init        
        % Ramp the lattices to their initial depth
       
        
%         Select the depth to ramp
        HF_latt_depth_list = [100];
        HF_latt_depth = getScanParameter(HF_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_depth','Er');
        
        
        % How quickly to ramp
        HF_latt_ramptime_list = [50];
        HF_latt_ramptime = getScanParameter(HF_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_ramptime','ms');

        
%% Pre Dec 22,2021 depths
        % Ramp the powers
%         AnalogFuncTo(calctime(curtime,T0),'xLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+0.855)/1.012);   
%         AnalogFuncTo(calctime(curtime,T0),'yLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth-0.715)/1.158);    
% curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+9.571)/1.147); 
%%
%New calibrations from Dec 22
%  AnalogFuncTo(calctime(curtime,T0),'xLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+2.073)/1.082);   
%         AnalogFuncTo(calctime(curtime,T0),'yLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+6.355)/1.278);    
% curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+10.677)/1.199); 

%%
% %New calibrations from Jan 31
%  AnalogFuncTo(calctime(curtime,T0),'xLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth-3.505)/0.99);   
%         AnalogFuncTo(calctime(curtime,T0),'yLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+3.568)/1.095);    
% curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             HF_latt_ramptime, HF_latt_ramptime, HF_latt_depth); 

%New calibrations from Feb 18
 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+0.033)/0.969);
    end   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare Lattice and State %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Feshbach ramp
    if field_ramp_init
        % Feshbach Field ramp
        HF_FeshValue_Initial_List = [200]; [197];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_Lattice','G');
        
%         HF_FeshValue_Initial = paramGet('HF_FeshValue_Initial');

        
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
        delta_freq = 0.5; 0.025;0.1;
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
        
%New calibrations from Feb 18
 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth+0.033)/0.969); 

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Perform Spectroscopy Measurements %%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    if pulse_raman
        %only useful in conjuction with raman spec code below. Otherwise
        %shutter won't turn off which is BAAAAD!!!
        Raman_on_time = paramGet('Raman_Pulse_Time');
        
        if Raman_on_time == 0
           curtime = calctime(curtime,25);
 
        else
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
        
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2a',0); %turn off R2
        curtime = calctime(curtime,25+Raman_on_time);
        end
    end
    
    
    % Raman spectrscopy
    if do_raman_spectroscopy

        mF1=-9/2;   % Lower energy spin state
        mF2=-7/2;   % Higher energy spin state

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        

        if (abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        
        Raman_AOM3_freq_list =  [-75]*1e-3/2+(80+...   %-88 for 300Er, -76 for 200Er
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; %-0.14239
        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
%         
%            freq = paramGet('Raman_freq');
%            Raman_AOM3_freq = freq*1e-3/2+(80+...   
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; 
%            addOutputParam('Raman_AOM3_freq',Raman_AOM3_freq);
% 
%         
        
        Raman_AOM3_pwr_list = 0.680; %0.740
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
    
%           RamanspecMode = 'sweep';
        RamanspecMode = 'pulse';
        
        % R3 beam settings
        switch RamanspecMode
            case 'sweep'
                Sweep_Range_list = [5]/1000;  %in MHz
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
                Pulse_Time_list = [0.08];
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

            Raman_AOM2_pwr_list = 0.490; %0.51
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

        Raman_AOM2_pwr_list = 0.50;
        Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

        addVISACommand(Device_id, str);


        %R3 beam settings

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
        B = HF_FeshValue_Initial + 2.35*zshim;

        Raman_AOM3_freq_list =  [-63]*1e-3/2+(80+...
            abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6))/2; %-0.14239

        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        Raman_AOM3_pwr_list = [0.36];
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');



            Sweep_Range_list = [10]/1000;  %in MHz
            Sweep_Range = getScanParameter(Sweep_Range_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
            Sweep_Time_list = [0.1 0.2 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5]; %in ms, resolution = 10us
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
            Rigol_sweep_range = round(Rigol_sweep_time/Sweep_Time*Sweep_Range,2);

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
        delta_freq = 0.10; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 5;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%      HF5_wait_time_list = [1:10 12:2:20 25:5:100];
%      HF5_wait_time = getScanParameter(HF5_wait_time_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');

%Double pulse sequence
    HF5_wait_time = paramGet('HF_wait_time_5');
    curtime = calctime(curtime,HF5_wait_time);
         
     
     sweep_pars.delta_freq  = -delta_freq; 0.025;0.1;
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);


    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
        
curtime = calctime(curtime,50);

    end
        
    % Feshbach field ramp Another
    if field_ramp_2
        clear('ramp');
        HF_FeshValue_Spectroscopy_List =[200.1];
        HF_FeshValue_Spectroscopy = getScanParameter(HF_FeshValue_Spectroscopy_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Spectroscopy','G');           
%         
%         HF_FeshValue_Spectroscopy = paramGet('HF_FeshValue_Spectroscopy');
      
        HF_FeshValue_Initial = HF_FeshValue_Spectroscopy; %For use below in spectroscopy
        seqdata.params.HF_probe_fb = HF_FeshValue_Spectroscopy; %For imaging

        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_shimvalue_Spectroscopy','A');

%         zshim = paramGet('HF_shimvalue_Spectroscopy');
        
        ramptime2 = 50;
          % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = ramptime2;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
        % FB coil 
        ramp.fesh_ramptime = ramptime2;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Spectroscopy;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
 
    % Hold time at the end
     HF_wait_time_list = [0];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');
    
curtime = calctime(curtime,HF_wait_time);
    seqdata.params.HF_fb = HF_FeshValue_Spectroscopy;
    seqdata.params.HF_probe_fb = HF_FeshValue_Spectroscopy;

    end         

    if lattice_ramp_3
        HF_spec_latt_depth_list = [300];
        HF_spec_latt_depth = getScanParameter(HF_spec_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_depth','Er');

%         HF_spec_latt_depth = paramGet('HF_spec_latt_depth');

        HF_spec_latt_ramptime_list = [75];
        HF_spec_latt_ramptime = getScanParameter(HF_spec_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_ramptime','ms');
        

%%
%New calibrations from Feb 18
 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth+0.033)/0.969); 
        
%             disp(x_latt_voltage);
%             disp(y_latt_voltage);
%             disp(z_latt_voltage);            
%             
%             addOutputParam('latt_ramp3_X',x_latt_voltage);
%             addOutputParam('latt_ramp3_Y',y_latt_voltage);
%             addOutputParam('latt_ramp3_Z',z_latt_voltage);
 

curtime = calctime(curtime,5);  %extra wait time
    end
     
   % RF Rabi Oscillations
    if rf_rabi_manual
        mF1=-7/2;
        mF2=-9/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;            
        
%         rf_list =  [15.15]*1e-3 +... 
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6); 
%         rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
%             seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];    
        
        rf_rabi_freq_HF_shift = paramGet('rf_rabi_freq_HF_shift');
        rabi.freq =  rf_rabi_freq_HF_shift*1e-3 +... 
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        addOutputParam('rf_rabi_freq_HF',rabi.freq,'MHz');       

          if (rabi.freq < 10)
                         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
          end
          
%           rf_pulse_length_list = [0.005:0.005:0.075];  %0.23
%           rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
%             seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               
        
       rabi.pulse_length = paramGet('rf_rabi_time_HF');
        
        rabi_source = 'DDS';
%         rabi_source = 'SRS';
        
        switch rabi_source
            case 'DDS' 
                    power_list =  [-1]; 2.5;
                    rabi.power = getScanParameter(power_list,...
                        seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF','V');            
                        %rf_pulse_length_list = [0.5]/15;
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
                        
                        if ~do_rf_post_spectroscopy
                        % Turn off RF
                        setDigitalChannel(curtime,'RF TTL',0);   
                        end
                    end

                    % Lower the power
                    setAnalogChannel(calctime(curtime,0),'RF Gain',-10);             

                    % Extra Wait Time
                    curtime=calctime(curtime,1);  
                    
            case 'SRS'
            %under development  
        end
       
    end  
    
    % RF Sweep Spectroscopy
    if do_rf_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        
        rf_shift_list = [-9:1:1];       
        rf_shift = getScanParameter(rf_shift_list,seqdata.scancycle,...
                        seqdata.randcyclelist,'rf_freq_HF_shift','kHz');
         
%             rf_shift = paramGet('rf_freq_HF_shift');
%         rf_shift = 10;
        
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        % Define the sweep parameters
        delta_freq= 0.0025; %0.00125; %.0025;  in MHz            
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

        % RF Pulse 
        rf_pulse_length_list = 2; %ms
        rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_pulse_length');
        
%         sweep_type = 'DDS';
        sweep_type = 'SRS_HS1';
        
        switch sweep_type
            case 'DDS'
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
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  

                rf_srs_power_list = [5];
                rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_srs_power','dBm');
%                 rf_srs_power = paramGet('rf_srs_power');
                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address='192.168.1.121';                       % K uWave ("SRS B");
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_srs_power;                           
                rf_srs_opts.Frequency = rf_freq_HF;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
                disp(['     Freq Delta   : ' num2str(delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;                    
                rf_srs_opts.SweepRange=abs(delta_freq);     
                
                % Set SRS Source to the new one
                setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

                % Set SRS Direction to RF
                setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
                
                if rf_rabi_manual
                    setDigitalChannel(calctime(curtime,...
                         rf_wait_time + extra_wait_time),'RF Source',1); 
                    setAnalogChannel(calctime(curtime,...
                         rf_wait_time + extra_wait_time),'RF Gain',rf_off_voltage);
                else    
                 % Set RF power to low
                setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);
                     
                 % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'RF Source',1);

                end
                    
                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'RF TTL',1);    

                % Ramp the SRS modulation using a TANH
                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'uWave FM/AM',...
                    @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,1);

                % Sweep the linear VVA
                AnalogFunc(calctime(curtime,...
                    rf_wait_time  + extra_wait_time),'RF Gain',...
                    @(t,T,beta) -10 + ...
                    20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta);

                % Wait for Sweep
                            curtime = calctime(curtime,rf_pulse_length);

                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF Gain',rf_off_voltage);
                
                if ~do_rf_post_spectroscopy
                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length+1),'RF Source',0);
                setDigitalChannel(calctime(curtime,...
                     rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source',1);
                end 
                

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
                params.isProgrammedSRS = 1;
                
                 % Extra Wait Time
                 
                HF_hold_time_list = [35]+rf_pulse_length;
                HF_hold_time = getScanParameter(HF_hold_time_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'HF_hold_time','ms');
% %                 
%                 HF_hold_time =  rf_pulse_length+ paramGet('HF_hold_time');
                
                curtime=calctime(curtime,HF_hold_time); 
                
                if HF_hold_time > 1
                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length-HF_hold_time),'RF TTL',0); 
                end
                
        end  
    end
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Post Spectropscy Operations %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if do_rf_post_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-9/2;   % Higher energy spin state

        
        % Get the center frequency
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
%         rf_shift = 15;

        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

       

        % Define the sweep parameters
%         delta_freq= 0.025; %.0025;  in MHz            
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

        % RF Pulse 
%         rf_pulse_length_list = 1; %ms
%         rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
%             seqdata.randcyclelist,'rf_pulse_length');

%         sweep_type = 'DDS';
        sweep_type = 'SRS_HS1';
        
        switch sweep_type
            case 'DDS'
                freq_list=rf_freq_HF+[...
                    -0.5*delta_freq ...
                    -0.5*delta_freq ...
                    0.5*delta_freq ...
                    0.5*delta_freq];            
                pulse_list=[0.1 rf_pulse_length 0.1];

                % Max rabi frequency in volts (uncalibrated for now)
                off_voltage=-10;
                peak_voltage=5;

                % Display the sweep settings
                disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
                disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
                disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
                disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


                % Set RF gain to zero a little bit before
%                 setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

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
                dTP=0.05;
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
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  

%                 rf_srs_power_list = [6];[10];
%                 rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
%                     seqdata.randcyclelist,'rf_srs_power','dBm');

                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address=29;                       % Rb SRS temporarily used here;
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_srs_power;                           
                rf_srs_opts.Frequency = rf_freq_HF;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
                disp(['     Freq Delta   : ' num2str(delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;     
%                 rf_srs_opts.Enable=1;          % Power on
                rf_srs_opts.SweepRange=abs(delta_freq);  
                
                if rf_rabi_manual
                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,0),'RF Source',1);
                % Set SRS Source to the new one
                setDigitalChannel(calctime(curtime,0),'SRS Source',0);
                end  

% 
%                 % Set SRS Direction to RF
%                 setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set SRS source post spec to Rb one
                setDigitalChannel(calctime(curtime,0),'SRS Source post spec',1);


                % Set RF power to low
                setAnalogChannel(calctime(curtime,0),'RF Gain',rf_off_voltage);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1);

                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'RF TTL',1);    

                % Ramp the SRS modulation using a TANH
                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'uWave FM/AM',...
                    @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,1);

                % Sweep the linear VVA
                AnalogFunc(calctime(curtime,...
                    rf_wait_time  + extra_wait_time),'RF Gain',...
                    @(t,T,beta) -10 + ...
                    20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta);

                % Wait for Sweep
%                             curtime = calctime(curtime,rf_pulse_length);

                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF TTL',0); 

                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF Gain',rf_off_voltage);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length+1),'RF Source',0);
                
                setDigitalChannel(calctime(curtime,...
                     rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source',1);
                
                 
                 setDigitalChannel(calctime(curtime,...
                      rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source post spec',0);

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
                params.isProgrammedSRS = 1;
                
                 % Extra Wait Time
                curtime=calctime(curtime,35);    

                
        end  
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

% seqdata.params.HF_probe_fb = seqdata.params.HF_fb;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare for Imaging %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We perform imaging a "standard" field of 195 G. Ramp the field to
    % this value to perform time of flight and imaging
    % Feshbach Field Ramp (imaging)
    if field_ramp_img

        % Feshbach Field ramp Field ramp
        HF_FeshValue_Final_List = 195;
        HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_Lattice','G');

        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    end
        
    % Hold time at the end
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
    dispLineStr('ramp_HF_and_back',curtime);

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

% Immediately shut off lattices and dipole traps
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


% Turn off of lattices
 if ( seqdata.flags.load_lattice == 1 ) %shut off lattice, keep dipole trap on
    
    ScopeTriggerPulse(curtime,'lattice_off');
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
        dip1_endpower = seqdata.params.ODT_zeros(1);
        dip2_endpower = seqdata.params.ODT_zeros(2);
        
        disp([' Ramp Start (ms) : ' num2str(dip_rampstart) ]);
        disp([' Ramp Time  (ms) : ' num2str(dip_ramptime) ]);
        disp([' End Power   (W) : ' num2str(dip_endpower)]);
        
        
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_ramptime,dip_ramptime,dip1_endpower);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            dip_ramptime,dip_ramptime,dip2_endpower);
        
        seqdata.params.XDT_area_ratio*dip2_endpower;
        setDigitalChannel(calctime(curtime,dip_rampstart+dip_ramptime),...
            'XDT TTL',1); %cut lattice power for bandmapping?    
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
            AnalogFuncTo(calctime(curtime,0),'xLattice',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                lat_rampdowntime,lat_rampdowntime,xlat_endpower);
            AnalogFuncTo(calctime(curtime,0),'yLattice',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,...
                lat_rampdowntime,ylat_endpower);
curtime =   AnalogFuncTo(calctime(curtime,0),'zLattice',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),lat_rampdowntime,...
                lat_rampdowntime,zlat_endpower);

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
%     setDigitalChannel(calctime(curtime,0),11,1);  %0: ON / 1: OFF, XLatticeOFF         
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

disp('time here')
disp(curtime);
%% Output

seqdata.times.lattice_end_time = curtime;

timeout = curtime;

end