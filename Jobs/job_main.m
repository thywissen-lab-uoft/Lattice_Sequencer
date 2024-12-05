function J=job_main

npt = struct;
npt.lattice_load_feshbach_field = 201.1;

%% Flags
%Make sure the ixon GUI is on auto camera config if swapping between
%different lattice_fluor_multi_mode for different jobs

doJob_warmup            = 0;
doJob_stabilize         = 0;
doJob_single_plane      = 0;
doJob_Conductivity      = 1;
doJob_Conductivity_single_freq_long_time = 0;
doJob_Conductivity_Vary_Force=0;
doJob_peakCond_v_U      = 0;
doJob_peakCond_v_T      = 1;
doJob_peakCond_v_amp    = 0;
doJob_peakCond_v_T_evap = 0;
%%

J_stripe            = job_stripe_feedback(npt);
J_focus             = job_single_plane_focus_feedback(npt);
J_single_plane      = job_single_plane(npt);

%% Warm Up Jobs
% Use the stripe but turn off the feedback, warm up for N=30?
if doJob_warmup
    
end
%% Stabilize Job
% Use stripe + focus only
if doJob_stabilize
    
end
%% Single Plane Statistics
% Focus+Stripe+Single_Plane

if doJob_single_plane
    clear J
    Nrpt = 20;

    J = J_focus;
    for kk=2:Nrpt
        J(end+1) = copy(J_stripe);
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_single_plane);
    end
end

%% AC Conductivity
if doJob_Conductivity
    J_ac = job_conducivity_ac_shake;
%     J_peak = job_peakcond_v_temp;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_ac)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_ac(rr));
        J(end+1) = copy(J_stripe);
    end
end
%% AC Conductivity Linearity Check
if doJob_Conductivity_Vary_Force
    J_ac_linearity = job_conductivity_vary_force;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_ac_linearity)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_ac_linearity(rr));
        J(end+1) = copy(J_stripe);
    end
end

%% AC Conductivity Single Frequency long time

if doJob_Conductivity_single_freq_long_time
    J_freq=job_conductivity_one_freq;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_freq)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_freq(rr));
        J(end+1) = copy(J_stripe);
    end
end

%% AC conductivity single freq, vary U
if doJob_peakCond_v_U
    J_pvU = job_peakcond_v_U;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_pvU)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_pvU(rr));
        J(end+1) = copy(J_stripe);
    end
end

%% AC conductivity single freq, vary U
if doJob_peakCond_v_T
    J_pvU = job_peakcond_v_temp;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_pvU)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_pvU(rr));
        J(end+1) = copy(J_stripe);
    end
end

%% AC conductivity single freq, vary mod amp
if doJob_peakCond_v_amp
    J_pvAmp = job_peakcond_v_amp;
%     J_peak = job_peakcond_v_temp;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_pvAmp)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_pvAmp(rr));
        J(end+1) = copy(J_stripe);
    end
end

%% AC conductivity single freq, vary T with evap depth
if doJob_peakCond_v_T_evap
    J_pvdepth = job_peakcond_v_temp_evap;
    clear J
    J(1)=copy(J_stripe);
    for rr=1:length(J_pvdepth)
        J(end+1) = copy(J_focus);
        J(end+1) = copy(J_pvdepth(rr));
        J(end+1) = copy(J_stripe);
    end
end

end

