function J=job_main

npt = struct;
npt.lattice_load_feshbach_field = 201;

%% Flags

doJob_warmup            = 0;
doJob_stabilize         = 0;
doJob_single_plane      = 1;
doJob_Conductivity      = 0;

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
    clear J
    J(1)=J_focus;
    for rr=1:length(J_ac)
        J(end+1) = J_ac(rr);
        J(end+1) = J_stripe;
        J(end+1) = J_focus;
    end
end

end

