function [timeout,I_QP,V_QP,P_dip,dip_holdtime,I_shim] =  dipole_transfer(timein, I_QP, V_QP,I_shim)

curtime = timein;
global seqdata;

%% Flags
%Dipole Loading Flags
%--------------------    
QP_value = I_QP;
vSet = V_QP;
qp_ramp_down_start_time = 0;
%stages of QP-dipole transfer
do_qp_ramp_down1 = 1;%1
do_qp_ramp_down2 = 1;%1
ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt); %try linear versus min jerk
%ramp_func = @(t,tt,y2,y1)(minimum_jerk(t,tt,y2-y1)+y1); 

%Evaporation in the XDT
%-------------------- 
tilt_evaporation = 0;
dipole_holdtime_before_evap = 0;    % not a flag but a value
ramp_Feshbach_B_before_CDT_evap = 0;

Evap_End_Power_List = [0.07];0.08;[0.08];

% Ending optical evaporation
exp_end_pwr = getScanParameter(Evap_End_Power_List,...
    seqdata.scancycle,seqdata.randcyclelist,'Evap_End_Power','W');    

% Second Stage ending evaporation power
Evap2_End_Power_List = [0.07];    
% Ending optical evaporation
exp_end_pwr2 = getScanParameter(Evap2_End_Power_List,...
    seqdata.scancycle,seqdata.randcyclelist,'Evap_End_Power2','W');

%%%%%%%%%%%%%%%%%%%%%%%%%%
%After Evaporation (unless CDT_evap = 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%
ramp_XDT_up = 0;                % Ramp dipole back up after evaporation before any further physics 
do_dipole_trap_kick = 0;        % Kick the dipole trap, inducing coherent oscillations for temperature measurement



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spectroscopy after Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%

do_K_uwave_spectroscopy = 0;    % do uWave Spectroscopy of 40K
do_K_uwave_multi_sweeps = 0;    % do multiple uWave sweeps of 40K
do_Rb_uwave_spectroscopy = 0;   % do uWave Spectroscopy of 87Rb
do_RF_spectroscopy = 0;         % do spectroscopy with DDS 
do_field_ramps = 0;             % Ramp shim and FB fields without spectroscopy
ramp_XDT_after_evap = 0;        % Ramp XDT up after evaporation to keep Rb and K at same location for lattice aligment              
k_rf_rabi_oscillation=0;        % RF rabi oscillations after evap
ramp_QP_FB_and_back = 0;        % Ramp up and down FB and QP to test field gradients
do_K_uWaveSpectrscopy_CORA = 1;
seqdata.flags.ramp_up_FB_for_lattice = 0;     %Ramp FB up at the end of evap  

%%%%%%%%%%%%%%%%%%%%%%%%%%
% FB Field and evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%

if qp_ramp_down_start_time<0
    error('QP ramp must happen after time zero');
end
    
%% XDT Powers

%%%%% Specify the XDT2 power relative to XDT1 %%%%%%%%%%%%%%%%%%%%%%%%%
% Power function of XDT1 relative to XDT2. Useful for making
% circularly symmetric trap at end of evaporation.
XDT2_power_func = @(x) x;

% Initial XDT power
P12_list = [1.4];1.4;
P12 = getScanParameter(P12_list,seqdata.scancycle,...
    seqdata.randcyclelist,'XDT_initial_power','W');
P1 = P12;
P2 = P12;       

% Sympathetic cooling powers
Pevap_list = [.8];
Pevap = getScanParameter(Pevap_list,...
    seqdata.scancycle,seqdata.randcyclelist,'XDT_Pevap','W');
P1e = Pevap; %0.8
P2e = Pevap; %0.8

% Final optical power
xdt1_end_power = exp_end_pwr;    
xdt2_end_power = XDT2_power_func(exp_end_pwr);

% Evaporation Time
Time_List =  [18]*1e3; % [15000] for normal experiment
Evap_time = getScanParameter(Time_List,seqdata.scancycle,...
    seqdata.randcyclelist,'evap_time','ms');   
exp_evap_time = Evap_time;      

% Exponetial time factor
Tau_List = [3.5];%[5];
exp_tau_frac = getScanParameter(Tau_List,seqdata.scancycle,...
    seqdata.randcyclelist,'Evap_Tau_frac');
exp_tau=Evap_time/exp_tau_frac;

% Power vector (load, hold, sympathetic, final)
DT1_power = 1*[P1 P1 P1e xdt1_end_power];
%     DT1_power = -1*[1         1        1          1]; 
DT2_power = 1*[P2 P2 P2e xdt2_end_power];  
%     DT2_power = -1*[1         1        1          1];  

%% Special Flags
% CF : I have no idea what this is for
if seqdata.flags.rb_vert_insitu_image
    seqdata.flags.do_Rb_uwave_transfer_in_ODT = 0;
    get_rid_of_Rb = 0;
    exp_end_pwr =0.18;
end

%% Sanity checks
if ( do_K_uwave_spectroscopy + do_Rb_uwave_spectroscopy + do_RF_spectroscopy ) > 1
    buildWarning('dipole_transfer','More than one type of spectroscopy is selected! Need specific solution?',1)
end

%% Dipole trap initial ramp on
% Perform the initial ramp on of dipole trap 1

    dipole_ramp_start_time_list =[0]; [-500];
    dipole_ramp_start_time = getScanParameter(dipole_ramp_start_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_start_time');
    
    %dipole_ramp_start_time = -500; % Offset time to begin ramp on   
    
    dipole_ramp_up_time_list = [75]; 
    dipole_ramp_up_time = getScanParameter(dipole_ramp_up_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_up_time');
%     dipole_ramp_up_time = 200;      % Duration of initial ramp on

    % CF : What are thes for? Can we delete?
    %RHYS - Actually unused. 
    CDT_power = 3.8;%3.5; %4.5   7.0 Jan 22nd
    dipole1_power = CDT_power*1; %1
    dipole2_power = CDT_power*0; %Voltage = 0.328 + 0.2375*dipole_power...about 4.2Watts/V when dipole 1 is off

    % CF : This is no longer used??
    % Enable ALPs feedback control and turn on XDTs AOMs
    setDigitalChannel(calctime(curtime,dipole_ramp_start_time-10),...
        'XDT Direct Control',0);
    
    % Enable XDT AOMs
    setDigitalChannel(calctime(curtime,dipole_ramp_start_time-10),'XDT TTL',0);  
    dispLineStr('ODT 1 ramp up started at',calctime(curtime,dipole_ramp_start_time));

    % Trigger function generator
%     DigitalPulse(calctime(curtime,dipole_ramp_start_time),...
%         'ODT Rigol Trigger',1,1)
    
    % Ramp dipole 1 trap on
    AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
        'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_ramp_up_time,dipole_ramp_up_time,...
        seqdata.params.ODT_zeros(1),DT1_power(1));
    
    % Ramp dipole 2 trap on
    AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
        'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_ramp_up_time,dipole_ramp_up_time,...
        seqdata.params.ODT_zeros(2),DT2_power(1)); %used to be starting from -1  
    
    ScopeTriggerPulse(curtime,'Rampup ODT');
    %% Ramp the QP Down    
    % Make sure shims are allowed to be bipolar (not necessary?)
    setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);

    QP_curval = QP_value;
    
    %value to ramp down to first
    QP_ramp_end1_list = [0.9];
    QP_ramp_end1 = getScanParameter(QP_ramp_end1_list*1.78,seqdata.scancycle,seqdata.randcyclelist,'QP_ramp_end1');
    
    qp_ramp_down_time1_list = [300];[250];[250];
    qp_ramp_down_time1 = getScanParameter(qp_ramp_down_time1_list,seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time1');        
       
    %value to ramp down to second
    QP_ramp_end2 = 0*1.78; %0*1.78 // doubled Dec-2013 (tighter hybrid trap)
    qp_ramp_down_time2_list = [100];100;
    qp_ramp_down_time2 = getScanParameter(qp_ramp_down_time2_list,seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time2');        

    %RHYS - I think this is now 0*500 because curtime is updated between
    %the two ramps. 
    qp_rampdown_starttime2 = 0; %500
    %RHYS - This used to be the larger value of 5.25.
    mean_fesh_current = 5.25392;%before 2017-1-6   22.6/4; %Calculated resonant fesh current. Feb 6th. %Rb: 21, K: 21
    fesh_current = mean_fesh_current;
        
    vSet_ramp = 1.07*vSet; %24   
    
    extra_hold_time_list =0;[0,50,100,200,500,750,1000]; %PX added for measuring lifetime hoding in high power XDT
    extra_hold_time = getScanParameter(extra_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'extra_hold_time');
    
    % Check thermal power dissipation
    if vSet_ramp^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
   
    %ramp up voltage supply depending on transfer
    %AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),dipole_transfer_time,dipole_transfer_time,vSet_ramp-vSet);
   
    %try to get servo to integrate down
    %AnalogFunc(calctime(curtime,-150),1,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),150,150,QP_curval*0.85,QP_curval);
     
    %setAnalogChannel(calctime(curtime,-150),1,QP_curval*0.82);
    %QP_curval = QP_curval*0.82;
    
%%%% QP RAMP DOWN PART 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    if do_qp_ramp_down1  
        dispLineStr('QP RAMP DOWN 1',curtime);
        
        % Calculate the change in QP current
        dI_QP=QP_ramp_end1-QP_curval; 
                
        % Calculate the change in shim currents
%         Cx = -0.0499;
%         Cy = 0.0045;
%         Cz = 0.0105;
        
        Cx = seqdata.params.plug_shims_slopes(1);
        Cy = seqdata.params.plug_shims_slopes(2);
        Cz = seqdata.params.plug_shims_slopes(3);
        
        dIx=dI_QP*Cx;
        dIy=dI_QP*Cy;
        dIz=dI_QP*Cz;   
                
        % Calculate the new shim values
        I_shim = I_shim + [dIx dIy dIz];        

        % Ramp the XYZ shims to new shim values
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Z Shim',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time1,qp_ramp_down_time1,I_shim(3),3); 
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Y Shim',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time1,qp_ramp_down_time1,I_shim(2),4); 
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'X Shim',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time1,qp_ramp_down_time1,I_shim(1),3); 

        % Turn off plug
        %AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),33,...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time1,qp_ramp_down_time1,0);

        % Ramp down FF.
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),...
            'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),...
            qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1*23/30);
        
        % Ramp down QP and advance time
        curtime = AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),...
            'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1);

        % Some extra advances in time (WHAT IS THIS FOR?)
        if (dipole_ramp_start_time+dipole_ramp_up_time)>(qp_ramp_down_start_time+qp_ramp_down_time1)
            curtime =   calctime(curtime,(dipole_ramp_start_time+dipole_ramp_up_time)-(qp_ramp_down_start_time+qp_ramp_down_time1));
        end
        
        I_QP  = QP_ramp_end1;        
 
    else
        I_QP = QP_curval;
    end
    
%%%% QP RAMP DOWN PART 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
   
    if do_qp_ramp_down2
        dispLineStr('QP RAMP DOWN 2',curtime);

        XDT_pin_time_list = [0];
        XDT_pin_time = getScanParameter(XDT_pin_time_list,seqdata.scancycle,seqdata.randcyclelist,'XDT_pin_time');                
        
        dipole2_ramp_start_time = 0; 
        
        % Ramp ODT2
        AnalogFuncTo(calctime(curtime,dipole2_ramp_start_time),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            XDT_pin_time,XDT_pin_time,DT2_power(2));
        
        % Ramp ODT1
        curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            XDT_pin_time,XDT_pin_time,DT1_power(2));
  

        % Ramp Feshbach field
        FB_time_list = [0];
        FB_time = getScanParameter(FB_time_list,seqdata.scancycle,seqdata.randcyclelist,'FB_time');
        setDigitalChannel(calctime(curtime,-100-FB_time),'fast FB Switch',1); %switch Feshbach field on
        setAnalogChannel(calctime(curtime,-95-FB_time),'FB current',0.0); %switch Feshbach field closer to on
        setDigitalChannel(calctime(curtime,-100-FB_time),'FB Integrator OFF',0); %switch Feshbach integrator on            
        %linear ramp from zero
        AnalogFunc(calctime(curtime,0-FB_time),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time2+FB_time,qp_ramp_down_time2+FB_time, fesh_current,0);
        fesh_current_val = fesh_current;    

        % Ramp down Feedforward voltage
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),18,@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2*23/30);      
        
        % ramp down QP currents
        AnalogFuncTo(calctime(curtime,0*qp_rampdown_starttime2),1,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2);
           
        % Calculate the change in QP currents
        dI_QP=QP_ramp_end2-QP_ramp_end1; 
        
        % Calculate the change in shim currents
%         Cx = -0.0499;
%         Cy = 0.0045;
%         Cz = 0.0105;
        
        Cx = seqdata.params.plug_shims_slopes(1);
        Cy = seqdata.params.plug_shims_slopes(2);
        Cz = seqdata.params.plug_shims_slopes(3);         
        
        dIx=dI_QP*Cx;
        dIy=dI_QP*Cy;
        dIz=dI_QP*Cz;    
        
        % Calculate the new shim values
        I_shim = I_shim + [dIx dIy dIz];
        
        % Ramp shims
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Z shim',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time2,qp_ramp_down_time2,I_shim(3),3); 
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Y Shim',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time2,qp_ramp_down_time2,I_shim(2),4); 
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'X Shim'....
            ,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            qp_ramp_down_time2,qp_ramp_down_time2,I_shim(1),3);
        
        % Save the shim values (appears unused?)
        seqdata.params.yshim_val = I_shim(2);
        seqdata.params.xshim_val = I_shim(1);
        seqdata.params.zshim_val = I_shim(3);

        % Advance time (CF: this seems weirdly defined?)
        curtime = calctime(curtime,qp_rampdown_starttime2+qp_ramp_down_time2+extra_hold_time);   
 
        I_QP  = QP_ramp_end2;
        
        if QP_ramp_end2 <= 0 % second rampdown segment concludes QP rampdown
            
            setAnalogChannel(calctime(curtime,0),1,0);%1
            %setAnalogChannel(calctime(curtime,qp_rampdown_starttime2+qp_ramp_down_time2),18,0);
            
            %make sure all coils are zero!!!
            %set all transport coils to zero (except MOT)
            for i = [7 8 9:17 22:24 20] 
                setAnalogChannel(calctime(curtime,0),i,0,1);
            end
            
        end

    else
        dipole2_pin_pwr = 4.5;%2.5
    end

    V_QP = vSet_ramp;
        
    % Turn off the plug beam now that the QP coils are off
    plug_turnoff_time_list =[0]; -200;
    plug_turnoff_time = getScanParameter(plug_turnoff_time_list,seqdata.scancycle,seqdata.randcyclelist,'plug_turnoff_time');
    setDigitalChannel(calctime(curtime,plug_turnoff_time),'Plug Shutter',0);%0:OFF; 1:ON; -200
    dispLineStr('Turning off plug ',calctime(curtime,plug_turnoff_time));
 
    % Update the dipole trap powers
    P_dip = dipole1_power;
    P_dip2 = DT2_power(2);
    %P_dip2 = dipole2_power; %Dipole 2 Power is definied to be zero, and
    %dipole 2 is instead ramped up to dipole2_pin_power
     
    % CF: Is this useful? Delete?
    do_dipole_handover = 0;
    if do_dipole_handover % for alignment checks -- load from DT1 in DT2
        handover_time = 50;
        DT2_handover_power = 4.5;
        %ramp dipole 1 trap down and ramp dipole 2 trap up
        AnalogFuncTo(calctime(curtime,0),40,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),handover_time,handover_time,0);
        curtime = AnalogFuncTo(calctime(curtime,0),38,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),handover_time,handover_time,DT2_handover_power);
    end

    %% Turn Off Voltage on Transport and Shim Supply 

    ScopeTriggerPulse(calctime(curtime,0),'Transport Supply Off');

    %Turn off Transport Supply
% curtime=AnalogFunc(calctime(curtime,-500),18,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),500,500,0,15.8);

    %Use QP TTL to shut off coil 16 
    setDigitalChannel(calctime(curtime,0),21,1);

    %Turn Coil 15 FET off
    setAnalogChannel(calctime(curtime,0),21,0,1);

    %Hold for some time (field settling?)
curtime = calctime(curtime,dipole_holdtime_before_evap);


%% Rb uWave 1 SWEEP FESHBACH FIELD

%Pre-ramp the field to 20G for transfer
if ( seqdata.flags.do_Rb_uwave_transfer_in_ODT)      
    dispLineStr('uWave Rb 2-->1',curtime);
    
    init_ramp_fields = 1; % Ramp field to starting value?
    do_F2_blowaway = 1; % Remove remaining F=2 atoms after transfer?


    %%%%%%%%%%%%%%%%%%%%%%%%
    % Program the SRS
    %%%%%%%%%%%%%%%%%%%%%%%
    % Use this code if using the SRS (instead of the Anritsu) to
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
    mean_field_list = 19.432;
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
               
        getChannelValue(seqdata,27,1,0);
        getChannelValue(seqdata,19,1,0);
        getChannelValue(seqdata,28,1,0);

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
        DDS_sweep(calctime(curtime,-15),DDS_id,f_osc*1e6,f_osc*1e6,1)    
        
        
        
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

        getChannelValue(seqdata,27,1,0);
        getChannelValue(seqdata,19,1,0);
        getChannelValue(seqdata,28,1,0);

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

if ( seqdata.flags.do_Rb_uwave_transfer_in_ODT2)
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

if seqdata.flags.init_K_RF_sweep
    dispLineStr('RF K Sweep 9-->-9',curtime);   
    
    % Get the Feshbach value (in G) at this time.
    fesh_value = getChannelValue(seqdata,'FB current',1,0);
    
    
    %Ramp FB if not done previously
%      if ~seqdata.flags.do_Rb_uwave_transfer_in_ODT && ~seqdata.flags.do_Rb_uwave_transfer_in_ODT2
         
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
    k_rf_freq_list = [6.05];
    k_rf_pulsetime_list = [100];100;
    k_rf_power_list = [-3];0;-3;
    k_rf_delta_list=[-1];-0.5;   
    
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

if (seqdata.flags.kill_K7_before_evap)
    
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

if (seqdata.flags.do_D1OP_before_evap==1)
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

if seqdata.flags.mix_at_beginning
    dispLineStr('RF K Sweeps for -7,-9 mixture.',curtime);  

    if ~seqdata.flags.do_D1OP_before_evap
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

    disp(['     Center Freq      (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq       (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Power              (V) : ' num2str(sweep_pars.power)]);
    disp(['     Sweep time        (ms) : ' num2str(sweep_pars.pulse_length)]);  


    f1=sweep_pars.freq-sweep_pars.delta_freq/2;
    f2=sweep_pars.freq+sweep_pars.delta_freq/2;

    n_sweeps_mix_list=[11];
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
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
        disp([' Sweep Number ' num2str(kk) ]);
        rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        curtime = calctime(curtime,T60);
    end     
curtime = calctime(curtime,50);

end

%% Ramp Magnetic Fields before Optical Evaporation

if ramp_Feshbach_B_before_CDT_evap

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
 
  



%% CDT evap
%RHYS - Imporant code, definitely should be kept and cleaned up.
if ( seqdata.flags.CDT_evap == 1 )
    dispLineStr('Optical evaporation',curtime);

    % Flag to perform optical exponential optical evaporation
    expevap = 1;

    % Flag to ramp the powers to sympathetic cooling regime
    do_pre_ramp = 1;

    % Pre ramp powers to sympathtetic cooling regime
    if do_pre_ramp 
        disp(' Performing pre ramp to sympathetic power regime');

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

    if expevap
        disp(' Performing exponential evaporation');
        disp(['     Evap Time (ms) : ' num2str(exp_evap_time)]);
        disp(['     tau       (ms) : ' num2str(exp_evap_time)]);
        disp(['     XDT1 end   (W) : ' num2str(DT1_power(4))]);
        disp(['     XDT2 end   (W) : ' num2str(DT2_power(4)*seqdata.params.XDT_area_ratio)]);


        % NOTE: exp_end_pwr moved all the way to top of function!
        P_dip=exp_end_pwr;

        evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));

        dipole1_exp_pwr = 1.0;
        dipole2_exp_pwr = 1*1; %2.2 for ODT beam sizes prior to Nov 2013, now beams have same equal area

        %Turn on dimple beam near end of evaporation.
        Dimple_in_XDT = 0;
        if(Dimple_in_XDT)
            Dimple_Ramp_Time = 50;
            Dimple_Power = 0.5;
            Dimple_On_Time_Scale = 0.8;
            setDigitalChannel(calctime(curtime,exp_evap_time*Dimple_On_Time_Scale),'Dimple TTL',0);%0
            AnalogFuncTo(calctime(curtime,exp_evap_time*Dimple_On_Time_Scale),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, Dimple_Power); 
        end

        % EXPONENTIAL RAMP 
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap_time,exp_evap_time,exp_tau,DT1_power(4));
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap_time,exp_evap_time,exp_tau,seqdata.params.XDT_area_ratio*DT2_power(4));


        dipole_oscillation = 0;
        % Oscillate trap after evaporation
        if dipole_oscillation
            disp(' Oscillating dipole depths.');

            % Oscillate with a sinuisoidal function
            dip_osc = @(t,freq,y2,y1)(y1 +y2*sin(2*pi*freq*t/1000));

            dip_osc_time = 500; 1000;       % Duration to modulate             

            dip_osc_offset = exp_end_pwr;   % CDT_rampup_pwr;
            dip_osc_amp = 0.05;             % Oscillation amplitude
            dip_osc_freq_list = [400:10:500 650];
            dip_osc_freq = getScanParameter(dip_osc_freq_list,seqdata.scancycle,seqdata.randcyclelist,'dip_osc_freq');

            % Modify time slightly to ensure complete cycles
            Ncycle = ceil((dip_osc_time*1E-3)*dip_osc_freq);
            dip_osc_time = 1E3*(Ncycle/dip_osc_freq);

            disp(['     Frequency (Hz) : ' num2str(dip_osc_freq)]);
            disp(['     Offset     (W) : ' num2str(dip_osc_offset)]);
            disp(['     Amplitude  (W) : ' num2str(dip_osc_amp)]);
            disp(['     Time      (ms) : ' num2str(dip_osc_time)]);                

            %oscillate dipole 1 
            AnalogFunc(calctime(curtime,0),'dipoleTrap1',@(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);
            %oscillate dipole 2 
%                 curtime = AnalogFunc(calctime(curtime,0),'dipoleTrap2',@(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);    

            % Advance Time
            curtime=calctime(curtime,dip_osc_time);
            % Trigger the scope 
            DigitalPulse(curtime,'ScopeTrigger',10,1);

curtime = calctime(curtime,100);

        end

curtime = calctime(curtime,0); %100      
        %this time gets passed out of function to keep cycle constant time
        dip_holdtime=25000-exp_evap_time;

    end
else
    dip_holdtime=25000;
end

%% Two Stage High Field Evaporation
% This evaporates at high field from the initial evaporation

if (seqdata.flags.CDT_evap_2_high_field==1)
    dispLineStr('Optical evaporation at high field',curtime);    
    curtime = dipole_high_field_evap(timein)       
end

%% Ramp Dipole Back Up Before Spectroscopy
%RHYS - Hmmm, sure. 
if ramp_XDT_up
    dip_1 = .1; %1.5
    dip_2 = .1; %1.5
    dip_ramptime = 1000; %1000
    dip_rampstart = 0;
    dip_waittime = 500;

    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1);
    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2);
curtime = calctime(curtime,dip_rampstart+dip_ramptime+dip_waittime);
end



%% Remove Rb from XDT
% After optical evaporation, it is useful to only have K in the trap. Do
% this by pulsing resonant Rb light

if (seqdata.flags.kill_Rb_after_evap && seqdata.flags. CDT_evap == 1)

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



%% Do field ramp for spectroscopy

% Shim values for zero field found via spectroscopy
%x_Bzero = 0.115; %0.03 minimizes field
%y_Bzero = -0.0925; %-0.075  -0.07 minimizes field
%z_Bzero = -0.145;% Z BIPOLAR PARAM, -0.075 minimizes the field
%(May 20th, 2013)
% To not ramp a field but leave it at its current value: do not specify the
% respective value, e.g. do not specify a value for ramp.xshim_final to
% keep current value.

% % %ADD FIELD RAMP HERE
% % %Ramp dipole on before pulsing the lattice beam. This should allow for
% % %better alignment of lattice to the potassium cloud, avoiding issue of
% % %gravitational sag for Rb. The XDT is then snapped off after the
% % %lattice pulse. 

%dip_1 = 1;
%dip_2 = 1;
%dip_ramptime = 1000; %1000
%dip_rampstart = 50;

%ramp_XDT_before_spect = 1;

%if ramp_XDT_before_spect
    %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1);
    %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2);
%curtime = calctime(curtime,dip_rampstart+dip_ramptime);
%end



%RHYS - All the various types of spectroscopy share a common field ramp
%code, which bring the FB field to some value. Again, I think the field
%ramp should just be part of a general spectroscopy function, however.
if ( do_K_uwave_spectroscopy || do_K_uwave_multi_sweeps || do_Rb_uwave_spectroscopy || do_RF_spectroscopy || do_field_ramps )

    ramp_fields = 1; % do a field ramp for spectroscopy

    if ramp_fields
        clear('ramp');
        %ramp.shim_ramptime = 50;
        %ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero

        %getChannelValue(seqdata,27,1,0)
        %getChannelValue(seqdata,19,1,0)
        %getChannelValue(seqdata,28,1,0)

        %First, ramp on a quantizing shim.
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -0;
        ramp.xshim_final = getChannelValue(seqdata,27,1,0);
        ramp.yshim_final = getChannelValue(seqdata,19,1,0);%1.61;
        ramp.zshim_final = getChannelValue(seqdata,28,1,0);%getChannelValue(seqdata,28,1,0); %0.065 for -1MHz   getChannelValue(seqdata,28,1,0)
        addOutputParam('shim_value',ramp.zshim_final - getChannelValue(seqdata,28,1,0))

        %Give ramp shim values if we want to do spectroscopy using the
        %shims instead of FB coil. If nothing set here, then
        %ramp_bias_fields just takes the getChannelValue (which is set to
        %field zeroing values)
        %ramp.xshim_final = getChannelValue(seqdata,27,1,0);
        %ramp.yshim_final = 1;
        %ramp.zshim_final = getChannelValue(seqdata,28,1,0);

        %FB coil settings for spectroscopy
        %ramp.fesh_ramptime = 50;
        %ramp.fesh_ramp_delay = -0;
        %ramp.fesh_final = 1.0105*2*22.6; %1.0077*2*22.6 for same transfer as plane selection

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_off_delay = 0;
        %B_List = [199.6 200.6 201 202.3 202.6 201.3:0.05:202.2];
        %B = getScanParameter(B_List,seqdata.scancycle,seqdata.randcyclelist,'B_Field');

        ramp.fesh_final = 25;%before 2017-1-6 2*22.6; %6*22.6*1.0068 - Current values for optimal stub-tuning near 120G.

        ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes

        %QP coil settings for spectroscopy
        %ramp.QP_ramptime = 50;
        %ramp.QP_ramp_delay = -0;
        %ramp.QP_final =  0*1.78; %7


        ramp.settling_time = 200;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
end


%% uWave spectroscopy (K or Rb)
%RHYS - More spectroscopy code to clean. These ones actually get used on
%occasion for checking field calibration.
if do_K_uwave_spectroscopy
    dispLineStr('do_K_uwave_spectroscopy',curtime);
    clear('spect_pars');

    freq_list = [0]/1000;
    freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
    %Currently 1390.75 for 2*22.6.
    spect_pars.freq = 1335.845 + freq_val; %Optimal stub-tuning frequency. Center of a sweep (~1390.75 for 2*22.6 and -9/2; ~1498.25 for 4*22.6 and -9/2)
    spect_pars.power = 15; %dBm
    spect_pars.delta_freq = 500/1000; % end_frequency - start_frequency
    spect_pars.mod_dev = spect_pars.delta_freq;

    %spect_pars.pulse_length = t0*10^(-1.5)/10^(pwr/10); % also is sweep length (max is Keithley time - 20ms)
    pulse_time_list = [spect_pars.delta_freq*1000/5]; %Keep fixed at 5kHz/ms.
    spect_pars.pulse_length = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'uwave_pulse_time');
    spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp up and down with min-jerk
    spect_pars.AM_ramp_time = 9;
    spect_pars.fake_pulse = 0;
    spect_pars.uwave_delay = 0; %wait time before starting pulse
    spect_pars.uwave_window = 0; % time to wait during 60Hz sync pulse (Keithley time +20ms)
    spect_type = 2; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps 9: field sweep
    spect_pars.SRS_select = 1;

    %addOutputParam('uwave_pwr',pwr)
    addOutputParam('sweep_time',spect_pars.pulse_length)
    addOutputParam('sweep_range',spect_pars.delta_freq)
    addOutputParam('freq_val',freq_val)

    do_field_sweep = 1;
    if do_field_sweep
        %Take frequency range in MHz, convert to shim range in Amps
        %  (-5.714 MHz/A on Jan 29th 2015)
        dBz = spect_pars.delta_freq / (-5.714); 

        %dBz = 0;
        field_shift_offset = 15;
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
        ACync_start_time = calctime(curtime,spect_pars.uwave_delay - 50);
        % Disable ACync 150ms after pulse
        ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
        spect_pars.pulse_length + 150);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end

    if ( seqdata.flags.pulse_raman_beams ~= 0)

        Raman_On_Delay = 0.0;
        Raman_On_Time = spect_pars.pulse_length;
        Raman_Ramp_Time = 0.00 * Raman_On_Time;
        %Ramp VVA to open.
        %AnalogFuncTo(calctime(curtime,-Raman_Ramp_Time-Raman_On_Delay),52,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Raman_Ramp_Time,Raman_Ramp_Time,9.9);
        %Pulse Raman beams on.
curtime = DigitalPulse(calctime(curtime,-Raman_Ramp_Time-Raman_On_Delay),'Raman TTL',Raman_On_Time+2*Raman_Ramp_Time+2*Raman_On_Delay,1);
        %Ramp VVA to closed.
        %AnalogFuncTo(calctime(curtime,-Raman_Ramp_Time),52,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Raman_Ramp_Time,Raman_Ramp_Time,0);
        %pulse_time_list = [100];
        %pulse_time = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_time');
%curtime = Pulse_RamanBeams(curtime,pulse_time,'MOTLightSource',2);
%curtime = calctime(curtime,Raman_On_Time); 
    end

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
    %change curtime for testing F pump
curtime = calctime(curtime,20);

    ScopeTriggerPulse(curtime,'K uWave Spectroscopy');

  %-----------------------ramp down Feshbach field for imaging
curtime=calctime(curtime,100);
    ramp_fields_down = 1; % do a field ramp for spectroscopy    
    if ramp_fields_down % if a coil value is not set, this coil will not be changed from its current value
        % shim settings for spectroscopy
        clear('ramp');
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero
        ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = 20; %22.6
        ramp.settling_time = 50;    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
    end
  %-----------------------ramp down Feshbach field for imaging


elseif ( do_Rb_uwave_spectroscopy ) % does a uwave pulse or sweep for spectroscopy

    %freq_list = [-20:0.8:-12]/1000;%
    %freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
    freq_val = 0.0;
    spect_pars.freq = 6894.0+freq_val; %MHz (6876MHz for FB = 22.6)
    %power_list = [8.6 7 5 3 1 0];
    %spect_pars.power = getScanParameter(power_list,seqdata.scancycle,seqdata.randcyclelist,'uwave_power');
    spect_pars.power = 8.6; %dBm
    spect_pars.delta_freq = 5; % end_frequency - start_frequency
    spect_pars.pulse_length = 100; % also is sweep length

    spect_type = 5; %5: sweeps, 6: pulse

    addOutputParam('freq_val',freq_val)

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % check rf_uwave_spectroscopy to see what struct spect_pars may contain

    %RHYS - Not sure what this commented code is for. It is probably not important.      
    %-----------------------ramp down Feshbach field for imaging
%curtime=calctime(curtime,200);
    %ramp_fields_down = 0; % do a field ramp for spectroscopy    
    %if ramp_fields_down % if a coil value is not set, this coil will not be changed from its current value
        %shim settings for spectroscopy
        %clear('ramp');
        %ramp.shim_ramptime = 50;
        %ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero
        %ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
        %ramp.yshim_final = seqdata.params.shim_zero(2);
        %ramp.zshim_final = seqdata.params.shim_zero(3);

        %FB coil settings for spectroscopy
        %ramp.fesh_ramptime = 50;
        %ramp.fesh_ramp_delay = 0;
        %ramp.fesh_final = 20; %22.6
        %ramp.settling_time = 50;    
%curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
%curtime=calctime(curtime,3000);     
    %end
    %-----------------------ramp down Feshbach field for imaging

end

%% RF Spectroscopy
%RHYS - Tests RF transfer for a specific set of states: there is a lot of
%baggage and commented-out codes here which could be deleted.
if ( do_RF_spectroscopy ) % does an rf pulse or sweep for spectroscopy
    check_effi = 0;


curtime=calctime(curtime,500);

    %Do RF Sweep
    clear('sweep');
    rf_list = [17.5];[44.65 44.67 66.63]; [31.3812]; 
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
    %sweep_pars.freq = 31.37;44.4247; %Sweeps -9/2 to -7/2 at 207.6G.
    rf_power_list = [5];
    sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
    delta_freq = 1.0;
    sweep_pars.delta_freq = delta_freq;  -0.2; % end_frequency - start_frequency   0.01
    sweep_pars.fake_pulse = 0;
    rf_pulse_length_list = [0.0:0.06:0.48];;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
    %sweep_pars.multiple_sweep = 1;
    %sweep_pars.multiple_sweep_list = [34.1583];


    %%Do RF Pulse
    %clear('pulse')
    %rf_list =  [45.04:0.01:45.12]; 
    %pulse_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
    %rf_power_list = [-6];
    %pulse_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  
    %rf_pulse_length_list = [0.1];
    %pulse_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');


    acync_time_start = curtime;
    %trigger    
    ScopeTriggerPulse(curtime,'rf_pulse_test');

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    total_pulse_length = sweep_pars.pulse_length+50;

    kill_one_spin = 0;
    %RHYS - Seems unnecessary to have this.
    if  (kill_one_spin==1)
    %Resonant light pulse to remove  atoms in 9/2 state

        kill_time_list = [0.25];
        kill_time = getScanParameter(kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'kill_time'); %10    
        kill_detuning = 39;   40;   %27 for 80G       %43 @ 2018-02-22
        addOutputParam('kill_det',kill_detuning);
        pulse_offset_time = -5; %Need to step back in time a bit to do the kill pulse
                                %directly after transfer, not after the subsequent wait times

        %set trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,-50),'K Trap FM',kill_detuning); %54.5
        %open K probe shutter
        setDigitalChannel(calctime(curtime,-10),'Downwards D2 Shutter',1); %0=closed, 1=open
        %set TTL off initially
        setDigitalChannel(calctime(curtime,-20),'Kill TTL',0);%0= off, 1=on
        ScopeTriggerPulse(curtime,'kill_test');
        %turn on AOM TTL
        setDigitalChannel(calctime(curtime,0),'Kill TTL',1);%0= off, 1=on
curtime = calctime(curtime,kill_time);
        setDigitalChannel(calctime(curtime,0),'Kill TTL',0);%0= off, 1=on

        %close K probe shutter
        setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0);

        %set kill AOM back on
        setDigitalChannel(calctime(curtime,50),'Kill TTL',1);           

        total_pulse_length=total_pulse_length+kill_time;
    end

    do_ACync_plane_selection = 1;
    if do_ACync_plane_selection
        ACync_start_time = calctime(acync_time_start,-80);
        ACync_end_time = calctime(curtime,total_pulse_length+40);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
    %-----------------------ramp down Feshbach field for imaging


curtime=calctime(curtime,41);
    ramp_fields_down = 1; % do a field ramp for spectroscopy    
    if ramp_fields_down % if a coil value is not set, this coil will not be changed from its current value
        %shim settings for spectroscopy
        clear('ramp');
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero
        ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);

        %FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = 20; %22.6
        ramp.settling_time = 50;    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
curtime=calctime(curtime,100);     
    end
    %-----------------------ramp down Feshbach field for imaging


%RHYS - Why do this here? Remove.
     Make_Spin_Mixture = 0;
    if (Make_Spin_Mixture)
        %%Multiple sweeps to drive the mixture towards 50/50
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
    end
    %Do RF Sweep
    %clear('sweep');        
    %sweep_pars.freq = 20;46.7897; %Sweeps -7/2 to -5/2 at 207.6G.
    %sweep_pars.power = 2.7; %-7.7
    %sweep_pars.delta_freq = 0.3; % end_frequency - start_frequency   0.01
    %sweep_pars.pulse_length = 30; % also is sweep length  0.5

    %addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
%curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);%3: sweeps, 4: pulse

    %RHYS - I think this was code for testing molecule formation near the FB
    %resonance. Could be included as a separate module.
    do_feshbach_resonance_physics = 0;
    if (do_feshbach_resonance_physics)
        clear('ramp')
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 5;
        ramp.fesh_ramp_delay = 5;
        B_List = [200.5 201.5:0.05:202.1];%before 2017-1-6 [200.5 201.5:0.05:202.1];
        B = getScanParameter(B_List,seqdata.scancycle,seqdata.randcyclelist,'B_Field');
        ramp.fesh_final = (B-0.1)*1.08962;%before 2017-1-6 (B-0.1)*1.08962;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
        ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
        ramp.settling_time = 0;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

        %Do RF Sweep
        clear('sweep');

        sweep_pars.freq = -0.025 + (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6; %Sweeps -9/2 to -7/2 at 207.6G.
        sweep_pars.power = 2.7; %-7.7
        sweep_pars.delta_freq = -0.1; % end_frequency - start_frequency   0.01
        sweep_pars.pulse_length = 10; % also is sweep length  0.5

        addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
curtime = calctime(curtime, 200);

        reverse_sweep = 0;
        if reverse_sweep
            clear('ramp')
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 5;
            ramp.fesh_ramp_delay = 5;
            B_2 = 199.6;%before 2017-1-6 199.6;
            ramp.fesh_final = (B_2-0.1)*1.08962;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
            ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
            ramp.settling_time = 5;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
            sweep_pars.freq = (BreitRabiK(B_2,9/2,-5/2) - BreitRabiK(B_2,9/2,-7/2))/6.6260755e-34/1E6; 
            sweep_pars.delta_freq = -sweep_pars.delta_freq;
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
        end
    end

    %freq_list = [150]/1000;
    %freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
    %freq_val = 1/1000;
    %addOutputParam('freq_val',freq_val);

    %spect_pars.freq = 47.045+freq_val; %MHz
    %power_list = [-8.2 -8.1 -7.9 -7.8 -7.7 -7.6];
    %time_list = ([-15:5:5])/1000;
    %spect_pars.power = getScanParameter(power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_power'); %uncalibrated "gain" for rf
    %spect_pars.power = -3; %-3
    %spect_pars.delta_freq = 800/1000; % end_frequency - start_frequency
    %sweeptime_list = [0.02 0.05 0.1 0.2 0.5:0.5:5];
    %spect_pars.pulse_length =  getScanParameter(sweeptime_list,seqdata.scancycle,seqdata.randcyclelist,'sweeptime'); % also is sweep length        
    %spect_pars.pulse_length = 0.2; % also is sweep length %0.2

    %spect_type = 4; %3: sweeps, 4: pulse

    %addOutputParam('rf_frequency',spect_pars.freq);
    %addOutputParam('rf_power',spect_pars.power);

%curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % check rf_uwave_spectroscopy to see what struct spect_pars may contain
end

%% Tilt Evaporation
%RHYS - An attempt to evaporate in the dipole trap by keeping a larger trap
%depth (for higher density) and tilting atoms out with a gradient. Was
%never better than the current evaporation method.
if tilt_evaporation

    %FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 10.49632;%before 2017-1-6 0.5*22.6; %22.6
    addOutputParam('PSelect_FB',ramp.fesh_final)

    qp_time_list = [1 1000 3000 6000 9000 12000];

    %QP coil settings for spectroscopy
    ramp.QP_ramptime = getScanParameter(qp_time_list,seqdata.scancycle,seqdata.randcyclelist,'qpTIME');%150 %This controls what fraction of the ramp is actually performed.
    ramp.QP_ramp_delay = 60;
    ramp.QP_final =  4.5*1.78; %12 works well for XDT power of 1, 24 for XDT power of 2 (although this is a lot of current). 
    %These two parameters define the shape - the time constant, and
    %how long it takes to get to max amplitude. 
    ramp.QP_ramp_tau = 5000; %4000 from side
    ramp.QP_ramptotaltime = 12000;
    ramp.QP_ramp_type = 'Exponential';

    ramp.shim_ramptime = ramp.QP_ramptime; %150 %This controls what fraction of the ramp is actually performed.
    ramp.shim_ramp_delay = ramp.QP_ramp_delay;
    ramp.xshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(1) - seqdata.params. shim_zero(1)) + seqdata.params. shim_zero(1); %5.5 from side
    ramp.yshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(2) - seqdata.params. shim_zero(2)) + seqdata.params. shim_zero(2);
    ramp.zshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(3) - seqdata.params. shim_zero(3)) + seqdata.params. shim_zero(3);
    %These two parameters define the shape - the time constant, and
    %how long it takes to get to max amplitude. 
    ramp.shim_ramp_tau = ramp.QP_ramp_tau ; %4000 from side
    ramp.shim_ramptotaltime = ramp.QP_ramptotaltime;
    ramp.shim_ramp_type = ramp.QP_ramp_type;

    ramp.settling_time = 150; %200

curtime = ramp_bias_fields(calctime(curtime,0), ramp); %

    %Wait some variable amount of time.
curtime = calctime(curtime, 100);

            clear('ramp')
            % QP coil settings for spectroscopy
            ramp.QP_ramptime = 150; %150
            ramp.QP_ramp_delay = 60;
            ramp.QP_final =  0*1.78; %7
            ramp.settling_time = 150; %200

curtime = ramp_bias_fields(calctime(curtime,0), ramp); %

end



%% Ramp XDT Up for Lattice Alignment
%RHYS - This usually gets used. Can clean. Also contains options for
%assessing XDT trap frequency, which should be separated back out into one
%of the other two modules that already do this.

%Ramp dipole on before pulsing the lattice beam. This should allow for
%better alignment of lattice to the potassium cloud, avoiding issue of
%gravitational sag for Rb. The XDT is then snapped off after the
%lattice pulse. 

if (ramp_XDT_after_evap && seqdata.flags.CDT_evap == 1)
    dispLineStr('Ramping XDTs back on.',curtime);

    power_list = [0.3];
    power_val = getScanParameter(power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'power_val','W');

    dip_1 = power_val; %1.5
    dip_2 = power_val;XDT2_power_func(dip_1);
       
    disp(['     XDT 1 (W) ' num2str(dip_1)]);
    disp(['     XDT 2 (W) ' num2str(dip_2)]);
    
    dip_sweep = 0.00;
    dip_end_ramptime_list =[1500];
    dip_ramptime = getScanParameter(dip_end_ramptime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dip_end_ramptime');
    dip_rampstart_list = [0];
    dip_rampstart = getScanParameter(dip_rampstart_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dip_on_time');

    dip_waittime_list = [0];
    dip_waittime = getScanParameter(dip_waittime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dip_hold_time');

    AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        dip_ramptime,dip_ramptime,dip_1-dip_sweep/2);
curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    dip_ramptime,dip_ramptime,dip_2-dip_sweep/2);

curtime = calctime(curtime,dip_waittime);

end

%% D1 Optical Pumping in ODT
% After optical evaporation, ensure mF spin polarization via D1 optical
% pumping.

if (seqdata.flags.do_D1OP_post_evap==1 && seqdata.flags.CDT_evap==1)
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

if (seqdata.flags.mix_at_end==1 && seqdata.flags.CDT_evap==1)      

    if ~seqdata.flags.do_D1OP_post_evap
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

%% K uWave Spectroscopy CORA
if (do_K_uWaveSpectrscopy_CORA)
    dispLineStr('do_K_uWaveSpectrscopy_CORA',curtime);      
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

if (seqdata.flags.kill_K7_after_evap && seqdata.flags.CDT_evap == 1)
    
    % optical pumping pulse length
    repump_pulse_time_list = [1];
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

if (k_rf_rabi_oscillation)      
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
    if do_dipole_trap_kick
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
    if do_dipole_trap_kick
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
if seqdata.flags.ramp_up_FB_for_lattice     
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
    
%% Ramp FB field up to 200G for High Field Imaging after ODT
    
if (seqdata.flags.High_Field_Imaging && ~seqdata.flags.load_lattice )         
    curtime = dipole_high_field_a(curtime);  
end
     
%% Ramp Feshbach and QP Coils
% To characerize field gradients, it is useful to ramp the FB and QP coils
% at the end of evaporation. Strong field gradients kick atoms out of the
% trap. And a "round trip" magnetic field ramp tests this.
if ramp_QP_FB_and_back
    dispLineStr('Ramping Fields Up and Down',curtime);

    % Feshvalue to ramp to
    HF_FeshValue_Initial_List =[200];
    HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_Fesh_RampUpDown','G');
    
    % QP Value to ramp to
    HF_QP_List =[0:.005:.05];
    HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_QP_RampUpDown','A');   
    
    clear('ramp');
    
    % Ramp the Feshbach Coils.
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = -0;   
    ramp.FeshValue = HF_FeshValue_Initial;
    ramp.SettlingTime = 50; 
    
    % Ramp the QP Coils
    ramp.QPRampTime = ramp.FeshRampTime;
    ramp.QPValue = HF_QP;    

    disp(['     Ramp Time     (ms) : ' num2str(ramp.FeshRampTime)]);
    disp(['     Settling Time (ms) : ' num2str(ramp.SettlingTime)]);
    disp(['     Fesh Value     (G) : ' num2str(ramp.FeshValue)]);
    disp(['     QP Value       (A) : ' num2str(ramp.QPValue)]);   

curtime = rampMagneticFields(calctime(curtime,0), ramp);

    wait_time = 50;
curtime = calctime(curtime,wait_time);

    clear('ramp');
    % Ramp Back to original values
    ramp.SettlingTime = 50;
    
    % Feshbach Ramp
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = 0;   
    ramp.FeshValue = 20;
    
    % Ramp the QP Coils
    ramp.QPRampTime = ramp.FeshRampTime;
    ramp.QPValue = 0;    
    
    curtime = rampMagneticFields(calctime(curtime,0), ramp);
end
%% The End!

    timeout = curtime;
   dispLineStr('Dipole Transfer complete',curtime);

end