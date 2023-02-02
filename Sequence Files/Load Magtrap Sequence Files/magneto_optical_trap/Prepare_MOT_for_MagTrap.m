function timeout = Prepare_MOT_for_MagTrap(timein)

global seqdata;

curtime = timein;

%% Turn off UV

setDigitalChannel(calctime(curtime,-500),'UV LED',0);

%% cMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
if seqdata.flags.MOT_CMOT==1
    dispLineStr('CMOT',curtime);



    k_cMOT_times=[20];
    k_cMOT_time= getScanParameter(k_cMOT_times,...
        seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_time');  
    rb_cMOT_time=k_cMOT_time;

    
    cMOT_time = max([rb_cMOT_time k_cMOT_time]);


    yshim_comp = 0.84;
    xshim_comp = 0.25;
    zshim_comp = 0.00;

    %%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
    % setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',0.84,2); 
    % setAnalogChannel(calctime(curtime,-2),'X MOT Shim',0.25,2); 
    % setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',0.00,2);

    %%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%

    % New way to set the detuning
    Rb_CMOT_Trap_detuning_list = -30;-36.5;
    Rb_CMOT_Trap_detuning = getScanParameter(Rb_CMOT_Trap_detuning_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Rb_CMOT_Trap_detuning','MHz');  %in MHZ

    f_osc = calcOffsetLockFreq(Rb_CMOT_Trap_detuning,'MOT');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01);    

    setAnalogChannel(calctime(curtime,0),'Rb Repump AM',getVar('cmot_rb_repump_power'));  
    setAnalogChannel(calctime(curtime,0),'Rb Trap AM',getVar('cmot_rb_trap_power'));

    %%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
    % AnalogFuncTo(calctime(curtime,0),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_detuning);
       % AnalogFuncTo(calctime(curtime,0),'K Repump FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_repump_detuning,2);


    setAnalogChannel(calctime(curtime,0),'K Trap FM',getVar('cmot_k_trap_detuning')); 
    setAnalogChannel(calctime(curtime,0),'K Repump FM',getVar('cmot_k_repump_detuning'),2); 

    K_trap_am_list = [0.5];0.7;
    k_cMOT_trap_am = getScanParameter(K_trap_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_trap_am');  %in MHZ
    setAnalogChannel(calctime(curtime,0),'K Repump AM',0.25); %0.25
    setAnalogChannel(calctime(curtime,0),'K Trap AM',k_cMOT_trap_am); %0.7 %0.3 Oct 30, 2015 

    %%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
    % CMOTBGrad=10;
    % setAnalogChannel(calctime(curtime,0),'MOT Coil',CMOTBGrad);

    %%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
    curtime=calctime(curtime,cMOT_time);   
end
%% Combined Molasses - K D1 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time from the CMOT phase

if seqdata.flags.MOT_KGM_RbMol == 1
    dispLineStr('Molasses',curtime);

    %%%%%%%%%%%% Shift the fields %%%%%%%%%%%%
    % Set field gradient and shim values (ideally) to zero

    % Turn off field gradients
    setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);   

    % Set the shims
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.15,2); %0.15
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.15,2); %0.15
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.00,2); %0.00

    %%%%%%%%%%%% Turn off K D2  %%%%%%%%%%%%
    % Turn off the K D2 light
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);   % (1: OFF)
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); % (1: OFF)

    %%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%

    % Rb Mol detuning setting
    rb_molasses_detuning_list = [90];90;
    rb_molasses_detuning = getScanParameter(rb_molasses_detuning_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Rb_molasses_det','MHz');  

    % Rb Mol trap power setting
    rb_mol_trap_power_list = 0.15;
    rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
    
    % Rb Mol repump power settings
    rb_mol_repump_power_list = 0.08;
    rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');

    % Set the power and detunings
    setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);

    MOL_trap_detuning = -81;
    f_osc = calcOffsetLockFreq(MOL_trap_detuning,'MOT');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01);    


    setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
    setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 

    %%%%%%%%%%%% K D1 GM Settings %%%%%%%%%%%%
    % K D1 GM two photon detuning
    SRS_det_list = [0];%0
    SRS_det = getScanParameter(SRS_det_list,seqdata.scancycle,seqdata.randcyclelist,'GM_SRS_det');

    % K D1 GM two photon sideband power
    SRSpower_list = [4];   %%8
    SRSpower = getScanParameter(SRSpower_list,seqdata.scancycle,seqdata.randcyclelist,'SRSpower');

    % Set the two-photon detuning (SRS)
    SRSAddress = 27; rf_on = 1; SRSfreq = 1285.8+SRS_det;%1285.8
    addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));

    % K D1 GM double pass (single photon detuning) - shift from 70 MHz
    D1_freq_list = [0];
    D1_freq = getScanParameter(D1_freq_list,seqdata.scancycle,seqdata.randcyclelist,'D1_freq');

    % K D1 GM Double pass - modulation depth
    mod_amp_list = [1.3];
    mod_amp = getScanParameter(mod_amp_list,seqdata.scancycle,seqdata.randcyclelist,'GM_power');

    % Set the single photon detuning (Rigol)
    mod_freq = (70+D1_freq)*1E6;
    mod_offset =0;
    str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
    addVISACommand(3, str);

    % Open the D1 shutter (3 ms pre-trigger for delay)
    setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter',1);

    %%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
    % Total Molasses Time
    molasses_time_list = [8];
    molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time'); 

    %%%%%%%%%%%% advance time during molasses  %%%%%%%%%%%%
    curtime = calctime(curtime,molasses_time);

    % Close the D1 Shutter (3 ms pre-trigger for delay); 
    setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter 2',0); % we have a double shutter on this beam
    setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);     % close this shutter too
end


%% Optical Pumping
% Perform D2 optical pumping.  Could consider implemementing D1 optical
% pumping for K which as a true dark state

if seqdata.flags.MOT_optical_pumping == 1
    %digital trigger
    ScopeTriggerPulse(curtime,'Optical pumping');

    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);    
    setDigitalChannel(calctime(curtime,-1.8),'Rb Trap Shutter',0); 
    setDigitalChannel(calctime(curtime,-1.8),'K Trap Shutter',0);     
    curtime = optical_pumping(calctime(curtime,0.0));      
end
%% Floursence image

if seqdata.flags.MOT_flour_image

    %%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%

    % Turn off the field gradient
    setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);    

    % Turn off the D2 beams, if they arent off already
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

    % Turn off the D1 beams. The GM stage automattically does this

    %%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%

    % Set the time of flight
    tof_list =2; [5 10 15 20 25 30 35 40];
    tof =getScanParameter(tof_list,seqdata.scancycle,seqdata.randcyclelist,'tof_time'); 

    % Increment the time (ie. perform the time of flight
    curtime = calctime(curtime,tof);

    %%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
    %turn back on D2 for imaging (or make it on resonance)  

    % Set potassium detunings to resonances (0.5 ms prior to allow for switching)
    setAnalogChannel(calctime(curtime,0),'K Trap FM',0);
    setAnalogChannel(calctime(curtime,0),'K Repump FM',0,2);

    % Set potassium power to standard value
    setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
    setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

    % Set Rubidium detunings to resonance (0.5 ms prior to allow for switching)
    setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

    % Set rubdium power to standard value
    setAnalogChannel(calctime(curtime,-1),'Rb Trap AM', 0.7);            
    setAnalogChannel(calctime(curtime,-1),'Rb Repump AM',0.9);          

    % Turn the beams on
    if seqdata.flags.image_atomtype == 1
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);  
    else
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);  
    end

    % Camera Trigger (1) : Light+Atoms
    setDigitalChannel(calctime(curtime,0),15,1);
    setDigitalChannel(calctime(curtime,10),15,0);

    % Wait for second image trigger
    curtime = calctime(curtime,3000);

    % Camera Trigger (2) : Light only
    setDigitalChannel(calctime(curtime,0),15,1);
    setDigitalChannel(calctime(curtime,10),15,0);

end
%% Reset GM Shutters
% CF : Should this be done inside the GM code?

% switich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

%% Turn off the repump

% CF : No idea what this does
if ( seqdata.flags.image_type ~= 4 )
%RHYS - These turn on/turn off/turn on-off beam functions are confusing and
%could be rewritten.
curtime = turn_off_beam(calctime(curtime,1),2); %a little delayed w.r.t trap
end

%% The end

timeout = curtime;

end