function curtime = MT_2_XDT(timein)
curtime = timein;
global seqdata;
dispLineStr('XDT Load Begin',curtime);

%% Flags and Parameters

% XDT Beams 
seqdata.flags.mt_xdt_load2_xdt_on = 1;   
defVar('xdt_load_start_time',[0],'ms');
defVar('xdt_load_ramp_time',[50],'ms');
%defVar('xdt1_load_power',1.0,'W');  
%defVar('xdt2_load_power',1.0,'W'); 

%defVar('xdt2_load_power',getVar('xdt1_load_power'),'W'); 

% Plug
seqdata.flags.mt_xdt_load2_plug_ramp = 1; 
% defVar('xdt_load_plug_start_time',0); % Specify manually
defVar('xdt_load_plug_start_time',getVar('xdt_load_start_time')+getVar('xdt_load_ramp_time'));
defVar('xdt_load_plug_ramp_time',10);
defVar('xdt_load_plug_ramp_value',800);        

% QP Currents
seqdata.flags.mt_xdt_load2_mt_ramp_1 = 1; 
%defVar('xdt_load_qp_start_time',0); % specify manually
defVar('xdt_load_qp_start_time',getVar('xdt_load_plug_ramp_time')+getVar('xdt_load_plug_start_time'));
defVar('xdt_load_qp_ramp_time',[50]);
defVar('xdt_load_qp_ramp_value',0);     

% Feshbach Current
seqdata.flags.mt_xdt_load2_fb_ramp_1 = 1;    
%defVar('xdt_load_fb_start_time',0); % specify manually
defVar('xdt_load_fb_start_time',getVar('xdt_load_qp_start_time'));
defVar('xdt_load_fb_ramp_time',getVar('xdt_load_qp_ramp_time'));
defVar('xdt_load_fb_ramp_value',[5],'G?');   

% Total Time
%defVar('xdt_load_total_time',200);% specify manually
defVar('xdt_load_total_time',getVar('xdt_load_fb_start_time')+getVar('xdt_load_fb_ramp_time'));

% The starting times are specified separately, so you can customize the
% timings without relying on sequential ramps if desired.  Note that this
% code only has a single curtime update.
        
%% RF Shielding
                 

% Ramp the RF Frequency as FB ramps up
if seqdata.flags.mt_rf_shield
    if ~ seqdata.flags.mt_rf_shield_during_xdt_load        
        setDigitalChannel(calctime(curtime,0),'RF TTL',0);    % Turn off RF
    else
        
    end
end
% 
%    if seqdata.flags.mt_rf_shield_during_xdt_load
%         % Trigger pulse duration in ms
%         dTP=0.1; 
%          % Trigger the DDS
%          DigitalPulse(calctime(curtime,t0),'DDS ADWIN Trigger',dTP,1);  
% 
%          % Increment the number of DDS sweeps
%          seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;                
%          % DDS ID for RF evaporation
%         DDS_ID=1;
% 
%         kappa=defVar('xdt_load_rf_freq_per_amp',1.4,'MHz/A_FB');
%         df = Ifb*kappa; % FB is about 1 G/A, so if we increase the 
% 
% 
%          % Define the RF sweep amd add it to the DDS sweep list
%          dT=tr;                % Duration of this sweep in ms
%          f1=getVar('RF1B_freq_5')*1e6;          % Starting Frequency in Hz
%          f2=(getVar('RF1B_freq_5')+df)*1e6;     % Ending Frequency in Hz      
%          sweep=[DDS_ID f1 f2 dT];    % Sweep data;
%          seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;
%          setDigitalChannel(calctime(curtime,t0+tr),'RF TTL',0);    % Turn off RF
%    else
%         setDigitalChannel(calctime(curtime,t0),'RF TTL',0);    % Turn off RF
%    end 
% end
%% XDT Ramp ON

% Ramp on the XDTs
if  seqdata.flags.mt_xdt_load2_xdt_on 
    tr=getVar('xdt_load_ramp_time');
    t0=getVar('xdt_load_start_time');
    setDigitalChannel(calctime(curtime,-1),'XDT TTL',0);  
    % Ramp ODT1
    AnalogFuncTo(calctime(curtime,t0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,getVar('xdt1_load_power'));     
    % Ramp ODT2
    AnalogFuncTo(calctime(curtime,t0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,getVar('xdt2_load_power'));
end      
%% Plug Ramp ON
  
% Decrease the Plug power
if seqdata.flags.mt_xdt_load2_plug_ramp
    t0=getVar('xdt_load_plug_start_time');
    tr=getVar('xdt_load_plug_ramp_time');    
    v=getVar('xdt_load_plug_ramp_value');  
   AnalogFuncTo(calctime(curtime,t0),'Plug',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,v);            
    AnalogFuncTo(calctime(curtime,2000),'Plug',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        500,500,2500);      
end      
        
%% QP Ramp Off    
% Ramp the QP 
if seqdata.flags.mt_xdt_load2_mt_ramp_1

    i1 = getChannelValue(seqdata,'Coil 16',1);            
    i2 = getVar('xdt_load_qp_ramp_value');
    tr = getVar('xdt_load_qp_ramp_time');
    t0 = getVar('xdt_load_qp_start_time');

    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    dI_QP = i2 - i1;    
    Cx = getVar('mt_shim_slope_x');
    Cy = getVar('mt_shim_slope_y');
    Cz = getVar('mt_shim_slope_z');
    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,t0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr,tr,i2);  
    V_QP = i2*23/30;
    AnalogFuncTo(calctime(curtime,t0),'Transport FF',...
        @(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),...
        tr,tr,V_QP,2);             
    % Ramp the XYZ shims
    AnalogFunc(calctime(curtime,t0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,I_s(1),I_s(1)+dIx,3); 
    AnalogFunc(calctime(curtime,t0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,I_s(2),I_s(2)+dIy,4); 
    AnalogFunc(calctime(curtime,t0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr,tr,I_s(3),I_s(3)+dIz,3);  
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    I_shim = I_s;     
    
   
end  
        
%% FB Ramp ON
 
if seqdata.flags.mt_xdt_load2_fb_ramp_1                     
    Ifb = getVar('xdt_load_fb_ramp_value');
    tr = getVar('xdt_load_fb_ramp_time');
    t0 = getVar('xdt_load_fb_start_time');   
    
    AnalogFuncTo(calctime(curtime,-300),'FB Current',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
    100,100,0);
    AnalogFuncTo(calctime(curtime,t0),'FB Current',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
    tr,tr,Ifb);              
end
     
%% Advannce time
curtime = calctime(curtime,getVar('xdt_load_total_time'));

% Close the Shutter once QP if off
setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON
%% Wait
tw = defVar('xdt_hold_time',[0],'ms');
curtime=calctime(curtime,tw);

%% Spin Transfers
if ~seqdata.flags.mt_2_xdt_spin_xfers
    curtime=calctime(curtime,30);
end


%% Spin Transfers
seqdata.flags.QP_imaging=0;
  
end

