function curtime = MT_2_XDT(timein)
curtime = timein;
global seqdata;

%% Load 2


        dispLineStr('XDT Load Begin',curtime);
        seqdata.flags.mt_xdt_load2_xdt_on = 1;   
        seqdata.flags.mt_xdt_load2_zshim_ramp = 0;         

        seqdata.flags.mt_xdt_load2_plug_ramp = 1; 
        seqdata.flags.mt_xdt_load2_mt_ramp_1 = 1; 
        seqdata.flags.mt_xdt_load2_fb_ramp_1 = 1;         
       
       
        % Ramp on the XDTs
        if  seqdata.flags.mt_xdt_load2_xdt_on             
%             p1 = getVar('xdt1_load_power');  
%             p2 = getVar('xdt2_load_power'); 
%             t_xdt = getVar('xdt_load_time');
            t0=0;
            t_xdt = defVar('xdt_load_time2',[50],'ms');
             p1 = defVar('xdt1_load_power',1,'W');  
            p2 = defVar('xdt2_load_power',1,'W'); 

%             t_xdt = 50;
            setDigitalChannel(calctime(curtime,-1),'XDT TTL',0);  
            % Ramp ODT1
            AnalogFuncTo(calctime(curtime,t0),'dipoleTrap1',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_xdt,t_xdt,p1);     
            % Ramp ODT2
            AnalogFuncTo(calctime(curtime,t0),'dipoleTrap2',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_xdt,t_xdt,p2);
            curtime=calctime(curtime,t_xdt);
        end        
%                 

        % Lower and Raise the MT to get the rest of the atoms in the XDT
        % (But not for too long since majorana; is this even helpfuL/)
        if seqdata.flags.mt_xdt_load2_zshim_ramp
            t0=0;
            tR=10;
            Iz = getChannelValue(seqdata,'Z Shim',1);
            dIz = -.15;
            AnalogFunc(calctime(curtime,t0),'Z Shim',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                tR,tR,Iz,Iz+dIz,3);    
            curtime=calctime(curtime,tR);
            
            AnalogFunc(calctime(curtime,0),'Z Shim',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                tR,tR,Iz+dIz,Iz,3);    
            curtime=calctime(curtime,tR);
        end
        
        % Decrease the Plug power
        if seqdata.flags.mt_xdt_load2_plug_ramp
            t_plug_ramp=defVar('xdt_load_plug_ramp_time',10);
            plug_val=defVar('xdt_load_plug_ramp_value',800);            
           AnalogFuncTo(calctime(curtime,0),'Plug',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_plug_ramp,t_plug_ramp,plug_val); 
           
            AnalogFuncTo(calctime(curtime,2000),'Plug',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                500,500,2500);      
            curtime=calctime(curtime,t_plug_ramp);
        end      
       
        % Ramp the QP 
        if seqdata.flags.mt_xdt_load2_mt_ramp_1
            defVar('xdt_load_qp_offset_time',0);
            defVar('xdt_load_qp_ramp_time',[50]);
            defVar('xdt_load_qp_ramp_value',0);            
            
            i1 = getChannelValue(seqdata,'Coil 16',1);            
            i2 = getVar('xdt_load_qp_ramp_value');
            t_ramp_qp = getVar('xdt_load_qp_ramp_time');
            t_start_qp = getVar('xdt_load_qp_offset_time');

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
            AnalogFuncTo(calctime(curtime,t_start_qp),'Coil 16',...
                @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
                t_ramp_qp,t_ramp_qp,i2);  
            V_QP = i2*23/30;
            AnalogFuncTo(calctime(curtime,t_start_qp),'Transport FF',...
                @(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),...
                t_ramp_qp,t_ramp_qp,V_QP,2);             
            % Ramp the XYZ shims
            AnalogFunc(calctime(curtime,t_start_qp),'X Shim',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_ramp_qp,t_ramp_qp,I_s(1),I_s(1)+dIx,3); 
            AnalogFunc(calctime(curtime,t_start_qp),'Y Shim',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_ramp_qp,t_ramp_qp,I_s(2),I_s(2)+dIy,4); 
            AnalogFunc(calctime(curtime,t_start_qp),'Z Shim',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                t_ramp_qp,t_ramp_qp,I_s(3),I_s(3)+dIz,3);  
            I_QP = getChannelValue(seqdata,'Coil 16',1);    
            I_s = [0 0 0];
            I_s(1) = getChannelValue(seqdata,'X Shim',1);
            I_s(2) = getChannelValue(seqdata,'Y Shim',1);
            I_s(3) = getChannelValue(seqdata,'Z Shim',1);
            I_shim = I_s;            
            curtime=calctime(curtime,t_ramp_qp);
        end  
        
        if seqdata.flags.mt_xdt_load2_fb_ramp_1                     
            t0 = -50;
            t0= - getVar('xdt_load_qp_ramp_time');
            tr = getVar('xdt_load_qp_ramp_time');
            Ifb=2;
            AnalogFuncTo(calctime(curtime,-300),'FB Current',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            100,100,0);
            AnalogFuncTo(calctime(curtime,t0),'FB Current',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            tr,tr,Ifb);
        end            
        
        % Close the Shutter
        setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON

        
        tw = defVar('xdt_hold_time',[0],'ms');
        curtime=calctime(curtime,tw);
        
        if ~seqdata.flags.mt_2_xdt_spin_xfers
            curtime=calctime(curtime,30);
        end

    %% Spin Transfers
    seqdata.flags.QP_imaging=0;
    if seqdata.flags.mt_2_xdt_spin_xfers
       [curtime] = xdt_spin_transfers(curtime); 
    end
% curtime=calctime(curtime,100);
end

