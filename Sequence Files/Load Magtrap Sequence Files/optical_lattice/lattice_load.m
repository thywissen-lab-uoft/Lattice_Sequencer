function timeout = lattice_load(timein)

global seqdata
curtime = timein;
if curtime==0
    main_settings;
    curtime = calctime(curtime,1000);
end


%% Prepare PID levels to load

dispLineStr('Loading into optical lattice',curtime);   

% Set lattice feedback offset (double PD configuration)
setAnalogChannel(calctime(curtime,-60),'Lattice Feedback Offset', -9.8,1);
% Set PID request to below zero to rail PID
setAnalogChannel(calctime(curtime,-60),'xLattice',-9.85,1);
setAnalogChannel(calctime(curtime,-60),'yLattice',-9.85,1);
setAnalogChannel(calctime(curtime,-60),'zLattice',-9.85,1);

% Enable AOMs on the lattice beams
setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off

% QPD is triggered 100 ms before lattice ramp
DigitalPulse(calctime(curtime,-100),'QPD Monitor Trigger',10,1);    

ScopeTriggerPulse(curtime,'lattice_ramp_0');
% Bring the PID levels to the "zero" value
AnalogFuncTo(calctime(curtime,-40),'xLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    20,20,seqdata.params.lattice_zero(1));
AnalogFuncTo(calctime(curtime,-40),'yLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    20,20,seqdata.params.lattice_zero(2));
AnalogFuncTo(calctime(curtime,-40),'zLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    20,20,seqdata.params.lattice_zero(3));
    

%% Turn on the Lattices

% Ramp the lattices to the desired value    
tL = getVar('lattice_load_time');

% Define individual lattices separately just in case
Ux = getVar('lattice_load_depthX');
Uy = getVar('lattice_load_depthY');
Uz = getVar('lattice_load_depthZ');

ScopeTriggerPulse(curtime,'lattice_ramp_1');
AnalogFuncTo(calctime(curtime,0),'xLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tL,tL,Ux); 
AnalogFuncTo(calctime(curtime,0),'yLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tL,tL,Uy);
AnalogFuncTo(calctime(curtime,0),'zLattice',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tL,tL,Uz);  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INSERT XDT AND DMD RAMPS WHICH WE DO NOT DO RIGHT NOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if seqdata.flags.lattice_load_dimple 
%     
%     
%     
% end

% Advance time
curtime = calctime(curtime,tL);  
%% Turn of XDTs
% When analyzing the properties of the lattice, it is sometimes useful to
% turn the XDT off.  This is typically not used in the experimental cycle.

if seqdata.flags.lattice_load_xdt_off
    tr = getVar('lattice_load_xdt_off_time');       
    % Ramp ODTs
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,seqdata.params.ODT_zeros(1));
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,seqdata.params.ODT_zeros(2));
    curtime = calctime(curtime,tr);    
    % Make sure its off
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);   
end


%% Hold after loading
% Hold time after loading 
tH = getVar('lattice_load_holdtime');
curtime=calctime(curtime,tH);    

%% Ramp Feshbach Field After Loading lattice
% After loading the lattice, ramp the feshbach field to a desired level for
% experiments.  This code works best if the xdtB.m is called and already
% ramps the feshbach field to a high field (and also the levitation field)
if seqdata.flags.lattice_load_feshbach_ramp   
    tr = getVar('lattice_load_feshbach_time');
    fesh = getVar('lattice_load_feshbach_field');

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = tr;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = tr;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = 20;    

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    % Hold after ramping up FB
    tFBH = getVar('lattice_load_feshbach_holdtime');
    curtime=calctime(curtime,tFBH);
end

%% Ramp lattices to science depth

if seqdata.flags.lattice_sci_ramp
    %Ramp the lattices to the desired value    
    tS = getVar('lattice_sci_time');
    
    % Define individual lattices separately just in case
    Ux = getVar('lattice_sci_depthX');
    Uy = getVar('lattice_sci_depthY');
    Uz = getVar('lattice_sci_depthZ');
    
    ScopeTriggerPulse(curtime,'lattice_sci_ramp');
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tS,tS,Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tS,tS,Uy);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tS,tS,Uz);  

    %Advance time
    curtime = calctime(curtime,tS);  
end
   
%% Unramp Lattices
if seqdata.flags.lattice_load_round_trip == 1   
     % Ramp the lattices to the desired value    
    tL = getVar('lattice_load_time');
    
    ScopeTriggerPulse(curtime,'lattice_ramp_1_off');

    % Ramp off the lattices
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(1)); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(2));
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(3));  
    
    curtime = calctime(curtime,tL);
    
    % Bring the request low to rail PID
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,-9.85,1);
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,-9.85,1);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,-9.85,1);
    curtime = calctime(curtime,20);
    
    % Disable the AOMs
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INSERT XDT AND DMD RAMPS WHICH WE DO NOT DO RIGHT NOW
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tW = getVar('lattice_ramp_1_round_trip_equilibriation_time');
    % Wait to equiblibriate
    curtime = calctime(curtime,tW);
end

%% Ending

timeout = curtime;

end

