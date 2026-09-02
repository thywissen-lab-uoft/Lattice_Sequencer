function [curtime, I_QP, V_QP,I_shim] = xdt_evap_stage_1(timein, I_QP, V_QP,I_shim)

curtime = timein;
global seqdata;

%% Turn on levitation

if seqdata.flags.xdt_levitate

    tr = getVar('xdt_levitate_ramptime');   
    
     %%%%%%%% Set switches for reverse QP coils %%%%%%%%%
    C15_zero_value = 0.062;
    tozero_ramp_time = 50;

    % Ramp C16 and C15 to off values
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tozero_ramp_time,tozero_ramp_time,0);    
    AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tozero_ramp_time,tozero_ramp_time,C15_zero_value,1); 
    curtime = calctime(curtime,tozero_ramp_time);

    % Wait for PID to settle
    curtime = calctime(curtime,50);

    % Close 15/16 Gate source to reverse current through QP coils
    t1516 = 10;    
    curtime = AnalogFuncTo(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            t1516, t1516, 0);         
    setDigitalChannel(curtime,'Coil 16 TTL',1);     % Turn of 16 (obsolete?)
    curtime = calctime(curtime,10);
    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage For levitation, need only 2V
    QP_FFValue = 4; 
    tFF = 100;
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFF,tFF,QP_FFValue);
    curtime = calctime(curtime,tFF);    
    % Ramp Coil 15
    I_QP_rev = getVar('xdt_levitate_current');
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,I_QP_rev,2); 
end

 %% Ramp to Sympathetic Cooling Regime
% Ramp the optical powers to their sympathetic values

% if seqdata.flags.CDT_evap ==1 && seqdata.flags.xdt_ramp2sympathetic
if seqdata.flags.xdt_ramp2sympathetic
    % Pre ramp powers to sympathtetic cooling regime
    logNewSection('Ramp to sympathetic regime',curtime);
    % Powers to ramp to
    Ps = getVar('xdt_evap_sympathetic_power');
    Ps1      = Ps;getVar('xdt_evap_sympathetic_power1');
    Ps2      = Ps;getVar('xdt_evap_sympathetic_power2');
    % Duration of ramp
    tr = getVar('xdt_evap_sympathetic_ramp_time');
    logText(['     Ramp Time (ms) : ' num2str(tr)]);      
    logText(['     XDT 1 (W)      : ' num2str(Ps)]);
    logText(['     XDT 2 (W)      : ' num2str(Ps)]); 
    % Ramp optical power requests to sympathetic regime
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tr,tr,Ps1);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tr,tr,Ps2);
    curtime = calctime(curtime,tr);
    
    defVar('symp_ramp_hold',[0],'ms');
    curtime = calctime(curtime,getVar('symp_ramp_hold'));

    
end
%% CDT evap
% Perform the first stage of optical evaporation

if ( seqdata.flags.CDT_evap == 1 )
    logNewSection('Optical evaporation 1',curtime);
    
    % Get Variables
    evap_time   = getVar('xdt_evap1_time');
    evap_tau    = getVar('xdt_evap1_time')/getVar('xdt_evap1_tau_fraction');
    p_end       = getVar('xdt_evap1_power');
    p_end1      = getVar('xdt_evap1_power1');p_end;
    p_end2      = getVar('xdt_evap1_power2');p_end;

    % Display Settings
    logText(' Performing exponential evaporation');
    logText(['     Evap Time (ms) : ' num2str(evap_time)]);
    logText(['     tau       (ms) : ' num2str(evap_tau)]);
    logText(['     XDT1 end   (W) : ' num2str(p_end)]);
    logText(['     XDT2 end   (W) : ' num2str(p_end)]);

    % Ramp Function
    evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1)); 
    evap_time_evaluate = evap_time; 
% 
   % This allows you to look during various times during evaporation
    % evap eval power
%     defVar('xdt_evap_eval_time',[24000],'ms');
%     evap_time_evaluate = getVar('xdt_evap_eval_time');
    
    final_p = evap_exp_ramp(evap_time_evaluate,evap_time,evap_tau,p_end,getVar('xdt_evap_sympathetic_power'));
    defVar('xdt_final_power',final_p);
%      

    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end1);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end2);
    
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

%% Turn off levitation

if seqdata.flags.xdt_levitate_off  
    trQP = getVar('xdt_levitate_off_ramptime');

    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),trQP,trQP,0,2);
      
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
             5,5,0); 
    % Go back to "normal" configuration
    curtime = calctime(curtime,10);
    % Turn off reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',0);
    curtime = calctime(curtime,10);
    % Turn on 15/16 switch
    curtime = AnalogFuncTo(calctime(curtime,0),'15/16 GS',...
         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
             10,10,9,1);              
    curtime = calctime(curtime,10); 
end


end

