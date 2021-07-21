%------
%Author: Dylan
%Created: May 2012
%Summary: Ramp the QP before QP transfer. Outputs are the currents/voltages
%after the ramp
%------
%RHYS - This code, probably originally intended to just load the dipole
%trap, now includes everything anyone would ever want to do in a dipole
%trap, including spin-flips/spectroscopy, evaporation, and a number of
%specialized or obsolete sequences. I would trim it back extensively, move
%hardcoded parameters out, and keep specialized sequences as optional
%xdt-specific flags to call.
function [timeout I_QP V_QP P_dip dip_holdtime,I_shim] = dipole_transfer(timein, I_QP, V_QP,I_shim)


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
    %ramps the shims based on the inverse of the gradient
    %shim_ramp_func2 =
    %@(t,tt,y2,y1)(y1-(y2-y1)/1.2/(5-1.2)+(y2-y1)/(5-1.2)./(1-t/tt+0.2));
    
    %After Loading the XDT
    %--------------------
    %RHYS - Move all of these flags out of this function, and declare them
    %in the seqdata structure to be passed in.  
    
    get_rid_of_Rb_init = 0;%get rid of Rb with resonant light pulse
    init_Rb_RF_sweep = 0;%Sweep 87Rb to |1,-1> (or |2,-2>) before evaporation
    seqdata.flags.do_K_uwave_transfer_in_ODT = 0;%transfer K atoms from F=9/2 to F=7/2
    dipole_oscillation_heating = 0;%Heat atoms by modulating the XDT beams 
    
    %Evaporation in the XDT
    %--------------------
    tilt_evaporation = 0;
    dipole_holdtime_before_evap = 0;
    %RHYS - A very important parameter. Pass these from elsewhere.
    Evap_End_Power_List =[0.085 0.09 0.095 0.1:0.01:0.2 0.22 0.25 0.3 0.35 0.4];[0.085];[.065];0.25;   %[0.80 0.6 0.5 0.4 0.3 0.25 0.2 0.35 0.55 0.45];0.1275; %0.119      %0.789;[0.16]0.0797 ; % XDT evaporative cooling final power; 
    
    
    exp_end_pwr = getScanParameter(Evap_End_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Evap_End_Power','W');
    Second_Evaporation_Stage = 0;
    %exp_end_pwr =  0.3; %0.36  

    %After Evaporation (unless CDT_evap = 0)
    %--------------------
    ramp_dipole_for_spect = 0;      %Ramp dipole back up before any further physics 
    do_dipole_trap_kick = 0;        %Kick the dipole trap, inducing coherent oscillations for temperature measurement
    do_end_uwave_transfer = 0;      %transfer Rb atoms from F=1 to F=2, then blow them away with probe pulse
    Rb_RF_sweep = 0;                %sweep atoms from |2,2> into |2,-2>
    Rb_repump = 0;                  %repump atoms back into F = 2
    seqdata.flags.get_rid_of_Rb = 0;%Get rid of Rb at end of evap (only happens when CDT_evap = 1
    do_RF_sweep_before_uWave = 0;   %Do an mF sweep before uWave spectroscopy
    do_K_uwave_spectroscopy = 0;    %do uWave Spectroscopy of 40K
    do_K_uwave_multi_sweeps = 0;    %do multiple uWave sweeps of 40K
    do_Rb_uwave_spectroscopy = 0;   %do uWave Spectroscopy of 87Rb
    do_RF_spectroscopy = 0;         %do spectroscopy with DDS 
    do_singleshot_spectroscopy = 0; %do uwave spectroscopy using mF states to shelve population
    do_field_ramps = 0;             %Ramp shim and FB fields without spectroscopy
    K_repump_pulse = 0;             %Get rid of F = 7/2 Potassium
    K_probe_pulse = 0;              %Get rid of F = 9/2 Potassium
    D1_repump_pulse = 0;            %D1 repump instead of D2
    Dimple_in_XDT = 0;
    DMD_in_XDT = 0;
    Lattice_in_XDT_Evap = 0;
    ramp_up_FB_for_lattice = 0;     %Ramp FB up at the end of evap  
    Kill_Beam_Alignment = 0;        %Pulse Kill beam on for whatever needs to be aligned.    
    ramp_XDT_after_evap = 0;        %Ramp XDT up after evaporation to keep Rb and K at same location for lattice aligment              
    Raman_in_XDT = 0;
    
   
 
    k_rf_rabi_oscillation=0;        % RF rabi oscillations after evap
    
    % FB Field and evaporation
    ramp_Feshbach_B_before_CDT_evap = 1;
    ramp_Feshbach_B_in_CDT_evap = 0; %ramp up Feshbach field during CDT evap, try to create a colder sample
    ramp_Feshbach_B_after_CDT_evap = 0; %ramp up Feshbach field after CDT evap, try to create a colder sample
    
    load_lat_in_xdt_loading = 0;        %ramp up and ramp down lattice beams in the dipole transfer code;

    if qp_ramp_down_start_time<0
        error('QP ramp must happen after time zero');
    end
    
    
    %%%%% Specify the XDT2 power relative to XDT1 %%%%%%%%%%%%%%%%%%%%%%%%%
    % This is useful to ensure that at the end of optical evaporation the
    % horizontal trap frequencies are rotationally symmetric which is
    % useful for the condutitivty experiments.
    %Calibrate to match horizontal trap frequencies.
%     XDT2_power_func = @(P_XDT1)((sqrt(81966+1136.6*(21.6611-(-119.75576*P_XDT1^2+159.16306*P_XDT1+13.0019)))-286.29766)/2/(-284.1555));
    XDT2_power_func = @(P_XDT1)(P_XDT1/2);
    
    % Making it uniform for now (CF 2020/01/26)
    XDT2_power_func = @(x) x;
    
    %RHYS - More parameters.
%     %Initial powers.
%     P1 = 1.5;1.50;1;1.5;0.5;1.5;%Can currently be about 2.0W. ~1V/W on monitor. Feb 27, 2019.
%     P2 = 1.5;1.50;1.5;0.5;1.5;%Can currently be about 2.0W. ~1V/W on monitor. Feb 27, 2019.
%     

    % Initial XDT power
    P12_list = [1.5];
    P12 = getScanParameter(P12_list,...
        seqdata.scancycle,seqdata.randcyclelist,'XDT_initial_power','W');
    P1 = P12;
    P2 = P12;       %P2 = XDT2_power_func(P1);
            
    % Sympathetic cooling powers
    P1e = 1.0;0.5;1.0; %0.5
    P2e = 1.0;0.5; %0.5

    % Uncomment these to overwrite initial ramp and just use max powers.
%     P1e=P1;
%     P2e=P2;    
%     %P2e = XDT2_power_func(P1e);    
%     
    %Final powers.
    xdt1_end_power = exp_end_pwr;
    xdt2_end_power = XDT2_power_func(exp_end_pwr);
    %xdt2_end_power =(sqrt(81966+1136.6*(21.6611-(-119.75576*xdt1_end_power^2+159.16306*xdt1_end_power+13.0019)))-286.29766)/2/(-284.1555);
    
    % Evaporation Time
    Time_List =  [15000];[15000]; %[500] for fast evap, for sparse image, [15000] for normal experiment
    Evap_time = getScanParameter(Time_List,seqdata.scancycle,seqdata.randcyclelist,'evap_time');   
    exp_evap_time = Evap_time;         
    Tau_List = [5];[4];   %[0.80 0.6 0.5 0.4 0.3 0.25 0.2 0.35 0.55 0.45];0.1275; %0.119      %0.789;[0.16]0.0797 ; % XDT evaporative cooling final power; 
    exp_tau_frac = getScanParameter(Tau_List,seqdata.scancycle,seqdata.randcyclelist,'Evap_Tau_frac');
    exp_tau=Evap_time/exp_tau_frac;

    %Power    Load ODT1  Load ODT2  Begin Evap      Finish Evap
    DT1_power = 1*[P1         P1        P1e          xdt1_end_power];
%     DT1_power = -1*[1         1        1          1]; 
    DT2_power = 1*[P2      P2        P2e          xdt2_end_power];  
%     DT2_power = -1*[1         1        1          1];  

%% Special Flags
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

setAnalogChannel(calctime(curtime,-10000),40,-0.060);


    dipole_ramp_start_time_list =[0]; [-500];
    dipole_ramp_start_time = getScanParameter(dipole_ramp_start_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_start_time');
    
    %dipole_ramp_start_time = -500; % Offset time to begin ramp on   
    
    dipole_ramp_up_time_list = [75]; 
    dipole_ramp_up_time = getScanParameter(dipole_ramp_up_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dipole_ramp_up_time');
%     dipole_ramp_up_time = 200;      % Duration of initial ramp on

    %RHYS - Actually unused. 
    CDT_power = 3.8;%3.5; %4.5   7.0 Jan 22nd

    dipole1_power = CDT_power*1; %1
    dipole2_power = CDT_power*0; %Voltage = 0.328 + 0.2375*dipole_power...about 4.2Watts/V when dipole 1 is off

    % Enable ALPs feedback control and turn on XDTs AOMs
    setDigitalChannel(calctime(curtime,dipole_ramp_start_time-10),'XDT Direct Control',0);
    setDigitalChannel(calctime(curtime,dipole_ramp_start_time-10),'XDT TTL',0);  
    dispLineStr('ODT 1 ramp up started at',calctime(curtime,dipole_ramp_start_time));

    % Ramp dipole 1 trap on
    AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
        'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_ramp_up_time,dipole_ramp_up_time,-0.060,DT1_power(1));
    
    % Ramp dipole 2 trap on (not really)
    AnalogFunc(calctime(curtime,dipole_ramp_start_time),...
        'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dipole_ramp_up_time,dipole_ramp_up_time,0,DT2_power(1)); %used to be starting from -1  
    
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
        dIx=dI_QP*-0.0499;
        dIy=dI_QP*0.0045;
        dIz=dI_QP*0.0105;      
                
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
        %do_evap_stage(calctime(curtime,qp_ramp_down_start_time+200), 0, [8 8]*1E6, qp_ramp_down_time1-200, [-2], 0, 1);

        % Turn off plug
        %AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),33,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time1,qp_ramp_down_time1,0);

        % Ramp down FF.
        AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1*23/30);
        
        % Ramp down QP and advance time
        curtime = AnalogFuncTo(calctime(curtime,qp_ramp_down_start_time),'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1);

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
        
%         XDT_pin_time =400;400;

        dipole2_ramp_start_time = 0; 
        %ramp dipole 2 trap on
        AnalogFuncTo(calctime(curtime,dipole2_ramp_start_time),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),XDT_pin_time,XDT_pin_time,DT2_power(2));
        %ramp dipole 1 down a bit while dipole 2 ramps up

        curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),XDT_pin_time,XDT_pin_time,DT1_power(2));
  

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
        dIx=dI_QP*-0.0499;
        dIy=dI_QP*0.0045;
        dIz=dI_QP*0.0105;  
                
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
        
    plug_turnoff_time_list =[0]; -200;
    plug_turnoff_time = getScanParameter(plug_turnoff_time_list,seqdata.scancycle,seqdata.randcyclelist,'plug_turnoff_time');
     setDigitalChannel(calctime(curtime,plug_turnoff_time),'Plug Shutter',0);%0:OFF; 1:ON; -200
     dispLineStr('Turning off plug ',calctime(curtime,plug_turnoff_time));

    %this code below is to hold atoms in the XDT beams to check the heating issue 
    % hold_time_list = [17000 20000];
    % hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_XDT');
%curtime = calctime(curtime,hold_time);    
    
    P_dip = dipole1_power;
    P_dip2 = DT2_power(2);
    %P_dip2 = dipole2_power; %Dipole 2 Power is definied to be zero, and
    %dipole 2 is instead ramped up to dipole2_pin_power
     
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
%curtime=AnalogFunc(calctime(curtime,-500),18,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),500,500,0,15.8);

    %Use QP TTL to shut off coil 16 
    setDigitalChannel(calctime(curtime,0),21,1);

    %Turn Coil 15 FET off
    setAnalogChannel(calctime(curtime,0),21,0,1);


    %Hold for some time (field settling?)
curtime = calctime(curtime,dipole_holdtime_before_evap);


    %% Rb uWave transfer

    %RHYS - Next follows a long set of possible types of RF or microwave
    %transfer. These could in theory be combined into one general function. The
    %things to specify would be: the atom, the field, field ramp up/down times, 
    %whether to ramp the field or the function generator frequency, the sweep 
    %time, the sweep range, the power as a function of max, and whether to do
    %some kind of round trip there and back. General functions have been
    %attempted (see rf_uwave_spectroscopy) but are themselves messy, and so
    %many of these historical messy codes still exist. 
    
    if ( seqdata.flags.do_Rb_uwave_transfer_in_ODT )
        dispLineStr('uWave Rb 2-->1',curtime);
    end

    %Pre-ramp the field to 20G for transfer
    if ( seqdata.flags.do_Rb_uwave_transfer_in_ODT )      
        Rb_SRS=struct;
        Rb_SRS.Address=29;        % GPIB address of the Rb SRS
        
        Rb_SRS_list = [0];
        Rb_SRS_det = getScanParameter(Rb_SRS_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_SRS_det');
        Rb_SRS.Frequency=6.87560 + Rb_SRS_det/1000; % Frequency in GHz
        Rb_SRS.Power=8;%8           % Power in dBm (Don't go too high)
        Rb_SRS.Enable=1;          % Whether to enable 
        Rb_SRS.EnableSweep=0;
        
        programSRS_Rb(Rb_SRS);  
        
        
        %Field about which to do the sweep
        %mean_field =19.435;%19.468706; %before 2017-1-6 20.97; %21.66
        mean_field_list = 19.432;19.432;%0.2 for 0.7xdt power
        mean_field = getScanParameter(mean_field_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_Transfer_Field');
        del_fesh_current = 0.2;1;%0.10431;% before 2017-1-6 0.1; %0.1
        addOutputParam('del_fesh_current',del_fesh_current)
        %mean_field = (B_2-0.1)*1.08962 + del_fesh_current/2;

        ramp_fields = 1;
        if ramp_fields % if a coil value is not set, this coil will not be changed from its current value
            % shim settings for spectroscopy
            clear('ramp');
            shim_ramptime_list = [2];
            shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
            ramp.shim_ramptime = shim_ramptime;
            ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero

            %getChannelValue(seqdata,27,1,0);
            %getChannelValue(seqdata,19,1,0);
            %getChannelValue(seqdata,28,1,0);

            %Give ramp shim values if we want to do spectroscopy using the
            %shims instead of FB coil. If nothing set here, then
            %ramp_bias_fields just takes the getChannelValue (which is set to
            %field zeroing values)
            ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
            ramp.yshim_final = seqdata.params.shim_zero(2);
            ramp.zshim_final = seqdata.params.shim_zero(3);

            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = 0;
            ramp.fesh_final = mean_field+del_fesh_current/2; %22.6
            ramp.settling_time = 50;
            
            disp('Ramping the feshbach field');
%             disp(['     Field (G) : ' num2str(ramp.


curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
       
        end
    end
    

    % Perform Field ramp with uWave to transfer Rb from F=2 to F=1
    if seqdata.flags.do_Rb_uwave_transfer_in_ODT        
        do_roundtrip = 0;   % Sweep field there and back again?
        do_F2_blowaway = 1; % Remove remaining F=2 atoms after transfer?

        % switch Rb microwave source to Anritsu for transfer
        setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',0); %0 = Anritsu, 1 = Sextupler

curtime=calctime(curtime,0); % some time for opening transfer switches and field settling

        uWave_sweep_time = 60; %60
        fesh_uWave_current = mean_field-del_fesh_current/2;

        addOutputParam('uWave_sweep_time',uWave_sweep_time)

        uWave_pulse_freq = 21.52; % in MHz (???? this seems to be unnecessary)

        ScopeTriggerPulse(curtime,'Rb uwave transfer');

        % microwave pulse
        do_uwave_pulse(calctime(curtime,0), 0, uWave_pulse_freq*1E6, uWave_sweep_time,0);
       
        % sweeping the magnetic field during microwave pulse (for most rf/uwave sources works significantly better than a frequency sweep)
        if ( do_roundtrip ) % do a roundtrip sweep over 2*(uWave_sweep_time/2)

            fesh_current_val = getChannelValue(seqdata,37); % get curent value to ramp back to in the end
            AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),uWave_sweep_time/2,uWave_sweep_time/2, fesh_uWave_current);
curtime  = AnalogFuncTo(calctime(curtime,000+uWave_sweep_time/2),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),uWave_sweep_time/2,uWave_sweep_time/2, fesh_current_val);

        else % do a single sweep over uWave_sweep_time 

curtime  =  AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),uWave_sweep_time,uWave_sweep_time,fesh_uWave_current);
            fesh_current_val = fesh_uWave_current;

        end

        % optical pulse resonant with transition from F=2 to clean out remaining population
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

        sweep_back = 0;
        if sweep_back
            %Wait for some time
            wait_time = 50;
            curtime=calctime(curtime,wait_time);

            % microwave pulse
            do_uwave_pulse(calctime(curtime,0), 0, uWave_pulse_freq*1E6, uWave_sweep_time,0);

curtime  =  AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),uWave_sweep_time,uWave_sweep_time,mean_field+del_fesh_current/2);
%             fesh_current_val = mean_field+del_fesh_current/2;  
        end

        % switch Rb microwave source to Sextupled SRS for whatever follows
        setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler


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
 


%% Kill Rb in XDT
    %RHYS - Kind of unneccessary (could just kill it in the mag trap if desired).    
    if get_rid_of_Rb_init        
        do_repump_before_kill = 0;        

        kill_pulse_time_list = 2; %5 %%DO NOT SET TO ZERO%%
        kill_pulse_time = getScanParameter(kill_pulse_time_list,seqdata.scancycle,seqdata.randcyclelist,'kill_pulse_time');
        %repump atoms from F=1 to F=2, and blow away these F=2 atoms with
        %the probe
        %open shutter
        %probe
        setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %0=closed, 1=open, d25
        
        if do_repump_before_kill
            %repump
            setDigitalChannel(calctime(curtime,-10),'Rb Sci Repump',1); 
        else
            setDigitalChannel(calctime(curtime,-10),'Rb Sci Repump',0); 
        end
        setAnalogChannel(calctime(curtime,-100),'Rb Repump AM',0,1); %0.7
        
        
        %open analog
        %probe
        setAnalogChannel(calctime(curtime,-10),'Rb Probe/OP AM',0.7); %a36
        %repump (keep off since no TTL)

        %set TTL
        %probe
        setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);%d24
        %repump doesn't have one

        %set detuning
        setAnalogChannel(calctime(curtime,-10), 'Rb Beat Note FM',6590-237); %a34

        %pulse beam with TTL 
        %TTL probe pulse
        DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',kill_pulse_time,0);
        %repump pulse
        setAnalogChannel(calctime(curtime,0),'Rb Repump AM',1,1); %0.7
curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),'Rb Repump AM',0.0,1);

        %close shutter
        setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); %0=closed, 1=open
curtime = setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0);

curtime = calctime(curtime,50);
    end

    
%% 40K RF Sweep Init
%Sweep 40K to |9/2,-9/2> before optical evaporation   

if seqdata.flags.init_K_RF_sweep
    dispLineStr('RF K Sweep 9-->-9',curtime);   

    %Ramp FB if not done previously
    if ~seqdata.flags.do_Rb_uwave_transfer_in_ODT && ~seqdata.flags.do_Rb_uwave_transfer_in_ODT2
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
    k_rf_power_list = [-3];0;
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
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle, seqdata.randcyclelist, 'op_time'); %optical pumping pulse length
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle, seqdata.randcyclelist, 'op_repump_pwr'); %optical pumping repump power
    D1op_pwr_list = [5]; %min: 0, max:10
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle, seqdata.randcyclelist, 'D1op_pwr'); %optical power

    
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

%% Spin mixture after OP

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

    %% Turn on Gradient for CDT Evap (to adjust Rb vs. K trapping)

    gradient_evap = 0;
    %RHYS - This never took off.
    if gradient_evap

        y_shim_list = [-0.2,0.1,-0.05,0.05,0.1];

        % FB coil settings for gradient evap
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = 0.0115;%before 2017-1-6 0*22.6; %22.6
        x_shim_offset = -0.10;
        y_shim_offset = -0.40;
        z_shim_offset = -0.65; %Displace QP centre from trap
        addOutputParam('PSelect_FB',ramp.fesh_final)

        %qp_time_list = [1 1000 3000 6000 9000 12000];

        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 50;%150 %This controls what fraction of the ramp is actually performed.
        ramp.QP_ramp_delay = 100;
        ramp.QP_final =  0.3*1.78; %12 works well for XDT power of 1, 24 for XDT power of 2 (although this is a lot of current). 
        %These two parameters define the shape - the time constant, and
        %how long it takes to get to max amplitude.

        ramp.shim_ramptime = 100; %150 %This controls what fraction of the ramp is actually performed.
        ramp.shim_ramp_delay = 0;
        ramp.xshim_final = x_shim_offset + ramp.QP_final / QP_value * (seqdata.params. plug_shims(1) - seqdata.params. shim_zero(1)) + seqdata.params. shim_zero(1); %5.5 from side
        ramp.yshim_final = y_shim_offset + ramp.QP_final / QP_value * (seqdata.params. plug_shims(2) - seqdata.params. shim_zero(2)) + seqdata.params. shim_zero(2);
        ramp.zshim_final = z_shim_offset + ramp.QP_final / QP_value * (seqdata.params. plug_shims(3) - seqdata.params. shim_zero(3)) + seqdata.params. shim_zero(3);
        %These two parameters define the shape - the time constant, and
        %how long it takes to get to max amplitude. 

        ramp.settling_time = 150; %200

curtime = ramp_bias_fields(calctime(curtime,0), ramp); %

        %Wait some variable amount of time.
%curtime = calctime(curtime, 100);

        %clear('ramp')
        %QP coil settings for spectroscopy
        %ramp.QP_ramptime = 150; %150
        %ramp.QP_ramp_delay = 60;
        %ramp.QP_final =  0*1.78; %7
        %ramp.settling_time = 150; %200

%curtime = ramp_bias_fields(calctime(curtime,0), ramp); %

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
            evap_start_pwr1 = DT1_power(3); %0.8
            evap_start_pwr2 = DT2_power(3); %0.8*1
            dipole_preramp_time = 500;50;%500

            disp(['     Ramp Time (ms) : ' num2str(dipole_preramp_time)]);
            disp(['     XDT 1 init (W) : ' num2str(DT1_power(2))]);
            disp(['     XDT 2 init (W) : ' num2str(DT2_power(2))]);            
            disp(['     XDT 1 (W)      : ' num2str(DT1_power(3))]);
            disp(['     XDT 2 (W)      : ' num2str(DT2_power(3))]);            
            
            if ~(evap_start_pwr1==dipole1_power && evap_start_pwr1==dipole2_power)
                %ramp dipole traps to sympathetic cooling regime
                AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_preramp_time,dipole_preramp_time,DT1_power(3));
curtime =   AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_preramp_time,dipole_preramp_time,DT2_power(3));

            end
            dipole1_power = evap_start_pwr1;
            dipole2_power = evap_start_pwr2;

        else
            dipole2_power = dipole2_pin_pwr;
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

            %RHYS - Tried this, not helpful for final temp.
            if Lattice_in_XDT_Evap
                Lattice_On_Time = 0.05*exp_evap_time;

                P_Lat = 0.1;
                AnalogFunc(calctime(curtime,-100+Lattice_On_Time),'latticeWaveplate',@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),100,100,P_Lat);

                %set intital value and set digital channel value
                setAnalogChannel(calctime(curtime,Lattice_On_Time-60),'xLattice',-10,1);
                setAnalogChannel(calctime(curtime,Lattice_On_Time-60),'yLattice',-10,1);
                setAnalogChannel(calctime(curtime,Lattice_On_Time-60),'zLattice',-10,1);

                % Enable rf output on ALPS3 (fast rf-switch and enable integrator)
                setDigitalChannel(calctime(curtime,Lattice_On_Time-50),34,0);
                setDigitalChannel(calctime(curtime,Lattice_On_Time-25),'Lattice Direct Control',0);
                %---------------------------------------------------------
                lat_ramp_time = 200;
                lat_ramp_tau = 50;
                X_Lattice_Depth = 2.5;
                Y_Lattice_Depth = 2.5;
                Z_Lattice_Depth = 0;
                atomscale = 0.4;    %0.4 : K40;  1: Rb

                %ramp up
                AnalogFuncTo(calctime(curtime,Lattice_On_Time),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth/atomscale);
                AnalogFuncTo(calctime(curtime,Lattice_On_Time),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth/atomscale);
                AnalogFuncTo(calctime(curtime,Lattice_On_Time),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth/atomscale);

                X_Lattice_Depth = 0;
                Y_Lattice_Depth = 0;
                Z_Lattice_Depth = 0;    
                %ramp down
                AnalogFuncTo(calctime(curtime,exp_evap_time-lat_ramp_time),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth/atomscale);
                AnalogFuncTo(calctime(curtime,exp_evap_time-lat_ramp_time),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth/atomscale);
                AnalogFuncTo(calctime(curtime,exp_evap_time-lat_ramp_time),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth/atomscale);

                %---------------------------------------------------------
                %turn off TTLs
                setDigitalChannel(calctime(curtime,exp_evap_time),34,1);
                setDigitalChannel(calctime(curtime,exp_evap_time),'Lattice Direct Control',1);
            end

            % EXPONENTIAL RAMP 
            AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_time,exp_tau,DT1_power(4));
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_time,exp_tau,seqdata.params.XDT_area_ratio*DT2_power(4));
% setDigitalChannel(calctime(curtime,50),'XDT TTL',1)
            
%RHYS - Don't think this was ever helpful.
            if(Second_Evaporation_Stage)

                Second_Evap_Power = 0.16;
                Second_Evap_Time = 5000;
                Second_Evap_Total_Time = 5000;
                Second_Evap_Tau = Second_Evap_Total_Time/5;

                % exponential evaporation ramps (ramping down XDT beams)
                AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),Second_Evap_Time,Second_Evap_Total_Time,Second_Evap_Tau,Second_Evap_Power);
curtime =   AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),Second_Evap_Time,Second_Evap_Total_Time,Second_Evap_Tau,seqdata.params.XDT_area_ratio*Second_Evap_Power);
            end

            CDT_rampup = 0;
            CDT_rampup_time = 1500;%1000-100;

            CDT_rampdown_trapbottom =0;

            
            %RHYS - Never used.      
            if CDT_rampup

                CDT_rampup_pwr = 0.7;
                CDT_rampup_tau =CDT_rampup_time/3;

                evap_exp_rampdown = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(tt/tau)-1)*(exp(t/tau)-1));

                %ramp down dipole 1 
                AnalogFunc(calctime(curtime,0),40,@(t,tt,tau,y2,y1)(evap_exp_rampdown(t,tt,tau,y2,y1)),CDT_rampup_time,CDT_rampup_time,CDT_rampup_tau,CDT_rampup_pwr,exp_end_pwr*dipole1_exp_pwr);
                %ramp down dipole 2 
                curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,tau,y2,y1)(evap_exp_rampdown(t,tt,tau,y2,y1)),CDT_rampup_time,CDT_rampup_time,CDT_rampup_tau,CDT_rampup_pwr*dipole2_exp_pwr,exp_end_pwr*dipole2_exp_pwr);    

                curtime = calctime(curtime,100);
            end
            
            %RHYS - Never used.
            if CDT_rampdown_trapbottom

                CDT_rampdown_pwr = 0.25;
                CDT_rampdown_time = 150;

                %ramp dipole 1 trap on
                AnalogFunc(calctime(curtime,0),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),CDT_rampdown_time,CDT_rampdown_time,CDT_rampdown_pwr,DT1_power(4));
                %ramp dipole 2 trap on
curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),CDT_rampdown_time,CDT_rampdown_time,CDT_rampdown_pwr,DT2_power(4));
            end
            
            
            
            dipole_oscillation = 0;
            % Oscillate trap after evaporation
            if dipole_oscillation
                disp(' Oscillating dipole depths.');
                
                % Oscillate with a sinuisoidal function
                dip_osc = @(t,freq,y2,y1)(y1 +y2*sin(2*pi*freq*t/1000));

                dip_osc_time = 500; 1000;        % Duration to modulate             
 
                dip_osc_offset = exp_end_pwr;   % CDT_rampup_pwr;
                dip_osc_amp = 0.05;              % Oscillation amplitude
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

    %RHYS - Never used this, could be useful?
    elseif ( seqdata.flags.CDT_evap == 2 ) % fast linear rampdown to test depth

        linramp_time = 5000;
        ramp_end1 = 0.2; %bottom is 0.07
        ramp_end2 = 4;

        %ramp dipole 1 trap down
        AnalogFunc(calctime(curtime,0),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),linramp_time,linramp_time,ramp_end1,dipole1_power);
        %ramp dipole 2 trap down
curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),linramp_time,linramp_time,ramp_end2,dipole2_power);


        dip_holdtime=25000 - linramp_time;

    %RHYS - 'Piecewise linear evaporation' - I've never used it, delete.        
    elseif ( seqdata.flags.CDT_evap == 3 )

        linramp_time = [10000 14000]*0.4;

        dipole1_exp_pwr = 1.0;
        dipole2_exp_pwr = 2.2; %2

        %pre-ramp to sympathetic cooling regime
        evap_start_pwr1 = 1.0; %0.8
        evap_start_pwr2 = 1.0*2.2; %0.8*2.2

        dipole_preramp_time = 500;

        if ~(evap_start_pwr1==dipole1_power && evap_start_pwr1==dipole2_power)

            %ramp down QP
            %AnalogFunc(curtime,1,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_preramp_time,dipole_preramp_time,QP_ramp_end1*1.2,QP_ramp_end1);
            %ramp up bias

            %ramp dipole 1 trap on
            AnalogFunc(calctime(curtime,0),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_preramp_time,dipole_preramp_time,evap_start_pwr1,dipole1_power);
            %ramp dipole 2 trap on
curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_preramp_time,dipole_preramp_time,evap_start_pwr2,dipole2_power);
        end

        if do_qp_ramp_down2
curtime = calctime(curtime, max([qp_ramp_down_time2-dipole_holdtime_before_evap, qp_ramp_down_time2+shim_ramp_offset-dipole_holdtime_before_evap]));
        end

        ramp_pwrs = [1 0.14 0.08]; %bottom is 0.07


        for ii = 1:length(linramp_time)
            %ramp dipole 1 trap down
            AnalogFunc(calctime(curtime,0),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),linramp_time(ii),linramp_time(ii),ramp_pwrs(ii+1)*dipole1_exp_pwr,ramp_pwrs(ii)*dipole1_exp_pwr);
            %ramp dipole 2 trap down
curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),linramp_time(ii),linramp_time(ii),ramp_pwrs(ii+1)*dipole2_exp_pwr,ramp_pwrs(ii)*dipole2_exp_pwr);
        end

        dip_holdtime=25000 - sum(linramp_time);

    else
        dip_holdtime=25000;
    end

    %% Turn off Gradient after CDT Evap

    %RHYS - Unused, delete.
    if gradient_evap

        % FB coil settings for gradient evap
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final =  5.2539;%before 2017-1-6 0.25*22.6; %22.6
        addOutputParam('PSelect_FB',ramp.fesh_final)

        %qp_time_list = [1 1000 3000 6000 9000 12000];

        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 500;%150 %This controls what fraction of the ramp is actually performed.
        ramp.QP_ramp_delay = 100;
        ramp.QP_final =  0.0*1.78; %12 works well for XDT power of 1, 24 for XDT power of 2 (although this is a lot of current). 
        %These two parameters define the shape - the time constant, and
        %how long it takes to get to max amplitude.

        ramp.shim_ramptime = ramp.QP_ramptime; %150 %This controls what fraction of the ramp is actually performed.
        ramp.shim_ramp_delay = ramp.QP_ramp_delay;
        ramp.xshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(1) - seqdata.params. shim_zero(1)) + seqdata.params. shim_zero(1); %5.5 from side
        ramp.yshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(2) - seqdata.params. shim_zero(2)) + seqdata.params. shim_zero(2);
        ramp.zshim_final = ramp.QP_final / QP_value * (seqdata.params. plug_shims(3) - seqdata.params. shim_zero(3)) + seqdata.params. shim_zero(3);
        %These two parameters define the shape - the time constant, and
        %how long it takes to get to max amplitude. 

        ramp.settling_time = 150; %200

curtime = ramp_bias_fields(calctime(curtime,0), ramp); %

    end


    %% Ramp Dipole Back Up Before Spectroscopy
    %RHYS - Hmmm, sure. 
    if ramp_dipole_for_spect
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


    %% Get rid of Rb by doing repump and probe pulse
        %Only do this if evaporation has happened

    %RHYS - This is commonly used. 
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
    


    %% Repump atoms back into F=2 with repump light
    %RHYS - Why?
    if Rb_repump 

        setAnalogChannel(curtime,2,0.7,1);
curtime = DigitalPulse(curtime,5,50,1);
curtime = setAnalogChannel(curtime,2,0,1);

    end

    %% Do uWave transfer back to F=2
    %RHYS - Why? Delete.
    if do_end_uwave_transfer

        AnalogFunc(calctime(curtime,50),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),uWave_sweep_time,uWave_sweep_time, fesh_current,fesh_uWave_current);

curtime  = do_uwave_pulse(calctime(curtime,0), 0, uWave_pulse_freq*1E6, uWave_sweep_time,2);

        %blow away atoms in F=2
        %%open shutter
        %setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
        %%open analog
        %setAnalogChannel(calctime(curtime,-10),26,0.7);
        %%set TTL
        %setDigitalChannel(calctime(curtime,-10),24,1);
        %%set detuning
        %setAnalogChannel(calctime(curtime,-10),34,6590-237);
        %%pulse beam with TTL 
%curtime = DigitalPulse(calctime(curtime,0),24,15,0);

    end

    %%Turn on Shim Supply Relay
    %setDigitalChannel(calctime(curtime,-50),33,1);
%curtime=calctime(curtime,0);

    %setDigitalChannel(calctime(curtime,0),33,1);
    

    %% Get rid of F = 7/2 atoms using D1 Beam
    %RHYS - Why? Delete.
    if D1_repump_pulse

curtime = calctime(curtime,10);

        %Set Detuning
        setAnalogChannel(calctime(curtime,-10),48,205);
        
        %turn on D1 AOM 20s before it's being used in order for it to
        %warm up (shutter is closed 
        setAnalogChannel(calctime(curtime,-40000),47,0.7,1);

        %Pulse D1 beam with TTL
curtime = DigitalPulse(calctime(curtime,0),35,1,1);

        %Close D1 Shutter
        setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);

        %Turn F Pump TTLack On to Keep Warm
        setDigitalChannel(calctime(curtime,10),35,1);
    else
    end

    %% Do Sweep before uWave

    %RHYS - Should sweep K state from one side of manifold to the other. I
    %think we have other ways of doing this, so delete.
    if do_RF_sweep_before_uWave

        %Ramp FB Field
        clear('ramp');

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 41.9507;%before 2017-1-6 2*22.6; %22.6
        ramp.settling_time = 100;

curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        %Do RF Sweep
        clear('sweep');
        sweep_pars.freq = 6.9; %MHz
        sweep_pars.power = 4.9;
        sweep_pars.delta_freq = -2.00; % end_frequency - start_frequency
        sweep_pars.pulse_length = 40; % also is sweep length
         
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

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
    
    %RHYS - Not sure what this commented code is for either. It is probably not important.     
    %% RF spectroscopy test

    %if (do_RF_spectroscopy_test == 1)
%curtime = calctime(curtime,500);
        %rf_power=10;
        %rf_freq =31.3812;
        %delta_freq = 0.2;    
        %start_freq=rf_freq-delta_freq/2;
        %end_freq=rf_freq+delta_freq/2;
        %pulse_length = 0.2;
        
        %%do a pulse
        %pulse_start_time = curtime;
        %pulse_end_time = calctime(curtime,pulse_length);
        %%Set RF power
        %setAnalogChannel(caltime(curtime,-0.1),'RF Gain',rf_power,1);
        %%set RF freq
        %DDS_sweep(pulse_start_time,1,start_freq,end_freq,pulse_length);% DDS_id = 1: use the rf evap DDS
        %%turn on RF TTL
        %setDigitalChannel(pulse_start_time,'RF TTL',1); % 0: power off, 1: power on
        %%turn off RF TTL
        %setDigitalChannel(pulse_end_time,'RF TTL',0); % 0: power off, 1: power on
        %%set RF power to -10
        %setAnalogChannel(caltime(pulse_end_time,0.1),'RF Gain',rf_power,1);
        %%wait 1ms after turn off TTL
%curtime = calctime(pulse_end_time,1);    
    % end


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

        %RHYS - Remove all of the following.
        %sweep_pars.freq = 41.2989;
        
        %sweep_pars.delta_freq = -1*delta_freq;        
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 32.6815;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
         
        %sweep_pars.freq = 34.1583;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
        
        %sweep_pars.freq = 35.8558;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
        
        %sweep_pars.freq = 37.835;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
 
        %sweep_pars.freq = 40.1836;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 43.0334;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 46.5928;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 51.2166;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
    
%curtime=calctime(curtime,100);

        %if (check_effi == 1)
            %sweep_pars.freq = 51.2166;
        %else 
            %sweep_pars.freq = 51.2166;
        %end
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 46.5928;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 43.0334;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

        %sweep_pars.freq = 40.1836;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
      
        %sweep_pars.freq = 37.835;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
      
        %sweep_pars.freq = 35.8558;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
       
        %sweep_pars.freq = 34.1583;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
      
        %sweep_pars.freq = 32.6815;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;
      
        %sweep_pars.freq = 31.3812;
        %sweep_pars.delta_freq = -1*delta_freq;
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %total_pulse_length=total_pulse_length+sweep_pars.pulse_length;

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


    %% Ramp FB field up to 20G before loading lattice
    %RHYS - Useful for tuning interaction strength when loading lattice.
    if ramp_up_FB_for_lattice

        % Turn the FB up to 20G before loading the lattice, so that large field
        % ramps in the lattice can be done more quickly
        clear('ramp');

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 150;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;%before 2017-1-6 100*1.08962; %22.6
        ramp.settling_time = 100;

        addOutputParam('FB_Scale',ramp.fesh_final/22.6)



curtime = ramp_bias_fields(calctime(curtime,0), ramp);

    end
    %RHYS - Can be deleted.
    %% ramp up compensation beam
    %Comp_Ramptime = 50;
    %Comp_Power = 2;%unit is mW
    %if seqdata.flags.compensation_in_modulation == 1
        %%AOM direct control off
        %setDigitalChannel(calctime(curtime,-50),'Compensation Direct',0); %0: off, 1: on
        %%turn off compensation AOM initailly
        %setDigitalChannel(calctime(curtime,-20),'Plug TTL',1); %0: on, 1: off
        %set compensation AOM power to 0
        %setAnalogChannel(calctime(curtime,-10),'Compensation Power',-1);
        %%turn On compensation Shutter
        %setDigitalChannel(calctime(curtime,-5),'Compensation Shutter',0); %0: on, 1: off
        %%turn on compensation AOM
        %setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off       
        %%ramp up compensation beam
        %AnalogFuncTo(calctime(curtime,100),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, Comp_Power);
    %end  %compensation_in_modulation == 1

    %% ramp up Feshbach field for crossed dipole trap evaporative cooling
    %RHYS - Tried ramping up interactions near end of XDT evap. This needs to
    %be done carefully, as the FB coils can heat while large currents are being
    %driven through them, and also, there is a gradient formed that can easily
    %rip atoms out of a weak XDT.
    if (ramp_Feshbach_B_in_CDT_evap == 1)
        ramp_start_time=calctime(curtime,-6000);
        ramp_up_time = 500;
        ramp_down_time=500;
        % ramp up Feshbach field
        clear('ramp');

        ramp.fesh_ramptime = ramp_up_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 180;
        ramp.settling_time = 10;
        ramp_time = ramp_bias_fields(calctime(ramp_start_time,0), ramp);

        hold_time = 2000;
        ramp_time = calctime(ramp_time, hold_time);

        % ramp down Feshbach field
        clear('ramp');

        ramp.fesh_ramptime = ramp_down_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 10;
        ramp_time = ramp_bias_fields(calctime(ramp_time,0), ramp);

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
       
       
        power_list = [0.1];
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
        
        
        %RHYS - This kind of modulation stuff already exists elsewhere.
        A_mod = 0;
        f_mod_list = 0;0.65;[350:10:490]/1000; %Frequency is in kHz.
        f_mod = getScanParameter(f_mod_list,seqdata.scancycle,seqdata.randcyclelist,'dip_mod_freq');%

        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1-dip_sweep/2);
curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2-dip_sweep/2);
curtime = calctime(curtime,dip_waittime);

        %if (Dimple_in_XDT)
            %AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, 0); %0
%curtime = setDigitalChannel(calctime(curtime,50),'Dimple TTL',1);
        %end
%curtime = calctime(curtime,50);
        %setAnalogChannel(calctime(curtime,-10),'dipoleTrap1',-3);
        %setAnalogChannel(calctime(curtime,-10),'dipoleTrap2',-3);
%curtime = calctime(curtime,0.5);
        %setAnalogChannel(calctime(curtime,-10),'dipoleTrap1',dip_1);
        %setAnalogChannel(calctime(curtime,-10),'dipoleTrap2',dip_2);
%curtime = calctime(curtime,10);
        %%for measuring the lifetime in XDT
        %xdt_hold_time_list = [0];
        %xdt_hold_time = getScanParameter(xdt_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'XDT_hold');
%curtime = calctime(curtime,xdt_hold_time);

        %ScopeTriggerPulse(calctime(curtime,dip_rampstart),'ODT Hold');
         
%curtime = calctime(curtime,dip_rampstart+dip_ramptime);
        
        %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk_mod(t,tt,y1,y2,A_mod/2,f_mod)), dip_sweeptime,dip_sweeptime,dip_1+dip_sweep/2);
%curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk_mod(t,tt,y1,y2,A_mod/2,f_mod)), dip_sweeptime,dip_sweeptime,dip_2+dip_sweep/2);
%curtime = calctime(curtime,50);
        %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_sweeptime,dip_sweeptime,dip_1+dip_sweep/2);
        %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_sweeptime,dip_sweeptime,dip_2+dip_sweep/2);
         
%curtime = calctime(curtime,dip_waittime+dip_sweeptime);
        
        %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,0.5);
        %AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,0.5);      
    end

%% DMD in XDT 
    %RHYS - Is this desirable?
    if DMD_in_XDT
        DMD_power_val_list =[3]; %Do not exceed 3.5 here
        DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
        DMD_ramp_time = 100;
        DMD_on_time_list = [0 20 40 60 100 150 200 250 300 400 500];
        DMD_on_time = getScanParameter(DMD_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time');
        setAnalogChannel(calctime(curtime,-1),'DMD Power',0);
        setDigitalChannel(calctime(curtime,-200),'DMD TTL',0);%1 off 0 on
        setDigitalChannel(calctime(curtime,-100),'DMD TTL',1); %pulse time does not matter
        setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1); %1 on 0 off 
curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
curtime = calctime(curtime,DMD_on_time)
%curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, 0.3);
        %setAnalogChannel(calctime(curtime,0),'DMD Power',0);
curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, 0);
        setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0); %1 on 0 off
    end 
%% D1 Optical Pumping in ODT
% After optical evaporation, ensure mF spin polarization via D1 optical
% pumping. (mainly for testing optical pumping after spin mixture)
% FC+CF 2021/05/12

% @VV AND PX FEEL FREE TO DELETE THIS IF THIS IS CRAP CODE
if (seqdata.flags.do_D1OP_post_evap==1 && seqdata.flags.CDT_evap==1)
        dispLineStr('D1 Optical Pumping post op evap',curtime);  

        
    op_time_list = [1]; %1
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle, seqdata.randcyclelist, 'op_time'); %optical pumping pulse length
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle, seqdata.randcyclelist, 'op_repump_pwr'); %optical pumping repump power
    D1op_pwr_list = [5]; %min: 0, max:10 %5
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle, seqdata.randcyclelist, 'D1op_pwr'); %optical power

    
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
%% ramp up Feshbach field after crossed dipole trap evaporative cooling
    %RHYS - Another opportunity to ramp up the FB field before lattice loading.
    %This exists a bit higher up in the code too, so maybe only keep one.
    if (ramp_Feshbach_B_after_CDT_evap == 1)
        ramp_up_time = 50;
        ramp_down_time=50;
        % ramp up Feshbach field
        clear('ramp');

        ramp.fesh_ramptime = ramp_up_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 180;
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        hold_time = 2000;
curtime = calctime(curtime, hold_time);

        % ramp down Feshbach field
        clear('ramp');

        ramp.fesh_ramptime = ramp_down_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);

    end
    %% ramp up and ramp down lattice beams
    %RHYS - Potentially useful option. 
    if (load_lat_in_xdt_loading == 1)
        %set intital value and set digital channel value
        setAnalogChannel(calctime(curtime,-60),'xLattice',-10,1);
        setAnalogChannel(calctime(curtime,-60),'yLattice',-10,1);
        setAnalogChannel(calctime(curtime,-60),'zLattice',-10,1);

        % Enable rf output on ALPS3 (fast rf-switch and enable integrator)
        setDigitalChannel(calctime(curtime,-50),34,0);
        setDigitalChannel(calctime(curtime,-25),'Lattice Direct Control',0);
        setDigitalChannel(calctime(curtime,0),'ScopeTrigger',1);
        setDigitalChannel(calctime(curtime,1),'ScopeTrigger',0);
        %---------------------------------------------------------
        lat_ramp_time = 200;
        lat_ramp_tau = 50;
        X_Lattice_Depth = 1;
        Y_Lattice_Depth = 1;
        Z_Lattice_Depth = 1;
        atomscale = 0.4;    %0.4 : K40;  1: Rb
        lat_hold_time_list = [0,5,15,10,20,30]*1000;
        lat_hold_time = getScanParameter(lat_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_hold_time');
        %ramp up
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth/atomscale);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth/atomscale);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth/atomscale);
curtime = calctime(curtime,lat_hold_time);%holding

        lat_ramp_time = 200;
        lat_ramp_tau = 50;
        X_Lattice_Depth = 0;
        Y_Lattice_Depth = 0;
        Z_Lattice_Depth = 0;    
        %ramp down
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth/atomscale);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth/atomscale);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth/atomscale);
%curtime = calctime(curtime,10);%holding for 10 ms

        %---------------------------------------------------------
        %turn off TTLs
        setDigitalChannel(calctime(curtime,lat_ramp_time+0.1),34,1);
curtime = calctime(curtime,100);
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

    %% Kick the dipole trap (or punch, if so inclined).
    %RHYS - An alterative way to measure trap frequency using a piezo mirror to
    %give the atoms a kick. 
    if do_dipole_trap_kick
        dispLineStr('Kicking the dipole trap',curtime);
        %How Long to Wait After Kick
        kick_ramp_time = 100;
        curtime = calctime(curtime, kick_ramp_time+20);
        kick_voltage = 10;
        time_list = [10.6 11 11.4 11.8 12.2];[0:0.75:15];
        kick_wait_time =getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = 0;
        %addOutputparam('kick_wait_time',kick_wait_time);


       
        kick_channel=54;
    
        %Ramp the Piezo Mirror to a Displaced Position
        AnalogFuncTo(calctime(curtime,-kick_ramp_time),kick_channel,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),kick_ramp_time,kick_ramp_time,kick_voltage);

        %Jump the Piezo Mirror Back to Trap Geometry
        setAnalogChannel(curtime,kick_channel,0);

%         %Turn off the ODT1 to measure ODT2 trap frequency only
%         setAnalogChannel(curtime,'dipoleTrap1',-1); 

        %Piezo mirror is reset to 0 at the beginning of Load_MagTrap_Sequence
    end


    %% Pulse Raman beams in XDT.
    %RHYS - Probably deprecated. Was used to check alignment of Raman beams
    %through diffraction if beams are the same frequency (make a lattice).
    if Raman_in_XDT
curtime = calctime(curtime, 0.3);
        time_list = [0.25]; 
        Raman_On_Time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'Raman_Time');
        DigitalPulse(calctime(curtime,-5),'D1 Shutter',Raman_On_Time+10,1);
curtime = DigitalPulse(calctime(curtime,0),'F Pump TTL',Raman_On_Time,1);

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

    %% Keep XDT On for Some Time
    %RHYS - Either hold for some time after using dipole trap kick, or just
    %holds a bit in general. The one second hold time seems useful for loading
    %the lattice as it gives the rotating waveplate time to turn before the
    %lattice turns on.
    if do_dipole_trap_kick

        curtime = calctime(curtime,kick_wait_time);

    else
        %XDT on for 100ms before further physics
%curtime=calctime(curtime,100 + 0*10000); %100%35
%         exxdthold_list=1000;[1000];[1000];+500; %necessory for loading lattice => give some time for waveplate to rotate 
        
        exxdthold_list= [100];
        exxdthold = getScanParameter(exxdthold_list,seqdata.scancycle,seqdata.randcyclelist,'exxdthold');
        curtime=calctime(curtime,exxdthold);%for sparse image

    end
    
    %RHYS - High field imaging stuff. What to keep, what to delete?
    %Record the current of the Feshbach coil
    %seqdata.params. feshbach_val = fesh_current_val;

    %%% Ramp FB field up to 200G for High Field Imaging
    % 
    %%ADD XDT HOLD AGAIN!!!!
    %if seqdata.flags.High_Field_Imaging
        %clear('ramp');
     
        %%FB coil settings for spectroscopy
        %ramp.fesh_ramptime = 150;
        %ramp.fesh_ramp_delay = -0;
        %ramp.fesh_final = 205;%before 2017-1-6 100*1.08962; %22.6
        %ramp.settling_time = 50;    
     
%curtime = ramp_bias_fields(calctime(curtime,0), ramp);
   
        %ScopeTriggerPulse(curtime,'FB_ramp');
        %clear('ramp');
    
        %%FB coil settings for spectroscopy
        %ramp.fesh_ramptime = 15;
        %ramp.fesh_ramp_delay = -0;
        %ramp.fesh_final = 190;%before 2017-1-6 100*1.08962; %22.6
        %ramp.settling_time = 1;
     
%curtime = ramp_bias_fields(calctime(curtime,0), ramp);
     
        %%turn off dipole trap  
        %setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);
        %setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);
        %setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
         
%curtime = calctime (curtime,5);
   
        %clear('ramp');

        %%FB coil settings for spectroscopy
        %ramp.fesh_ramptime = 5;
        %ramp.fesh_ramp_delay = 10;
        %ramp.fesh_final = 205;%before 2017-1-6 100*1.08962; %22.6
        %ramp.settling_time = 1;

        %ramp_bias_fields(calctime(curtime,0), ramp);
    
    %end


    %%%Spin Flip For High Field Imaging
     
    %spin_flip_for_HF_imaging = 0;
     
    %if spin_flip_for_HF_imaging
        %clear('sweep');
        %rf_list = [6.3371]; 
        %sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
        %rf_power_list = [-9.0];
        %sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
        %delta_freq = 0.02;
        %sweep_pars.delta_freq = delta_freq;
        %rf_pulse_length_list = [5];
        %sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
         
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
       
        %clear('ramp');
        %ramp.FeshRampTime = 150;
        %ramp.FeshRampDelay = -0;
        %ramp.FeshValue = 205;%before 2017-1-6 100*1.08962; %22.6
        %ramp.SettlingTime = 50;     
%curtime = rampMagneticFields(calctime(curtime,0), ramp);
         
        %clear('sweep');
        %rf_list = 47.7062; [6.3371]; 
        %sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
        %rf_power_list = [0];
        %sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
        %delta_freq = 1;0.02;
        %sweep_pars.delta_freq = delta_freq;
        %rf_pulse_length_list = 20;[5];
        %sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
        %addOutputParam('RF_Pulse_Length',sweep_pars.freq);    
        
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        
    %clear('ramp');
    %ramp.FeshRampTime = 150;
    %ramp.FeshRampDelay = -0;
    %ramp.FeshValue = 20;%before 2017-1-6 100*1.08962; %22.6
    %ramp.SettlingTime = 50; 
%curtime = rampMagneticFields(calctime(curtime,0), ramp);

    %end
    

    %% Temperature Measurment for High Field Ramps

    %%flip the spin from -7 to -5   
    %clear('sweep');
    %rf_list = [6.3371]; 
    %sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
    %rf_power_list = [-9.0];
    %sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
    %delta_freq = 0.02;
    %sweep_pars.delta_freq = delta_freq;
    %rf_pulse_length_list = [5];
    %sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

    HF_ramp_temp_measurement = 0;
    %RHYS - More high field stuff. 
    if HF_ramp_temp_measurement
        time_in_HF_imaging = curtime;

        ScopeTriggerPulse(curtime,'FB_ramp');

        %FB ramp up
        clear('ramp');
        % FB coil settings for spectroscopy
        FeshRampTime_list = [150];
        ramp.FeshRampTime = getScanParameter(FeshRampTime_list,seqdata.scancycle,seqdata.randcyclelist,'HF_RampTime');
        rampup_time = ramp.FeshRampTime;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = 205;%before 2017-1-6 100*1.08962; %22.6
        ramp.SettlingTime = 50; 
curtime = rampMagneticFields(calctime(curtime,0), ramp);


        %FB ramp down
        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = rampup_time;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = 20.98111;%before 2017-1-6 100*1.08962; %22.6
        ramp.SettlingTime = 50;
curtime = rampMagneticFields(calctime(curtime,0), ramp);

        %flip the spin from -5 to -7   
        clear('sweep');
        rf_list = [6.3571]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
        rf_power_list = [-9.0];
        sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
        delta_freq = 0.02;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = [5];
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        %Do RF Sweep
        clear('sweep');

        sweep_pars.freq = 6.3075;6.255;% May 14 2018 6.275; %6.07 MHz
        sweep_pars.power = -9;0;   %-7.7
        sweep_pars.delta_freq = 0.02; % end_frequency - start_frequency   0.01
        sweep_pars.pulse_length = 5;%0.2 

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

        %Multiple sweeps to drive the mixture towards 50/50
curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);
curtime = calctime(curtime,2);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = calctime(curtime,2);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = calctime(curtime,2);
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
curtime = calctime(curtime,2);

curtime = calctime(curtime,50);
     
        time_out_HF_imaging = curtime;

        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
    end    

    %% RF Test Transfer at high field for field calibrations
    rf_test_at_HF = 0;
    if (rf_test_at_HF && seqdata.flags.High_Field_Imaging==0)
        time_in_HF_imaging = curtime;
        spin_flip_for_HF_imaging_FB = 1;


        clear('ramp');
        %FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List =[201.6:0.15:202.5];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
        ramp.FeshValue = HF_FeshValue_Initial;
        ramp.SettlingTime = 50;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);
        ScopeTriggerPulse(curtime,'FB_ramp');

        if spin_flip_for_HF_imaging_FB
            clear('sweep');
            B = 202.1; 
            rf_list = [0];
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')+(BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
            sweep_pars.power =  [0];
            delta_freq = 0.05;0.02;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 2;[5];
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
    curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        end

        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = 20.98111;
        ramp.SettlingTime = 50;   
curtime = rampMagneticFields(calctime(curtime,0), ramp);




        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
    end


    %% RF Transfer at high field

    rf_transfer_at_HF = 0;

    if (rf_transfer_at_HF && seqdata.flags.High_Field_Imaging==0)
        time_in_HF_imaging = curtime;
        spin_flip_for_HF_imaging_FB = 1;

        %Flip -7/2 to -5/2 before field ramp up.
        if spin_flip_for_HF_imaging_FB
            clear('sweep');
            rf_list = [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
            rf_power_list = [-9.0];
            sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
            delta_freq = 0.02;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = [5];
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        end


        clear('ramp');
        %FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List = [200.5];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
        ramp.FeshValue = HF_FeshValue_Initial;
        ramp.SettlingTime = 50;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);
        ScopeTriggerPulse(curtime,'FB_ramp');

        %Associate molecules 
        if spin_flip_for_HF_imaging_FB
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list = [.13 .14 .15 .16];
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq1')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            sweep_pars.power =  [10];
            delta_freq = -0.02;+0.02;0.02;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 5;[5];
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        end


curtime = calctime(curtime,150);



        %Flip Free -7/2 back to -5/2.
        if spin_flip_for_HF_imaging_FB
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list = [0.0];
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            sweep_pars.power =  [5];
            delta_freq = 0.1;0.02;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = 20;[5];
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        end


        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = 20.98111;
        ramp.SettlingTime = 50;   
curtime = rampMagneticFields(calctime(curtime,0), ramp);



        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
    end

    %% CDT Evaporation at High Field
    CDT_evap_at_HF = 0;

    if (CDT_evap_at_HF && ~ramp_XDT_after_evap)
        time_in_HF_imaging = curtime;

        spin_flip_for_HF_imaging_FB = 0;

        %Flip -7/2 to -5/2 before field ramp up.
        if spin_flip_for_HF_imaging_FB
            clear('sweep');
            rf_list = [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
            rf_power_list = [-9.0];
            sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
            delta_freq = 0.02;
            sweep_pars.delta_freq = delta_freq;
            rf_pulse_length_list = [5];
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        end   

        clear('ramp');
        %FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List = [195];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
        ramp.FeshValue = HF_FeshValue_Initial;
        ramp.SettlingTime = 50;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);
        ScopeTriggerPulse(curtime,'FB_ramp');


%curtime = calctime(curtime,500);

        HF_evap_time_list = [1000];
        HF_evap_time = getScanParameter(HF_evap_time_list,seqdata.scancycle,seqdata.randcyclelist,'HF_evap_time');

        exp_tau_HF = HF_evap_time/4;
        HF_evap_end_power_list = [0.14];

        HF_evap_end_power = getScanParameter(HF_evap_end_power_list,seqdata.scancycle,seqdata.randcyclelist,'HF_evap_end_power');

        %exponential evaporation ramps (ramping down XDT beams)
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),HF_evap_time,HF_evap_time,exp_tau_HF,HF_evap_end_power);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),HF_evap_time,HF_evap_time,exp_tau_HF,seqdata.params.XDT_area_ratio*HF_evap_end_power);

        ramp_after_evap_in_HF = 1;

        if ramp_after_evap_in_HF
            dip_ramptime = 500;
            dip1_final_HF = 0.2;
            dip_rampstart = 0;
            AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip1_final_HF);
curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,seqdata.params.XDT_area_ratio*dip1_final_HF);
        end


        clear('ramp');
        %FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List = [20];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final');
        ramp.FeshValue = HF_FeshValue_Initial;
        SettlingTime_list = [50];
        ramp.SettlingTime = getScanParameter(SettlingTime_list,seqdata.scancycle,seqdata.randcyclelist,'HF_rampdown_settle_time');;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);



        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end

    end

    %% Ramp FB field up to 200G for High Field Imaging after ODT
    if (seqdata.flags.High_Field_Imaging && ~seqdata.flags.load_lattice )
        dispLineStr('Ramping High Field in XDT',curtime);
        time_in_HF_imaging = curtime;
        
        spin_flip_9_7 = 0;
        spin_flip_7_5 = 0;        
        
        rabi_7_5=0;       
        rabi_manual=0;
        
        shift_reg_at_HF = 0;
        


        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List = 200;[202.78];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
        ramp.FeshValue = HF_FeshValue_Initial;
        ramp.SettlingTime = 50;    
curtime = rampMagneticFields(calctime(curtime,0), ramp);
        ScopeTriggerPulse(curtime,'FB_ramp');        
        seqdata.params.HF_fb = HF_FeshValue_Initial;
        
        % Extra initial hold time
        HF_wait_time_list = [0];
        HF_wait_time = getScanParameter(HF_wait_time_list,seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time');
curtime = calctime(curtime,HF_wait_time);        
 
        %Do rf transfer from -9/2 to -7/2
        if spin_flip_9_7
            disp(' RF Transfer -9/2 --> -7/2');
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list =  [0] +...
                (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf97_freq_HF');
            sweep_pars.power_list =  [0];
            sweep_pars.power = getScanParameter( sweep_pars.power_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf97_power_HF');
            delta_freq_list =[0.5]; 0.025;0.1;
            sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf97_deltaFreq_HF');
            rf_pulse_length_list = 200;5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf97_time_HF');  % also is sweep length  0.5               

            disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
            disp([' Delta Frequency  (MHz) : ' num2str(sweep_pars.delta_freq)]);
            disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);       
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

curtime=calctime(curtime,10);
        end
        
        
                
        %Do rf transfer from -7/2 to -5/2
        if spin_flip_7_5
            disp(' RF Transfer -7/2 --> -5/2');
            clear('sweep');
            B = HF_FeshValue_Initial; 
            rf_list = [0.01] +...
                (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            %rf_list = 48.3758; %@209G  [6.3371]; 
            sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf57_freq_HF');
            sweep_pars.power_list =  [0];
            sweep_pars.power = getScanParameter( sweep_pars.power_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf75_power_HF');
            delta_freq_list = [1];0.025;0.1;
            sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf75_deltaFreq_HF');
            rf_pulse_length_list = [.2 .5 2 .8];5;20;
            sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf75_time_HF');  % also is sweep length  0.5               

            
            disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
            disp([' Delta Frequency  (MHz) : ' num2str(sweep_pars.delta_freq)]);
            disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);

curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        end   
        
        if rabi_7_5
            disp(' Rabi Oscillations');
            clear('rabi');
            rabi=struct;
            B = HF_FeshValue_Initial; 
            rf_list = [0.0151] +...
                (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf75_rabi_freq_HF');
            power_list =  [0];
            rabi.power = getScanParameter(power_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf75_rabi_power_HF');            
%             rf_pulse_length_list = [0.5]/15;
            rf_pulse_length_list = [0:.01:.15];      
            rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf75_rabi_time_HF');  % also is sweep length  0.5               
            
            disp(rabi);

curtime = rf_uwave_spectroscopy(calctime(curtime,0),4,rabi);%3: sweeps, 4: pulse
curtime=calctime(curtime,10);
        end
        
        if rabi_manual
            mF1=-7/2;
            mF2=-5/2;    
            
            disp(' Rabi Oscillations Manual');
            clear('rabi');
            rabi=struct;          
            
            B = HF_FeshValue_Initial; 
            rf_list = [0.0151] +...
                (BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6;
            rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_rabi_freq_HF');
            power_list =  [0];
            rabi.power = getScanParameter(power_list,...
                seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF');            
%             rf_pulse_length_list = [0.5]/15;
            rf_pulse_length_list = [0:0.01:.15];      
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

%         clear('ramp');
%         % FB coil settings for spectroscopy
%         ramp.FeshRampTime = 7;
%         ramp.FeshRampDelay = -0;
%         FeshValue_Drop_List = 201.67; [199:0.5:204];
%         FeshValue_Drop = getScanParameter(FeshValue_Drop_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final');
%         ramp.FeshValue = FeshValue_Drop;
%         ramp.SettlingTime = 0;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);

        %turn off dipole trap  
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0,1);
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
        setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);


        %%Dissociate molecules to form -9/2 and -5/2
        %if spin_flip_for_HF_imaging_FB
            %clear('sweep');
            %B = FeshValue_Drop; 
            %rf_list = 100;[0:0.05:0.40];
            %%rf_list = 48.3758; %@209G  [6.3371]; 
            %sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq1')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
            %sweep_pars.power =  [10];
            %delta_freq = 0.05;+0.02;0.02;
            %sweep_pars.delta_freq = delta_freq;
            %rf_pulse_length_list = 1;[5];
            %sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %end
      
%curtime = calctime(curtime,4);

        %%Shift Register to bring -5/2 to -9/2
        %if spin_flip_for_HF_imaging_FB
            %clear('sweep');
            %B = FeshValue_Drop; 
            %rf_list = [0.05];
            %rf_list = 48.3758; %@209G  [6.3371]; 
            %sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq2')+ 45.73;
            %sweep_pars.power =  [10];
            %delta_freq_list = [-3.0];0.02;
            %sweep_pars.delta_freq = getScanParameter(delta_freq_list,seqdata.scancycle,seqdata.randcyclelist,'register_sweep_width');;
            %rf_pulse_length_list = 5;[5];
            %sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
%curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        %end    


        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end

    end
 
    
%% Ramp HF and back
ramp_HF_and_back = 0;
if ramp_HF_and_back

        clear('ramp');
        % FB coil settings for spectroscopy
        ramp.FeshRampTime = 150;
        ramp.FeshRampDelay = -0;
        HF_FeshValue_Initial_List =[195];[202.78];
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
        HF_FeshValue_final_list = [10];
        seqdata.HF_FeshValue_final = getScanParameter(HF_FeshValue_final_list,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_final');
        ramp.FeshValue = seqdata.HF_FeshValue_final;%before 2017-1-6 100*1.08962; %22.6
        ramp.SettlingTime = 50;
        curtime = rampMagneticFields(calctime(curtime,0), ramp);

end


%% END OF HIGH-FIELD IMAGING SECTION
%RHYS - Here ends the high-field imaging section. Everything before this
%could be moved out into functions, and perhaps much could be deleted. 

%RHYS - What follows is more high-field stuff, presumably old code that we
%don't want anymore...

%ADD XDT HOLD AGAIN!!!!

% if (seqdata.flags.High_Field_Imaging)
% time_in_HF_imaging = curtime;
%     spin_flip_for_HF_imaging_FB = 1;
% 
%     %Flip -7/2 to -5/2 before field ramp up.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         rf_list = [6.3371]; 
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
%         rf_power_list = [-9.0];
%         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%         delta_freq = 0.02;
%         sweep_pars.delta_freq = delta_freq;
%         rf_pulse_length_list = [5];
%         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
%     
%     
%     clear('ramp');
%     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 150;
%     ramp.FeshRampDelay = -0;
%     HF_FeshValue_Initial_List = [202.78];
%     HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
%     ramp.FeshValue = HF_FeshValue_Initial;
%     ramp.SettlingTime = 50;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% ScopeTriggerPulse(curtime,'FB_ramp');
% 
% 
%     %Flip -5/2 back to -7/2.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         B = HF_FeshValue_Initial; 
%         rf_list = [0];
%         %rf_list = 48.3758; %@209G  [6.3371]; 
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
%         sweep_pars.power =  [5];
%         delta_freq = -1;0.02;
%         sweep_pars.delta_freq = delta_freq;
%         rf_pulse_length_list = 20;[5];
%         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
%  
% 
% 
%     %Ramp field slowly from 202.78 to 201.67
%     clear('ramp');
%     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 7;
%     ramp.FeshRampDelay = -0;
%     FeshValue_Drop_List = 200.5;[199:0.5:204];
%     FeshValue_Drop = getScanParameter(FeshValue_Drop_List,seqdata.scancycle,seqdata.randcyclelist,'B_Drop');
%     ramp.FeshValue = FeshValue_Drop;
%     ramp.SettlingTime = 0;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% 
% %   turn off dipole trap  
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0,1);
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
%     setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
% 
%   %wait for some time
% curtime = calctime(curtime,1);   
% 
%     %Ramp field from 201.67 to 195
%     clear('ramp');
%     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 3;
%     ramp.FeshRampDelay = -0;
%     FeshValue_TOF = 195;
%     ramp.FeshValue = FeshValue_TOF;
%     ramp.SettlingTime = 2;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% %     
%     %Flip free -7/2 to -5/2.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         B = FeshValue_TOF; 
%         rf_list = [0];
%         %rf_list = 48.3758; %@209G  [6.3371]; 
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq_5')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
%         sweep_pars.power = [10];
%         delta_freq = 0.5;0.02;
%         sweep_pars.delta_freq = delta_freq;
%         sweep_pars.pulse_length = 2;[5];
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
%     
%    % Flip free -9/2 to -7/2.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         B = FeshValue_TOF; 
%         rf_list = [0];
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq_7')+(BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
%         sweep_pars.power = [10];
%         delta_freq = 0.5;0.02;
%         sweep_pars.delta_freq = delta_freq;
%         sweep_pars.pulse_length = 2;[5];
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
% 
% % curtime = calctime(curtime,3);
% % curtime = calctime(curtime,3);
% % curtime = calctime(curtime,6);
%     
% %     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 8;
%     ramp.FeshRampDelay = 0;
%     HF_FeshValue_final_list = [203];
%     seqdata.HF_FeshValue_final = getScanParameter(HF_FeshValue_final_list,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final');
%     ramp.FeshValue = seqdata.HF_FeshValue_final;%before 2017-1-6 100*1.08962; %22.6
%     ramp.SettlingTime = 0;
%     
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
%     
%     time_out_HF_imaging = curtime;
%     if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
%         error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
%     end
% end
% 
% 








%     spin_flip_for_HF_imaging_FB = 1;
% 
%     %Flip -7/2 to -5/2 before field ramp up.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         rf_list = [6.3371]; 
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
%         rf_power_list = [-9.0];
%         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%         delta_freq = 0.02;
%         sweep_pars.delta_freq = delta_freq;
%         rf_pulse_length_list = [5];
%         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5           
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
%     
%     clear('ramp');
%     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 150;
%     ramp.FeshRampDelay = -0;
%     HF_FeshValue_Initial_List = [190];
%     HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
%     ramp.FeshValue = HF_FeshValue_Initial;
%     ramp.SettlingTime = 50;    
%     
%     % Z shim settings for spectroscopy
%     ramp.ShimRampTime = 150;
%     ramp.ShimRampDelay = -0;
%     ramp.zShimValue = seqdata.params. shim_zero(3)+ 1.7013; %1.7013 = 4G
% 
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% %THIS IS THE SUPERIOR FUNCTION BUT NEEDS SOME UPDATES. SHOULD REPLACE RAMP
% %BIAS FIELDS EVERYWHERE SINCE RAMP BIAS FIELDS TIMING HAS MISTAKES.
% 
% % 
% ScopeTriggerPulse(curtime,'FB_ramp');
%     %Flip -5/2 back to -7/2.
%     if spin_flip_for_HF_imaging_FB
%         clear('sweep');
%         B = HF_FeshValue_Initial + 4; 
%         rf_list = (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
%         %rf_list = 48.3758; %@209G  [6.3371]; 
%         sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq');
%         rf_power_list = [0];
%         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%         delta_freq = 1;0.02;
%         sweep_pars.delta_freq = delta_freq;
%         rf_pulse_length_list = 20;[5];
%         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
%     end
% 
% 
%     clear('ramp');    
%     % FB coil settings for spectroscopy
%     FeshRampTime_list = [0.5];
%     ramp.FeshRampTime = getScanParameter(FeshRampTime_list,seqdata.scancycle,seqdata.randcyclelist,'Mol_FeshRampTime');
%     ramp.FeshRampDelay = -0;
%     FeshValue_list = [180];
%     ramp.FeshValue = getScanParameter(FeshValue_list,seqdata.scancycle,seqdata.randcyclelist,'Mol_SnapVal');%199.5-0.2034;   201-0.2034;%before 2017-1-6 100*1.08962; %22.6
%     SettlingTime_list = [0, 40,100];
%     ramp.SettlingTime = getScanParameter(SettlingTime_list,seqdata.scancycle,seqdata.randcyclelist,'Mol_Settle_time');
%     
%     ramp.ShimRampTime = ramp.FeshRampTime;
%     ramp.ShimRampDelay = -0;
%     ramp.zShimValue = 0;
%     
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% 
% % %   turn off dipole trap  
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0,1);
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0,1);
%     setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
%     
% 
% %  clear('ramp');    
% %     % FB coil settings for spectroscopy
% %     FeshRampTime_list = [5];
% %     ramp.FeshRampTime = getScanParameter(FeshRampTime_list,seqdata.scancycle,seqdata.randcyclelist,'Mol_FeshRampTime');
% %     ramp.FeshRampDelay = -0;
% %     ramp.FeshValue = 180;201-0.2034;%before 2017-1-6 100*1.08962; %22.6
% %     SettlingTime_list = [0];
% %     ramp.SettlingTime = getScanParameter(SettlingTime_list,seqdata.scancycle,seqdata.randcyclelist,'Mol_Settle_time');
% %     
% % curtime = rampMagneticFields(calctime(curtime,0), ramp);
% curtime = calctime(curtime,10);
% 
% % clear('sweep');
% %         B = ramp.FeshValue; 
% %         rf_offset_list = [0.6];%0.02(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
% %         %rf_list = 48.3758; %@209G  [6.3371]; 
% %         sweep_pars.freq = getScanParameter(rf_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rf_offset_freq')+(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
% %         rf_power_list = [-3];
% %         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
% %         delta_freq = 0.1;0.1;
% %         sweep_pars.delta_freq = delta_freq;
% %         rf_pulse_length_list = 3;[5];
% %         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
% % curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
% % 
% % 
% % 
% % clear('sweep');
% %         B = ramp.FeshValue; 
% %         rf_offset_list = [0.265];%0.02(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
% %         %rf_list = 48.3758; %@209G  [6.3371]; 
% %         sweep_pars.freq = getScanParameter(rf_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rf_offset_freq')+(BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
% %         rf_power_list = [-3];
% %         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
% %         delta_freq = 0.1;0.1;
% %         sweep_pars.delta_freq = delta_freq;
% %         rf_pulse_length_list = 3;[5];
% %         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
% % curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
% 
% 
% 
% 
% %Why were there delay times added in rf_uwave_spectroscopy again? Can these
% % be eliminated?
% 
% %  clear('sweep');
% %         B = ramp.FeshValue; 
% %         rf_offset_list = [0.125];%0.025(BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
% %         %rf_list = 48.3758; %@209G  [6.3371]; 
% %         sweep_pars.freq = getScanParameter(rf_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rf_offset_freq')+ (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
% %         rf_power_list = [-3];
% %         sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
% %         delta_freq = 0.1;0.02;
% %         sweep_pars.delta_freq = delta_freq;
% %         rf_pulse_length_list = 3;[5];
% %         sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
% % curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
% 
%     clear('ramp');
% % 
% %     % FB coil settings for spectroscopy
%     ramp.FeshRampTime = 5;
%     ramp.FeshRampDelay = 0;
%     HF_FeshValue_final_list = [205];
%     seqdata.HF_FeshValue_final = getScanParameter(HF_FeshValue_final_list,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_final');
%     ramp.FeshValue = seqdata.HF_FeshValue_final;%before 2017-1-6 100*1.08962; %22.6
%     ramp.SettlingTime = 0;
%     
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
% 
% time_out_HF_imaging = curtime;
%     if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
%         error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
%     end
% 
% end





% %% Ramp XDT Up for Lattice Alignment
% 
%     %Ramp dipole on before pulsing the lattice beam. This should allow for
%     %better alignment of lattice to the potassium cloud, avoiding issue of
%     %gravitational sag for Rb. The XDT is then snapped off after the
%     %lattice pulse. 
%     
%     if (ramp_XDT_after_evap && seqdata.flags. CDT_evap == 1)
%         
%         power_list = [0.2];%0.2 sep28
%         power_val = getScanParameter(power_list,seqdata.scancycle,seqdata.randcyclelist,'power_val');
%         
%         dip_1 = power_val; %1.5
%         dip_2 =  (sqrt(81966+1136.6*(21.6611-(-119.75576*dip_1^2+159.16306*dip_1+13.0019)))-286.29766)/2/(-284.1555);%(((sqrt(dip_1)*83.07717-0.8481)+3.54799)/159.3128)^2;%(((sqrt(dip_1)*79.53844+2.75255)+2.38621)/140.61417)^2;%power_val; %1.5
% %         (((sqrt(dip_1)*83.07717-0.8481)+3.54799)/159.3128)^2;%sep28
% %         dip_1 = 0.15;
% %         dip_2 = 0.062;
%         dip_sweep = 0.00;
%         dip_ramptime = 500; %500%sep28
%         dip_sweeptime = 2000;
%         dip_rampstart = 0;
%         dip_waittime = 10;
%         
%         A_mod = 0;
%         f_mod_list = 0;0.65;[350:10:490]/1000; %Frequency is in kHz.
%         f_mod = getScanParameter(f_mod_list,seqdata.scancycle,seqdata.randcyclelist,'dip_mod_freq');%
%         
%         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1-dip_sweep/2);
% curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2-dip_sweep/2);
% 
% %         if (Dimple_in_XDT)
% %             AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, 0); %0
% % curtime = setDigitalChannel(calctime(curtime,50),'Dimple TTL',1);
% %         end
% % curtime = calctime(curtime,50);
% %         setAnalogChannel(calctime(curtime,-10),'dipoleTrap1',-3);
% %         setAnalogChannel(calctime(curtime,-10),'dipoleTrap2',-3);
% % curtime = calctime(curtime,0.5);
% %         setAnalogChannel(calctime(curtime,-10),'dipoleTrap1',dip_1);
% %         setAnalogChannel(calctime(curtime,-10),'dipoleTrap2',dip_2);
% % curtime = calctime(curtime,10);
% %         %for measuring the lifetime in XDT
% %         xdt_hold_time_list = [0];
% %         xdt_hold_time = getScanParameter(xdt_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'XDT_hold');
% %         curtime = calctime(curtime,xdt_hold_time);
%         
% %         ScopeTriggerPulse(calctime(curtime,dip_rampstart),'ODT Hold');
% %         
% %         curtime = calctime(curtime,dip_rampstart+dip_ramptime);
% %         
% %         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk_mod(t,tt,y1,y2,A_mod/2,f_mod)), dip_sweeptime,dip_sweeptime,dip_1+dip_sweep/2);
% % curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk_mod(t,tt,y1,y2,A_mod/2,f_mod)), dip_sweeptime,dip_sweeptime,dip_2+dip_sweep/2);
% % curtime = calctime(curtime,50);
% %         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_sweeptime,dip_sweeptime,dip_1+dip_sweep/2);
% %         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_sweeptime,dip_sweeptime,dip_2+dip_sweep/2);
% %         
% %         curtime = calctime(curtime,dip_waittime+dip_sweeptime);
% %         
% %         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,0.5);
% %         AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,0.5);
% %         
%     end

    %RHYS - End of dipole transfer code. Keep this.
    timeout = curtime;
   dispLineStr('Dipole Transfer complete',curtime);

end