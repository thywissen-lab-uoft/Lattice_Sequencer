%------
%Author: Stefan ( Ctrl-C/Ctrl-V )
%Created: Feb 2013
%Summary:   Loading the lattice -- intentionally left without parameters.
%           Rampup times and everything that is done in the lattice should
%           be specified in here.
%           Typically called after evaporation in ODT
%------

function [timeout] = Load_Lattice(timein)
global seqdata;

lattice_flags(timein);

curtime = timein;
lattices = {'xLattice','yLattice','zLattice'};
seqdata.params.XDT_area_ratio = 1; %RHYS - Why is this defined here again?


%% Lattice Flags    
% These are the lattice flags sorted roughly chronologically. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lattice Ramps and Waveplates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_rotate_waveplate_1 = 1;        % First waveplate rotation for 90%
do_lattice_ramp_1 = 1;            % Load the lattices

seqdata.flags.do_lattice_am_spec = 0;               % Amplitude modulation spectroscopy             

do_rotate_waveplate_2 = 0;        % Second waveplate rotation 95% 
do_lattice_ramp_2 = 0 ;            % Secondary lattice ramp for fluorescence imaging

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
seqdata.flags.lattice_PA = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conductivity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags are associated with the conducitivity experiment
seqdata.flags.do_conductivity = 0;      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RF/uWave Spectroscopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.lattice_uWave_spec = 0;

do_K_uwave_spectroscopy_old = 0;        % (3786) keep
do_RF_spectroscopy = 0;                 % (3952,4970)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DMD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection, Raman Transfers, and Fluorescence Imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
seqdata.flags.lattice_do_optical_pumping = 0;                 % (1426) keep : optical pumping in lattice  
seqdata.flags.do_plane_selection = 0;                 % Plane selection flag


% Actual fluorsence image flag
seqdata.flags.Raman_transfers = 0;                                % (4727)            keep : apply fluorescence imaging light

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


% Band Map time
lattice_rampdown_list = [3]; %0 for snap off (for in-situ latice postions for alignment)
                             %3 for band mapping
lattice_rampdown = getScanParameter(lattice_rampdown_list,...
    seqdata.scancycle,seqdata.randcyclelist,'latt_rampdown_time','ms'); %Whether to down a rampdown for bandmapping (1) or snap off (0) - number is also time for rampdown


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

    AnalogFunc(calctime(curtime,-100-wp_Trot1),'latticeWaveplate',...
        @(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),...
        wp_Trot1,wp_Trot1,P_RotWave_I);    
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
            U = 200;

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



%% conductivity modulation without dimple
%RHYS - This is the code for the conductivity experiment. Should probably
%keep for now, just clean up. A very long code: make its own module, delete
%all the commented crap.
%
% CF: moved to a subfucnction, unclear if it rworks

if (seqdata.flags.do_conductivity == 1 )
   curtime = lattice_conductivity(curtime);
end


%% Optical Pumping
% Optical pumping

if (seqdata.flags.lattice_do_optical_pumping == 1)
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

if seqdata.flags.do_plane_selection
    dispLineStr('Plane Selection',curtime);      
    curtime = plane_selection(curtime);
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


if ( do_K_uwave_spectroscopy_old || ...
        do_RF_spectroscopy || seqdata.flags.lattice_uWave_spec)
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

%% K uWave Spectroscopy

if seqdata.flags.lattice_uWave_spec
    
     dispLineStr('uWave_K_Spectroscopy',curtime);
   
    % Frequency
    freq_shift_list = [0]; % Offset in kHz
    f0 = 1338.345;          % MHz % Normal frequency
    

    uwave_freq_shift = getScanParameter(freq_shift_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_freq_shift','kHz');    
    uwave_freq = uwave_freq_shift/1000 + f0;
    
    addOutputParam('uWave_freq',uwave_freq,'MHz');
    
    % Frequency Shift
    % Only used for sweep spectroscopy
    uwave_delta_freq_list = [200];
    uwave_delta_freq=getScanParameter(uwave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq','kHz');
        
    % Time
    uwave_time_list = [30];
    uwave_time = getScanParameter(uwave_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_time','ms');    
    
    % Power
    uwave_power_list = [15];
    uwave_power = getScanParameter(uwave_power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_power','dBm');  
        
    % Spetroscopy parameters
    spec_pars = struct;
    spec_pars.Mode='sweep_frequency_chirp';
    spec_pars.use_ACSync = 0;
    spec_pars.PulseTime = uwave_time;
    
    spec_pars.FREQ = uwave_freq;                % Center in MHz
    spec_pars.FDEV = (uwave_delta_freq/2)/1000; % Amplitude in MHz
    spec_pars.AMPR = uwave_power;               % Power in dBm
    spec_pars.ENBR = 1;                         % Enable N Type
    spec_pars.GPIB = 30;                        % SRS GPIB Address    
    
    % Do you sweep back after a variable hold time?
    spec_pars.doSweepBack = 0;
    uwave_hold_time_list = [0];
    uwave_hold_time  = getScanParameter(uwave_hold_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'hold_time','ms');     
    spec_pars.HoldTime = uwave_hold_time;
        
    curtime = K_uWave_Spectroscopy(curtime,spec_pars);    
end

%% K uWave Spectroscopy (OLD)
% This code performs K uWave manipulations such as Rabi Oscillations,
% Landau Zener Sweeps. It is hoped that this code is deprecated and will no
% longer be used.
            
if do_K_uwave_spectroscopy_old
   curtime = uwave_K_spec_lattice_old(curtime);
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


if ( do_K_uwave_spectroscopy_old || ...
        do_RF_spectroscopy || seqdata.flags.lattice_uWave_spec...
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

if seqdata.flags.do_lattice_am_spec
   curtime = lattice_am_spectroscopy(curtime);
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
    imaging_depth_list = [200]; [675]; 
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
else
    curtime = calctime(curtime,50);
    
end

%% Vortex Pulse
if seqdata.flags.lattice_PA
    curtime = PA_pulse(curtime);
end

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
%  - 2022/09/26 - F pump gets 57% transfer back to F=9/2 w 0.1V and 1ms  

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

if (seqdata.flags.Raman_transfers == 1)
    dispLineStr('Raman Transfer',curtime);

    %During imaging, generate about a 4.4G horizontal field. Both shims get
    %positive control voltages, but draw from the 'negative' shim supply. 
    clear('horizontal_plane_select_params');
    
    horizontal_plane_select_params.Fake_Pulse = 0;
    
    
    Raman_On_Time_List =[2000];[2000];[4800];%2000ms for 1 images. [4800]= 2*2000+2*400, 400 is the dead time of EMCCD

   % uWave or Raman Tranfers
   % 1: uwave, 2: Raman 3:Raman with field sweep
    horizontal_plane_select_params.Microwave_Or_Raman = 2; %Set to 2 in order for iXon triggers to happen
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% EIT Settings %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Do you want the EIT beams to pulse?
    horizontal_plane_select_params.Use_EIT_Beams = 1;    
    
%     horizontal_plane_select_params.Enable_FPump = 0;
%     horizontal_plane_select_params.Enable_EITProbe = 0;
%     horizontal_plane_select_params.Enable_Raman = 0 ;
    
    %%%% F Pump Power %%%
    F_Pump_List = [.6];[0.6];
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
    horizontal_plane_select_params.Rigol_Mode = 'Pulse';  %'Sweep', 'Pulse', 'Modulate'

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

%% Extra Wait For funsies
curtime = calctime(curtime,25);

%% High Field transfers + Imaging

if seqdata.flags.High_Field_Imaging
   curtime = lattice_HF(curtime);
end

%% Lattice Turn Off
% Turn off the lattices.
%
% During typical operation :
%
% Ramp off the XDTs
% Perform Bandmapping

% Turn off of lattices
 if ( seqdata.flags.load_lattice)
   
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
    
     ScopeTriggerPulse(curtime,'lattice_off');
    % Parameters for ramping down the lattice (after things have been done)
    zlat_endpower = L0(3)-1;-19;-0.2;       % where to end the ramp
    ylat_endpower = L0(2)-1;-20;-0.2;       % where to end the ramp
    xlat_endpower = L0(1)-1;-22; -0.2;       % where to end the ramp
    lat_rampdowntime =lattice_rampdown*1; % how long to ramp (0: switch off)   %1ms
    lat_rampdowntau = 1*lattice_rampdown/5;    % time-constant for exponential rampdown (0: min-jerk)
        
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
        end
    end   
    
    %TTLs
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);  %0: ON / 1: OFF,yLatticeOFF
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1); % Added 2014-03-06 in order to avoid integrator wind-up
    

    
end


%% Output

seqdata.times.lattice_end_time = curtime;

timeout = curtime;

end