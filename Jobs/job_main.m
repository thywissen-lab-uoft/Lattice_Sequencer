function J=job_main

npt = struct;
npt.lattice_load_feshbach_field = 201;
%%
J_stripe = job_stripe_feedback(npt);
J_focus = job_single_plane_focus_feedback(npt);
J_single_plane = job_single_plane(npt);

%% Interleave Stripe, Single plane calibration
clear J
Nrpt = 10;

J = J_focus;
for kk=2:Nrpt
    J(end+1) = copy(J_stripe);
    J(end+1) = copy(J_focus);
    J(end+1) = copy(J_single_plane);
end

end

