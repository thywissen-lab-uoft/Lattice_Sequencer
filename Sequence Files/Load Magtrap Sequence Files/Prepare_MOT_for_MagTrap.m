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

%RHYS - Old code. 
%% Turn off extra Rb probe beam.

% setDigitalChannel(calctime(curtime,-500),'Rb Probe/OP TTL',1);
% 
% setDigitalChannel(calctime(curtime,-500),'Rb Probe/OP shutter',0);

%% Take Flouresence image of MOT
%cam trigger
%DigitalPulse(curtime,1,1,1);

%% MOT Feed Forward 
%Increase the voltage on the supplies
%setAnalogChannel(calctime(curtime,10),18,10/6.6); 

%% Bright MOT (Take out dark spot)
   
%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

%% Turn off UV light.
%Turn off UV cataract-inducing light.
setDigitalChannel(calctime(curtime,-500),'UV LED',0);
setAnalogChannel(calctime(curtime,-500),'UV Lamp 2',0);

setDigitalChannel(calctime(curtime,0),15,1)
setDigitalChannel(calctime(curtime,10),15,0)

%% Compression
%RHYS - Should be a seqdata flag.
do_compression = 1;

if do_compression %&& (~(seqdata.flags.image_type==4))
    D1_cMOT = 0;
    %RHYS - D1 molasses/cMOT not used right now, unless Vijin revives it.
    if D1_cMOT
        
        ScopeTriggerPulse(calctime(curtime,0),'cMOT',1);
        %Set cMOT time
        rb_cMOT_time = 10;10; %100 June 25
        k_cMOT_time = 10;10; %20 
        cMOT_time = 10; %100
    
        %Set shim coil values
            yshim_comp = 0.8; %0.9 %0.8
            xshim_comp = 0.4; %0.25 %0.4
            zshim_comp = 0.42; %0.75 %0.42

            %optimize shims for compression (put cloud at the position of the mag
            %trap center)
            %turn on the Y (quantizing) shim 
            setAnalogChannel(calctime(curtime,-2),'Y Shim',yshim_comp); %1.25
            %turn on the X (left/right) shim
            setAnalogChannel(calctime(curtime,-2),'X Shim',xshim_comp); %0.3 
            %turn on the Z (top/bottom) shim 
            setAnalogChannel(calctime(curtime,-2),'Z Shim',zshim_comp); %0.2
            
        %Set gradient
            setAnalogChannel(calctime(curtime,0),'MOT Coil',10);
                       
        %Set Beams
            k_cMOT_detuning = 15;
            k_cMOT_repump_detuning = 20; %-ve numbers are red detuning
            k_cMOT_D1_detuning = 248;
            addOutputParam('k_cMOT_D1_detuning',k_cMOT_D1_detuning); 
            
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time-10),48,k_cMOT_D1_detuning);          
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
            %turn repump down
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.3); 
            %turn trap off
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.0);
            %turn D1 beam on
            setDigitalChannel(calctime(curtime,cMOT_time - k_cMOT_time),'D1 TTL B',1);
            
            rb_cMOT_detuning = 40; %35 June 1, 2015   %40 before         

            %detuning
            setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
            %FF
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FF',-0.025,1); %0.1                             
            %turn repump down
            setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',0.2); %0.2 June 25

        %Wait time
       curtime=calctime(curtime,cMOT_time);
        
       %turn D1 beam off
       setDigitalChannel(curtime,'D1 TTL B',0);
       %reset repump detuning
       setAnalogChannel(curtime,'K Repump FM',0,2);
        
    else
        %RHYS - This is actually the current cMOT - only 1ms of Rb?? That
        %probably does not even work with 25ms of K?
        ScopeTriggerPulse(calctime(curtime,0),'cMOT',1);
        %Set cMOT time
        cmot_time_list = [50];50 ;%40
        

        rb_cMOT_time = getScanParameter(cmot_time_list,seqdata.scancycle,seqdata.randcyclelist,'rb_cMOT_time'); %100 June 25 30
        k_cMOT_time = 25;25;1; %20 
        cMOT_time = rb_cMOT_time; %100 80
    
        %Set shim coil values
            %optimized by looking after evap in science cell (April 18,
            %2012)
             if (seqdata.atomtype==1 || seqdata.atomtype==4)%K-40
                yshim_comp = 0.8;0.75;0.3;0.8;%0.8; %0.9 %0.8
                xshim_comp = 0.25;0.6;0.4;%0.4; %0.25 %0.4
                %zshim_comp = 0.42; %0.75 %0.42
                %z shim compression via bipolar supply
                zshim_comp = 0.6;0.425;0.42;0.42;%0.42;
             else
                yshim_comp = 1.6;%0.8; %0.9 %0.8
                xshim_comp = 0.4;%0.4; %0.25 %0.4
                zshim_comp = 1.6;%0.42; %0.75 %0.42
             end

            %optimize shims for compression (put cloud at the position of the mag
            %trap center)
            %turn on the Y (quantizing) shim 
            setAnalogChannel(calctime(curtime,-2),'Y Shim',yshim_comp); %1.25
            %turn on the X (left/right) shim
            setAnalogChannel(calctime(curtime,-2),'X Shim',xshim_comp); %0.3 
            %turn on the Z (top/bottom) shim 
            setAnalogChannel(calctime(curtime,-2),'Z Shim',zshim_comp); %0.2
            
            %Set gradient
            setAnalogChannel(calctime(curtime,0),'MOT Coil',10);
                                 
        if (seqdata.atomtype==1 || seqdata.atomtype==4)%K-40
                       
            
            k_cMOT_detuning = 5;5;%5; %20 Oct 30, 2015 20; 
            addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
            k_cMOT_repump_detuning = 0;
            addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
            
            
            %set detuning
            %detuning
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
            
            %turn repump down
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.25); %0.25
            %turn trap down
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.7); %0.7 %0.3 Oct 30, 2015 
            
            %increase gradient to 15 G/cm
            setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'MOT Coil',10);
                
        end
            
        if (seqdata.atomtype==3 || seqdata.atomtype==4) %Rb
            rb_cmot_detuning_list = [42];[42]; 
            rb_cMOT_detuning = getScanParameter(rb_cmot_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'rb_cMOT_detuning');           
            %rb_cMOT_detuning = 42;%before 2016-11-25:40 %35 June 1, 2015   %40 before 
            
            %set detuning
            %detuning
            setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
            %FF
%             setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FF',-0.025,1); %0.1
                               
            %turn repump down
            %RHYS - Not sure we can trust the passive stability of the repump power
            %when the values requested are so small.
            rb_CMOT_repump_power_list = [0.0275];[0.0275];[0.025]; %0.025
            rb_cmot_repump_power = getScanParameter(rb_CMOT_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'cmot_rb_repump_power');;

            setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',rb_cmot_repump_power);
            %before 2016-11-25 0.2%0.2 June 25

            %turn trap down  (cannot change Trap Power very well due to AOM placement before TA)
            setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Trap AM',0.1);
            
                        
        end

       curtime=calctime(curtime,cMOT_time);
       
       setAnalogChannel(curtime,'K Repump FM',0,2);
    
    end
       
end

%% Turn off the MOT

if ( seqdata.flags.image_type ~= 4 )
    %turn the MOT off
    %CATS
%     MOT_ramp_down_time = 1;
%     AnalogFuncTo(calctime(curtime,MOT_ramp_down_time),'MOT Coil',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),MOT_ramp_down_time,MOT_ramp_down_time,0);
    setAnalogChannel(curtime,'MOT Coil',0,1); 
    %TTL
    setDigitalChannel(curtime,16,0); %1 is fast turn-off, 0 is not
end

%% Molasses 

%To fix: the quadrupole field is not turning off *completely* here
%RHYS - Compression, molasses, and OP could all be separate
%functions/methods.
do_molasses = 1;

molasses_time_list = 15;[15];[5];7;
molasses_time = getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time');
% molasses_time = 7.5; %(10 for Rb evap ) %10 (overwritten below if K is selected)

if do_molasses
    %RHYS - Still not sure K D2 molasses does much of anything.
    k_molasses_detuning_list =[7.5];[7.5];[7.5];5.5; %%20 Oct 30, 2015
    k_molasses_detuning = getScanParameter(k_molasses_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_molasses_detuning');
    k_molasses_repump_detuning = -50;-20;%-50 seems better than -20 somehow...
    
    %While true that this 'works' out to large detunings, optimizing for a
    %'long' (e.g. 200ms) molasses time shows a sharp max.
    rbmolasses_List = [77];[77];[65]; %75 60
    rbmolasses_det=getScanParameter(rbmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'rb_molasses_det');
    rb_molasses_detuning = rbmolasses_det;50; %53;%before 2016-11-25:50  %48 %46.5 (2014-04-25)
    
    %turn on the shims for optical pumping and/or molasses
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.25); %0.25 for D2, 0.25 for D1
    %turn on the X (left/right) shim 
    setAnalogChannel(calctime(curtime,0),'X Shim',0.25); %0.2 for D2, 0.4 for D1
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.05);%0.05 %0.11 for D2, 0 for D1
                                                           
    %set shims and detuning (atom dependent)
    if (seqdata.atomtype==1 || seqdata.atomtype==4)%K40
                
        %set molasses detuning
        setAnalogChannel(calctime(curtime,0),'K Trap FM',k_molasses_detuning); 
        setAnalogChannel(calctime(curtime,0),'K Repump FM',k_molasses_repump_detuning,2); %765
        %turn down Trap power for molasses
        setAnalogChannel(calctime(curtime,0),'K Trap AM',0.7); %0.7 Oct 30, 2015
        %set Repump power (turn down for molasses)
%         kmolasses_List=[0 0.5:0.1:0.7];
%         kmolasses_am=getScanParameter(kmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'kmolasses_am');
        setAnalogChannel(calctime(curtime,0),'K Repump AM',0.025); %0.5
    end
     
    if (seqdata.atomtype==3 || seqdata.atomtype==4) %Rb
        %set molasses detuning 
        setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
        %offset FF
%         setAnalogChannel(calctime(curtime,0),'Rb Beat Note FF',-0.06,1); %0.06, -0.09 April 22/2014
        %turn trap down for molasses
        rb_mol_trap_power_list = [0.10]; %0.25
        rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');

        setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
        %turn repump down
%         rbmolasses_List=[0.06];
%         rbmolasses_am=getScanParameter(rbmolasses_List,seqdata.scancycle,seqdata.randcyclelist,'rbmolasses_am');
        
        rb_mol_repump_power_list = [0.02]; %0.25
        rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'mol_rb_repump_power');
        setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 
        %before 2016-11-25:0.12
        %0.15 for all repump power in MOT beams
        %0.1 for some repump in the extra path (21 degrees on waveplate)
    end
             
   ScopeTriggerPulse(curtime,'Molasses',molasses_time);
  
    % Advance in time (molasses_time)
    curtime = calctime(curtime,molasses_time);
    
    setAnalogChannel(curtime,'K Repump FM',0,2);
    
else
    
    %need to do this so that the probe detuning is ok
    
     %set molasses detuning
%     setAnalogChannel(calctime(curtime,0),34,756); %756
%     %offset FF
%      setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06

end
%% K40 D2 gray molasses  2018-03-14
% as of March 2019, most of the digital channels used in this section have
% been renamed and are being used somewhere else
% % % % % % % % curtime = calctime(curtime,-molasses_time);
 K_gray_molasses_time = 3;
 %RHYS - This code is unlikely to ever be used again.
 if seqdata.flags.K_D2_gray_molasses == 1
     %set shim coil values:
%         gray_molasses_x_shim_list=[0:0.02:0.26];%0.25
%         gray_molasses_x_shim= getScanParameter(gray_molasses_x_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_x_shim');  %in MHZ
%         setAnalogChannel(calctime(curtime,-1),'X Shim',gray_molasses_x_shim);
%      
%         gray_molasses_y_shim_list=[-0.2:0.05:0.2];%0.25
%         gray_molasses_y_shim= getScanParameter(gray_molasses_y_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_y_shim');  %in MHZ
%         setAnalogChannel(calctime(curtime,-1),'Y Shim',gray_molasses_y_shim);
%         
%         gray_molasses_z_shim_list=[0.05];%0.25
%         gray_molasses_z_shim= getScanParameter(gray_molasses_z_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_z_shim');  %in MHZ
%         setAnalogChannel(calctime(curtime,-1),'Z Shim',gray_molasses_z_shim);
 
        K_molasses_repump_detuning_list = [0]; 
        K_molasses_repump_detuning = getScanParameter(K_molasses_repump_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_det');  %in MHZ
  
        K_molasses_trap_detuning_list = [-1:0.2:1];
        K_molasses_trap_detuning = getScanParameter(K_molasses_trap_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_det');
  
% %Parameters
        %K_repump double pass AOM- Rigol Channel 1
        K_molasses_repump_freq = 81.31 + K_molasses_repump_detuning; %This is multiplied by 4 using two doublers %83.71 78.1
        K_molasses_repump_amp_list = [0.6]; 
        K_molasses_repump_amp = getScanParameter(K_molasses_repump_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_power');
        K_molasses_repump_offset = 0;
        
        %K_repump shear mode AOM path
        setDigitalChannel(curtime,'gray molasses shear mod AOM TLL',1); %0: AOM off; 1: AOM on
        setDigitalChannel(calctime(curtime,-2),'K Repump 0th Shutter',0); % 0:Turn off zeroth order beam 1: Turn on zeroth order beam
        setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);% turn on K repump shear mode -1th power for K D2 molasses
        
        %K_trap double pass AOM - Rigol Channel 2
        K_molasses_trap_freq = 117 + K_molasses_trap_detuning;
        K_molasses_trap_amp = 1.25; %1.25
        K_molasses_trap_offset = 0;
        
        %K_trap single pass AOM -SRS Generator
        K_molasses_trap_SRS_amp_list = [10]; %
        K_molasses_trap_SRS_amp = getScanParameter(K_molasses_trap_SRS_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_SRS_power');
        strSRS = sprintf('FREQ 321.4 MHz; AMPR %g dBm; MODL 0; DISP 2; ENBR 1;',K_molasses_trap_SRS_amp);
        addGPIBCommand(27,strSRS); 
        
       %-------------------------set Rigol DG4162 ---------
        str111=sprintf(':SOUR1:APPL:SIN %gMHz,%f,%f; :OUTPut1 ON;',K_molasses_repump_freq,K_molasses_repump_amp,K_molasses_repump_offset);
        str121=sprintf(':SOUR2:APPL:SIN %gMHz,%f,%f; :OUTPut2 ON;',K_molasses_trap_freq,K_molasses_trap_amp,K_molasses_trap_offset);
        str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');
        str141=sprintf(':SYSTem:ROSCillator:SOURce EXTernal;');
        str2=[str111,str121,str131,str141];
        addVISACommand(2, str2);
        
%         setAnalogChannel(calctime(curtime,-0.1),'K Repump AM',)
        setDigitalChannel(curtime,'Gray Molasses switch',1)  %0: MOT Beam sources 1: D2 Molsses Beam source        

        curtime = calctime(curtime,K_gray_molasses_time);        
        
        setDigitalChannel(curtime,'gray Molasses switch',0) % Switch back to MOT sources
%         setDigitalChannel(calctime(curtime,0),'K Repump 0th Shutter',5);
%         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);
        curtime = calctime(curtime,0.1);
 end   
     

%% Turn the trap light off
%RHYS - Never used, unless Vijin revives, but probably would need to
%rewrite anyway.
do_D1_molasses = 0;

if ( seqdata.flags.image_type ~= 4 && do_D1_molasses == 0)
    if do_molasses
        turn_off_beam(calctime(curtime,0),1);
    else
        %this is so that the trap light and the trap turn off simultaneously
        curtime = turn_off_beam(calctime(curtime,0),1);
        
    end
end

if (do_D1_molasses == 1)
    %Turn off Rb trap
    analogid = 4;
    ttlid = 8;
    shutterid = 4;
    shutterdelay = -2.0; %-2.2
    setAnalogChannel(curtime,analogid,0,1);
    setDigitalChannel(curtime,ttlid,1);
    setDigitalChannel(calctime(curtime,shutterdelay),shutterid,0);
    
    %Need to leave K Trap Shutter open for D1 beams
    analogid = 26;
    ttlid = 6;
    setAnalogChannel(curtime,analogid,0,1);
    setDigitalChannel(curtime,ttlid,1);
    
    %Prepare shims
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,-1),'Y Shim',0.35); %0.25 for D2, 0.25 for D1
    %turn on the X (left/right) shim 
    setAnalogChannel(calctime(curtime,-1),'X Shim',0.30); %0.2 for D2, 0.4 for D1
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,-1),'Z Shim',0.0); %0.11 for D2, 0 for D1

end
    

%lag for trap shutter (1.7ms)
% curtime = calctime(curtime,0.0);

%% D1 molasses
if do_D1_molasses
   
    D1_cooling_time = 7;
    k_D1_Molasses_detuning = 247;
    addOutputParam('k_D1_Molasses_detuning',k_D1_Molasses_detuning); 
    
%     setAnalogChannel(calctime(curtime,0),'K Trap FM',20); 
    
    setAnalogChannel(calctime(curtime,-10),48,k_D1_Molasses_detuning);
%     setAnalogChannel(calctime(curtime,0),'K Repump AM',0.0);
    setDigitalChannel(curtime,'K Repump TTL',1); %Repump off (shutter is still open for OP)
            
    %Turn on D1 beams
    %TTL
    DigitalPulse(calctime(curtime,0),'D1 TTL B',D1_cooling_time,1);
   
    curtime = calctime(curtime,D1_cooling_time);
    
    %Close shutter
    shutterid = 2;
    shutterdelay = -1.2; %-1.2
    
    setDigitalChannel(calctime(curtime,shutterdelay),shutterid,0);
    
    
end
%% Optical Pumping
%RHYS - Always used. Already has a separate script that could be called
%from main.
do_optical_pumping = 1;
if do_optical_pumping == 1;
    %digital trigger
    ScopeTriggerPulse(curtime,'Optical pumping');

    curtime = optical_pumping(calctime(curtime,0.0));
      
else
    % expect a drop in number by factor of 3
end

%% Turn off the repump
if ( seqdata.flags.image_type ~= 4 )
%RHYS - These turn on/turn off/turn on-off beam functions are confusing and
%could be rewritten.
curtime = turn_off_beam(calctime(curtime,0.5),2); %a little delayed w.r.t trap
end

timeout = curtime;

end