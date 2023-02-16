function [timeout,I_QP,V_QP,P_dip,I_shim] =  dipole_transfer(timein, I_QP, V_QP,I_shim)

curtime = timein;
global seqdata;

%% Flags
%%%%%%%%%%%%%%%%%%%%%%%%%%
%Dipole Loading Flags
%%%%%%%%%%%%%%%%%%%%%%%%%%    
seqdata.flags.xdt_qp_ramp_down1         = 1;
seqdata.flags.xdt_qp_ramp_down2         = 1;
ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt); %try linear versus min jerk
%ramp_func = @(t,tt,y2,y1)(minimum_jerk(t,tt,y2-y1)+y1); 

%%%%%%%%%%%%%%%%%%%%%%%%%%
%Evaporation in the XDT
%%%%%%%%%%%%%%%%%%%%%%%%%% 
seqdata.flags.xdt_ramp_FB_before_evap   = 0; % Ramp up feshbach before evaporation
seqdata.flags.xdt_levitate_evap         = 0; % Apply levitation gradient
seqdata.flags.xdt_unlevitate_evap       = 0;

% Dipole trap asymmetry (useful for making a symmetric trap for lattice + QGM)
seqdata.params.xdt_p2p1_ratio           = 1; % ratio of ODT2:ODT1 power

Evap_End_Power_List = [.12];

% Ending optical evaporation
exp_end_pwr = getScanParameter(Evap_End_Power_List,...
    seqdata.scancycle,seqdata.randcyclelist,'Evap_End_Power','W');  

seqdata.flags.xdt_ramp2sympathetic      = 1;  


seqdata.flags.xdt_evap2stage            = 0; %Perform K evap at low field
seqdata.flags.xdt_evap2_HF              = 1; %Perform K evap at high field (set rep. or attr. in file)

%%%%%%%%%%%%%%%%%%%%%%%%%%
%After Evaporation (unless CDT_evap = 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_ramp_power_end        = 0;    % Ramp dipole back up after evaporation before any further physics 
seqdata.flags.xdt_do_dipole_trap_kick   = 0;    % Kick the dipole trap, inducing coherent oscillations for temperature measurement
seqdata.flags.xdt_do_hold_end           = 0;
seqdata.flags.xdt_am_modulate           = 0;    % 1: ODT1, 2:ODT2

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spectroscopy after Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_k_rf_rabi_oscillation = 0;    % RF rabi oscillations after evap
seqdata.flags.xdt_ramp_QP_FB_and_back   = 0;    % Ramp up and down FB and QP to test field gradients
seqdata.flags.xdt_uWave_K_Spectroscopy  = 0;
seqdata.flags.xdt_ramp_up_FB_for_lattice    = 0;    %Ramp FB up at the end of evap  

    
%% XDT Powers

%%%%% Specify the XDT2 power relative to XDT1 %%%%%%%%%%%%%%%%%%%%%%%%%
% Power function of XDT1 relative to XDT2. Useful for making
% circularly symmetric trap at end of evaporation.
XDT2_power_func = @(x) x;

% Initial XDT power
P12_list = [1.5];
P12 = getScanParameter(P12_list,seqdata.scancycle,...
    seqdata.randcyclelist,'XDT_initial_power','W');
P1 = P12;
P2 = P12;       

% Sympathetic cooling powers
Pevap_list = 0.8;[.8];
Pevap = getScanParameter(Pevap_list,...
    seqdata.scancycle,seqdata.randcyclelist,'XDT_Pevap','W');
P1e = Pevap; %0.8
P2e = Pevap; %0.8

% Final optical power
xdt1_end_power = exp_end_pwr;    
xdt2_end_power = XDT2_power_func(exp_end_pwr);

% Evaporation Time
Time_List =  [25]*1e3; 18;% [15000] for normal experiment
evap_time_total = getScanParameter(Time_List,seqdata.scancycle,...
    seqdata.randcyclelist,'evap_time','ms');   

% If you want to do a partial evaporation in time
doPartialEvap = 0;

% Exponetial time factor
Tau_List = [3.5];%[5];
exp_tau_frac = getScanParameter(Tau_List,seqdata.scancycle,...
    seqdata.randcyclelist,'Evap_Tau_frac');
exp_tau=evap_time_total/exp_tau_frac;

% Power vector (load, hold, sympathetic, final)
DT1_power = 1*[P1 P1 P1e xdt1_end_power];
%     DT1_power = -1*[1         1        1          1]; 
DT2_power = 1*[P2 P2 P2e xdt2_end_power];  
%     DT2_power = -1*[1         1        1          1];  

% Plug Shim Z Slope delta
dCz_list = [-.0025];
dCz = getScanParameter(dCz_list,seqdata.scancycle,...
    seqdata.randcyclelist,'dCz','arb.');  


%% Dipole trap initial ramp on
dispLineStr('ODT 1 ramp up started at',calctime(curtime,0));

% XDT Ramp time delay (or pre turn on)
dipole_ramp_start_time_list =[0]; [-500];
dipole_ramp_start_time = getScanParameter(dipole_ramp_start_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_start_time');

% XDT Ramp on time length
dipole_ramp_up_time_list = [75]; 
dipole_ramp_up_time = getScanParameter(dipole_ramp_up_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_up_time');

% Turn on XDT AOMs
setDigitalChannel(calctime(curtime,dipole_ramp_start_time-10),'XDT TTL',0);  

% Ramp dipole 1 trap on
AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
    'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    dipole_ramp_up_time,dipole_ramp_up_time,...
    seqdata.params.ODT_zeros(1),DT1_power(1));

% Ramp dipole 2 trap on
AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
    'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    dipole_ramp_up_time,dipole_ramp_up_time,...
    seqdata.params.ODT_zeros(2),DT2_power(1));
    
ScopeTriggerPulse(curtime,'Rampup ODT');
%% Ramp the QP Down    
% Make sure shims are allowed to be bipolar (not necessary?)
setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);

% QP1 Value
QP_ramp_end1_list = [0.9];
QP_ramp_end1 = getScanParameter(QP_ramp_end1_list*1.78,seqdata.scancycle,...
    seqdata.randcyclelist,'QP_ramp_end1');

% QP1 Time
qp_ramp_down_time1_list = [300];[250];[250];
qp_ramp_down_time1 = getScanParameter(qp_ramp_down_time1_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time1','ms');        

% QP2 Value
QP_ramp_end2 = 0*1.78; 
qp_ramp_down_time2_list = [100];100;
qp_ramp_down_time2 = getScanParameter(qp_ramp_down_time2_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time2','ms');        

% Fesh values
%Calculated resonant fesh current. Feb 6th. %Rb: 21, K: 21
mean_fesh_current = 5.25392;%before 2017-1-6   22.6/4; 
fesh_current = mean_fesh_current;

% Transport supply voltage check
vSet_ramp = 1.07*V_QP; %24   
% Check thermal power dissipation
if vSet_ramp^2/4/(2*0.310) > 700
    error('Too much power dropped across FETS');
end

%% QP Ramp Down 1
if seqdata.flags.xdt_qp_ramp_down1  
    dispLineStr('QP RAMP DOWN 1',curtime);

    % Calculate the change in QP current
    dI_QP=QP_ramp_end1-I_QP; 

    % Calculate the change in shim currents
    Cx = seqdata.params.plug_shims_slopes(1);
    Cy = seqdata.params.plug_shims_slopes(2);
    Cz = seqdata.params.plug_shims_slopes(3)+dCz;

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   

    % Calculate the new shim values
    I_shim = I_shim + [dIx dIy dIz];        

    % Ramp the XYZ shims to new shim values
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(3),3); 
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(2),4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(1),3); 

    % Ramp down FF.
    AnalogFuncTo(calctime(curtime,0),...
        'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1*23/30);

    % Ramp down QP and advance time
    curtime = AnalogFuncTo(calctime(curtime,0),...
        'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1);

    % Some extra advances in time (WHAT IS THIS FOR?)
    if (dipole_ramp_start_time+dipole_ramp_up_time)>(qp_ramp_down_time1)
        curtime =   calctime(curtime,...
            (dipole_ramp_start_time+dipole_ramp_up_time)-(qp_ramp_down_time1));
    end

    I_QP  = QP_ramp_end1; 
end
    
%% QP Ramp Down 2

if seqdata.flags.xdt_qp_ramp_down2

    dispLineStr('QP RAMP DOWN 2',curtime);

    XDT_pin_time_list = [0];
    XDT_pin_time = getScanParameter(XDT_pin_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'XDT_pin_time'); 
   
    % Ramp ODT2
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        XDT_pin_time,XDT_pin_time,DT2_power(2));

    % Ramp ODT1
    curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        XDT_pin_time,XDT_pin_time,DT1_power(2));

    % Ramp Feshbach field
    FB_time_list = [0];
    FB_time = getScanParameter(FB_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'FB_time');
    setDigitalChannel(calctime(curtime,-100-FB_time),'fast FB Switch',1); %switch Feshbach field on
    setAnalogChannel(calctime(curtime,-95-FB_time),'FB current',0.0); %switch Feshbach field closer to on
    setDigitalChannel(calctime(curtime,-100-FB_time),'FB Integrator OFF',0); %switch Feshbach integrator on            
    
    % Ramp up FB Current
    AnalogFunc(calctime(curtime,0-FB_time),'FB current',...
        @(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),...
        qp_ramp_down_time2+FB_time,qp_ramp_down_time2+FB_time, fesh_current,0);
    fesh_current_val = fesh_current;    

    % Ramp down Feedforward voltage
    AnalogFuncTo(calctime(curtime,0),...
        'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2*23/30);      

    % Ramp down QP currents
    AnalogFuncTo(calctime(curtime,0),...
        'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2);

    % Calculate the change in QP currents
    dI_QP=QP_ramp_end2-QP_ramp_end1; 

    % Calculate the change in shim currents
    Cx = seqdata.params.plug_shims_slopes(1);
    Cy = seqdata.params.plug_shims_slopes(2);
    Cz = seqdata.params.plug_shims_slopes(3)+dCz;         

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;    

    % Calculate the new shim values
    I_shim = I_shim + [dIx dIy dIz];

    % Ramp shims
    AnalogFuncTo(calctime(curtime,0),'Z shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(3),3); 
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(2),4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim'....
        ,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(1),3);

    % Save the shim values (appears unused?)
    seqdata.params.yshim_val = I_shim(2);
    seqdata.params.xshim_val = I_shim(1);
    seqdata.params.zshim_val = I_shim(3);

    % Advance time (CF: this seems weirdly defined?)
    curtime = calctime(curtime,qp_ramp_down_time2);   

    I_QP  = QP_ramp_end2;

    if QP_ramp_end2 <= 0 % second rampdown segment concludes QP rampdown
        setAnalogChannel(calctime(curtime,0),1,0);%1
        %set all transport coils to zero (except MOT)
        for i = [7 8 9:17 22:24 20] 
            setAnalogChannel(calctime(curtime,0),i,0,1);
        end
    end
end

V_QP = vSet_ramp;

%% Plug Turn off
% Turn off the plug beam now that the QP coils are off

plug_turnoff_time_list =[0]; -200;
plug_turnoff_time = getScanParameter(plug_turnoff_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'plug_turnoff_time');
setDigitalChannel(calctime(curtime,plug_turnoff_time),'Plug Shutter',0);%0:OFF; 1:ON; -200

dispLineStr('Turning off plug ',calctime(curtime,plug_turnoff_time));


%% Turn Off Voltage on Transport and Shim Supply 

ScopeTriggerPulse(calctime(curtime,0),'Transport Supply Off');

%Use QP TTL to shut off coil 16 
setDigitalChannel(calctime(curtime,0),'Coil 16 TTL',1);

%Turn Coil 15 FET off
setAnalogChannel(calctime(curtime,0),'Coil 15',0,1);

%% Rb uWave 1 SWEEP FESHBACH FIELD

%Pre-ramp the field to 20G for transfer
if ( seqdata.flags.xdt_Rb_21uwave_sweep_field)      
    dispLineStr('uWave Rb 2-->1',curtime);
    
    init_ramp_fields = 1; % Ramp field to starting value?
    do_F2_blowaway = 1 ; % Remove remaining F=2 atoms after transfer?


    %%%%%%%%%%%%%%%%%%%%%%%%
    % Program the SRS
    %%%%%%%%%%%%%%%%%%%%%%%
    % Use this code if using the SRS (inSstead of the Anritsu) to
    % transfer atoms

    Rb_SRS=struct;
    Rb_SRS.Address=29;        % GPIB address of the Rb SRS        
    Rb_SRS_list = [0]; %in MHz
    Rb_SRS_det = getScanParameter(Rb_SRS_list,seqdata.scancycle,...
        seqdata.randcyclelist,'Rb_SRS_det');
    Rb_SRS.Frequency=6.87560 + Rb_SRS_det/1000; % Frequency in GHz
    Rb_SRS.Power=8;%8           % Power in dBm (Don't go too high)
    Rb_SRS.Enable=1;          % Whether to enable 
    Rb_SRS.EnableSweep=0;        
%         programSRS_Rb(Rb_SRS);          

    %%%%%%%%%%%%%%%%%%%%%%%%
    % Field Sweep settings
    %%%%%%%%%%%%%%%%%%%%%%%        
    % Center feshbach field
    mean_field_list =19.432;
    mean_field = getScanParameter(mean_field_list,seqdata.scancycle,...
        seqdata.randcyclelist,'Rb_Transfer_Field','G');

    % Total field sweep range
    del_fesh_current = 0.2;1;%0.10431;% before 2017-1-6 0.1; %0.1        
    addOutputParam('del_fesh_current',del_fesh_current,'G')

    %%%%%%%%%%%%%%%%%%%%%%%%
    % INITIALIZING FIELD RAMP : (mean field + delta/2)
    %%%%%%%%%%%%%%%%%%%%%%%
    if init_ramp_fields 
        
        clear('ramp');
        shim_ramptime_list = [2];
        shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
               
        getChannelValue(seqdata,'X Shim',1,0);
        getChannelValue(seqdata,'Y Shim',1,0);
        getChannelValue(seqdata,'Z Shim',1,0);

        % Ramp shims to the zero condition
        ramp = struct;
        ramp.shim_ramptime = shim_ramptime;
        ramp.shim_ramp_delay = 0; 
        ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        
        % Ramp FB to initial magnetic field
        fb_ramp_time = 50;
        ramp.fesh_ramptime = fb_ramp_time;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = mean_field+del_fesh_current/2; %22.6
        ramp.settling_time = 50;

        disp('Ramping the feshbach field to initial value.');

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end

    %%%%%%%%%%%%%%%%%%%%%%%%
    % uWave with Field sweep
    %%%%%%%%%%%%%%%%%%%%%%%
    % Send scope trigger
    ScopeTriggerPulse(curtime,'Rb uwave transfer');

    % Use Anritsu Source
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',0); %0 = Anritsu, 1 = Sextupler

    % Set the field sweep time
    % Anritsu needs a bit longer (100 ms).
    uWave_sweep_time_list = 100;60;
    uWave_sweep_time = getScanParameter(uWave_sweep_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uWave_sweep_time','ms');

    % No idea what this does
    uWave_pulse_freq = 21.52;

    % Pulse uWave during the field sweep
    do_uwave_pulse(calctime(curtime,0), 0, uWave_pulse_freq*1E6, uWave_sweep_time,0);

    % Ramp the FB field
curtime  =  AnalogFuncTo(calctime(curtime,0),'FB current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        uWave_sweep_time,uWave_sweep_time,mean_field-del_fesh_current/2);

    % Switch Rb microwave source to Sextupled SRS for whatever follows
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler    
        
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % F=2 Pulse Blow Away
    %%%%%%%%%%%%%%%%%%%%%%%
    if do_F2_blowaway
        dispLineStr('Blowing Rb F=2 away',curtime);

        %wait a bit before pulse
        curtime = calctime(curtime,0);

        setAnalogChannel(calctime(curtime,-10),4,0.0); % set amplitude   0.7
        AnalogFuncTo(calctime(curtime,-15),34,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,6590-237); % Ramp Rb trap laser to resonance   237

        probe32_trap_detuning = 0;
        f_osc = calcOffsetLockFreq(probe32_trap_detuning,'Probe32');
        DDS_id = 3;    
        DDS_sweep(calctime(curtime,-15),DDS_id,f_osc*1e6,f_osc*1e6,1);    
        
        
        
        AnalogFuncTo(calctime(curtime,-15),35,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,1.2,1); % Ramp FF to Rb trap beat-lock 
        setDigitalChannel(calctime(curtime,-10),25,1); % open Rb probe shutter
        setDigitalChannel(calctime(curtime,-10),24,1); % disable AOM rf (TTL), just to be sure
        RbF2_kill_time_list =[2]; 3;
        pulse_time = getScanParameter(RbF2_kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'RbF2_kill_time');
curtime = DigitalPulse(calctime(curtime,0),24,pulse_time,0); % pulse beam with TTL   15

       setDigitalChannel(calctime(curtime,0),25,0); % close shutter
    end
   
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Final Field Ramp
    %%%%%%%%%%%%%%%%%%%%%%%
    %Ramp the field back down after transfer to keep coil cool
    ramp_fields = 0; % do a field ramp for spectroscopy
    if ramp_fields % if a coil value is not set, this coil will not be changed from its current value
        % shim settings for spectroscopy
        clear('ramp');
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero

        getChannelValue(seqdata,'X Shim',1,0);
        getChannelValue(seqdata,'Y Shim',1,0);
        getChannelValue(seqdata,'Z Shim',1,0);

        %Give ramp shim values if we want to do spectroscopy using the
        %shims instead of FB coil. If nothing set here, then
        %ramp_bias_fields just takes the getChannelValue (which is set to
        %field zeroing values)
        %ramp.xshim_final = 0.146; %0.146
        %ramp.yshim_final = -0.0517;
        %ramp.zshim_final = 1.5;

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 10;
        ramp.fesh_final = 62.92029;% before 2017-1-6 (60/20)*22.6; %22.6
        ramp.settling_time = 100;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

    else
        %some additional hold time
curtime = calctime(curtime,70);70;

    end

end 

%% Rb uWave transfer 3 - Sweep the uWave to transfer Rb
% This section of code transfer the Rb cloud from the |2,2> to the |1,1>
% state using a uWave frequency sweep.

if ( seqdata.flags.xdt_Rb_21uwave_sweep_freq)
    % Ramp the field to the desired value
    dispLineStr('Field Ramp for RF/uWave Transfer',curtime);        

    % F=2 Rb Blow Away
    do_F2_blowaway=1;
    
    %%%%%%%%%%%%%%%%%%%%
    % Field Ramp 
    %%%%%%%%%%%%%%%%%%%%
    % Ramp the shims and FB current to the desired transfer field
    
    mean_field_list = 19.332;
    mean_field = getScanParameter(mean_field_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_Transfer_Field');
       
    shim_ramptime_list = [2];
    shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
  
    % Initialzie Field Ramp
    clear('ramp');
    ramp=struct;
    
    % Shim ramp settings
    ramp.xshim_final = seqdata.params.shim_zero(1);
    ramp.yshim_final = seqdata.params.shim_zero(2);
    ramp.zshim_final = seqdata.params.shim_zero(3);    
    ramp.shim_ramptime = shim_ramptime;
    ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero
   
    % Feshbach Ramp settings
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = 0;
    ramp.fesh_final = mean_field;    
    ramp.settling_time = 50;
    
    disp(['     FB Current (Gauss) : ' num2str(ramp.fesh_final)]);
    disp(['     Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp(['     Settling Time (ms) : ' num2str(ramp.settling_time)]);

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
       
    %%%%%%%%%%%%%%%%%%%%
    % uWave Sweeep Prepare
    %%%%%%%%%%%%%%%%%%%%
%     use_ACSync=0;    
    dispLineStr('Sweeping uWave Rb 2-->1',curtime);   
    
    % uWave Center Frequency
    freq_list = [-0.125];
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rb_uwave_freq_offset','MHz');    
    
    uWave_delta_freq_list=[0.05];
    uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_delta_freq','MHz');
        
    uwave_sweep_time_list =[10]; 
    sweep_time = getScanParameter(uwave_sweep_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_sweep_time','ms');   
     
    Rb_SRS=struct;
    Rb_SRS.Address=29;        % GPIB address of the Rb SRS    
    Rb_SRS.Frequency=6.87560+freq_offset*1E-3; % Frequency in GHz
    Rb_SRS.Frequency=6.83465+2.11*1E-3*mean_field+freq_offset*1E-3; % Frequency in GHz 

    Rb_SRS.Power=9;           % Power in dBm 
    Rb_SRS.Enable=1;          % Power on
    Rb_SRS.EnableSweep=1;     % Sweep on     
    Rb_SRS.SweepRange=uWave_delta_freq; % Sweep range in MHz   
             
    addOutputParam('rb_uwave_pwr',Rb_SRS.Power,'dBm')
    addOutputParam('rb_uwave_frequency',Rb_SRS.Frequency,'GHz');            
    
    disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);
    disp(['     Sweep Range  : ' num2str(uWave_delta_freq) ' MHz']);
    disp(['     Freq Offset  : ' num2str(freq_offset) ' MHz']);     
    
    % Program the SRS    
    programSRS_Rb(Rb_SRS);      
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-35),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-35),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-35),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave) for Rb (1)
    setDigitalChannel(calctime(curtime,-30),'RF/uWave Transfer',1); 
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',1); 
    setDigitalChannel(calctime(curtime,-35),'Rb Source Transfer',0); %0 = SRS, 1 = Sextupler

    % Set initial modulation
    setAnalogChannel(calctime(curtime,-35),'uWave FM/AM',-1);    
    
    %%%%%%%%%%%%%%%%%%%%
    % uWave Sweeep 
    %%%%%%%%%%%%%%%%%%%%           
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',1);      % Turn on uWave 
    AnalogFunc(calctime(curtime,0),'uWave FM/AM',...              % Ramp +-1V
        @(t,T) -1+2*t/T,sweep_time,sweep_time);
    curtime = calctime(curtime,sweep_time);                       % Wait
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);      % Turn off uWave
    
    % Reset the uWave deviation after a while
    setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);  
    
    % Pulse F=2 to kill untransfered Rb
    if do_F2_blowaway
        disp('Blowing the F=2 away');
        %wait a bit before pulse
        setAnalogChannel(calctime(curtime,-10),4,0.0); % set amplitude   0.7
        AnalogFuncTo(calctime(curtime,-15),34,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,6590-237); % Ramp Rb trap laser to resonance   237
        AnalogFuncTo(calctime(curtime,-15),35,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,1.2,1); % Ramp FF to Rb trap beat-lock 
        setDigitalChannel(calctime(curtime,-10),25,1); % open Rb probe shutter
        setDigitalChannel(calctime(curtime,-10),24,1); % disable AOM rf (TTL), just to be sure
        RbF2_kill_time_list =[1]; 3;
        pulse_time = getScanParameter(RbF2_kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'RbF2_kill_time');
curtime = DigitalPulse(calctime(curtime,0),24,pulse_time,0); % pulse beam with TTL   15
        setDigitalChannel(calctime(curtime,0),25,0); % close shutter
        
        disp(['     Pulse Time (ms) : ' num2str(pulse_time)]);
    end 
    
    % Extra wait a little bit
    time_list = [0];
    wait_time =  getScanParameter(time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uwave_rf_hold_time','ms');
curtime = calctime(curtime,wait_time);
end 
     
%% 40K RF Sweep Init
%Sweep 40K to |9/2,-9/2> before optical evaporation   

if seqdata.flags.xdt_K_p2n_rf_sweep_freq
    dispLineStr('RF K Sweep 9-->-9',curtime);   
    
    % Get the Feshbach value (in G) at this time.
    fesh_value = getChannelValue(seqdata,'FB current',1,0);
    
    
    %Ramp FB if not done previously 
     if fesh_value~=19.332
        clear('ramp');
        ramp=struct;
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 19.332;
        addOutputParam('k_rftransfer_field',ramp.fesh_final);
        ramp.settling_time = 200;%         
        disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
        disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp);   
     end

    disp(' Applying RF sweep to transfer K state.');
    
    % RF Sweep Settings
    k_rf_freq_list = [6.1];[6.05];
    k_rf_pulsetime_list = [100];100;
    k_rf_power_list = [-3];0;-3;
    k_rf_delta_list=[-1.2];[-1];-0.5;   
    
    clear('sweep');
    sweep=struct;
    sweep_pars.freq = getScanParameter(k_rf_freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'k_rftransfer_freq'); 
    sweep_pars.power = getScanParameter(k_rf_power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'k_rftransfer_power'); 
    sweep_pars.pulse_length = getScanParameter(k_rf_pulsetime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_pulsetime');
    sweep_pars.delta_freq = getScanParameter(k_rf_delta_list,...
        seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_delta');        
    sweep_pars.fake_pulse = 0;      %Fake the pulse (for debugging)         
    disp(['     Center Freq     (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq      (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Sweep time       (ms) : ' num2str(sweep_pars.pulse_length)]);
    disp(['     Sweep Rate   (kHz/ms) : ' num2str(1E3*sweep_pars.delta_freq./sweep_pars.pulse_length)]);

    % Apply the RF
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars); 
curtime = calctime(curtime,5);

end

%% Kill F=7/2 in ODT before evap

if (seqdata.flags.xdt_kill_K7_before_evap)
    
    % optical pumping pulse length
    repump_pulse_time_list = [1];
    repump_pulse_time = getScanParameter(repump_pulse_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_time1','ms');
    
    % optical pumping repump power
    repump_power_list = [0.7];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_power1','V');     
    
curtime = calctime(curtime,10);

    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),'K Repump Shutter',1);  
    
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),'K Repump AM',repump_power);

    %repump TTL
    curtime = DigitalPulse(calctime(curtime,0),'K Repump TTL',repump_pulse_time,0); 

    %Close Repump Shutter
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);
    
    %turn repump back down
    setAnalogChannel(calctime(curtime,0),'K Repump AM',0.0);
end

    
%% D1 Optical Pumping in ODT before evap!

if (seqdata.flags.xdt_d1op_start==1)
    dispLineStr('D1 Optical Pumping pre op evap',curtime);  

    op_time_list = [1];
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_time1','ms'); %optical pumping pulse length
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_repump_pwr1','V'); %optical pumping repump power
    D1op_pwr_list = [8]; %min: 0, max:10
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_D1op_pwr1','V'); %optical power

    
    %Determine the requested frequency offset from zero-field resonance
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
            'FeshValue',0.01,'QPValue',0,'SettlingTime',200);

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
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
    
    %Optical pumping time
curtime = calctime(curtime,optical_pump_time);
    
    % Turn off OP before F-pump so atoms repumped back to -9/2.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);

    op_repump_extra_time = 2;
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

clear('ramp');     

        % Ramp the bias fields
newramp = struct('ShimValues',seqdata.params.shim_zero,...
            'FeshValue',20,'QPValue',0,'SettlingTime',100);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);       

    curtime = calctime(curtime,50);
end

%% Spin mixture after Optical Pumping

if seqdata.flags.xdt_rfmix_start
    dispLineStr('RF K Sweeps for -7,-9 mixture.',curtime);  

    if ~seqdata.flags.xdt_d1op_start
        disp(' Ramping the magnetic field');
        % FB coil settings
        ramp=struct;
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 50;

        disp('Ramping fields');
        disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
        disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

        % Ramp the bias fields
        curtime = ramp_bias_fields(calctime(curtime,0), ramp);            
    end    

    %Do RF Sweep
    clear('sweep');

    rf_k_sweep_freqs=[5.995];

    % With delta_freq =0.1;
    % 3.01 --> (-7,-5) (a little -9)
    % 3.07 --> (-1,+1,+3); 
    rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_post_evap');

    sweep_pars.freq=rf_k_sweep_center;        
    sweep_pars.power = -9.2;-9.1;   

    delta_freq_list = -0.01;[0.01];%0.006; 0.01
    sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_post_evap');
    pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
    sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_post_evap');

    n_sweeps_mix_list=[11];
    n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
        seqdata.scancycle,seqdata.randcyclelist,'n_sweeps_mix');  % also is sweep length  0.5               

    
    disp(['     Center Freq      (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq       (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Power              (V) : ' num2str(sweep_pars.power)]);
    disp(['     Sweep time        (ms) : ' num2str(sweep_pars.pulse_length)]);  
    disp(['     Num Sweeps             : ' num2str(n_sweeps_mix)]);  


    f1=sweep_pars.freq-sweep_pars.delta_freq/2;
    f2=sweep_pars.freq+sweep_pars.delta_freq/2;


    T60=16.666; % 60 Hz period

    do_ACync_rf = 1;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-30);
        ACync_end_time = calctime(curtime,(sweep_pars.pulse_length+T60)*n_sweeps_mix+30);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
%         disp([' Sweep Number ' num2str(kk) ]);
        rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        curtime = calctime(curtime,T60);
    end     
curtime = calctime(curtime,50);

end

%% Ramp Magnetic Fields before Optical Evaporation
% Ramp the FB field. This typically is already done by the spin manulations
% so it is unclear if this code is necessary

if seqdata.flags.xdt_ramp_FB_before_evap
    dispLineStr('Ramping FB field prior to optical evaporation',curtime);
    Evap_FB_field_list = [15];
    Evap_FB_field = getScanParameter(Evap_FB_field_list,seqdata.scancycle,...
                seqdata.randcyclelist,'Evap_FB_field','G');
    clear('ramp');

    %  FB coil settings
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = 0;
    ramp.fesh_final = Evap_FB_field;

    if seqdata.flags.CDT_evap
        ramp.settling_time = 0;
    else
        ramp.settling_time = 50;
    end

    disp(['     Field             (G) : ' num2str(ramp.fesh_final)]);
    disp(['     Ramp Time        (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp(['     Settling Time    (ms) : ' num2str(ramp.settling_time)]);

    % Ramp the bias fields
    curtime = ramp_bias_fields(calctime(curtime,0), ramp); 
end
 
  
%% Ramp QP for levitation
% During optical evaporation, the maximum power for sympathetic evaporation
% is limited because the stark shift for K is greater than Rb.  To allow
% for efficient evaporation at high optical powers, apply a levitation
% gradient which prevents K from falling out of the trap, while still
% allowing Rb to fall from gravity.
%
% Has not been shown to work

if seqdata.flags.xdt_levitate_evap
    % QP Value to ramp to
    LF_QP_List =  [.3];.14;0.115;
    LF_QP = getScanParameter(LF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'LF_QPReverse','V');  

    % Ramp C16 and C15 to off values
    pre_ramp_time = 100;
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 

    curtime = calctime(curtime,50);
    % Turn off 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',0); 
    curtime = calctime(curtime,10);

    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage
    QP_FFValue = 23*(LF_QP/.125/30); % voltage FF on delta supply
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        100,100,QP_FFValue);
    curtime = calctime(curtime,50);

    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,LF_QP,1); 
end
%% Preramp
if seqdata.flags.CDT_evap ==1 && seqdata.flags.xdt_ramp2sympathetic
    % Pre ramp powers to sympathtetic cooling regime
    dispLineStr('Ramp to sympathetic regime',curtime);

    % Powers to ramp to 
    dipole_preramp_time = 500;

    disp(['     Ramp Time (ms) : ' num2str(dipole_preramp_time)]);
    disp(['     XDT 1 init (W) : ' num2str(DT1_power(2))]);
    disp(['     XDT 2 init (W) : ' num2str(DT2_power(2))]);            
    disp(['     XDT 1 (W)      : ' num2str(DT1_power(3))]);
    disp(['     XDT 2 (W)      : ' num2str(DT2_power(3))]);            

    % Ramp optical power requests to sympathetic regime
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_preramp_time,dipole_preramp_time,DT1_power(3));
curtime =   AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_preramp_time,dipole_preramp_time,DT2_power(3));
end
%% CDT evap
if ( seqdata.flags.CDT_evap == 1 )
    dispLineStr('Optical evaporation 1',curtime);

    disp(' Performing exponential evaporation');
    disp(['     Evap Time (ms) : ' num2str(evap_time_total)]);
    disp(['     tau       (ms) : ' num2str(evap_time_total)]);
    disp(['     XDT1 end   (W) : ' num2str(DT1_power(4))]);
    disp(['     XDT2 end   (W) : ' num2str(DT2_power(4)*seqdata.params.xdt_p2p1_ratio)]);

    % NOTE: exp_end_pwr moved all the way to top of function!
    P_dip=exp_end_pwr;

    evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));
    
    evap_time_evaluate = evap_time_total;
    
    if doPartialEvap
        evap_time_evaluate_list =  [1]*evap_time_total;
        evap_time_evaluate = getScanParameter(evap_time_evaluate_list,seqdata.scancycle,...
            seqdata.randcyclelist,'evap_time_evaluate','ms');   
    end

    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time_total,exp_tau,DT1_power(4));
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time_total,exp_tau,seqdata.params.xdt_p2p1_ratio*DT2_power(4));
end

%% CDT evap tilt


%% CDT evap 2
if ( seqdata.flags.CDT_evap == 1 && seqdata.flags.xdt_evap2stage)
    dispLineStr('Optical evaporation 2',curtime);
    
    %%%%%%%%%%%%%%%% DO THE SECOND EVAP STAGE %%%%%%%%%%%%%%%%%%%%%
    pend = 0.06;0.06;
    evap_exp_ramp = @(t,tt,tau,y2,y1) ...
        (y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    
    

    evap_time_2_list =  [10000];
    evap_time_2 = getScanParameter(evap_time_2_list,seqdata.scancycle,...
        seqdata.randcyclelist,'evap_time_2','ms');

    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_2,evap_time_2,exp_tau,pend);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_2,evap_time_2,exp_tau,pend);
    
end

%% CDT evap 2 high field

if (seqdata.flags.xdt_evap2_HF && seqdata.flags.xdt_evap2stage == 0)
    curtime = dipole_high_field_evap2(curtime);
end


%% Ramp Dipole Back Up

if seqdata.flags.xdt_ramp_power_end 
    dispLineStr('Ramping XDT Power Back Up',curtime);    
    dip_1 = .1; %1.5
    dip_2 = .1; %1.5
    dip_ramptime = 1000; %1000
    dip_rampstart = 0;
    dip_waittime = 500;
    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1);
    AnalogFuncTo(calctime(curtime,dip_rampstart),...
        'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2);
curtime = calctime(curtime,dip_rampstart+dip_ramptime+dip_waittime);
end


%% AM Modulate Dipole Powers
% AM modulate the dipole trap powers to measure the trap depth. 
% CF : I dont recall ever using this? Kick measurements are likely easier.
% Also, it makes more sense to not modulate the requests because that
% requires the PID to follow. Use the modulation control directly on the
% regulation boxes

if seqdata.flags.xdt_am_modulate
    dispLineStr('Modulate Dipole trap beam power',curtime);    

    % Oscillate with a sinuisoidal function
    dip_osc = @(t,freq,y2,y1)(y1 +y2*sin(2*pi*freq*t/1000));

    dip_osc_time = 500; 1000;       % Duration to modulate             

    dip_osc_offset = exp_end_pwr;   % CDT_rampup_pwr;
    dip_osc_amp = 0.05;             % Oscillation amplitude
    dip_osc_freq_list = [400:10:500 650];
    dip_osc_freq = getScanParameter(dip_osc_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dip_osc_freq');

    % Modify time slightly to ensure complete cycles
    Ncycle = ceil((dip_osc_time*1E-3)*dip_osc_freq);
    dip_osc_time = 1E3*(Ncycle/dip_osc_freq);

    disp(['     Frequency (Hz) : ' num2str(dip_osc_freq)]);
    disp(['     Offset     (W) : ' num2str(dip_osc_offset)]);
    disp(['     Amplitude  (W) : ' num2str(dip_osc_amp)]);
    disp(['     Time      (ms) : ' num2str(dip_osc_time)]);                


    switch seqdata.flags.xdt_am_modulate
        case 1
            AnalogFunc(calctime(curtime,0),'dipoleTrap1',...
                    @(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),...
                    dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);
        case 2
            AnalogFunc(calctime(curtime,0),'dipoleTrap2',...
                  @(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),...
                  dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);   
        otherwise
            error('oh no')
    end 

    % Wait for modulation Time
    curtime=calctime(curtime,dip_osc_time);
    
    % Trigger the scope 
    DigitalPulse(curtime,'ScopeTrigger',10,1);

    % Wait time
    curtime = calctime(curtime,100);    
end

%% Unramp Gradient
% 
% if do_levitate_evap
%     ramp_time_1 = 100;
%     ramp_time_2 = 10;
%     
%     % Ramp off Coil 15
%     curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
%         ramp_time_1,ramp_time_1,0,1);     
%     
%     % Make sure Coil 16 and kitten are low
%     AnalogFuncTo(calctime(curtime,0),'Coil 16',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
%         ramp_time_2,ramp_time_2,0);  
%     curtime = AnalogFuncTo(calctime(curtime,0),'Kitten',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
%         ramp_time_2,ramp_time_2,0,1);   
%     
%     % Enable QP mode of current control
%     setDigitalChannel(curtime,'15/16 Switch',1);
%     
%     % Disable Kitten
%     setDigitalChannel(curtime,'Kitten Relay',0);
%     
%     % Disable Transport FF
%     setAnalogChannel(calctime(curtime,0),'Transport FF',0);
% 
%     % Wait for relay to switch
%     curtime = calctime(curtime,50); 
% end
% 


%% Remove Rb from XDT
% After optical evaporation, it is useful to only have K in the trap. Do
% this by pulsing resonant Rb light

if (seqdata.flags.xdt_kill_Rb_after_evap && seqdata.flags. CDT_evap == 1)

    %repump atoms from F=1 to F=2, and blow away these F=2 atoms with
    %the probe
    %open shutter
    %probe

    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %0=closed, 1=open
    %repump
    setDigitalChannel(calctime(curtime,-10),'Rb Sci Repump',1);
    %open analog
    %probe
    setAnalogChannel(calctime(curtime,-10),'Rb Probe/OP AM',0.7);
    %repump (keep off since no TTL)

    %set TTL
    %probe
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);
    %repump doesn't have one

    %set detuning (Make sure that the laser is not coming from OP
    %resonance... it will take ~75ms to reach the cycling transition)
    setAnalogChannel(calctime(curtime,-10),'Rb Beat Note FM',6590-237);

    % Rb Probe Detuning    
    % Not optimized!!
    f_osc = calcOffsetLockFreq(10,'Probe32');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,-10),DDS_id,f_osc*1e6,f_osc*1e6,1)    



    %pulse beam with TTL 
    %TTL probe pulse
    DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',5,0);
    %repump pulse
    setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0.7);
curtime = setAnalogChannel(calctime(curtime,5),'Rb Repump AM',0.0);

    %close shutter
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); %0=closed, 1=open
curtime = setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0);

curtime=calctime(curtime,100);
end   

%% D1 Optical Pumping in ODT
% After optical evaporation, ensure mF spin polarization via D1 optical
% pumping.

if (seqdata.flags.xdt_d1op_end==1 && seqdata.flags.CDT_evap==1)
    dispLineStr('D1 Optical Pumping post optical evaporation',curtime);  

    % optical pumping pulse length
    op_time_list = [5];[1]; %1
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_time2','ms');
    
    % optical pumping repump power
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_repump_pwr2','V'); 
    
    %optical power
    D1op_pwr_list = [8]; %min: 0, max:10 (CF : I think the AOM power is too low)
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_D1op_pwr2','V'); 

    % fpump extra time
    op_repump_extra_time_list = [2];
    op_repump_extra_time = getScanParameter(op_repump_extra_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_time_extra2','ms');  
    
    % values
    op_after_options = struct;
    op_after_options.op_time = optical_pump_time;
    op_after_options.fpump_power = repump_power;
    op_after_options.d1op_power = D1op_pwr;
    op_after_options.fpump_extratime = op_repump_extra_time;    
    op_after_options.leave_on = 0;    
    
    % Perform optical pumping
    curtime = opticalpumpingD1(curtime,op_after_options);    
end        
    
%% Remix at end: Ensure a 50/50 mixture after spin-mixture evaporation

if (seqdata.flags.xdt_rfmix_end==1 && seqdata.flags.CDT_evap==1)      

    if ~seqdata.flags.xdt_d1op_end
        disp(' Ramping the magnetic field');
        % FB coil settings
        ramp=struct;
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 50;

        disp('Ramping fields');
        disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
        disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

        % Ramp the bias fields
        curtime = ramp_bias_fields(calctime(curtime,0), ramp);            
    end
    
        dispLineStr('RF K Sweeps for -7,-9 mixture.',curtime);  

        %Do RF Sweep
        clear('sweep');
                
        
        rf_k_sweep_freqs=[5.995];

        % With delta_freq =0.1;
        % 3.01 --> (-7,-5) (a little -9)
        % 3.07 --> (-1,+1,+3); 
        rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_post_evap','MHz');
        
        sweep_pars.freq=rf_k_sweep_center;    
        
        sweep_pars.power = -8.5;-9.1;-9.2;   
        
        delta_freq_list =-.01;[0.0040];%0.006; 0.01
        sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_post_evap','MHz');
        pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
        
        sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_post_evap','ms');
                
        disp(['     Center Freq (MHz) : ' num2str(sweep_pars.freq)]);
        disp(['     Delta Freq  (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp(['     Power         (V) : ' num2str(sweep_pars.power)]);
        disp(['     Sweep time   (ms) : ' num2str(sweep_pars.pulse_length)]);          
        
        f1=sweep_pars.freq-sweep_pars.delta_freq/2;
        f2=sweep_pars.freq+sweep_pars.delta_freq/2;
        
        n_sweeps_mix_list=[10];
        n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
            seqdata.scancycle,seqdata.randcyclelist,'n_sweeps_mix');  % also is sweep length  0.5               
        T60=16.666; % 60 Hz period        
        do_ACync_rf = 1;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-30);
            ACync_end_time = calctime(curtime,(sweep_pars.pulse_length+T60)*n_sweeps_mix+30);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
        
        %%%%%%%%%% Manual specification %%%%%%%%%%%%%%
                % DDS Trigger Settings
%         dTP=0.1;        % Pulse duration
%         DDS_ID=1;       % DDS ID
        % Pre-set RF gain and TTL state
%         setAnalogChannel(calctime(curtime,-35),'RF Gain',sweep_pars.power); 
%         setDigitalChannel(calctime(curtime,-35),'RF TTL',0);        
%         for kk=1:n_sweeps_mix        
%             disp([' Sweep Number ' num2str(kk) ]);
% 
%             % Define a frequency sweep        
%             sweep=[DDS_ID 1E6*f1 1E6*f2 sweep_pars.pulse_length];     
%             seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
%             seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;          
%             
%             % Trigger DDS
%             DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
%             
%             % Enable the RF
%             DigitalPulse(curtime,'RF TTL',sweep_pars.pulse_length,1);  
% 
%             % Advance time by 60 Hz period
%             curtime=calctime(curtime,T60);        
%         end        
%         setAnalogChannel(calctime(curtime,1),'RF Gain',-10);         
                 
        %%%%%%%%%% Automatic specification %%%%%%%%%%%%%%
        for kk=1:n_sweeps_mix
            disp([' Sweep Number ' num2str(kk) ]);
            rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
            curtime = calctime(curtime,T60);
        end      
curtime = calctime(curtime,10);

end

%% uWave_K_Spectroscopy
if (seqdata.flags.xdt_uWave_K_Spectroscopy)
    dispLineStr('uWave_K_Spectroscopy',curtime);      
%     
    % FB coil settings
    ramp=struct;
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 20;
    ramp.settling_time = 200;

    disp('Ramping fields');
    disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
    disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

    % Ramp the bias fields
    curtime = ramp_bias_fields(calctime(curtime,0), ramp);   
    
    % Frequency
    freq_shift_list = [5]; % Offset in kHz
    f0 = 1335.811;         % MHz

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
    uwave_hold_time_list = [10];
    uwave_hold_time  = getScanParameter(uwave_hold_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'hold_time','ms');     
    spec_pars.HoldTime = uwave_hold_time;
        
    curtime = K_uWave_Spectroscopy(curtime,spec_pars);    
end

%% Get rid of F = 7/2 K using a repump pulse

if (seqdata.flags.xdt_kill_K7_after_evap && seqdata.flags.CDT_evap == 1)
    
    % optical pumping pulse length
    repump_pulse_time_list = [10];
    repump_pulse_time = getScanParameter(repump_pulse_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_time2','ms');
    
    % optical pumping repump power
    repump_power_list = [0.7];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_power2','V');     
    
curtime = calctime(curtime,10);

    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),'K Repump Shutter',1);  
    
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),'K Repump AM',repump_power);

    %repump TTL
    curtime = DigitalPulse(calctime(curtime,0),'K Repump TTL',repump_pulse_time,0); 

    %Close Repump Shutter
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);
    
    %turn repump back down
    setAnalogChannel(calctime(curtime,0),'K Repump AM',0.0);
end


%% RF Rabi Oscillation

if (seqdata.flags.xdt_k_rf_rabi_oscillation)      
    dispLineStr('RF K Rabi Oscillations',curtime);  

    do_ramp_field=1;
    if do_ramp_field
        disp(' Ramping the magnetic field');
        % FB coil settings
        ramp=struct;
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 50;

        disp('Ramping fields');
        disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
        disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

        % Ramp the bias fields
        curtime = ramp_bias_fields(calctime(curtime,0), ramp);            
    end

    % RF Frequency
    rf_k_freqs=[3.0495];%3.048 [1.8353];3.01;
    rf_k_freq = getScanParameter(rf_k_freqs,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_freq');
    
    % Time for pulse
    pulse_length_list = [.1:.1:1];
    pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_time');
    
    % RF Power
    rf_power_list = [-9];
    rf_power = getScanParameter(rf_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_power');   
    
    rabi_pars=struct;
    rabi_pars.delta_freq   = 0;
    rabi_pars.freq         = rf_k_freq;        
    rabi_pars.power        = rf_power;     
    rabi_pars.pulse_length = pulse_length;

    disp(['     Freq (MHz) : ' num2str(rabi_pars.freq)]);
    disp(['     Power         (V) : ' num2str(rabi_pars.power)]);
    disp(['     Time   (ms) : ' num2str(rabi_pars.pulse_length)]);  

    do_ACync_rf = 1;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-30);
        ACync_end_time = calctime(curtime,rabi_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end

    % Set source to RF
    setDigitalChannel(calctime(curtime,-35),'RF/uWave Transfer',0);   
    
    % Make sure RF is off
    setDigitalChannel(calctime(curtime,-35),'RF TTL',0);   
    
    % Preset RF Gain
    setAnalogChannel(calctime(curtime,-35),'RF Gain',rabi_pars.power);   
            

    % Trigger pulse duration
    dTP=0.1;
    DDS_ID=1;                
        
    % Primary Sweep, constant power            
    sweep=[DDS_ID 1E6*rabi_pars.freq 1E6*rabi_pars.freq rabi_pars.pulse_length+20];    
    DigitalPulse(calctime(curtime,-10),'DDS ADWIN Trigger',dTP,1);      
    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;        
    
    % Pulse the RF
    setDigitalChannel(curtime,'RF TTL',1);         
curtime=calctime(curtime,rabi_pars.pulse_length);            
    setDigitalChannel(curtime,'RF TTL',0); 
    
    % Reset RF power to low
    setAnalogChannel(calctime(curtime,10),'RF Gain',-10);       
    
    
%     curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
%     curtime = calctime(curtime,30);
end


    %% Kick the dipole trap
    %RHYS - An alterative way to measure trap frequency using a piezo mirror to
    %give the atoms a kick. 
    if seqdata.flags.xdt_do_dipole_trap_kick
        dispLineStr('Kicking the dipole trap',curtime);
        %How Long to Wait After Kick
        kick_ramp_time = 100;
        curtime = calctime(curtime, kick_ramp_time+20);
        kick_voltage = 10;
        time_list = [0:0.75:15];
        kick_wait_time =getScanParameter(time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = 0;
        %addOutputparam('kick_wait_time',kick_wait_time);
       
        kick_channel=54;
    
        %Ramp the Piezo Mirror to a Displaced Position
        AnalogFuncTo(calctime(curtime,-kick_ramp_time),kick_channel,...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),kick_ramp_time,kick_ramp_time,kick_voltage);

        %Jump the Piezo Mirror Back to Trap Geometry
        setAnalogChannel(curtime,kick_channel,0,1);

%         %Turn off the ODT1 to measure ODT2 trap frequency only
%         setAnalogChannel(curtime,'dipoleTrap1',-1); 

        %Piezo mirror is reset to 0 at the beginning of Load_MagTrap_Sequence
    end
  
 
    %% Keep XDT On for Some Time
    %RHYS - Either hold for some time after using dipole trap kick, or just
    %holds a bit in general. The one second hold time seems useful for loading
    %the lattice as it gives the rotating waveplate time to turn before the
    %lattice turns on.
    if seqdata.flags.xdt_do_dipole_trap_kick
        curtime = calctime(curtime,kick_wait_time);
    else
        % Why is this hold time here?
        exxdthold_list= [100];
        exxdthold = getScanParameter(exxdthold_list,...
            seqdata.scancycle,seqdata.randcyclelist,'exxdthold','ms');
        curtime=calctime(curtime,exxdthold);%for sparse image
    end
    
    
%% Ramp FB field up before loading lattice

% Before loading the lattices, it is sometimes useful to control the
% magnetic field to establish the interaction (attractive versus repulsive)
% during the loading. Attractive interactions tend to create a larger
% number of doubly occupied sites.
if seqdata.flags.xdt_ramp_up_FB_for_lattice     
    seqdata.params.time_in_HF = curtime;
    Lattice_loading_field_list =[207];
    Lattice_loading_field = getScanParameter(Lattice_loading_field_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Lattice_loading_field','G');

    % Coarse initial ramp to 195 G
    clear('ramp');
    ramp.fesh_ramptime = 150;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 195;
    ramp.settling_time = 100;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    
    % Secondary ramp to final field
    clear('ramp');
    ramp.fesh_ramptime = 2;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = Lattice_loading_field;
    ramp.settling_time = 50;
    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
end
    
%% Dipole Trap High Field Operations 1
% Perform operations in the dipole trap at high magnetic field.

if (seqdata.flags.xdt_high_field_a)    
    dispLineStr('Dipole Trap High Field a',curtime);
    curtime = dipole_high_field_a(curtime);  
end
     
%% Ramp Feshbach and QP Coils
% To characerize field gradients, it is useful to ramp the FB and QP coils
% at the end of evaporation. Strong field gradients kick atoms out of the
% trap. And a "round trip" magnetic field ramp tests this.
if seqdata.flags.xdt_ramp_QP_FB_and_back
    dispLineStr('Ramping Fields Up and Down',curtime);

    % Feshvalue to ramp to
    HF_FeshValue_Initial_List =[195];
    HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_Fesh_RampUpDown','G');    

    clear('ramp');       
    doRampQPPre=1;
   if doRampQPPre
    % QP Value to ramp to
    HF_QP_List =  [0.117];.14;0.115;
    HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'LF_QPReverse','V');  

    % Ramp C16 and C15 to off values
    pre_ramp_time = 100;
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 

    curtime = calctime(curtime,50);
    % Turn off 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',0); 
    curtime = calctime(curtime,10);

    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage
    QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        100,100,QP_FFValue);
    curtime = calctime(curtime,50);

    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 
   end

       % Ramp the Feshbach Coils.
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = -0;   
    ramp.FeshValue = HF_FeshValue_Initial;
    ramp.SettlingTime = 50; 


    disp(['     Ramp Time     (ms) : ' num2str(ramp.FeshRampTime)]);
    disp(['     Settling Time (ms) : ' num2str(ramp.SettlingTime)]);
    disp(['     Fesh Value     (G) : ' num2str(ramp.FeshValue)]);

curtime = rampMagneticFields(calctime(curtime,0), ramp);

    wait_time = 5000;
curtime = calctime(curtime,wait_time);

    clear('ramp');
    % Ramp Back to original values
    ramp.SettlingTime = 50;
    
    % Feshbach Ramp
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = 0;   
    ramp.FeshValue = 20;
    
%     % Ramp the QP Coils off
%     ramp.QPRampTime = ramp.FeshRampTime;
%     
%     if doRampQPNormal
%         ramp.QPReverse = 0;
%         ramp.QPValue = 0;  
%     end
    
    curtime = rampMagneticFields(calctime(curtime,0), ramp);
%     
    if doRampQPPre
%         curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0.062,1);  
             curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1); 
        
        curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            5,5,0);   
    end
%     
%     % Go back to "normal" configuration
%     curtime = calctime(curtime,10);
%     % Turn off reverse QP switch
%     setDigitalChannel(curtime,'Reverse QP Switch',0);
%     curtime = calctime(curtime,10);
% 
%     % Turn on 15/16 switch
%     setDigitalChannel(curtime,'15/16 Switch',1);
%     curtime = calctime(curtime,10);
% 


end

%% Unlevitate
if seqdata.flags.xdt_unlevitate_evap 
    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1); 
    curtime = calctime(curtime,100);
end


%% XDT Hold

if seqdata.flags.xdt_do_hold_end 
    dispLineStr('Holding XDT at End',curtime);
    xdt_wait_time_list = [15000];
    xdt_wait_time = getScanParameter(xdt_wait_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'xdt_wait_time','ms');   
    curtime = calctime(curtime,xdt_wait_time);
end
%% The End!

timeout = curtime;
dispLineStr('Dipole Transfer complete',curtime);

end