
%------
function timeout = xdt_load(timein)
curtime = timein;
global seqdata;

logNewSection('Dipole Loading',curtime);

seqdata.flags.xdt_load_ramp_odt1    = 1;   % Ramp on the XDTs
seqdata.flags.xdt_load_ramp_odt2    = 1;   % Ramp on the XDTs
seqdata.flags.xdt_load_plug_off     = 1;    % Turn off the plug
seqdata.flags.xdt_load_ramp_qp_1    = 1;   % Lower Rb into XDT
seqdata.flags.xdt_load_ramp_qp_2    = 1;   % Lower K into XDT
seqdata.flags.xdt_load_ramp_bias    = 1;   % Ramp off QP and raise bias field
seqdata.flags.xdt_load_insitu_img   = 0;
seqdata.flags.xdt_load_hold =       0;
%% ODT Ramps

defVar('xdt_load_odt1_power',1.5,'W');
defVar('xdt_load_odt1_start_time',0,'ms');
defVar('xdt_load_odt1_ramp_time',300,'ms');
defVar('xdt_load_odt2_power',1.5,'W');
defVar('xdt_load_odt2_start_time',0,'ms');
defVar('xdt_load_odt2_ramp_time',300,'ms');

% Enable regulation of XDT
setDigitalChannel(calctime(curtime,0),'XDT TTL',0); 

if seqdata.flags.xdt_load_ramp_odt1
    t0_odt1 = getVar('xdt_load_odt1_start_time');
    tr_odt1 = getVar('xdt_load_odt1_ramp_time');
    p_odt1 = getVar('xdt_load_odt1_power');
    AnalogFunc(calctime(curtime,t0_odt1),'dipoleTrap1',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr_odt1,tr_odt1,0,p_odt1);
end

if seqdata.flags.xdt_load_ramp_odt2
    t0_odt2 = getVar('xdt_load_odt2_start_time');
    tr_odt2 = getVar('xdt_load_odt2_ramp_time');
    p_odt2 = getVar('xdt_load_odt1_power');
    AnalogFunc(calctime(curtime,t0_odt2),'dipoleTrap2',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr_odt2,tr_odt2,0,p_odt2);
end

%% QP Ramp 1
defVar('xdt_load_qp_ramp_time_1',300,'ms');
defVar('xdt_load_qp_val_1',5,'A');5;

if seqdata.flags.xdt_load_ramp_qp_1 
    tr1 = getVar('xdt_load_qp_ramp_time_1');
    i1 = getVar('xdt_load_qp_val_1');
    
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);

    dI_QP = i1 - I_QP;    
    
    % Calculate the change in shim currents    
    Cx = -0.0507;Cy = 0.0025;Cz = 0.014;

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   
    
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,i1);  
    
    % Ramp the XYZ shims
    AnalogFunc(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(1),I_s(1)+dIx,3); 
    AnalogFunc(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(2),I_s(2)+dIy,4); 
    AnalogFunc(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(3),I_s(3)+dIz,3);  
    curtime = calctime(curtime,tr1);
end
%% QP Ramp 2
defVar('xdt_load_qp_ramp_time_2',200,'ms');
defVar('xdt_load_qp_val_2',0,'A');


if seqdata.flags.xdt_load_ramp_qp_2
    tr2 = getVar('xdt_load_qp_ramp_time_2');
    i2 = getVar('xdt_load_qp_val_2');
    
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    dI_QP = i2 - I_QP;    
    
    % Calculate the change in shim currents    
    Cx = -0.0507;Cy = 0.0025;Cz = 0.012;

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=.2;dI_QP*Cz;   
    
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr2,tr2,i2);  
    
    % Ramp the XYZ shims
    AnalogFunc(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr2,tr2,I_s(1),I_s(1)+dIx,3); 
    AnalogFunc(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr2,tr2,I_s(2),I_s(2)+dIy,4); 
    AnalogFunc(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr2,tr2,I_s(3),I_s(3)+dIz,3);  
    curtime = calctime(curtime,tr2);
    
  t_ff_off = 50;
      AnalogFunc(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        t_ff_off,t_ff_off,0,-2,2); 
%     curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         t_ff_off,t_ff_off,20,0,2);    

end
%% Ramp
% Diabatically turn on a projection field
% To make 
if seqdata.flags.xdt_load_ramp_bias
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
%     I_FB_set = 5.25392;
    
    % Diabatically ramp up Y shim (along plug) to establish a quantization
    % field, atoms not currently in the XDT will shuttle over.
    dIy = 2;
    AnalogFunc(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        50,50,I_s(2),I_s(2)+dIy,4); 
    curtime = calctime(curtime,50);  
%     
%     
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%
%     % Field Sweep settings
%     %%%%%%%%%%%%%%%%%%%%%%%        
%     % Center feshbach field
%     mean_field_list =5;
%     mean_field = getScanParameter(mean_field_list,seqdata.scancycle,...
%     seqdata.randcyclelist,'Rb_Transfer_Field','G');
% 
%     clear('ramp');
%     shim_ramptime_list = [50];
%     shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
% 
%     getChannelValue(seqdata,'X Shim',1,0);
%     getChannelValue(seqdata,'Y Shim',1,0);
%     getChannelValue(seqdata,'Z Shim',1,0);
% 
%     % Ramp shims to the zero condition
%     ramp = struct;
%     ramp.shim_ramptime = shim_ramptime;
%     ramp.shim_ramp_delay = 0; 
%     ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
%     %         ramp.yshim_final = seqdata.params.shim_zero(2);
%     %         ramp.zshim_final = seqdata.params.shim_zero(3);        
%     % Ramp FB to initial magnetic field
%     fb_ramp_time = 50;
%     ramp.fesh_ramptime = fb_ramp_time;
%     ramp.fesh_ramp_delay = 0;
%     ramp.fesh_final = mean_field; %22.6
%     ramp.settling_time = 0;
% curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
%  
%     
%     I_s(2) = getChannelValue(seqdata,'Y Shim',1);
%     I_s(3) = getChannelValue(seqdata,'Z Shim',1);
% 
%     AnalogFunc(calctime(curtime,0),'Y Shim',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         10,10,I_s(2),seqdata.params.shim_zero(2),4); 
%     AnalogFunc(calctime(curtime,0),'Z Shim',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         10,10,I_s(3),seqdata.params.shim_zero(3),3);  
%     curtime = calctime(curtime,50);  
end
%% Plug Off

if seqdata.flags.xdt_load_plug_off
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON
end      

%% Hold Time

if seqdata.flags.xdt_load_hold
   curtime = calctime(curtime,100); 
end

logNewSection('xdt load is onde',curtime);
%% Output
timeout = curtime;
end
