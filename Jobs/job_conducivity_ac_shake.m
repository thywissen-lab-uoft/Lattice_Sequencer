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
        defVar('Evap_End_Power',evap_depth,'W');
        
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
    npt.SequenceFunctions   = {@main_settings,@(curtime) ac_conductivity(curtime,x),@main_sequence};
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
        defVar('Evap_End_Power',evap_depth,'G');       

        seqdata.flags.conductivity_ODT1_mode = 0; 
        seqdata.flags.conductivity_ODT2_mode = 0; 
        seqdata.flags.plane_selection.dotilt = 1;
        defVar('conductivity_mod_time',0,'ms');   
    end

    function feedback_stripe
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
npt.ScanCyclesRequested = 1:3;
npt.JobName             = ['stripe ' ...
    num2str(B) 'G,' num2str(1e3*pow) ' mW'];
npt.SaveDirName         = npt.JobName;    
Jstripe = sequencer_job(npt);

%% Stripe Phase Job

    function curtime = start_conductivity(curtime,field,evap_depth)
        global seqdata
        defVar('conductivity_FB_field',field,'G');       
        defVar('Evap_End_Power',evap_depth,'G');       

        seqdata.flags.conductivity_ODT1_mode = 0; 
        seqdata.flags.conductivity_ODT2_mode = 0; 
        seqdata.flags.plane_selection.dotilt = 0;
        defVar('conductivity_mod_time',0,'ms');   
    end

B = 195;
pow = 0.085;

npt = struct;
npt.SequenceFunctions   = {...
    @main_settings,...
    @(curtime)start_conductivity(curtime,B,pow),...
    @main_sequence};
npt.JobCompleteFcn      = @feedback_stripe;
npt.ScanCyclesRequested = 1:3;
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

N = 10; % Number of total repitions
J = [Jstripe];
Jsingle.ScanCyclesRequested = 1:10;
for kk=1:N
    J(end+1) = Jsingle;
    J(end+1) = Jstripe;
end


end

