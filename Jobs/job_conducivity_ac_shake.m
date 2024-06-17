function J=job_conducivity_ac_shake
   
% This function evaluates at the end of the job
    function jobComplete
    end



%% AC conductivity job function

 function curtime = ac_conductivity(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');

        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G');   
        seqdata.flags.lattice_conductivity_new      = 1;    

        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');        
        
        % Modulation time
        t0 = 50;T = 1e3/freq;
        tvec = round(t0 + linspace(0,2*T,30),1);
        defVar('conductivity_mod_time',tvec,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection.dotilt            = 0;
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',uwave_freq_amp,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset - 0*20;        
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear Jac

% Magnetic Field (G)
B_conductivity = 200.8;
% Optical Evaporation Power (W)
power_conductivity = 0.077;   
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);
uwave_freq_amp = 15;
% Modulation Frequencies
freq_list = [20 30 40:5:80 90 100 62 57 52 67];
% Randomize the modulation frequencies
freq_list = freq_list(randperm(numel(freq_list)));


for ii = 1:length(freq_list)
    % Get the current modulation frequency
    f = freq_list(ii);    
    
    % Modulation Amplitude Calibration    
    x0 = 50;
    y0 = 0.9513;
    aL = [7.87e-4 -9.73e-7 8.73e-10 -3.47e-13];
    aH = [1.28e-3 -1.61e-7 1.56e-11 -7.28e-16];    
    if f<=x0
        a=aL;
    else
        a=aH;
    end        
    mod_strength = y0 + a(1)*(f-x0)^2 + a(2)*(f-x0)^4 + a(3)*(f-x0)^6 + a(4)*(f-x0)^8; 
    mod_strength = min([mod_strength 4]);

    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity(curtime,f,B_conductivity,power_conductivity,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    npt.ScanCyclesRequested = 1:30;
    npt.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
    npt.SaveDirName         = npt.JobName;    
    Jac(ii) = sequencer_job(npt);
end

%% Stripe Job
clear Jstripe

    function curtime = stripe(curtime,evap_depth,field)
        global seqdata        
 
        % optical Evaporation
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        
       % Do not run conductivity code
        seqdata.flags.lattice_conductivity_new      = 0;    
        
        % Plane Selection, do tilt
        seqdata.flags.plane_selection.dotilt = 1;
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');        
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
            fold = mean(freqs(inds));
            % Restrict ourselves to data with focus position +- 18
            dN = 18;
            dN = 30;
            binds = logical((n0m>(nSet+dN)) + (n0m<(nSet-dN)));   
            inds = ~binds;            
            Lbar = mean(Lm(inds));
            n0bar = mean(n0m(inds));            
            dN = n0bar - nSet;
            m = 2.285/100; % planes/kHz            
            df = -(dN/Lbar)/m;            
            fnew = fold + df*0.8; 
            f_offset = round(fnew);
            save('f_offset.mat','f_offset');
            disp(fnew)
        end
    end


% The magnetic field and evaporation depth should be the same as the
% conductivityy
B = B_conductivity;
pow = 0.1;


npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)stripe(curtime,pow,B),...
    @main_sequence};
npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:3;
npt.JobName             = ['stripe ' ...
    num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jstripe = sequencer_job(npt);

%% Normal Plane Selection

    function curtime = normal_ps(curtime,field,pow)
        global seqdata        
         % Optical evaporation
        defVar('xdtB_evap_power',pow,'W');        
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        % Do not run conductivity code
        seqdata.flags.lattice_conductivity_new      = 0;    
        % No Tilt
        seqdata.flags.plane_selection.dotilt = 0;
        % Single plane uwave sweep
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',15,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');        
    end

% The magnetic field and evaporation depth should be the same as the
% conductivityy
B = B_conductivity;
pow = power_conductivity;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)normal_ps(curtime,B,pow),...
    @main_sequence};
% npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:20;
npt.JobName             = ['calibrate ' num2str(B) 'G, ' num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jsingle = sequencer_job(npt);

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

