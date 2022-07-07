function [timeout,I_QP,V_QP,P_dip,dip_holdtime,I_shim] =  dipole_transfer(timein, I_QP, V_QP,I_shim)
%RHYS - This code, probably originally intended to just load the dipole
%trap, now includes everything anyone would ever want to do in a dipole
%trap, including spin-flips/spectroscopy, evaporation, and a number of
%specialized or obsolete sequences. I would trim it back extensively, move
%hardcoded parameters out, and keep specialized sequences as optional
%xdt-specific flags to call.

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

    %After Loading the XDT
    %--------------------
    %RHYS - Move all of these flags out of this function, and declare them
    %in the seqdata structure to be passed in.  
    
    init_Rb_RF_sweep = 0;%Sweep 87Rb to |1,-1> (or |2,-2>) before evaporation
    seqdata.flags.do_K_uwave_transfer_in_ODT = 0;%transfer K atoms from F=9/2 to F=7/2
    dipole_oscillation_heating = 0;%Heat atoms by modulating the XDT beams 
    
    Rb_RF_sweep = 0;                % sweep atoms from |2,2> into |2,-2>

    
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
    Evap2_End_Power_List = [0.08];    
    % Ending optical evaporation
    exp_end_pwr2 = getScanParameter(Evap2_End_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Evap_End_Power2','W');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %After Evaporation (unless CDT_evap = 0)
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    ramp_XDT_up = 0;                % Ramp dipole back up after evaporation before any further physics 
    do_dipole_trap_kick = 0;        % Kick the dipole trap, inducing coherent oscillations for temperature measurement
    seqdata.flags.get_rid_of_Rb = 1;% Get rid of Rb at end of evap (only happens when CDT_evap = 1
    do_K_uwave_spectroscopy = 0;    % do uWave Spectroscopy of 40K
    do_K_uwave_multi_sweeps = 0;    % do multiple uWave sweeps of 40K
    do_Rb_uwave_spectroscopy = 0;   % do uWave Spectroscopy of 87Rb
    do_RF_spectroscopy = 0;         % do spectroscopy with DDS 
    do_singleshot_spectroscopy = 0; % do uwave spectroscopy using mF states to shelve population
    do_field_ramps = 0;             % Ramp shim and FB fields without spectroscopy
    K_repump_pulse = 0;             % Get rid of F = 7/2 Potassium
    K_probe_pulse = 0;              % Get rid of F = 9/2 Potassium
    DMD_in_XDT = 0;
    Kill_Beam_Alignment = 0;        %Pulse Kill beam on for whatever needs to be aligned.  
    Raman_Vertical_Alignment = 0;   %Pulse Vertical Raman beam on for alignment. 
    ramp_XDT_after_evap = 0;        %Ramp XDT up after evaporation to keep Rb and K at same location for lattice aligment              
    k_rf_rabi_oscillation=0;        % RF rabi oscillations after evap
    ramp_QP_FB_and_back = 0;        % Ramp up and down FB and QP to test field gradients

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
    Pevap_list = [0.8];
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
    if ( do_K_uwave_spectroscopy + do_Rb_uwave_spectroscopy + do_RF_spectroscopy + do_singleshot_spectroscopy) > 1
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
        
        % Turn on RF knife
        %Maybe not beneficially when transferring at lower freqs
        %cut_freq = 0.6;
        %do_evap_stage(calctime(curtime,qp_ramp_down_start_time+200), ...
%             0, [8 8]*1E6, qp_ramp_down_time1-200, [-2], 0, 1);

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
%         
        
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
    % 2021/05/12 Make a generic mixture
    % These settings don't care about setting a particular mixture
    rf_k_sweep_freqs=[3.0495];%3.048 [1.8353];3.01;

    rf_k_sweep_freqs=[5.990]+[-0.003];%3.048 [1.8353];3.01;

    % With delta_freq =0.1;
    % 3.01 --> (-7,-5) (a little -9)
    % 3.07 --> (-1,+1,+3); 
    rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_post_evap');

    sweep_pars.freq=rf_k_sweep_center;        
    sweep_pars.power = -9.2;-9.1;   

    delta_freq_list = 0.01;[0.01];%0.006; 0.01
    sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_post_evap');
    pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
    sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_post_evap');

    %numbers for spin mixture -9 and -7; power = -9.1, delta =
    %0.01,time = 1.25
    %numbers for near spin polarized -7/2; power = -8.4, delta = 0.06, time = 6ms 

    disp(['     Center Freq      (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq       (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Power              (V) : ' num2str(sweep_pars.power)]);
    disp(['     Sweep time        (ms) : ' num2str(sweep_pars.pulse_length)]);  


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
    %% Sweep Rb to |1,-1>
    %RHYS - Could keep the parameters around for use in a generalized function,
    %but this is never itself used.
    if init_Rb_RF_sweep

        %Ramp FB Field
        clear('ramp');

        %FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20.98111;%before 2017-1-6 1*22.6; %22.6
        ramp.settling_time = 100;

curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        %Do RF Sweep
        clear('sweep');
        sweep_pars.freq = 14.1; %MHz
        sweep_pars.power = 8.9;
        sweep_pars.delta_freq = +0.6; % end_frequency - start_frequency
        sweep_pars.pulse_length = 40; % also is sweep length

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

        second_sweep = 0; %second RF sweep/pulse to make a spin mixture
        if (second_sweep)
            %[freq, power, delta_f, pulse_length] = [6.0, -9, -0.5, 40] for 50% transfer to |9/2,-7/2>

            %Do RF Sweep
            clear('sweep');
            sweep_pars.freq = 6.07; %MHz
            sweep_pars.power = -2;   %-9
            sweep_pars.delta_freq = +0.05; % end_frequency - start_frequency   0.01
            sweep_pars.pulse_length = 0.6; % also is sweep length  0.5

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

            sweep_back = 0;
            if sweep_back
                %wait for some time to dephase
                dephasing_time = 0.0;
                sweep_pars.delta_freq = +0.01;
                curtime = calctime(curtime,dephasing_time);

                %Do the sweep again
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
            end
        end

        reduce_field = 1;
        if reduce_field
            %Ramp field back down
            clear('ramp');

            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 5.253923;%before 2017-1-6 0.25*22.6; %22.6
            ramp.settling_time = 50;

curtime = ramp_bias_fields(calctime(curtime,0), ramp);
        end

    end

    %% K uWave Transfer
    %RHYS - Pretty sure this is deprecated, would use K_uwave_spectroscopy.
    if seqdata.flags.do_K_uwave_transfer_in_ODT


        %Add repump pulse before transfer to ensure all atoms in 9/2
        do_repump_pulse = 0;

        if do_repump_pulse
            %Open Repump Shutter
            setDigitalChannel(calctime(curtime,-10),3,1);  
            %turn repump back up
            setAnalogChannel(calctime(curtime,-10),25,0.7);

            %repump TTL
            curtime = DigitalPulse(calctime(curtime,0),7,10,0); 

            %Close Repump Shutter
            setDigitalChannel(calctime(curtime,0),3,0);
            %turn repump back down
            setAnalogChannel(calctime(curtime,0),25,0.0);

        else
        end

        %Ramp Feshbach current up
        pre_ramp_feshbach = 1;

        if pre_ramp_feshbach
            %Ramp Feshbach field to above the resonant value
            rampup_time = 40;
            init_fesh_current = 21.3522576;%before 2017-1-6 23;
curtime = AnalogFuncTo(calctime(curtime,10),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rampup_time,rampup_time,init_fesh_current);
            fesh_current_val = init_fesh_current;
        else
        end

        uWave_sweep_time = 2*100; %Time for uWave sweep: with -12dBm, 50ms each way is good
        fesh_uWave_current = fesh_current_val - del_fesh_current; %Feshbach current to which to ramp.
        %Changed from fesh_uWave_current = fesh_current - 9; Feb 6th.

        ramp_Bfield_thereback = 0;

        if ramp_Bfield_thereback == 1

            %Wait time before sweeping back
            thereback_waittime = 0;

            %Ramp there and back again
            AnalogFunc(calctime(curtime,50),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),uWave_sweep_time/2,uWave_sweep_time/2, fesh_uWave_current,fesh_current_val);    

            AnalogFunc(calctime(curtime,50+thereback_waittime+uWave_sweep_time/2),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),uWave_sweep_time/2,uWave_sweep_time/2, fesh_current_val,fesh_uWave_current);

            %Pulse on uWaves
curtime  = do_uwave_pulse(calctime(curtime,50), 0, 0, uWave_sweep_time+thereback_waittime, 2, 1);

        else
            %Ramp Feshbach field
            AnalogFunc(calctime(curtime,50),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),uWave_sweep_time,uWave_sweep_time, fesh_uWave_current,fesh_current_val);

            %Pulse on uWaves
curtime  = do_uwave_pulse(calctime(curtime,50), 0, 0, uWave_sweep_time, 2, 1);
%curtime = calctime(curtime,100+uWave_sweep_time);

            fesh_current_val = fesh_uWave_current;

        end    

        do_blowaway = 1;

        if do_blowaway
            %Blow away any atoms left in F=9/2

            %set probe detuning
            setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',190); %195
            %set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,-10),'K Trap FM',42); %54.5

            %open K probe shutter
            setDigitalChannel(calctime(curtime,-10),30,1); %0=closed, 1=open
            %turn up analog
            setAnalogChannel(calctime(curtime,-10),29,0.17);
            %set TTL off initially
            setDigitalChannel(calctime(curtime,-10),9,1);

            %pulse beam with TTL
curtime = DigitalPulse(calctime(curtime,0),9,15,0);

            %close K probe shutter
            setDigitalChannel(calctime(curtime,0),30,0);

        else

        end

        %Wait for some time afterward
curtime = calctime(curtime,0); 

        %Add repump pulse before transfer to ensure all atoms in 9/2
        do_repump_pulse_B = 0;

        if do_repump_pulse_B
            %Open Repump Shutter
            setDigitalChannel(calctime(curtime,-10),3,1);  
            %turn repump back up
            setAnalogChannel(calctime(curtime,-10),25,0.7);

            %repump TTL
curtime = DigitalPulse(calctime(curtime,0),7,1.5,0); 

            %Close Repump Shutter
            setDigitalChannel(calctime(curtime,0),3,0);
            %turn repump back down
            setAnalogChannel(calctime(curtime,0),25,0.0);

        else
        end


        %sweep back
        ramp_Bfield_back = 0;

        if ramp_Bfield_back == 1

            %Wait for some time before a sweep back (there is already a 100ms
            %wait from way this is called to wait for the transfer switch)
curtime = calctime(curtime,1000);

            %Ramp back again
            AnalogFunc(calctime(curtime,100),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),uWave_sweep_time,uWave_sweep_time, mean_fesh_current + del_fesh_current,fesh_uWave_current);

            %Pulse on uWaves
curtime  = do_uwave_pulse(calctime(curtime,50), 0, 0, uWave_sweep_time, 2, 1);

            fesh_current_val = mean_fesh_current + del_fesh_current;

        else
        end


        %Wait for some time afterward
curtime = calctime(curtime,10); 

    else
    end

    %% Heat Cloud with Dipole Oscillation
    %RHYS - Useful benchmarking tool, but similar idea also repeated elsewhere
    %in this code.
    if dipole_oscillation_heating


        dip_osc = @(t,freq,y2,y1)(y1 +y2*sin(2*pi*freq*t/1000));

        %dip_osc_freq_list = [ 40:5:70 ];
   
        %Create Randomized list
        %index=seqdata.randcyclelist(seqdata.cycle);

        %dip_osc_freq =  dip_osc_freq_list(index);
        %addOutputParam('dip_hold', dip_osc_freq);  

        dip_osc_time = 1000;
        dip1_osc_offset = P_dip;
        dip2_osc_offset = P_dip2;
        dip_osc_amp = 0.1;
        dip_osc_freq=340.0; %in Hz

        %oscillate dipole 1 
        AnalogFunc(calctime(curtime,0),'dipoleTrap1',@(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),dip_osc_time,dip_osc_freq,dip_osc_amp,dip1_osc_offset);
        %oscillate dipole 2 
curtime = AnalogFunc(calctime(curtime,0),'dipoleTrap2',@(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),dip_osc_time,dip_osc_freq,dip_osc_amp,dip2_osc_offset);    

        DigitalPulse(curtime,12,10,1);

curtime = calctime(curtime,300);

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
    
    field_ramp_1 = 1;       % Initial ramp to high field
    expevap2 = 0 ;          % Optical Evaporation
    field_ramp_img = 0;     % High Field Imaging
    spin_flip_9_7 = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Ramp B Field to High Value %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Ramp magnetic field to high field value
    if field_ramp_1
        clear('ramp');                
        
        zShim = 0;
        
        % Fesh Ramp        
        XDT_Evap2_FeshValue_List =[195];
        XDT_Evap2_FeshValue = getScanParameter(XDT_Evap2_FeshValue_List,...
            seqdata.scancycle,seqdata.randcyclelist,'XDT_Evap2_FeshValue');

        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3) + zShim;
        % FB coil 
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = XDT_Evap2_FeshValue;
        ramp.settling_time = 100;      

        % Also going to want to ramp shims (but do that later)  
        disp(' Ramping to high field');
        disp(['     Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
        disp(['     Settling Time (ms) : ' num2str(ramp.settling_time)]);
        disp(['     Fesh Value     (G) : ' num2str(ramp.fesh_final)]);
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        fieldReal = XDT_Evap2_FeshValue + 2.35*zShim + 0.1; 

        seqdata.params.HF_probe_fb = XDT_Evap2_FeshValue; 
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Spin Flip 97 %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if spin_flip_9_7
        B = fieldReal; 
        rf_pulse_length_list = 100;
        delta_freq = 10;        
        
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        
        clear('sweep_pars');
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'xdt_hf_rf_freq');
        sweep_pars.delta_freq = delta_freq;
        sweep_pars.power =  0; %in dBm
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  
        
        disp(' DDS Spin Flip');
        disp(['     Frequency    (MHz) : ' num2str(sweep_pars.freq)]);
        disp(['     Delta Freq   (kHz) : ' num2str(sweep_pars.delta_freq)]);
        disp(['     Pulse Time    (ms) : ' num2str(sweep_pars.pulse_length)]);
        disp(['     Power          (V) : ' num2str(sweep_pars.power)]);      

        curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Optical Evaporation %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if expevap2
        exp_evap2_time = 5000;
        tau2 = exp_evap2_time;
        P1_end = exp_end_pwr2;    
        P2_end = P1_end*seqdata.params.XDT_area_ratio;    

        % Display evaporation parameters
        disp(' Performing exponential evaporation');
        disp(['     Evap Time (ms) : ' num2str(exp_evap2_time)]);
        disp(['     tau       (ms) : ' num2str(tau2)]);
        disp(['     XDT1 end   (W) : ' num2str(P1_end)]);
        disp(['     XDT2 end   (W) : ' num2str(P2_end)]);

        % Ramp function
        evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));

        % Ramp the powers
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap2_time,exp_evap2_time,tau2,P1_end);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap2_time,exp_evap2_time,tau2,P2_end);   
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare for Imaging %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We perform imaging a "standard" field of 195 G. Ramp the field to
    % this value to perform time of flight and imaging
    % Feshbach Field Ramp (imaging)
    if field_ramp_img

        % Feshbach Field ramp Field ramp
        HF_FeshValue_Final_List = 206;
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

    %% Rf sweep
    %RHYS - Another example of an RF sweep code that may do what it promises,
    %but is never used.
    if Rb_RF_sweep


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
        sweep_pars.freq = 14.1; %MHz
        sweep_pars.power = 8.9;
        sweep_pars.delta_freq = +0.6; % end_frequency - start_frequency
        sweep_pars.pulse_length = 40; % also is sweep length

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

        reduce_field = 1;
        if reduce_field
            %Ramp field back down
            clear('ramp');

            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 5.25392;%before 2016-1-6 0.25*22.6; %22.6
            ramp.settling_time = 50;

curtime = ramp_bias_fields(calctime(curtime,0), ramp);
        end

    end


%% Remove Rb from XDT
% After optical evaporation, it is useful to only have Rb in the trap. Do
% this by pulsing resonant Rb light

    if (seqdata.flags.get_rid_of_Rb && seqdata.flags. CDT_evap == 1)

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
    if ( do_K_uwave_spectroscopy || do_K_uwave_multi_sweeps || do_Rb_uwave_spectroscopy || do_RF_spectroscopy || do_singleshot_spectroscopy || do_field_ramps )

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

        Raman_Back = 0;

        if Raman_Back
            %advance by waittime
            waittime = 500;
            curtime = calctime(curtime,waittime);

            freq_list = [150]/1000;
            freq_val = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
            %Currently 1390.75 for 2*22.6.
            spect_pars.freq = 1292.3 + freq_val; %Center of a sweep (~1390.75 for 2*22.6 and -9/2; ~1498.25 for 4*22.6 and -9/2)
            spect_pars.power = -3; %dBm
            spect_pars.delta_freq = 1000/1000; % end_frequency - start_frequency
            spect_pars.mod_dev = 1000/1000;

            spect_pars.SRS_select = 1;
            spect_pars.pulse_length = 2000; % also is sweep length
            spect_type = 1; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps

            addOutputParam('freq_val',freq_val)

            %if ( seqdata.flags.pulse_raman_beams ~= 0)
                %Raman_On_Time = spect_pars.pulse_length;
                %DigitalPulse(curtime,'D1 TTL',Raman_On_Time,1);
                %pulse_time_list = [100];
                %pulse_time = getScanParameter(pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_time');
%curtime = Pulse_RamanBeams(curtime,pulse_time,'MOTLightSource',2);
%curtime = calctime(curtime,25); 
            %end

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
        end


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

    %% uWave single shot spectroscopy
    %RHYS - Stefan's single-shot spectroscopy module. Cool, but never really
    %used.
    if ( do_singleshot_spectroscopy ) % does an rf pulse or sweep for spectroscopy

curtime = uwave_singleshot_spectroscopy(calctime(curtime,0)); 

    end   

    %% Get rid of F = 7/2 K using a repump pulse
    %RHYS - Could be useful
    if K_repump_pulse

curtime = calctime(curtime,10);

        %Open Repump Shutter
        setDigitalChannel(calctime(curtime,-10),3,1);  
        %turn repump back up
        setAnalogChannel(calctime(curtime,-10),25,0.7);

        %repump TTL
        curtime = DigitalPulse(calctime(curtime,0),7,1,0); 

        %Close Repump Shutter
        setDigitalChannel(calctime(curtime,0),3,0);
        %turn repump back down
        setAnalogChannel(calctime(curtime,0),25,0.0);
    else
    end

    %% Get rid of F = 9/2 K using a probe pulse
    %RHYS - Could be useful.
    if K_probe_pulse

        clear('ramp');

        %First, ramp on a quantizing shim.    
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -10; 
        ramp.xshim_final = getChannelValue(seqdata,27,1,0);
        ramp.yshim_final = 1.61;%0.6;
        y_shim_temp = getChannelValue(seqdata,19,1,0);
        ramp.zshim_final = getChannelValue(seqdata,28,1,0);

        %Ramp down Feshbach concurrently.
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 0.0116;%before 2017-1-6 0.0001; %18
        fesh_temp = getChannelValue(seqdata,37,1,0);

curtime =  ramp_bias_fields(calctime(curtime,0), ramp);

        k_probe_scale = 1;
        kill_detuning = 40;  %400ER: 33
        kill_probe_pwr = 0.6*k_probe_scale*0.17;   %0.2  0.22   4*k_probe_scale*0.17
        kill_time = 4;


        %set probe detuning
        setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',190); %195
        %set trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,-10),'K Trap FM',kill_detuning); %54.5

        %open K probe shutter
        setDigitalChannel(calctime(curtime,-5),30,1); %0=closed, 1=open
        %turn up analog
        setAnalogChannel(calctime(curtime,-5),29,kill_probe_pwr);
        %set TTL off initially
        setDigitalChannel(calctime(curtime,-5),9,1);

        %pulse beam with TTL
curtime = DigitalPulse(calctime(curtime,0),9,kill_time,0);

        %close K probe shutter
        setDigitalChannel(calctime(curtime,0),30,0);

        uwave_back = 1; % do a field ramp for spectroscopy

        if uwave_back % if a coil value is not set, this coil will not be changed from its current value
            %shim settings for spectroscopy
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
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final =41.9507;%before 2017-1-6 2*22.6; %22.6
            ramp.settling_time = 200;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

            %Redo original sweep, but longer to transfer all atoms
            spect_pars.pulse_length = 30; % also is sweep length
            spect_type = 1; %1: sweeps, 2: pulse

            addOutputParam('freq_val',spect_pars.freq)

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);

        end
    else
    end


    %% Ramp XDT Up for Lattice Alignment
    %RHYS - This usually gets used. Can clean. Also contains options for
    %assessing XDT trap frequency, which should be separated back out into one
    %of the other two modules that already do this.

    %Ramp dipole on before pulsing the lattice beam. This should allow for
    %better alignment of lattice to the potassium cloud, avoiding issue of
    %gravitational sag for Rb. The XDT is then snapped off after the
    %lattice pulse. 

    if (ramp_XDT_after_evap && seqdata.flags. CDT_evap == 1)
        dispLineStr('Ramping XDTs back on.',curtime);
       
       
        power_list = [0.3];
        power_val = getScanParameter(power_list,seqdata.scancycle,...
            seqdata.randcyclelist,'power_val','W');

        dip_1 = power_val; %1.5
        dip_2 = power_val;XDT2_power_func(dip_1);
        
        % 2020/01/26 ramp to full power
%         dip_1 = P1;
%         dip_2 = P2;
% 
%         
        disp(['     XDT 1 (W) ' num2str(dip_1)]);
        disp(['     XDT 2 (W) ' num2str(dip_2)]);

        
       % 2021/05/12 what is dip_sweep for?!
        %dip_1 = 1;
        dip_sweep = 0.00;
        dip_end_ramptime_list =[1500];
        dip_ramptime = getScanParameter(dip_end_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'dip_end_ramptime');
        dip_rampstart_list = [0];
        dip_rampstart = getScanParameter(dip_rampstart_list,seqdata.scancycle,seqdata.randcyclelist,'dip_on_time');
        
        dip_waittime_list = [0];
        dip_waittime = getScanParameter(dip_waittime_list,seqdata.scancycle,seqdata.randcyclelist,'dip_hold_time');
        
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1-dip_sweep/2);
curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2-dip_sweep/2);
curtime = calctime(curtime,dip_waittime);

    end

%% DMD in XDT 
    %RHYS - Is this desirable?
    if DMD_in_XDT
        ScopeTriggerPulse(curtime,'DMD pulse');

        offset_time=-200;-400;
        DMD_power_val_list = [1]; %Do not exceed 2 here
        DMD_power_val = getScanParameter(DMD_power_val_list,...
            seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
        DMD_ramp_time = 100;
        DMD_on_time_list = [300];
        DMD_on_time = getScanParameter(DMD_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time');
%         setAnalogChannel(calctime(curtime,-1000),'DMD Power',2);
        setDigitalChannel(calctime(curtime,-10+offset_time),'DMD Shutter',0);%0 on 1 off
        setDigitalChannel(calctime(curtime,-100+offset_time),'DMD TTL',0);%1 off 0 on
        setDigitalChannel(calctime(curtime,0+offset_time),'DMD TTL',1); %pulse time does not matter
        setDigitalChannel(calctime(curtime,-20+offset_time),'DMD AOM TTL',0);
        setDigitalChannel(calctime(curtime,-20+offset_time),'DMD PID holder',1);
%         setAnalogChannel(calctime(curtime,-20+offset_time),'DMD Power',0);
        AnalogFuncTo(calctime(curtime,-30+offset_time),'DMD Power',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1, 1, 0);
        setDigitalChannel(calctime(curtime,0+offset_time),'DMD AOM TTL',1); %1 on 0 off 
        setDigitalChannel(calctime(curtime,0+offset_time),'DMD PID holder',0);
curtime = AnalogFuncTo(calctime(curtime,0+offset_time),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ...
    DMD_ramp_time, DMD_ramp_time, DMD_power_val);
% curtime = calctime(curtime,DMD_on_time)
%curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, 0.3);
%         setAnalogChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD Power',-0.1);
% curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, 0);
        AnalogFuncTo(calctime(curtime,DMD_on_time),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            DMD_ramp_time, DMD_ramp_time, -0.1);
        setDigitalChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD AOM TTL',0); %1 on 0 off
        setDigitalChannel(calctime(curtime,DMD_on_time+DMD_ramp_time+10),'DMD Shutter',1);
        setDigitalChannel(calctime(curtime,DMD_on_time+DMD_ramp_time+20),'DMD AOM TTL',1);
        setAnalogChannel(calctime(curtime,DMD_on_time+DMD_ramp_time+20),'DMD Power',2);
% curtime = calctime(curtime,DMD_on_time)
curtime = calctime(curtime,DMD_on_time-100); -50;
        
%         DMD_on_time_list = [80];
%     DMD_on_time = getScanParameter(DMD_on_time_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time','ms');
%     
%     DMD_ramp_time = 20; %10
%     lat_hold_time_list = 50;%50 sept28
%     lat_hold_time = getScanParameter(lat_hold_time_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time');%maximum is 4
%     lat_rampup_time = 1*[50,DMD_on_time+DMD_ramp_time-20,50,2,50,lat_hold_time]; 
% % % %     lat_rampup_time = 1*[50,2+DMD_on_time+DMD_ramp_time,10,2,50,lat_hold_time];
% %     lat_rampup_time = 1*[20,30,30,10,50,lat_hold_time]; 
% % % % %     
% % % % % % % % % % %     
%     offset_time = 40;
%     DMD_power_val_list = 2; %2V is roughly the max now 
%     DMD_power_val = getScanParameter(DMD_power_val_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
%     % setDigitalChannel(calctime(curtime,-220),'DMD TTL',0);%1 off 0 on
%     % setDigitalChannel(calctime(curtime,-220+100),'DMD TTL',1); %pulse time does not matter
%     % setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
%     % % setAnalogChannel(calctime(curtime,0),'DMD Power',3.5);
%     % AnalogFuncTo(calctime(curtime,0),'DMD Power',...
%     %     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%     % setAnalogChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time),'DMD Power',-5);
%     % setDigitalChannel(calctime(curtime,0+DMD_on_time+ DMD_ramp_time),'DMD AOM TTL',0);%0 off 1 on
% 
% 
%     setDigitalChannel(calctime(curtime,-10 +offset_time),'DMD Shutter',0);%0 on 1 off
%     setDigitalChannel(calctime(curtime,-100+offset_time),'DMD TTL',0);
%     setDigitalChannel(calctime(curtime,0+offset_time),'DMD TTL',1);
%     setDigitalChannel(calctime(curtime,-20+offset_time),'DMD AOM TTL',0);
%     setAnalogChannel(calctime(curtime,-20+offset_time),'DMD Power',-0.1);
%     setDigitalChannel(calctime(curtime,0+offset_time),'DMD AOM TTL',1);%1 on 0 off
%     AnalogFuncTo(calctime(curtime,0+offset_time),'DMD Power',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
% 
%     % curtime = calctime(curtime,DMD_on_time + DMD_ramp_time);
%     % curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',...
%     %     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, -0.1);
%     setAnalogChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+offset_time),'DMD Power',-0.1);
%     setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+offset_time),'DMD AOM TTL',0);
%     setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+10+offset_time),'DMD Shutter',1);
%     setDigitalChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+20+offset_time),'DMD AOM TTL',1);
%     setAnalogChannel(calctime(curtime,0+DMD_on_time+DMD_ramp_time+20+offset_time),'DMD Power',3);
    end 
%% D1 Optical Pumping in ODT
% After optical evaporation, ensure mF spin polarization via D1 optical
% pumping.

if (seqdata.flags.do_D1OP_post_evap==1 && seqdata.flags.CDT_evap==1)
        dispLineStr('D1 Optical Pumping post op evap',curtime);  

    % optical pumping pulse length
    op_time_list = [1]; %1
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_time2','ms');
    
    % optical pumping repump power
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_repump_pwr2','V'); 
    
    %optical power
    D1op_pwr_list = [8]; %min: 0, max:10 %5
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_D1op_pwr2','V'); 

    
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
        % 2021/05/12 Make a generic mixture
        % These settings don't care about setting a particular mixture
        rf_k_sweep_freqs=[3.0495];%3.048 [1.8353];3.01;
        
        rf_k_sweep_freqs=[5.990]+[-0.003];%3.048 [1.8353];3.01;

        % With delta_freq =0.1;
        % 3.01 --> (-7,-5) (a little -9)
        % 3.07 --> (-1,+1,+3); 
        rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_post_evap');
        
        sweep_pars.freq=rf_k_sweep_center;        
        sweep_pars.power = -9.1;-9.2;   
        
        delta_freq_list =.01;[0.0040];%0.006; 0.01
        sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_post_evap');
        pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
        sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_post_evap');
        
        %numbers for spin mixture -9 and -7; power = -9.1, delta =
        %0.01,time = 1.25
        %numbers for near spin polarized -7/2; power = -8.4, delta = 0.06, time = 6ms 
        
        disp(['     Center Freq (MHz) : ' num2str(sweep_pars.freq)]);
        disp(['     Delta Freq  (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp(['     Power         (V) : ' num2str(sweep_pars.power)]);
        disp(['     Sweep time   (ms) : ' num2str(sweep_pars.pulse_length)]);  
        
        
        f1=sweep_pars.freq-sweep_pars.delta_freq/2;
        f2=sweep_pars.freq+sweep_pars.delta_freq/2;
        
        n_sweeps_mix_list=[10];10
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
        % Perform any additional sweeps
        for kk=1:n_sweeps_mix
            disp([' Sweep Number ' num2str(kk) ]);
            rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
            curtime = calctime(curtime,T60);
        end     

        
            

curtime = calctime(curtime,50);

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
    %% Get Rid of Rb at the Very Very End
    get_rid_of_Rb_at_the_end = 0;
    %RHYS - Not sure why this would be useful.
    if (get_rid_of_Rb_at_the_end && seqdata.flags. CDT_evap == 1)

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


    %% Pulse kill beam for alignment
    %RHYS - Can be useful. Pretty sure it exists in lattice too though.
    if Kill_Beam_Alignment

        %kill_probe_pwr = 1;
        %kill_time = 2000;
        %pulse_offset_time = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        kill_probe_pwr = 1;
        kill_time = 10;
        pulse_offset_time = 0;

        %set TTL off initially
        setDigitalChannel(calctime(curtime,-20),'Kill TTL',0); % 0 = power off; 1=  power on
        %open K probe shutter
        setDigitalChannel(calctime(curtime,-10),'Downwards D2 Shutter',1); %0=closed, 1=open

        %turn AOM on
        setDigitalChannel(calctime(curtime,0),'Kill TTL',1);

curtime=calctime(curtime,kill_time);
        %turn AOM off
        setDigitalChannel(calctime(curtime,0),'Kill TTL',0);

        %close K probe shutter
        setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0); %0=closed, 1=open
        %turn AOM on
        setDigitalChannel(calctime(curtime,500),'Kill TTL',1); 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%open K probe shutter
        %setDigitalChannel(calctime(curtime,pulse_offset_time-10),'Downwards D2 Shutter',1); %0=closed, 1=open
    
        %%set TTL off initially
        %setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',1);%1=  power on
    
        %%pulse beam with TTL
        %DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,0);
    
        %%close K probe shutter
        %setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),'Downwards D2 Shutter',0);
     
        %%set kill AOM back on
%curtime = setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 5),'Kill TTL',0);

    end

    
 %% Vertical Raman Alignment
 if Raman_Vertical_Alignment
     
     curtime=calctime(curtime,50);
     
     Device_id = 1;
     Raman_vert_freq = 110*1E6;
     Raman_vert_pwr = 0.8;
     Raman_vert_offset = 0;
     str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',Raman_vert_freq,Raman_vert_pwr,Raman_vert_offset);
    
     addVISACommand(Device_id, str);
     
     setDigitalChannel(calctime(curtime,-50),'Raman TTL 2a',0);
     setDigitalChannel(calctime(curtime,-50),'Raman TTL 2',0);
     setDigitalChannel(calctime(curtime,-50),'Raman TTL 3a',0);
     setDigitalChannel(calctime(curtime,-50),'Raman TTL 3',0);
     setDigitalChannel(calctime(curtime,-50),'Raman TTL 1',0);
     
     setDigitalChannel(calctime(curtime,-5),'Raman Shutter',1);
     
     raman_time_list = [1];
     raman_time = getScanParameter(raman_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'raman_time');
    
     DigitalPulse(calctime(curtime,0),'Raman TTL 2',raman_time,1);
     DigitalPulse(calctime(curtime,0),'Raman TTL 2a',raman_time,1);
     
     setDigitalChannel(calctime(curtime,raman_time),'Raman Shutter',0);
     setDigitalChannel(calctime(curtime,raman_time),'Raman TTL 2a',1);
     setDigitalChannel(calctime(curtime,raman_time),'Raman TTL 2',1);
     setDigitalChannel(calctime(curtime,raman_time),'Raman TTL 3a',1);
     setDigitalChannel(calctime(curtime,raman_time),'Raman TTL 3',1);
     setDigitalChannel(calctime(curtime,raman_time),'Raman TTL 1',1);
     
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
    
    % CF: This code is a quite a mess and should be cleanaed up. 1000
    % lines?! If you need a specific portion, just make a separate flag
    
    if (seqdata.flags.High_Field_Imaging && ~seqdata.flags.load_lattice )  %This is a way of doing normal high field imaging from the ODT using the seqdata.flags.High_Field_Imaging flag from the load magtrap sequence
%     if (seqdata.flags.High_Field_Imaging)             % Use this flag if
%     you still want to ramp the high field from ODT and then load lattice
%     on the atrractive side of the resonance. 
        dispLineStr('Ramping High Field in XDT',curtime);
        time_in_HF_imaging = curtime;
                
        spin_flip_9_7 = 0;
        do_raman_spectroscopy = 0;
        spin_flip_7_5 = 0;        
        rabi_manual=0;
        rf_rabi_manual = 0;
        do_rf_spectroscopy= 0; % 
        do_rf_post_spectroscopy =0;
        shift_reg_at_HF = 0;
        ramp_field_2 = 0;
        
        spin_flip_9_7_again = 0;
        spin_flip_7_5_again= 0;
        
        ramp_field_3 = 0;
        spin_flip_7_5_3 = 0;
        
        ramp_field_for_imaging = 0;
        spin_flip_7_5_4 = 0;


 % Fesahbach Field ramp
    HF_FeshValue_Initial_List =[190]; %200.5 201 201.5
    HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_ODT','G');
     
%     HF_FeshValue_Initial = paramGet('HF_FeshValue_Initial');
%             Define the ramp structure
            ramp=struct;
            ramp.shim_ramptime = 150;
            ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
            ramp.xshim_final = seqdata.params.shim_zero(1); 
            ramp.yshim_final = seqdata.params.shim_zero(2);
            ramp.zshim_final = seqdata.params.shim_zero(3);
            % FB coil 
            ramp.fesh_ramptime = 150;
            ramp.fesh_ramp_delay = 0;
            ramp.fesh_final = HF_FeshValue_Initial; %22.6
            ramp.settling_time = 100;    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');

%     seqdata.params.HF_fb = HF_FeshValue_Initial;
    seqdata.params.HF_probe_fb =  HF_FeshValue_Initial;
        
        %Do rf transfer from -9/2 to -7/2
        if spin_flip_9_7
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list =  [0] +...
                (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF');
            sweep_pars.power =  [0];
            delta_freq =1;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 100;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
     HF_wait_time_list = [30];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_ODT','ms');
curtime = calctime(curtime,HF_wait_time);

% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

            

            do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
        end
          
    if do_raman_spectroscopy

        mF1=-9/2;   % Lower energy spin state
        mF2=-7/2;   % Higher energy spin state

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        Boff = 0.11;
        zshim = 0;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        

        if (abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        Raman_AOM3_freq_list =  [0]*1e-3/2+(80+...   %-88 for 300Er, -76 for 200Er
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; %-0.14239
        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        
%            freq = paramGet('Raman_freq');
%            Raman_AOM3_freq = freq*1e-3/2+(80+...   
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; 
        
        Raman_AOM3_pwr_list = 0.66; %0.66
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
                Pulse_Time_list = [100];[0:0.015:0.15];
                Pulse_Time = getScanParameter(Pulse_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                Raman_on_time = Pulse_Time; %ms
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        end


        addVISACommand(Device_id, str);
        % R2 beam settings
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list = 0.30; %0.51
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
                seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
                Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

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
        
        %Do rf transfer from -7/2 to -5/2
        if spin_flip_7_5
            clear('sweep');
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = HF_FeshValue_Initial; 
            rf_list =  [0] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF','MHz');
            disp(sweep_pars.freq)

            sweep_pars.power =  [0];
            delta_freq = 0.1; 0.025;0.1;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 10;5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
         HF5_wait_time_list = [50];
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
        
        if rabi_manual
            mF1=-7/2;
            mF2=-9/2;    
            
            disp(' Rabi Oscillations Manual');
            clear('rabi');
            rabi=struct;          
            
            B = HF_FeshValue_Initial; 
            rf_list = [-2]*1e-3 +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
            rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_rabi_freq_HF');
            power_list =  [2.5];
            rabi.power = getScanParameter(power_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF');            
%             rf_pulse_length_list = [0.5]/15;
            rf_pulse_length_list = [0.005:0.005:.155];      
            rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF');  % also is sweep length  0.5               
                        
            % Define the frequency
            dTP=0.1;
            DDS_ID=1; 
            sweep=[DDS_ID 1E6*rabi.freq 1E6*rabi.freq rabi.pulse_length+2];
          
            
            disp(rabi);

            % Preset RF Power
            setAnalogChannel(calctime(curtime,0),'RF Gain',rabi.power);         
            setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);             
            
            do_ACync_rf = 1;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,1);
                ACync_end_time = calctime(curtime,1+rabi.pulse_length+35);
                curtime=setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);                
            end         
            
            % Wait 5 ms to get ready
            curtime=calctime(curtime,5);           
            
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
            
            setAnalogChannel(calctime(curtime,1),'RF Gain',-10);         

            % Extra Wait Time
            curtime=calctime(curtime,35);            
        end    
        
                   % RF Rabi Oscillations
    if rf_rabi_manual
        mF1=-7/2;
        mF2=-9/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        Boff = 0.11;
        zshim = 0;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;            
        rf_list =  [-2]*1e-3 +... 
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6); 
        rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];       
        
          if (rabi.freq < 10)
                         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
          end
          
%           rf_pulse_length_list = [1.005:0.01:1.095 3.005:0.01:3.095];  %0.23
%           rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
%             seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               
%         
            rabi.pulse_length = paramGet('rf_rabi_time_HF');

        rabi_source = 'DDS';
%         rabi_source = 'SRS';
        
        switch rabi_source
            case 'DDS' 
                    power_list =  [2.5]; 2.5;
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
        
        do_rf_spectroscopy_old = 0;
        if do_rf_spectroscopy_old
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = HF_FeshValue_Initial; 
            rf_list =  [-0.105:0.01:0.085] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            rf_freq_HF = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF','MHz');
            
            % Define the sweep parameters
            delta_freq=.02; %0.02
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

            
            do_ACync_rf = 1;
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
        

    % RF Sweep Spectroscopy new with DDS/SRS (same code as in load lattice)
    if do_rf_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        
        % Get the center frequency
        zshim = 0;
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        
%          rf_shift_list = [-20:2:10];       
%         rf_shift = getScanParameter(rf_shift_list,seqdata.scancycle,...
%                         seqdata.randcyclelist,'rf_freq_HF_shift','kHz');
         
%             rf_shift = paramGet('rf_freq_HF_shift');
        rf_shift = 0;
        
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        % Define the sweep parameters
        delta_freq= 0.1; %0.00125; %.0025;  in MHz            
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
                curtime=calctime(curtime,10);    
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  

                rf_srs_power_list = [4];
                rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_srs_power','dBm');
%                 rf_srs_power = paramGet('rf_srs_power');
                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address='192.168.1.120';                       % K uWave ("SRS B");
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
                rf_rabi_manual =0;
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
%                             curtime = calctime(curtime,rf_pulse_length);



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
                 
                HF_hold_time_list = [40];
                HF_hold_time = getScanParameter(HF_hold_time_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'HF_hold_time_ODT','ms');
% %                 
%                 HF_hold_time = paramGet('HF_hold_time');
                
                curtime=calctime(curtime,HF_hold_time); 
                
                if HF_hold_time > 1
                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length-HF_hold_time),'RF TTL',0); 
                end
                
        end  
    end
    
    
    
    if do_rf_post_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);

        % Get the center frequency
        Boff = 0.11;
        zshim =0;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
%         rf_shift = 15;

        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end
          
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

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
    
        %Do shift register
        if shift_reg_at_HF
            dispLineStr('Performing shift register in XDT',curtime);
            clear('sweep');
            B = HF_FeshValue_Initial; 
            f1 = (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            f2 = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
            rf_list =(f1+f2)/2; 
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rfSR_freq_HF');
            sweep_pars.power_list =  [0];
            sweep_pars.power = getScanParameter( sweep_pars.power_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_power_HF');
            delta_freq_list = 3.5; 0.1;
            sweep_pars.delta_freq = getScanParameter(delta_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_deltaFreq_HF');
            rf_pulse_length_list =40; 20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_time_HF');  % also is sweep length  0.5               

            disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
            disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);
            disp([' Sweep Delta      (MHz) : ' num2str(sweep_pars.delta_freq)]);
            
            n_sweeps_mix_list=[1];
            n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
                seqdata.scancycle,seqdata.randcyclelist,'n_sweeps');  % also is sweep length  0.5               

            % Perform the first sweep            
            disp(['Sweep Number ' num2str(1) ]);
%             curtime = calctime(curtime,100);
            curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

            % Perform any additional sweeps
            for kk=2:n_sweeps_mix
                disp(['Sweep Number ' num2str(kk) ]);
                curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);%3: sweeps, 4: pulse
            end
            
        end

seqdata.params.HF_probe_fb = HF_FeshValue_Initial;  

   if ramp_field_2
    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [209]; % 206 207 208 209 210 211
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_ODT','G');
 
    % Define the ramp structure
    ramp=struct;
    ramp.FeshRampTime = 100;
    ramp.FeshRampDelay = -0;
    ramp.FeshValue = HF_FeshValue_Final;
    ramp.SettlingTime = 50; 50;    
    
    % Ramp the magnetic Fields
curtime = rampMagneticFields(calctime(curtime,0), ramp);
    
    seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    HF_FeshValue_Initial = HF_FeshValue_Final;
    end
%  curtime = calctime(curtime,100);

 
 if spin_flip_9_7_again
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list =  [0] +...
                (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF');
            sweep_pars.power =  [0];
            delta_freq =1;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 100;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
     HF_wait_time_list = [30];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_ODT','ms');
curtime = calctime(curtime,HF_wait_time);
            do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
 end
 
  if spin_flip_7_5_again
            clear('sweep');
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = HF_FeshValue_Initial; 
            rf_list =  [0] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF','MHz');
            disp(sweep_pars.freq)

            sweep_pars.power =  [0];
            delta_freq = 0.1; 0.025;0.1;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 10;5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%double pulse sequence
% curtime = calctime(curtime,35);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,50);

        do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
  end
  
  
     if ramp_field_3

        clear('ramp');
        HF_FeshValue_List =[210];
        HF_FeshValue = getScanParameter(HF_FeshValue_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_ODT_3','G');           
%         
%         HF_FeshValue = paramGet('HF_FeshValue_ODT_3');
      
        HF_FeshValue_Initial = HF_FeshValue; %For use below in spectroscopy
        seqdata.params.HF_probe_fb = HF_FeshValue; %For imaging

        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_shimvalue_ODT_3','A');
        
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
        ramp.fesh_final = HF_FeshValue;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
 
    % Hold time at the end
     HF_wait_time_list = [0];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');
    
curtime = calctime(curtime,HF_wait_time);
  
     end
  
    if spin_flip_7_5_3
            clear('sweep');
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = HF_FeshValue_Initial +2.35*zshim+0.11; 
            rf_list =  [0] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF_3','MHz');
            disp(sweep_pars.freq)

            sweep_pars.power =  [0];
            delta_freq = 0.1; 0.025;0.1;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 10;5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%double pulse sequence
curtime = calctime(curtime,35);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,50);

        do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
    end
  
 
   if ramp_field_for_imaging

    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [195]; % 206 207 208 209 210 211
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Imaging_ODT','G');
 
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

 if spin_flip_7_5_4
            clear('sweep');
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = seqdata.params.HF_probe_fb; 
            rf_list =  [0] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF','MHz');
            disp(sweep_pars.freq)

            sweep_pars.power =  [0];
            delta_freq = 0.1; 
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 10;5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
  end

 HF5_wait_time_list = [35];
 HF5_wait_time = getScanParameter(HF5_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end

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