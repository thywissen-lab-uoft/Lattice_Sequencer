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
% tmax=15;
optime_list = [2];
optime = getScanParameter(optime_list,seqdata.scancycle,seqdata.randcyclelist,'optime');

% K
k_op_am_list = [.3]; [1];[0.6];
k_op_am = getScanParameter(k_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_am');
k_op_offset = 0.0;
k_op_time = optime;
k_op_detuning_list = [3];3;[31];  32;29; 
k_op_detuning = getScanParameter(k_op_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_det');

% Rb
rb_op_am_list = 0.8;[0.8];[0.8];  %  (1) RF amplitude (V)       
rb_op_am = getScanParameter(rb_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'rb_op_am');
rb_op_offset = 0.0;
rb_op_time = optime;        % (1) optical pumping time

rb_op_detuning_set(1) = -20;-5;     %5 for 2->2    
rb_op_detuning_set(2) = -3;     % for 2->3

% rb_op_detuning = rb_op_detuning_set(seqdata.flags.Rb_Probe_Order);
% 
rb_op_detuning_list = [-20];-20;
rb_op_detuning = getScanParameter(rb_op_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'rb_op_detuning');

%% Prepare OP

% zshims=0:0.1:1;
% zshim=getScanParameter(zshims,seqdata.scancycle,seqdata.randcyclelist,'op_zshim');

% Old configuration
% setAnalogChannel(calctime(curtime,0.0),'Y Shim',3.3,2); % 3.3
%turn on the X (left/right) shim 
% setAnalogChannel(calctime(curtime,0.0),'X Shim',0.2,2); % 0.2,2
%turn on the Z (top/bottom) shim 
% setAnalogChannel(calctime(curtime,0.0),'Z Shim',0.2,2); %0.0

% xshims=0:.5:4;
% xshim=getScanParameter(xshims,seqdata.scancycle,seqdata.randcyclelist,'op_xshim');

% For pumping along X axis
setAnalogChannel(calctime(curtime,0.0),'X Shim',3.5,2); % 3.3
setAnalogChannel(calctime(curtime,0.0),'Y Shim',0.0,2); % 0.2,2
setAnalogChannel(calctime(curtime,0.0),'Z Shim',0.0,2); %0.0


%Turn repump back up
%K
if (seqdata.atomtype==1 || seqdata.atomtype==4)
%     K_OP_repump_am = 0.7;

     K_OP_repump_am_list = [0.3];
     K_OP_repump_am =  getScanParameter(K_OP_repump_am_list,seqdata.scancycle,seqdata.randcyclelist,'K_OP_repump_am');

     setAnalogChannel(curtime,'K Repump AM',K_OP_repump_am); %0.3
% %      
%      setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
%      setDigitalChannel(calctime(curtime,-5),'K Repump Shutter',0);

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
    setDigitalChannel(calctime(curtime,-10),'K Probe/OP Shutter',1); % Open K Shtter with pre-trigger
    %Now at k_op_offset time because there is no TTL (turns on pulse). 
    setAnalogChannel(calctime(curtime,k_op_offset),'K Probe/OP AM',k_op_am);%setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',k_op_am); %0.11
    % CF : Why do the probe beams have a pre-trigger?; Seems odd to turn on
    % beams with the amplitude modulation call
    setDigitalChannel(calctime(curtime,-10),'K Probe/OP TTL',0); 
    %setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',0);% inverted logic
end

%Rb
if (seqdata.atomtype==3 || seqdata.atomtype==4)
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP Shutter',1); % Open shutter
    setAnalogChannel(calctime(curtime,-5),'Rb Probe/OP AM',rb_op_am); % Set 
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
    setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); % 0 is off
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

% curtime = calctime(curtime,tmax-optime);   

timeout = curtime;

end