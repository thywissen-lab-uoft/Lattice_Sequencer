function timeout = loadMOTSimple(timein,dumpMOT)

curtime = timein;
global seqdata;

if nargin==1
    dumpMOT = 1;
end

%% Send Scope Trigger
ScopeTriggerPulse(curtime,'Load MOT',1);

%% MOT Parameters
% Powers are not changeable for now, as they should typically be at their
% maximal values.

% Field Gradient
BGrad_list = 10;
BGrad=getScanParameter(BGrad_list,...
    seqdata.scancycle,seqdata.randcyclelist,'MOT_Gradient','??');

% Rb Trap Detuning
Rb_Trap_MOT_det_list=[-25];[-25];[-28];
Rb_Trap_MOT_detuning=getScanParameter(Rb_Trap_MOT_det_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_Trap_MOT_detuning','MHz');

% Rb Repump Detuning
addOutputParam('Rb_Repump_MOT_detuning',-156.947/2+80.5,'MHz');

% K Trap Detuning
K_Trap_MOT_detuning_list = 22;
K_Trap_MOT_detuning = getScanParameter(K_Trap_MOT_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'K_Repump_MOT_detuning');        

% K Repump Detuning
K_Repump_MOT_detuning_list = 0;
K_Repump_MOT_detuning = getScanParameter(K_Repump_MOT_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'K_Repump_MOT_detuning'); 


%% Keep Bipolar Shim Relay On 

%Don't close relay for Science Cell Shims because of current spikes
setDigitalChannel(curtime,'Bipolar Shim Relay',1);

%% Set Detunings of all beams
      
% K Trap Detuning
setAnalogChannel(curtime,'K Trap FM',K_Trap_MOT_detuning);    

% K Repump Detuning
setAnalogChannel(curtime,'K Repump FM',K_Repump_MOT_detuning,2);

% Rb Trap Detuning    
f_osc = calcOffsetLockFreq(Rb_Trap_MOT_detuning,'MOT');
DDS_id = 3;    
DDS_sweep(curtime,DDS_id,f_osc*1e6,f_osc*1e6,1);    

% Rb Repumper Detuning
% Currently unable to change this

%% Set Power of all beams
% Set the power in all the beams and turn on the AOMs (but don't set
% shutters just yet)

% K Trap Power
setAnalogChannel(curtime,'K Trap AM',0.8);    % K MOT trap power
setDigitalChannel(curtime,'K Trap TTL',0);    % K MOT trap TTL

% K Repump Power
setAnalogChannel(curtime,'K Repump AM',0.55); % K MOT repump power
setDigitalChannel(curtime,'K Repump TTL',0);  % K MOT repump TTL

% Rb Trap Power
setDigitalChannel(curtime,'Rb Trap TTL',0);   % Rb MOT trap TTL     (0 : ON)

%Added 06/10/2022 by FC and RL
%This modulates the frequency and amplitude of the Rb Trap AOM
% %frequency source (Rigol DG 4162) (Device 8). 
rb_trap_freq_list =  [109]; % in MHz
rb_trap_freq=getScanParameter(rb_trap_freq_list,...
seqdata.scancycle,seqdata.randcyclelist,...
'rb_trap_AOM_FM', 'MHz');

rb_trap_amp = 1.08; %in V
rb_trap_offset = 0; %in V

str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',(rb_trap_freq)*1E6,rb_trap_amp,rb_trap_offset);
addVISACommand(8, str);  %Device 8 Source 2 is the new Rb trap AOM FM

% Rb Repump Power
setAnalogChannel(curtime,'Rb Repump AM',0.9);           % Rb MOT repump power (voltage)


%% Turn on MOT Coil

% Feed Forward
setAnalogChannel(calctime(curtime,0),'Transport FF',10); 

% MOT Gradient
setAnalogChannel(calctime(curtime,0),'MOT Coil',BGrad);     
       
% TTL (What does this do?)
curtime = setDigitalChannel(calctime(curtime,0),'MOT TTL',0); %MOT TTL
    
%turn on channel 16 fast swithch
setDigitalChannel(curtime,21,0);

%% Turn on Shims

%Turn on Shim Supply Relay
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

if ~isfield(seqdata,'params') || ~isfield(seqdata.params,'MOT_shim')
    seqdata.params.MOT_shim = [0.2 2.0 0.9];    % Rb Optimized Shim values    
%     seqdata.params.MOT_shim = [0.0 0.0 0.2];    % K Optimized Shim values
end

% Rb optimized shim values
% setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.2,2);
% setAnalogChannel(calctime(curtime,0),'Y MOT Shim',2.0,2);
% setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.9,2);

% K optimized shim values
% setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.0 ,2);  0.2;
% setAnalogChannel(calctime(curtime,0),'Y MOT Shim', 0.0  ,2); 2;
% setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.2 ,2);  0.9;

setAnalogChannel(calctime(curtime,0),'X MOT Shim',seqdata.params.MOT_shim(1),2);
setAnalogChannel(calctime(curtime,0),'Y MOT Shim',seqdata.params.MOT_shim(2),2);
setAnalogChannel(calctime(curtime,0),'Z MOT Shim',seqdata.params.MOT_shim(3),2);

%% UV ON : LIAD
% Turn on UV cataract-inducing light.

setDigitalChannel(curtime,'UV LED',1); %1 = on; 0, off

%% Wait a HOT Second
curtime = calctime(curtime,100);

%% Close Shutters if desired
% Before loading the MOT unloaded the MOT in case you want to get rid of
% anything

if dumpMOT
    setDigitalChannel(calctime(curtime,0),'Rb Trap Shutter',0);        
    setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0);       

    setDigitalChannel(calctime(curtime,0),'K Trap Shutter',0);       
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);        
    
    % Wait for atoms to die
    curtime = calctime(curtime, 500);
end

setDigitalChannel(calctime(curtime,0),'Rb Trap Shutter',1);        % Rb MOT trap shutter (1 : ON)
setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',1);      % Rb MOT repumper shutter (1 : ON)

setDigitalChannel(calctime(curtime,0),'K Trap Shutter',1);         % K MOT trap shutter (1 : ON)
setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);       % K MOT repump shutter


%% End it
timeout=curtime;

    
