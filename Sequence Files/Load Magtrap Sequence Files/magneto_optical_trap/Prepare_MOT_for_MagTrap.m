%------
%Author: David + Dylan
%Created: March 2011
%Summary: Prepares the cloud for loading into the magnetic trap
%------

%----Input Vars
%blue_mot: flag to turn on blue mot
%----------
%RHYS - Tons of parameters in these codes. Allow these to be loaded in
%through a text file, with everything else. 
function timeout = Prepare_MOT_for_MagTrap(timein)

global seqdata;

curtime = timein;

%% Turn off UV

setDigitalChannel(calctime(curtime,-500),'UV LED',0);


%% cMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
doCMOTv3 =1;        
if doCMOTv3

            
% Time duration
rb_cMOT_time = 25;              % Ramp time of Rb CMOT
k_cMOT_time = 25;               % Ramp time of K CMOT

% Rubidum
rb_cMOT_detuning = 42;          % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;  % Rubidum CMOT repump power in V

% rb_cMOT_detunings=0:5:50;
% rb_cMOT_detuning=getScanParameter(rb_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_detuning');

% rb_cmot_repump_powers=0:.1:.9;
% rb_cmot_repump_power= getScanParameter(rb_cmot_repump_powers,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_repump_am');  %in MHZ
%  


% Potassium
k_cMOT_detuning = 5; 5;         % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz


k_cMOT_detunings=[5];
k_cMOT_detuning= getScanParameter(k_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_detuning');  %in MHZ

k_cMOT_times=[20];
k_cMOT_time= getScanParameter(k_cMOT_times,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_time');  
rb_cMOT_time=k_cMOT_time;

cMOT_time = max([rb_cMOT_time k_cMOT_time]); [50];% Total CMOT time

% Append output parameters if desired   
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
addOutputParam('rb_cMOT_detuning',rb_cMOT_detuning);
addOutputParam('rb_cmot_repump_power',rb_cmot_repump_power); 

yshim_comp = 0.84;
xshim_comp = 0.25;
zshim_comp = 0.00;

%%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
% setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',0.84,2); 
% setAnalogChannel(calctime(curtime,-2),'X MOT Shim',0.25,2); 
% setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',0.00,2);

%%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_cMOT_detuning); 

% New way to set the detuning
Rb_CMOT_Trap_detuning_list = -30;-36.5;
Rb_CMOT_Trap_detuning = getScanParameter(Rb_CMOT_Trap_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_CMOT_Trap_detuning','MHz');  %in MHZ

f_osc = calcOffsetLockFreq(Rb_CMOT_Trap_detuning,'MOT');
DDS_id = 3;    
DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01)    


% AnalogFuncTo(calctime(curtime,0),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rb_cMOT_time,rb_cMOT_time,6590+rb_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',rb_cmot_repump_power);
setAnalogChannel(calctime(curtime,0),'Rb Trap AM',0.1);

%%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'K Trap FM',k_cMOT_detuning); %765
% AnalogFuncTo(calctime(curtime,0),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'K Repump FM',k_cMOT_repump_detuning,2); %765
% AnalogFuncTo(calctime(curtime,0),'K Repump FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_repump_detuning,2);

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
doMol = 1;
if doMol

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
rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
% Rb Mol repump power settings
rb_mol_repump_power_list = 0.08;[0.01:0.01:0.15];
rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');
   
% Set the power and detunings
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);

MOL_trap_detuning = -81;
f_osc = calcOffsetLockFreq(MOL_trap_detuning,'MOT');
DDS_id = 3;    
DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01)    


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


%% Compression
%RHYS - Should be a seqdata flag.


% do_compression = 0;
% 
% if do_compression %&& (~(seqdata.flags.image_type==4))
%     D1_cMOT = 0;
%     %RHYS - D1 molasses/cMOT not used right now, unless Vijin revives it.
%     if D1_cMOT
%         
%         ScopeTriggerPulse(calctime(curtime,0),'cMOT',1);
%         %Set cMOT time
%         rb_cMOT_time = 10;10; %100 June 25
%         k_cMOT_time = 10;10; %20 
%         cMOT_time = 10; %100
%     
%         %Set shim coil values
%             yshim_comp = 0.8; %0.9 %0.8
%             xshim_comp = 0.4; %0.25 %0.4
%             zshim_comp = 0.42; %0.75 %0.42
% 
%             %optimize shims for compression (put cloud at the position of the mag
%             %trap center)
%             %turn on the Y (quantizing) shim 
%             setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',yshim_comp); %1.25
%             %turn on the X (left/right) shim
%             setAnalogChannel(calctime(curtime,-2),'X MOT Shim',xshim_comp); %0.3 
%             %turn on the Z (top/bottom) shim 
%             setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',zshim_comp); %0.2
%             
%         %Set gradient
%             setAnalogChannel(calctime(curtime,0),'MOT Coil',10);
%                        
%         %Set Beams
%             k_cMOT_detuning = 15;
%             k_cMOT_repump_detuning = 20; %-ve numbers are red detuning
%             k_cMOT_D1_detuning = 248;
%             addOutputParam('k_cMOT_D1_detuning',k_cMOT_D1_detuning); 
%             
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time-10),48,k_cMOT_D1_detuning);          
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
%             %turn repump down
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.3); 
%             %turn trap off
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.0);
%             %turn D1 beam on
%             setDigitalChannel(calctime(curtime,cMOT_time - k_cMOT_time),'D1 TTL B',1);
%             
%             rb_cMOT_detuning = 40; %35 June 1, 2015   %40 before         
% 
%             %detuning
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
%             %FF
% %             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FF',-0.025,1); %0.1                             
%             %turn repump down
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',0.2); %0.2 June 25
% 
%         %Wait time
%        curtime=calctime(curtime,cMOT_time);
%         
%        %turn D1 beam off
%        setDigitalChannel(curtime,'D1 TTL B',0);
%        %reset repump detuning
%        setAnalogChannel(curtime,'K Repump FM',0,2);
%         
%     else
%         %RHYS - This is actually the current cMOT - only 1ms of Rb?? That
%         %probably does not even work with 25ms of K?
%         ScopeTriggerPulse(calctime(curtime,0),'cMOT',1);
%         %Set cMOT time
%         cmot_time_list = [50];50 ;%40
%         
% 
%         rb_cMOT_time = getScanParameter(cmot_time_list,seqdata.scancycle,seqdata.randcyclelist,'rb_cMOT_time'); %100 June 25 30
%         k_cMOT_time = 25;25;1; %20 
%         cMOT_time = rb_cMOT_time; %100 80
%     
%         %Set shim coil values
%             %optimized by looking after evap in science cell (April 18,
%             %2012)
%              if (seqdata.atomtype==1 || seqdata.atomtype==4)%K-40
%                 yshim_comp = 0.8;0.75;0.3;0.8;%0.8; %0.9 %0.8
%                 xshim_comp = 0.25;0.6;0.4;%0.4; %0.25 %0.4
%                 %zshim_comp = 0.42; %0.75 %0.42
%                 %z shim compression via bipolar supply
%                 zshim_comp = 0.6;0.425;0.42;0.42;%0.42;
%              else
%                 yshim_comp = 1.6;%0.8; %0.9 %0.8
%                 xshim_comp = 0.4;%0.4; %0.25 %0.4
%                 zshim_comp = 1.6;%0.42; %0.75 %0.42
%              end
% 
%             %optimize shims for compression (put cloud at the position of the mag
%             %trap center)
%             %turn on the Y (quantizing) shim 
%             setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',yshim_comp); %1.25
%             %turn on the X (left/right) shim
%             setAnalogChannel(calctime(curtime,-2),'X MOT Shim',xshim_comp); %0.3 
%             %turn on the Z (top/bottom) shim 
%             setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',zshim_comp); %0.2
%             
%             %Set gradient
%             setAnalogChannel(calctime(curtime,0),'MOT Coil',10);
%                                  
%         if (seqdata.atomtype==1 || seqdata.atomtype==4)%K-40
%                        
%             
%             k_cMOT_detuning = 5;5;%5; %20 Oct 30, 2015 20; 
%             addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
%             k_cMOT_repump_detuning = 0;
%             addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
%             
%             
%             %set detuning
%             %detuning
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
%             
%             %turn repump down
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.25); %0.25
%             %turn trap down
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.7); %0.7 %0.3 Oct 30, 2015 
%             
%             %increase gradient to 15 G/cm
%             setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'MOT Coil',10);
%                 
%         end
%             
%         if (seqdata.atomtype==3 || seqdata.atomtype==4) %Rb
%             rb_cmot_detuning_list = [42];[42]; 
%             rb_cMOT_detuning = getScanParameter(rb_cmot_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'rb_cMOT_detuning');           
%             %rb_cMOT_detuning = 42;%before 2016-11-25:40 %35 June 1, 2015   %40 before 
%             
%             %set detuning
%             %detuning
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
%             %FF
% %             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FF',-0.025,1); %0.1
%                                
%             %turn repump down
%             %RHYS - Not sure we can trust the passive stability of the repump power
%             %when the values requested are so small.
%             rb_CMOT_repump_power_list = [0.0275];[0.0275];[0.025]; %0.025
%             rb_cmot_repump_power = getScanParameter(rb_CMOT_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'cmot_rb_repump_power');;
% 
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',rb_cmot_repump_power);
%             %before 2016-11-25 0.2%0.2 June 25
% 
%             %turn trap down  (cannot change Trap Power very well due to AOM placement before TA)
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Trap AM',0.1);
%             
%                         
%         end
% 
%        curtime=calctime(curtime,cMOT_time);
%        
% %        setAnalogChannel(curtime,'K Repump FM',0,2);
%     
%     end
%        
% end
%% Molasses
% 
% %To fix: the quadrupole field is not turning off *completely* here
% %RHYS - Compression, molasses, and OP could all be separate
% %functions/methods.
% do_molasses = 0;
% 
% molasses_time_list = 15;[15];[5];7;
% molasses_time = getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time');
% % molasses_time = 7.5; %(10 for Rb evap ) %10 (overwritten below if K is selected)
% 
% if do_molasses
%     %RHYS - Still not sure K D2 molasses does much of anything.
%     k_molasses_detuning_list =[7.5];[7.5];[7.5];5.5; %%20 Oct 30, 2015
%     k_molasses_detuning = getScanParameter(k_molasses_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_molasses_detuning');
%     k_molasses_repump_detuning = -50;-20;%-50 seems better than -20 somehow...
%     
%     %While true that this 'works' out to large detunings, optimizing for a
%     %'long' (e.g. 200ms) molasses time shows a sharp max.
%     rbmolasses_List = [77];[77];[65]; %75 60
%     rbmolasses_det=getScanParameter(rbmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'rb_molasses_det');
%     rb_molasses_detuning = rbmolasses_det;50; %53;%before 2016-11-25:50  %48 %46.5 (2014-04-25)
%     
%     %turn on the shims for optical pumping and/or molasses
%     %turn on the Y (quantizing) shim 
%     setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.25); %0.25 for D2, 0.25 for D1
%     %turn on the X (left/right) shim 
%     setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.25); %0.2 for D2, 0.4 for D1
%     %turn on the Z (top/bottom) shim 
%     setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.05);%0.05 %0.11 for D2, 0 for D1
%                                                            
%     %set shims and detuning (atom dependent)
%     if (seqdata.atomtype==1 || seqdata.atomtype==4)%K40
%                 
%         %set molasses detuning
%         setAnalogChannel(calctime(curtime,0),'K Trap FM',k_molasses_detuning); 
%         setAnalogChannel(calctime(curtime,0),'K Repump FM',k_molasses_repump_detuning,2); %765
%         %turn down Trap power for molasses
%         setAnalogChannel(calctime(curtime,0),'K Trap AM',0.7); %0.7 Oct 30, 2015
%         %set Repump power (turn down for molasses)
% %         kmolasses_List=[0 0.5:0.1:0.7];
% %         kmolasses_am=getScanParameter(kmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'kmolasses_am');
%         setAnalogChannel(calctime(curtime,0),'K Repump AM',0.025); %0.5
%     end
%      
%     if (seqdata.atomtype==3 || seqdata.atomtype==4) %Rb
%         %set molasses detuning 
%         setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
%         %offset FF
% %         setAnalogChannel(calctime(curtime,0),'Rb Beat Note FF',-0.06,1); %0.06, -0.09 April 22/2014
%         %turn trap down for molasses
%         rb_mol_trap_power_list = [0.10]; %0.25
%         rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
% 
%         setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
%         %turn repump down
% %         rbmolasses_List=[0.06];
% %         rbmolasses_am=getScanParameter(rbmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'rbmolasses_am');
%         
%         rb_mol_repump_power_list = [0.02]; %0.25
%         rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'mol_rb_repump_power');
%         setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 
%         %before 2016-11-25:0.12
%         %0.15 for all repump power in MOT beams
%         %0.1 for some repump in the extra path (21 degrees on waveplate)
%     end
%              
%    ScopeTriggerPulse(curtime,'Molasses',molasses_time);
%   
%     % Advance in time (molasses_time)
%     curtime = calctime(curtime,molasses_time);
%     
%     setAnalogChannel(curtime,'K Repump FM',0,2);
%     
% else
%     
%     %need to do this so that the probe detuning is ok
%     
%      %set molasses detuning
% %     setAnalogChannel(calctime(curtime,0),34,756); %756
% %     %offset FF
% %      setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06
% 
% end
% %% K40 D2 gray molasses  2018-03-14
% % as of March 2019, most of the digital channels used in this section have
% % been renamed and are being used somewhere else
% % % % % % % % % curtime = calctime(curtime,-molasses_time);
%  K_gray_molasses_time = 3;
%  %RHYS - This code is unlikely to ever be used again.
%  if seqdata.flags.K_D2_gray_molasses == 1
%      %set shim coil values:
% %         gray_molasses_x_shim_list=[0:0.02:0.26];%0.25
% %         gray_molasses_x_shim= getScanParameter(gray_molasses_x_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_x_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'X MOT Shim',gray_molasses_x_shim);
% %      
% %         gray_molasses_y_shim_list=[-0.2:0.05:0.2];%0.25
% %         gray_molasses_y_shim= getScanParameter(gray_molasses_y_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_y_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'Y MOT Shim',gray_molasses_y_shim);
% %         
% %         gray_molasses_z_shim_list=[0.05];%0.25
% %         gray_molasses_z_shim= getScanParameter(gray_molasses_z_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_z_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'Z MOT Shim',gray_molasses_z_shim);
%  
%         K_molasses_repump_detuning_list = [0]; 
%         K_molasses_repump_detuning = getScanParameter(K_molasses_repump_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_det');  %in MHZ
%   
%         K_molasses_trap_detuning_list = [-1:0.2:1];
%         K_molasses_trap_detuning = getScanParameter(K_molasses_trap_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_det');
%   
% % %Parameters
%         %K_repump double pass AOM- Rigol Channel 1
%         K_molasses_repump_freq = 81.31 + K_molasses_repump_detuning; %This is multiplied by 4 using two doublers %83.71 78.1
%         K_molasses_repump_amp_list = [0.6]; 
%         K_molasses_repump_amp = getScanParameter(K_molasses_repump_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_power');
%         K_molasses_repump_offset = 0;
%         
%         %K_repump shear mode AOM path
%         setDigitalChannel(curtime,'gray molasses shear mod AOM TLL',1); %0: AOM off; 1: AOM on
%         setDigitalChannel(calctime(curtime,-2),'K Repump 0th Shutter',0); % 0:Turn off zeroth order beam 1: Turn on zeroth order beam
%         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);% turn on K repump shear mode -1th power for K D2 molasses
%         
%         %K_trap double pass AOM - Rigol Channel 2
%         K_molasses_trap_freq = 117 + K_molasses_trap_detuning;
%         K_molasses_trap_amp = 1.25; %1.25
%         K_molasses_trap_offset = 0;
%         
%         %K_trap single pass AOM -SRS Generator
%         K_molasses_trap_SRS_amp_list = [10]; %
%         K_molasses_trap_SRS_amp = getScanParameter(K_molasses_trap_SRS_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_SRS_power');
%         strSRS = sprintf('FREQ 321.4 MHz; AMPR %g dBm; MODL 0; DISP 2; ENBR 1;',K_molasses_trap_SRS_amp);
%         addGPIBCommand(27,strSRS); 
%         
%        %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %gMHz,%f,%f; :OUTPut1 ON;',K_molasses_repump_freq,K_molasses_repump_amp,K_molasses_repump_offset);
%         str121=sprintf(':SOUR2:APPL:SIN %gMHz,%f,%f; :OUTPut2 ON;',K_molasses_trap_freq,K_molasses_trap_amp,K_molasses_trap_offset);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');
%         str141=sprintf(':SYSTem:ROSCillator:SOURce EXTernal;');
%         str2=[str111,str121,str131,str141];
%         addVISACommand(2, str2);
%         
% %         setAnalogChannel(calctime(curtime,-0.1),'K Repump AM',)
%         setDigitalChannel(curtime,'Gray Molasses switch',1)  %0: MOT Beam sources 1: D2 Molsses Beam source        
% 
%         curtime = calctime(curtime,K_gray_molasses_time);        
%         
%         setDigitalChannel(curtime,'gray Molasses switch',0) % Switch back to MOT sources
% %         setDigitalChannel(calctime(curtime,0),'K Repump 0th Shutter',5);
% %         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);
%         curtime = calctime(curtime,0.1);
%  end   
%      
% 
% %% Turn the trap light off
% %RHYS - Never used, unless Vijin revives, but probably would need to
% %rewrite anyway.
% do_D1_molasses = 0;
% 
% if ( seqdata.flags.image_type ~= 4 && do_D1_molasses == 0)
%     if do_molasses
%         turn_off_beam(calctime(curtime,0),1);
%     else
%         %this is so that the trap light and the trap turn off simultaneously
%         curtime = turn_off_beam(calctime(curtime,0),1);
%         
%     end
% end
% 
% if (do_D1_molasses == 1)
%     %Turn off Rb trap
%     analogid = 4;
%     ttlid = 8;
%     shutterid = 4;
%     shutterdelay = -2.0; %-2.2
%     setAnalogChannel(curtime,analogid,0,1);
%     setDigitalChannel(curtime,ttlid,1);
%     setDigitalChannel(calctime(curtime,shutterdelay),shutterid,0);
%     
%     %Need to leave K Trap Shutter open for D1 beams
%     analogid = 26;
%     ttlid = 6;
%     setAnalogChannel(curtime,analogid,0,1);
%     setDigitalChannel(curtime,ttlid,1);
%     
%     %Prepare shims
%     %turn on the Y (quantizing) shim 
%     setAnalogChannel(calctime(curtime,-1),'Y MOT Shim',0.35); %0.25 for D2, 0.25 for D1
%     %turn on the X (left/right) shim 
%     setAnalogChannel(calctime(curtime,-1),'X MOT Shim',0.30); %0.2 for D2, 0.4 for D1
%     %turn on the Z (top/bottom) shim 
%     setAnalogChannel(calctime(curtime,-1),'Z MOT Shim',0.0); %0.11 for D2, 0 for D1
% 
% end
%     
% 
% %lag for trap shutter (1.7ms)
% % curtime = calctime(curtime,0.0);
% 
% %% D1 molasses
% if do_D1_molasses
%    
%     D1_cooling_time = 7;
%     k_D1_Molasses_detuning = 247;
%     addOutputParam('k_D1_Molasses_detuning',k_D1_Molasses_detuning); 
%     
% %     setAnalogChannel(calctime(curtime,0),'K Trap FM',20); 
%     
%     setAnalogChannel(calctime(curtime,-10),48,k_D1_Molasses_detuning);
% %     setAnalogChannel(calctime(curtime,0),'K Repump AM',0.0);
%     setDigitalChannel(curtime,'K Repump TTL',1); %Repump off (shutter is still open for OP)
%             
%     %Turn on D1 beams
%     %TTL
%     DigitalPulse(calctime(curtime,0),'D1 TTL B',D1_cooling_time,1);
%    
%     curtime = calctime(curtime,D1_cooling_time);
%     
%     %Close shutter
%     shutterid = 2;
%     shutterdelay = -1.2; %-1.2
%     
%     setDigitalChannel(calctime(curtime,shutterdelay),shutterid,0);
%     
%     
% end
%% Optical Pumping
%RHYS - Always used. Already has a separate script that could be called
%from main.
do_optical_pumping = 1;
if do_optical_pumping == 1
    %digital trigger
    ScopeTriggerPulse(curtime,'Optical pumping');

    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);    
    setDigitalChannel(calctime(curtime,-1.8),'Rb Trap Shutter',0); 
    setDigitalChannel(calctime(curtime,-1.8),'K Trap Shutter',0); 
    
    curtime = optical_pumping(calctime(curtime,0.0));
      
else
    % expect a drop in number by factor of 3
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

% wtich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),1,0);
setDigitalChannel(calctime(curtime,0),65,1);
%% Turn off the repump
if ( seqdata.flags.image_type ~= 4 )
%RHYS - These turn on/turn off/turn on-off beam functions are confusing and
%could be rewritten.
curtime = turn_off_beam(calctime(curtime,1),2); %a little delayed w.r.t trap
end

timeout = curtime;

end