function J=job_conducivity_ac_shake
   
% This function evaluates at the end of the job
    function jobComplete
    end

%% AC conductivity jobs

 function curtime = ac_conductivity(curtime,freq,field,evap_depth)
        global seqdata;        
        % Define field, frequency, and evaporation depth
        defVar('conductivity_FB_field',field,'G');       
        defVar('conductivity_mod_freq',freq,'Hz');          
        defVar('xdt_evap1_power',evap_depth,'W');
        
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');

        % Modulation time vector
        t0 = 50;
        T = 1e3/freq;
        tvec = round(t0 + linspace(0,3*T,25),1);
        defVar('conductivity_mod_time',tvec,'ms');      
 end

clear Jac

var_list = [20:10:160];
var_list = var_list(randperm(numel(var_list)));
B = 195;
pow = 0.085;   

for ii = 1:length(var_list)
    f = var_list(ii); 
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ac_conductivity(curtime,f,B,pow),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    npt.ScanCyclesRequested = 1:25;
    npt.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B) 'G,' num2str(1e3*pow) ' mW'];
    npt.SaveDirName         = npt.JobName;    
    Jac(ii) = sequencer_job(npt);
end

%% Stripe Phase Job
clear Jstripe

    function curtime = stripe(curtime,field,evap_depth)
        global seqdata
        defVar('conductivity_FB_field',field,'G');       
        defVar('xdt_evap1_power',evap_depth,'G');       

        seqdata.flags.conductivity_ODT1_mode = 0; 
        seqdata.flags.conductivity_ODT2_mode = 0; 
        seqdata.flags.plane_selection.dotilt = 1;
        defVar('conductivity_mod_time',0,'ms');   
        
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
            freqs(l) = olddata{l}.Params.qgm_plane_uwave_frequency_offset;
        end
        
%         freqs = [Params.qgm_plane_uwave_frequency_offset];
        fold = median(freqs);
        
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
        
        if sum(inds)>0
            nSet = 85;            
            Lbar = mean(L(inds));
            n0bar = median(n0(inds));            
            disp('hi ben');
            dN = n0bar - nSet;
            m = 2.285/100; % planes/kHz            
            df = -(dN/Lbar)/m;            
            fnew = fold + df; 
            f_offset = round(fnew);
            save('f_offset.mat','f_offset');
        end
        

        % wait a few seconds for stripe analysis to finish?
        % load in the 3 most recent stripe data
        % use this info to define a new frequency in a file
    end

B = 195;
pow = 0.120;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)stripe(curtime,B,pow),...
    @main_sequence};
npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:2;
npt.JobName             = ['stripe ' ...
    num2str(B) 'G,' num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jstripe = sequencer_job(npt);

%% Normal Plane Select Job

    function curtime = normal_ps(curtime,field,evap_depth)
        global seqdata
        defVar('conductivity_FB_field',field,'G');       
        defVar('xdt_evap1_power',evap_depth,'G');       

        seqdata.flags.conductivity_ODT1_mode = 0; 
        seqdata.flags.conductivity_ODT2_mode = 0; 
        seqdata.flags.plane_selection.dotilt = 0;
        defVar('conductivity_mod_time',0,'ms');   
        
        d = load('f_offset.mat');
        f_offset = d.f_offset;        
        defVar('f_offset',f_offset,'kHz');
    end

B = 195;
pow = 0.1;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)normal_ps(curtime,B,pow),...
    @main_sequence};
% npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:2;
npt.JobName             = ['calibrate ' num2str(B) 'G,' num2str(1e3*pow) ' mW'];
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
clear J

N = 200; % Number of total repitions
J = [Jstripe];
Jsingle.ScanCyclesRequested = 1:1;
for kk=1:N
    J(end+1) = copy(Jsingle);
    J(end+1) = copy(Jstripe);
%     J(end+1) = Jsingle;
%     J(end+1) = Jstripe;
end


end

