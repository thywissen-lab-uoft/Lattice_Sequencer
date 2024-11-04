function [curtime, I_QP, V_QP,I_shim] = xdt_evap_stage_1(timein, I_QP, V_QP,I_shim)

curtime = timein;
global seqdata;

 %% Ramp to Sympathetic Cooling Regime
% Ramp the optical powers to their sympathetic values

if seqdata.flags.CDT_evap ==1 && seqdata.flags.xdt_ramp2sympathetic
    % Pre ramp powers to sympathtetic cooling regime
    logNewSection('Ramp to sympathetic regime',curtime);
    % Powers to ramp to
    Ps = getVar('xdt_evap_sympathetic_power');
    % Duration of ramp
    tr = getVar('xdt_evap_sympathetic_ramp_time');
    disp(['     Ramp Time (ms) : ' num2str(tr)]);      
    disp(['     XDT 1 (W)      : ' num2str(Ps)]);
    disp(['     XDT 2 (W)      : ' num2str(Ps)]); 
    % Ramp optical power requests to sympathetic regime
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tr,tr,Ps);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tr,tr,Ps);
    curtime = calctime(curtime,tr);
end
%% CDT evap
% Perform the first stage of optical evaporation

if ( seqdata.flags.CDT_evap == 1 )
    logNewSection('Optical evaporation 1',curtime);
    
    % Get Variables
    evap_time   = getVar('xdt_evap1_time');
    evap_tau    = getVar('xdt_evap1_time')/getVar('xdt_evap1_tau_fraction');
    p_end       = getVar('xdt_evap1_power');

    % Display Settings
    disp(' Performing exponential evaporation');
    disp(['     Evap Time (ms) : ' num2str(evap_time)]);
    disp(['     tau       (ms) : ' num2str(evap_tau)]);
    disp(['     XDT1 end   (W) : ' num2str(p_end)]);
    disp(['     XDT2 end   (W) : ' num2str(p_end)]);

    % Ramp Function
    evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    
    evap_time_evaluate = evap_time;       

    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    
    % Advance time
    curtime = calctime(curtime,evap_time_evaluate);   
end


%% Ramp Dipole After Evap
% Compress XDT after Stage 2 optical evaporation

if seqdata.flags.xdt_ramp_power_end 
    logNewSection('Ramping XDT Power Back Up',curtime); 

    Pr = getVar('xdt_evap_end_ramp_power');
    Pr2 = getVar('xdt_evap_end_ramp_power2');
    tr = getVar('xdt_evap_end_ramp_time');   
    
    % Ramp ODTs
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr2);
    curtime = calctime(curtime,tr);
  
    % Hold after ramping
    th = getVar('xdt_evap_end_ramp_hold');
    curtime = calctime(curtime,th);
end


end

