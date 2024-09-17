function [timeout, I_QP, V_QP,I_shim] = xdt_load2(timein)
% Author : C Fujiwara
%
% This code loads the dipole trap from the magnetic trap.  The loading is
% done in two stages.  In the first stage, the magnetic field gradient is
% ramped down to relax the trap, while the optical powers are turned up.
%
% In the second stage the magnetic field gradient is ramped completely off
% while the feshbach field is increaesd to maintain the quantization axis.
% The optical powers are also ramped to their final values.
%
% After the optical trap has been loaded, the plug beam is turned off.

%% Flags

curtime = timein;
global seqdata;



defVar('xdt_load2_mt_decompress_time',100);
defVar('xdt_load2_mt_decompress_value',6);
defVar('xdt_load2_wait_time',200,'ms');


%% Decompress Magnetic Trap

if seqdata.flags.xdt_load2_mt_decompress     
    dispLineStr('Decompressing MT',curtime);    

    tr1 = getVar('xdt_load2_mt_decompress_time');
    i1 = getVar('xdt_load2_mt_decompress_value');
    
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    dI_QP = i1 - I_QP;    

    Cx = getVar('mt_shim_slope_x');
    Cy = getVar('mt_shim_slope_y');
    Cz = getVar('mt_shim_slope_z');

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   
    
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,i1);  
    
    V_QP = i1 * 23/30;        
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,V_QP);  
    
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
       
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    I_shim = I_s;    
end

%% Ramp on XDTs

if seqdata.flags.xdt_load2_xdt_on

    p1 = getVar('xdt1_load_power');  
    p2 = getVar('xdt2_load_power'); 
    t_xdt = getVar('xdt_load_time');
    t_xdt_hold = getVar('xdt_load2_wait_time');    

    % Turn on XDT AOMs
    setDigitalChannel(calctime(curtime,-1),'XDT TTL',0);  
    % Ramp ODT1
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        t_xdt,t_xdt,p1);     
    % Ramp ODT2
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        t_xdt,t_xdt,p2);    
    curtime = calctime(curtime,t_xdt);    
    curtime= calctime(curtime,t_xdt_hold);  
end

%% QP Off
        
if seqdata.flags.xdt_load2_mt_off
        defVar('xdt_load2_mt_off_value',[3.5]);
        i2 = getVar('xdt_load2_mt_off_value');
        
        tr1 = 100;
        I_s = [0 0 0];
        I_s(1) = getChannelValue(seqdata,'X Shim',1);
        I_s(2) = getChannelValue(seqdata,'Y Shim',1);
        I_s(3) = getChannelValue(seqdata,'Z Shim',1);
        dI_QP = i2 - i1;    

        Cx = getVar('mt_shim_slope_x');
        Cy = getVar('mt_shim_slope_y');
        Cz = getVar('mt_shim_slope_z');
        

        % Plug Shim Z Slope delta
        dCz_list = -.003;
        dCz = getScanParameter(dCz_list,seqdata.scancycle,...
            seqdata.randcyclelist,'dCz','arb.'); 

        dIx=dI_QP*Cx;
        dIy=dI_QP*Cy;
        dIz=dI_QP*(Cz+dCz);   

        % Ramp the QP Current
        AnalogFuncTo(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
            tr1,tr1,i2);  

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


        I_QP = getChannelValue(seqdata,'Coil 16',1);    
        I_s = [0 0 0];
        I_s(1) = getChannelValue(seqdata,'X Shim',1);
        I_s(2) = getChannelValue(seqdata,'Y Shim',1);
        I_s(3) = getChannelValue(seqdata,'Z Shim',1);
        I_shim = I_s;

        
       % Turn off the QP current completely.
%          curtime = AnalogFuncTo(calctime(curtime,0),'Coil 16',...
%              @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
%              tr1,tr1,0);  



    % Add bias field at same time as blah
%         AnalogFunc(calctime(curtime,0),'X Shim',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
%             50,50,I_s(1),I_s(1)-.5,3); 
%          curtime = AnalogFuncTo(calctime(curtime,0),'Coil 16',...
%                  @(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),...
%               50,50,0);  
%          
        curtime = calctime(curtime,30);

end

%% Snap on Shim Field
if seqdata.flags.xdt_load2_shim_snap
    defVar('xdt_load2_shim_ramp_time',100,'ms');
    defVar('xdt_load2_shim_ramp_delta',[.2],'A');

    % Ramp the Z shim to slowly move the magnetic zero away from the XDT
    % (vertically up)
    tr=getVar('xdt_load2_shim_ramp_time');
    dI = getVar('xdt_load2_shim_ramp_delta');
    
    curtime = AnalogFunc(calctime(curtime,0),'Z Shim',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            tr,tr,I_s(1),I_s(1)+dI,3); 
        
    if seqdata.flags.xdt_load2_plug_off            
        setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON
    end
       
 % Ramp the QP Coils off adiabatically
      curtime = AnalogFuncTo(calctime(curtime,0),'Coil 16',...
           @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
           50,50,0);  
%       curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
%           @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
%               1,1,0); 
%           
           defVar('xdt_hold_time',[0],'ms');
           curtime=calctime(curtime,getVar('xdt_hold_time'));
     curtime = calctime(curtime,10);
end

%% Snap on FB Current
if seqdata.flags.xdt_load2_fb_on
       defVar('xdt_load_fesh',5.25392,'G');    
    defVar('xdt_load_fesh_time',.1,'ms');
    fesh_current = getVar('xdt_load_fesh');
    fesh_time = getVar('xdt_load_fesh_time');

    % Ramp Feshbach field
    setDigitalChannel(calctime(curtime,-100),'fast FB Switch',1); %switch Feshbach field on
    setAnalogChannel(calctime(curtime,-95),'FB current',0.05); %switch Feshbach field closer to on
    setDigitalChannel(calctime(curtime,-100),'FB Integrator OFF',0); %switch Feshbach integrator on            
    
    % Ramp up FB Current
    AnalogFunc(calctime(curtime,0),'FB current',...
        @(t,tt,y2,y1)(ramp_minjerk(t,tt,y2,y1)),...
        fesh_time,fesh_time, fesh_current,0.05); 
    
    curtime = calctime(curtime,fesh_time);
    
end

%% Turn off plug

if seqdata.flags.xdt_load2_plug_off
            
        % Turn off the plug
        setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON

end

%% Extra Time

curtime = calctime(curtime,50); 


%% Exit

timeout = curtime;
end

