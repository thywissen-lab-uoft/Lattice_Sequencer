%------
%Author: DJ
%Created: Sep 2009
%Summary: This function makes an Optical Pumping sequence
%------

%-----Update List-------
%Aug 12, 2010: Put code from Load_MagTrap_sequence into here (DCM)
%-----------------------
%RHYS - Again, parameters should be declared elsewhere.
function timeout = optical_pumping(timein)

global seqdata;

curtime = timein;

%% Optical pumping parameters
optime_list = [4];4;
optime = getScanParameter(optime_list,seqdata.scancycle,seqdata.randcyclelist,'optime');
% K
k_op_am_list = [1];[0.9];[0.6];%0.5 before 2019-01-09  %0.4: before 2018-02-15;0.7
k_op_am = getScanParameter(k_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_am');
k_op_offset = 0.0;
k_op_time = optime; %0.5
k_op_detuning_list = [3];3;[31];  32;29; %23 (2014-04-10) %24 %23 %18 12.5 13 30(before re-aligning OP beam) 30  26 March 18th 2014
k_op_detuning = getScanParameter(k_op_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_det');
% Rb
rb_op_am_list = [0.7];[0.9];       %before 2016-11-25: 0.7;%0.7 (2013-06-01)
rb_op_am = getScanParameter(rb_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'rb_op_am');
rb_op_offset = 0.0;
rb_op_time = optime;%1.0

rb_op_detuning_set(1) = -5; %5 for 2->2     2 (2014-04-29) %12 (2014-04-10)
rb_op_detuning_set(2) = -3; % for 2->3

rb_op_detuning = rb_op_detuning_set(seqdata.flags.Rb_Probe_Order);


%% Prepare OP

% %digital trigger  (beginning of OP function)
% DigitalPulse(calctime(curtime,0),'ScopeTrigger',1,1);


%turn on the Y (quantizing) shim on after 400us (the MOT turn-off time)
setAnalogChannel(calctime(curtime,0.0),'Y Shim',3.5); %3.5 setAnalogChannel(calctime(curtime,0.4),19,3.5);    
%turn on the X (left/right) shim 
setAnalogChannel(calctime(curtime,0.0),'X Shim',0.1); % 0.1
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0.0),'Z Shim',0.0); %0.0

%Turn repump back up
%K
if (seqdata.atomtype==1 || seqdata.atomtype==4)
    K_repump_power_for_OP = 0.7;%0.3
    %RHYS - delete, never will be used.
     if seqdata.flags.K_D2_gray_molasses == 1
        K_repump_power_for_OP_list = [0.4];
        K_repump_power_for_OP = getScanParameter(K_repump_power_for_OP_list,seqdata.scancycle,seqdata.randcyclelist,'K_repump_power_for_OP');
     end
     setAnalogChannel(curtime,'K Repump AM',K_repump_power_for_OP); %0.3
end

%Rb
if (seqdata.atomtype==3 || seqdata.atomtype==4)
    rb_op_repump_am = 0.05;
    setAnalogChannel(curtime,'Rb Repump AM',rb_op_repump_am); %0.3
    addOutputParam('rb_op_repump_am',rb_op_repump_am);
end


%% Prepare OP Light

%K
if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %shutter
    setDigitalChannel(calctime(curtime,-10),'K Probe/OP Shutter',1); %-10
    %analog
    %Now at k_op_offset time because there is no TTL (turns on pulse). 
    setAnalogChannel(calctime(curtime,k_op_offset),'K Probe/OP AM',k_op_am);%setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',k_op_am); %0.11
    %TTL
    setDigitalChannel(calctime(curtime,-10),'K Probe/OP TTL',0);
    %setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',0);% inverted logic
end


%Rb
if (seqdata.atomtype==3 || seqdata.atomtype==4)
    %shutter
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP Shutter',1);
    %analog
    setAnalogChannel(calctime(curtime,-5),'Rb Probe/OP AM',rb_op_am); %0.11
    %TTL
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1); % inverted logic
end


%% Change detunings

%K40
if (seqdata.atomtype == 1 || seqdata.atomtype == 4)
    %set OP detuning
    setAnalogChannel(calctime(curtime,-0.5),'K Probe/OP FM',190);%202.5); %200
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',k_op_detuning);
end


%Rb
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
    %offset piezo FF
%     setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FF',0.047-0.1254/32.71*(rb_op_detuning-23),1); %0.05-0.1254/32.71*(rb_op_detuning-23)
    %offset detuning ... should be close to the MOT detuning
%     setAnalogChannel(calctime(curtime,-5),'Rb Beat Note FF',0.18,1);
%     setDigitalChannel(calctime(curtime,-0.5),50,1);
    setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FM',6590+rb_op_detuning);
%     setDigitalChannel(calctime(curtime,0.5),50,0);
%     setAnalogChannel(calctime(curtime,5),'Rb Beat Note FF',0,1);
end


%% OP

%300us OP pulse after 1.5ms for Shim coil to turn on
%TTL

%K
if (seqdata.atomtype == 1 || seqdata.atomtype == 4)
    %Turn on the K optical pumping pulse (disabled, currently: no TTL). 
    DigitalPulse(calctime(curtime,k_op_offset),'K Probe/OP TTL',k_op_time,1);
    %Turn off the K optical pumping pulse.
    setAnalogChannel(calctime(curtime,k_op_offset+k_op_time),'K Probe/OP AM',0,1);% inverted logic
end

%Rb
if (seqdata.atomtype == 3 || seqdata.atomtype == 4) 
    %Turn on/off the Rb optical pumping pulse.
    DigitalPulse(calctime(curtime,rb_op_offset),'Rb Probe/OP TTL',rb_op_time,0); % inverted logic
end

% Advance in time
if seqdata.atomtype == 1 %K
    curtime = calctime(curtime,k_op_offset + k_op_time);
elseif seqdata.atomtype == 3 %Rb
    curtime = calctime(curtime,rb_op_offset + rb_op_time);
elseif seqdata.atomtype == 4 %K+Rb
    curtime = calctime(curtime,max(k_op_offset+k_op_time,rb_op_offset+rb_op_time));
end


%% Finish OP

curtime = calctime(curtime,0.1);

%turn the OP light off

%K
if (seqdata.atomtype == 1 || seqdata.atomtype == 4)
    %analog
    %setAnalogChannel(calctime(curtime,0),k_opanalogid,0);
    %ttl
    setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); % inverted logic
%     setDigitalChannel(calctime(curtime,0),'gray molasses shear mod AOM TLL',0); % turn off shear mod AOM
%     setDigitalChannel(calctime(curtime,0),'Gray Molasses switch',0); % Switch back to MOT sources
    %close shutter if transporting to science cell
    if seqdata.flags.image_loc == 1
        setDigitalChannel(calctime(curtime,2),'K Probe/OP Shutter',0);
    end
end

%Rb
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
    %analog
    %setAnalogChannel(calctime(curtime,0),rb_opanalogid,0);
    %ttl
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1); % inverted logic
    %close shutter if transporting to science cell
    if seqdata.flags.image_loc == 1
        setDigitalChannel(calctime(curtime,2),'Rb Probe/OP Shutter',0);
    end
end    

%set Rb trap laser back
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,4.0),35,0); 
    %offset detuning
    setAnalogChannel(calctime(curtime,4.0),'Rb Beat Note FM',6590+25);
end
            
timeout = curtime;

end