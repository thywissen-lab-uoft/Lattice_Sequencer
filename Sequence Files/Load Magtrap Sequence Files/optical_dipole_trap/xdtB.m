function timeout = xdtB(timein)

%% Load in
global seqdata
curtime = timein;


%% High Field Ramp up
% Ramp up Feshbach and levitation field

if seqdata.flags.xdtB_ramp_up_field
    
end


%% High Field Manipulation
% High Field Manipulations before evaporation

if seqdata.flags.xdtB_pre_evap
    
end

%% Optical Evaporation
if seqdata.flags.xdtB_evap
    
end
%% High Field Manipulation
if seqdata.flags.xdtB_post_evap
    
end

%% Ramp Down
if seqdata.flags.xdtB_ramp_down_field
    
end

%% The End

timeout = curtime;
end

