function J=job_conducivity_ac_shake
   
% This function evaluates at the end of the job
    function jobComplete
    end



%% AC conductivity job function

 function curtime = ac_conductivity(curtime,freq,field,levitate_value,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');

        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G');  
        
        %Levitation voltage value during xdtB
        defVar('xdtB_levitate_value',levitate_value,'V');
        
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
        t_start = T*ceil((t0+mod_ramp_time)/T);
%         tvec = round(t0 + linspace(0,2*T,30),1);
%         tvec = round(t_start + [zeros(1,3) 0.25*ones(1,3) 0.5*ones(1,3) 0.75*ones(1,3) ones(1,3)]*T, 1) - mod_ramp_time;
        tvec = round(t_start + ones(2,1).*[0:0.25:2]*T, 1) - mod_ramp_time;
        tvec = tvec(:);
        defVar('conductivity_mod_time',tvec,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',uwave_freq_amp,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear Jac

% Magnetic Field (G)
B_conductivity = 201.1;
% Optical Evaporation Power (W)
power_conductivity = 0.066; 
%Evaporation Levitation Voltage
lev_conductivity = 0.11;
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);
uwave_freq_amp = 30;
% Modulation Frequencies
freq_list = 57+[-30 -20 -15 -10 -5 -2.5 0 2.5 5 10 15 20 30];
% Randomize the modulation frequencies
freq_list = freq_list(randperm(numel(freq_list)));


for ii = 1:length(freq_list)
    % Get the current modulation frequency
    f = freq_list(ii);    
    
    % Modulation Amplitude Calibration    
    %0.85um amplitude response
%     x0 = 50;
%     y0 = 0.9513;
%     aL = [9.3e-4 -1.18e-6 1.04e-9 -3.95e-13];
%     aH = [1.41e-3 -2.08e-7 2.47e-11 -1.3e-15];   

    %0.65um amplitude response
%     x0 = 50;
%     y0 = 0.9513;
%     aL = [7.87e-4 -9.73e-7 8.73e-10 -3.47e-13];
%     aH = [1.28e-3 -1.61e-7 1.56e-11 -7.28e-16]; 

    %0.65um amplitude response
    x0 = 50;
    y0 = 1.2841;
    aL = [1.06e-3 -1.31e-6 1.18e-9 -4.68e-13];
    aH = [1.73e-3 -2.17e-7 2.09e-11 -9.72e-16]; 
    
    if f<=x0
        a=aL;
    else
        a=aH;
    end        
    mod_strength = y0 + a(1)*(f-x0)^2 + a(2)*(f-x0)^4 + a(3)*(f-x0)^6 + a(4)*(f-x0)^8; 
    mod_strength = min([mod_strength 4]);

    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity(curtime,f,B_conductivity,lev_conductivity,power_conductivity,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    npt.ScanCyclesRequested = 1:18;
    npt.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
    npt.SaveDirName         = npt.JobName;    
    Jac(ii) = sequencer_job(npt);
end

%% Stripe Job
clear Jstripe

    function curtime = stripe(curtime,evap_depth,field,levitate_value)
        global seqdata        
 
        % optical Evaporation
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        %Levitation voltage value during xdtB
        defVar('xdtB_levitate_value',levitate_value,'V');
        
       % Do not run conductivity code
        seqdata.flags.lattice_conductivity_new      = 0;    
        
        % Plane Selection, do tilt
        seqdata.flags.plane_selection_dotilt        = 1;
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
            BinStripes(l) = olddata{l}.BinStripe(1);
            freqs(l) = olddata{l}.Params.f_offset;
        end
                
        % Get the mod depths, phase, and Rsquare
        phi     = [BinStripes.Phase];
        alpha   = [BinStripes.ModDepth];
        n0      = [BinStripes.FocusCenter];
%         n0     = [BinStripes.FocusCenterFit];
        
        r2      = [BinStripes.RSquareStripe];
        L       = [BinStripes.Lambda];        
        
        inds = [alpha>=0.6].*[r2>0.85];
        inds = logical(inds);
        
        [~, ind] = sort(alpha,'descend');
        inds = inds(ind);        

        % Get High qualtiy data
        if sum(inds)>0
            nSet = 110;              
            % Get data that is high quality
            Lm = L(inds);
            n0m = n0(inds);
            fold = mean(freqs(inds));
            % Restrict ourselves to data with focus position +- Lm/2
%             dN = 18;
            dN = round(Lm)/2;
            binds = logical((n0m>(nSet+dN)) + (n0m<(nSet-dN)));   
            inds = ~binds;            
            Lbar = mean(Lm(inds));
            n0bar = median(n0m(inds));            
            dN = n0bar - nSet;
%             m = 2.285/100; % planes/kHz  
%             m = 1.25/100; % planes/kHz (10.22.2024, higher QP gradient)
            m = 1/80; % planes/kHz (10.22.2024, higher QP gradient)
            
            dPlane = dN/Lbar;
            df = -dPlane/m;
            
            fnew = fold + df*0.9; 
            f_offset = round(fnew);
            save('f_offset.mat','f_offset');
            disp(fnew)
        end
    end


% The magnetic field and evaporation depth should be the same as the
% conductivityy
B = B_conductivity;
pow = 0.1;power_conductivity;
lev = lev_conductivity;


npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)stripe(curtime,pow,B,lev),...
    @main_sequence};
npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:3;
npt.JobName             = ['stripe ' ...
    num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jstripe = sequencer_job(npt);


npt2 = struct;
npt2.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)stripe(curtime,pow,B,lev),...
    @main_sequence};
npt2.ScanCyclesRequested = 1:10;
npt2.JobName             = ['stripe no feedback ' ...
    num2str(1e3*pow) ' mW'];
npt2.SaveDirName         = npt2.JobName;    
Jstripe_nofeedback = sequencer_job(npt2);
%% Normal Plane Selection

    function curtime = normal_ps(curtime,field,pow,lev)
        global seqdata        
         % Optical evaporation
        defVar('xdtB_evap_power',pow,'W');        
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        %Levitation voltage value during xdtB
        defVar('xdtB_levitate_value',lev,'V');
        
        % Do not run conductivity code
        seqdata.flags.lattice_conductivity_new      = 0;    
        % No Tilt
        seqdata.flags.plane_selection_dotilt        = 0;
        % Single plane uwave sweep
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',20,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');        
    end

% The magnetic field and evaporation depth should be the same as the
% conductivityy
B = B_conductivity;
pow = power_conductivity;
lev = lev_conductivity;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)normal_ps(curtime,B,pow,lev),...
    @main_sequence};
% npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:20;
npt.JobName             = ['calibrate ' num2str(B) 'G, ' num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jsingle = sequencer_job(npt);

%% Interleave Stripe, Single plane calibration
clear J

J = copy(Jstripe);
for kk = 1:100
    J(end+1) = copy(Jstripe);
    J(end+1) =  copy(Jstripe_nofeedback);
end

% J =  copy(Jsingle);
% for kk = 1:20
%     J(end+1) = copy(Jstripe);
%     J(end+1) =  copy(Jsingle);
% end


% J = copy(Jsingle);
% J(end+1) = copy(Jstripe);
% J(end+1) = [copy(Jac(1))];
% for kk=2:length(Jac)
%     J(end+1) = copy(Jstripe);
%     if kk == round(length(Jac)/2)
%         J(end+1) = copy(Jsingle);
%         J(end+1) = copy(Jstripe);
%     end
%     J(end+1) = copy(Jac(kk));
% end


end

