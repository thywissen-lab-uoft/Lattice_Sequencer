function J=job_conducivity_ac_shake
   
% This function evaluates at the end of the job
    function jobComplete
    end

%% AC conductivity jobs

 function curtime = ac_conductivity(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.plane_selection.dotilt            = 0;
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction

        seqdata.flags.qgm_stripe_feedback2 = 1;
        % Define field, frequency, and evaporation depth
        defVar('conductivity_FB_field',field,'G');       
        defVar('conductivity_mod_freq',freq,'Hz');          
        defVar('xdt_evap1_power',evap_depth,'W');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');
        defVar('f_amplitude',uwave_freq_amp,'kHz');
%getVar('conductivity_ODT2_mod_amp')
        d = load('f_offset.mat');
        f_offset = d.f_offset - 20;        
        defVar('f_offset',f_offset,'kHz');

        % Modulation time vector
        t0 = 50;
        T = 1e3/freq;
        tvec = round(t0 + linspace(0,2*T,30),1);
        defVar('conductivity_mod_time',tvec,'ms');      
 end

clear Jac



B = 190;
pow = 0.057;   
% mod_strength=2;
mod_ramp_time = 50;
uwave_freq_amp = 45;

% var_list = [20:20:300];[5 10 25 50 150 300 600];
var_list = [20 30 40:5:80 90 100 110 120 140];
var_list = var_list(randperm(numel(var_list)));


for ii = 1:length(var_list)

    f = var_list(ii);
    
    if f < 20
        mod_strength = 0.8;
    elseif f >= 20 && f <= 56
        mod_strength = -0.0168*f + 1.015;
    elseif f > 56 && f <=135
        mod_strength = (1.597e-4)*(f+53.085)^2 - 1.827;
    elseif f > 135
        mod_strength = 4;
    end
    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ac_conductivity(curtime,f,B,pow,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    npt.ScanCyclesRequested = 1:30;
    npt.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B) 'G,' num2str(1e3*pow) ' mW ' num2str(mod_strength) ' amp, ' num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
    npt.SaveDirName         = npt.JobName;    
    Jac(ii) = sequencer_job(npt);
end

%% Stripe Phase Job
clear Jstripe

    function curtime = stripe(curtime,evap_depth)
        global seqdata
        seqdata.flags.conductivity_ODT1_mode            = 0; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 0; % 0:OFF, 1:SINE, 2:DC       
        defVar('xdt_evap1_power',evap_depth,'G');    
        seqdata.flags.plane_selection.dotilt = 1;
        defVar('conductivity_mod_time',50,'ms');  
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');
        seqdata.flags.qgm_stripe_feedback2 = 1;
    end

    function feedback_stripe
        global seqdata
        if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ...
                ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
            warning('No feedback directory to run on');
        return;    
        end
        % Get Recent Bin Stripe Data
        L = 3;
        olddata = getRecentGuiData(L); 
        freqs = zeros(3,1);
        for l=1:L
            BinStripes(l) = olddata{l}.BinStripe;
            freqs(l) = olddata{l}.Params.f_offset;
        end
        
%         freqs = [Params.qgm_plane_uwave_frequency_offset];
        
        % Get the mod depths, phase, and Rsquare
        phi     = [BinStripes.Phase];
        alpha   = [BinStripes.ModDepth];
        n0      = [BinStripes.FocusCenter];
        r2      = [BinStripes.RSquareStripe];
        L       = [BinStripes.Lambda];
        
        
        inds = [alpha>=0.8].*[r2>0.85];
        inds = logical(inds);
        
        [~, ind] = sort(alpha,'descend');
        inds = inds(ind);        

        % Get High qualtiy data
        if sum(inds)>0
            nSet = 95;  
            
            % Get data that is high quality
            Lm = L(inds);
            n0m = n0(inds);
            fold = median(freqs(inds));

            % Restrict ourselves to data with focus position +- 18
%             binds = logical((n0m>(nSet+20)) + (n0m<(nSet-20)));   
            binds = logical((n0m>(nSet+30)) + (n0m<(nSet-30)));            

            inds = ~binds;
            
            Lbar = mean(Lm(inds));
            n0bar = mean(n0m(inds));            
            dN = n0bar - nSet;
            m = 2.285/100; % planes/kHz            
            df = -(dN/Lbar)/m;            
            fnew = fold + df*0.9; 
            f_offset = round(fnew);
            save('f_offset.mat','f_offset');
            disp(fnew)
        end
        

        % wait a few seconds for stripe analysis to finish?
        % load in the 3 most recent stripe data
        % use this info to define a new frequency in a file
    end

% B = 195;
pow = 0.110;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)stripe(curtime,pow),...
    @main_sequence};
npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:3;
npt.JobName             = ['stripe ' ...
    num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jstripe = sequencer_job(npt);

%% Normal Plane Select Job

    function curtime = normal_ps(curtime,field,pow,uwave_freq_amp)
        global seqdata
        
        defVar('conductivity_FB_field',field,'G');       
        defVar('xdt_evap1_power',pow,'G');  
        defVar('f_amplitude',uwave_freq_amp,'kHz');

        seqdata.flags.conductivity_ODT1_mode = 0; 
        seqdata.flags.conductivity_ODT2_mode = 0; 
        seqdata.flags.plane_selection.dotilt = 0;
        defVar('conductivity_mod_time',50,'ms');  
        
        
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');
        seqdata.flags.qgm_stripe_feedback2 = 1;
    end

B = 190;
pow = 0.057;
uwave_freq_amp = 15;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)normal_ps(curtime,B,pow,uwave_freq_amp),...
    @main_sequence};
% npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:20;
npt.JobName             = ['calibrate ' num2str(B) 'G, ' num2str(1e3*pow) ' mW, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
npt.SaveDirName         = npt.JobName;    
Jsingle = sequencer_job(npt);

%% Interleave Stripe, Single plane calibration, and ac shake
% clear J
% J = [Jstripe Jsingle];
% for kk=1:length(Jac)
%     J(end+1) = Jac(kk);
%     J(end+1) = Jstripe;
%     J(end+1) = Jsingle;
% end
 
%% Interleave Stripe, Single plane calibration
% clear J
% 
% N = 50; % Number of total repitions
% J = [Jstripe];
% for kk=1:N
%     J(end+1) = copy(Jsingle);
%     J(end+1) = copy(Jstripe);
% %     J(end+1) = Jsingle;
% %     J(end+1) = Jstripe;
% end

%% Interleave Stripe, Single plane calibration
clear J

J = copy(Jsingle);
J(end+1) = copy(Jstripe);
J(end+1) = [copy(Jac(1))];
for kk=2:length(Jac)
    J(end+1) = copy(Jstripe);
    if kk == round(length(Jac)/2)
        J(end+1) = copy(Jsingle);
        J(end+1) = copy(Jstripe);
    end
    J(end+1) = copy(Jac(kk));
end
end

