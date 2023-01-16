function timeout = seq_opticalpumping2(timein,flags)
global seqdata;
curtime = timein;

if nargin==1
    flags=struct;
end    



%% Local parameters
optime_list = [5];
optime = getScanParameter(optime_list,seqdata.scancycle,seqdata.randcyclelist,'optime');

% K
k_op_am_list = [1];[0.9];[0.6];
k_op_am = getScanParameter(k_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_am');
k_op_offset = 0.0;
k_op_time = optime;
k_op_detuning_list = [3];3;[31];  32;29; 
k_op_detuning = getScanParameter(k_op_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_op_det');

% Rb
rb_op_am_list = [1];[0.7];  %  (1) RF amplitude (V)       
rb_op_am = getScanParameter(rb_op_am_list,seqdata.scancycle,seqdata.randcyclelist,'rb_op_am');
rb_op_offset = 0.0;
rb_op_time = optime;        % (1) optical pumping time

rb_op_detuning_set(1) = -5;     %5 for 2->2    
rb_op_detuning_set(2) = -3;     % for 2->3

rb_op_detuning = rb_op_detuning_set(seqdata.flags.Rb_Probe_Order);

%% Set the shims
% Optical pumping requires a quantizing magnetic field along the
% propagation vector of the pumping light.

% CF : Let's make sure to put the appropriate voltagefunc in shim calls

%turn on the Y (quantizing) shim
setAnalogChannel(calctime(curtime,0.0),'Y MOT Shim',3.5,2); 
%turn on the X (left/right) shim 
setAnalogChannel(calctime(curtime,0.0),'X MOT Shim',0.1,2); 
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0.0),'Z MOT Shim',0.0,2);

%% Turn repumper light on 
% Turn on the MOT repumper light to repump during optical pumping

% Potassium
K_repump_power_for_OP = 0.7;
setAnalogChannel(curtime,'K Repump AM',K_repump_power_for_OP); 

% Rubidium
rb_op_repump_am = 0.05;
setAnalogChannel(curtime,'Rb Repump AM',rb_op_repump_am); 
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


%% Set the detunings
% Set the detunings of the probe beams to their relevant values.

% Potassium
% Probe / OP Double pass
setAnalogChannel(calctime(curtime,-0.5),'K Probe/OP FM',190);
% Trap double pass AOM
setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',k_op_detuning);

%Rb
setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FM',6590+rb_op_detuning);

%% Flash the beams
% Here the beams are actually flashed using digital pulses to the AOM TTL
% and/or amplitude modulations for the AOMs

% Note that the potassium K Probe / OP TTL is a double pass. The 0th order
% light should be blocked for the pulse to function as a TTL. This is also
% why the amplitude modulation is turned down.

% Potassium
DigitalPulse(calctime(curtime,k_op_offset),'K Probe/OP TTL',k_op_time,1);       % Flash TTL
setAnalogChannel(calctime(curtime,k_op_offset+k_op_time),'K Probe/OP AM',0,1);  % Turn down AM

% Rubidium
DigitalPulse(calctime(curtime,rb_op_offset),'Rb Probe/OP TTL',rb_op_time,0);    % inverted logic

% Advance the seqeunce in time while the light is applied
if seqdata.atomtype == 1 %K
    curtime = calctime(curtime,k_op_offset + k_op_time);
elseif seqdata.atomtype == 3 %Rb
    curtime = calctime(curtime,rb_op_offset + rb_op_time);
elseif seqdata.atomtype == 4 %K+Rb
    curtime = calctime(curtime,max(k_op_offset+k_op_time,rb_op_offset+rb_op_time));
end


%% Reset the sequence

% Add a short wait time for digital sequence writing safety
curtime = calctime(curtime,0.05);

% Close the shutters
setDigitalChannel(calctime(curtime,0),'K Probe/OP Shutter',0);
setDigitalChannel(calctime(curtime,0),'Rb Probe/OP Shutter',0);

% Reset the TTLs to the AOMs
setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); 
setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1); % inverted logic

% Reset the detunings of the beams
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+25);

% Note the shim valeus are not set to a new value
            
timeout = curtime;
end