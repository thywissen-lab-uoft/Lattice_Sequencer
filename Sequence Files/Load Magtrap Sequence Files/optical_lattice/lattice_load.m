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


% Advance time
curtime = calctime(curtime,tL);   


%% Unramp Lattices
if seqdata.flags.lattice_load_1_round_trip == 1
    
    % Hold time after loading for round trip analysis   
    tH = getVar('lattice_ramp_1_holdtime');
    curtime=calctime(curtime,tH);       

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

