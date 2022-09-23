function [curtime] = lattice_conductivity(timein)

global seqdata

curtime = timein;

 time_in_cond = curtime;
    Post_Mod_Lat_Ramp = 0;
    Lattices_to_Pin = 1;
    ramp_up_FB_after_evap = 0;
    ramp_up_FB_during_mod_ramp = 0;
    ramp_up_FB_after_latt_loading = 0;
    do_RF_spectroscopy_in_lattice = 0;         %do spectroscopy with DDS after lattice loading
    DMD_on = 1;
    enable_modulation = 0;
    kick_lattice = 0;
    
    adiabatic_ramp_down = 0;
%     compensation_in_modulation = 0;   
    

% ramp FB field up to conductivity modulation
    if ramp_up_FB_after_evap
        clear('ramp');      
        ramp.xshim_final_list = 0.1585; %0.1585;
        ramp.xshim_final = getScanParameter(ramp.xshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'xshim');
        ramp.yshim_final_list = -0.0432;  %-0.0432;
        ramp.yshim_final = getScanParameter(ramp.yshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'yshim');
        ramp.zshim_final_list = -0.1354;-0.0865;  %-0.0865;
        ramp.zshim_final = getScanParameter(ramp.zshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'zshim');     
        
        shiftfb_list = [200];%[0,20,60,100,140,180,200];
        shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        

        FB_Ramp_Time_List = [250];
        FB_Ramp_Time = getScanParameter(FB_Ramp_Time_List,seqdata.scancycle,seqdata.randcyclelist,'FB_Ramp_Time');
        ramp.fesh_ramptime = FB_Ramp_Time; %150
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = shiftfb-0.06;                
        ramp.settling_time = 50;
        ramp.QP_ramptime = FB_Ramp_Time;
        ramp.QP_ramp_delay = -0;
        QP_final_val_list = [0.15];
        ramp.QP_final =  getScanParameter(QP_final_val_list,seqdata.scancycle,seqdata.randcyclelist,'QP_final_val'); 
%         ramp.settling_time = 0; %200    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
%         clear('rampdown');
%         rampdown.QP_ramptime = 50;
%         rampdown.QP_ramp_delay = -0;
%         rampdown.QP_final = 0;      
%         rampdown.settling_time = 0;
% curtime = ramp_bias_fields(calctime(curtime,-100), rampdown);


% % 
% %         conductivityfb_list = [200];
% %         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
% %         clear('ramp');
% %         ramp.xshim_final = 0.1585;
% %         ramp.yshim_final = -0.0432;
% %         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
% %         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
% %         ramp.fesh_ramptime = 0.2;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = conductivityfb-0.06;
% %         ramp.settling_time = 10;
% % curtime = ramp_bias_fields(calctime(curtime,0), ramp);

%=============================================== rf transfer
%        curtime=calctime(curtime,100);
      
%        Do RF Pulse
%        clear('pulse')
%        rf_list =  [41.003:0.006:41.03]; 
%        pulse_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%        rf_power_list = [-7];
%        pulse_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  
%        rf_pulse_length_list = [0.06];
%        pulse_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');
        
% %        Do RF Sweep
%        clear('sweep');
%        rf_list = [41.015];
%        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%        rf_power_list = [0];
%        sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%        delta_freq = 0.03;
%        sweep_pars.delta_freq = delta_freq;  -0.2; % end_frequency - start_frequency   0.01
%        rf_pulse_length_list = [15];
%        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
%        addOutputParam('RF_Pulse_Length',sweep_pars.freq);        
% % %        
%        acync_time_start = curtime;
% ScopeTriggerPulse(curtime,'rf_pulse_test');
%     
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),4,pulse_pars);%3: sweeps, 4: pulse
% total_pulse_length = 50;
% 
%             do_ACync_plane_selection = 1;
%             if do_ACync_plane_selection
%                 ACync_start_time = calctime(acync_time_start,-80);
%                 ACync_end_time = calctime(curtime,total_pulse_length+40);
%                 setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
%                 setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
%             end

%==========================================================================
    end

    %prepare xdt and lattice    
    xdtdepth_list = [0.20];%0.05
    xdtdepth = getScanParameter(xdtdepth_list,seqdata.scancycle,seqdata.randcyclelist,'xdtdepth');%maximum is 4
%   XDT2_Power = (((sqrt(XDT1_Power)*83.07717-0.8481)+3.54799)/159.3128)^2
    XDT1_Power = xdtdepth;
    XDT2_Power = (sqrt(81966+1136.6*(21.6611-(-119.75576*XDT1_Power^2+159.16306*XDT1_Power+13.0019)))-286.29766)/2/(-284.1555);%(((sqrt(XDT1_Power)*83.07717-0.8481)+3.54799)/159.3128)^2;%
    addOutputParam('xdt1power',XDT1_Power);
    addOutputParam('xdt2power',XDT2_Power);
    
    latdepth_list = 20; 
    latdepthx = getScanParameter(latdepth_list,seqdata.scancycle,seqdata.randcyclelist,'latdepx');%maximum is 4 
%     Comp_Ramptime = 50;
%     Comp_Power = 0;%unit is mW
    lat_ramp_time_list = 150;%150 sept28
    lat_ramp_time = getScanParameter(lat_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_ramp_time');
    xdt_ramp_time = lat_ramp_time;
    lat_ramp_tau = lat_ramp_time/3;40; %40 sept28 20 sep29        addOutputParam('lat_ramp_tau',lat_ramp_tau);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     X_Lattice_Depth =0;20; 20;10.76;10.76;2.5;0.5;          1.04; 2.5;0.3;%2.50;0
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     Y_Lattice_Depth =0;20; 20;0.23;0.23;2.77;11.1;      1.0;  2.77;10.16;%2.77;10.16
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     Z_Lattice_Depth =0;20; 20;11.57;11.57;2.44;2.45;9.6;       0.95; 2.44;9.49;%2.44;9.49
    X_Lattice_Depth = 2;-2.7;2.6; %2.5Er: 2.6; 15Er_15.7;  no ramp at the moment
    Y_Lattice_Depth = 2;2.32; %1Er_0.82;2.5Er_2.32;15Er_14.35;
    Z_Lattice_Depth = 2;2.2; %1Er_0.87;2.5Er_2.2;15Er_13.4;
%     X_Lattice_Depth2 = 0;60; %2.5Er: 3.15; 15Er_15.7;
%     Y_Lattice_Depth2 = 0;60;%1Er_0.82;2.5Er_2.3;15Er_14.35;
%     Z_Lattice_Depth2 = 0;60; %1Er_0.87;2.5Er_2.2;15Er_13.4;
%     lat_ramp_time2 = 0.5;
    %2.5Er: 2.50 2.77 2.44
    %3Er: 3.175 3.3 2.9
    %3.5Er: 3.7 3.85 3.4
    %4Er: 4.25 4.38 3.9
% % % % % % %     X_Lattice_Depth = 0;2.65;%2.65;%1.04;%2.65;%2.07;%3.63;%4.13;%3.09;   %2.65;    %2.07 2.16 1.88
% % % % % % %     Y_Lattice_Depth =0; 2.6;%2.6;%1.0;%2.6;%2.16;%3.66;%4.14;%3.08;  %2.6;     %
% % % % % % %     Z_Lattice_Depth =0; 2.38;%2.38;%0.95;%2.38;%1.88;%3.33;%3.79;%2.82;  %2.38;    %
    
%       setDigitalChannel(calctime(curtime,-50),34,1);% turn lattice TTL ON; 0: ON; 1: OFF
if (kick_lattice == 1)
    temp_kick_latdepth_list = [5.5];
    temp_kick_latdepth = getScanParameter(temp_kick_latdepth_list,seqdata.scancycle,seqdata.randcyclelist,'temp_kick_latdepth');
    temp_kick_latdepth=temp_kick_latdepth;
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,temp_kick_latdepth); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1,0.1,temp_kick_latdepth)
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,temp_kick_latdepth);
curtime=calctime(curtime,1);    
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,0); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1,0.1,0)
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.1,0.1,0);
curtime=calctime(curtime,100);    
end

    AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Z_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,X_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,Y_Lattice_Depth);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, XDT1_Power);
curtime =  AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, XDT2_Power);
curtime=calctime(curtime,5);    
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,Z_Lattice_Depth2/atomscale);
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,X_Lattice_Depth2/atomscale);
% curtime=    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time2,lat_ramp_time2,lat_ramp_tau,Y_Lattice_Depth2/atomscale);

if ramp_up_FB_after_latt_loading
        clear('ramp');
        
        clear('ramp');
        ramp.fesh_ramptime = 100;%50 %THIS LONG?
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 150;                
        ramp.settling_time = 10;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
% holdtime = 1000;
% curtime = calctime(curtime,holdtime);

%         conductivityfb_list = [205];
%         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
%         clear('ramp');
%         ramp.xshim_final = 0.1585;
%         ramp.yshim_final = -0.0432;
%         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
%         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
%         ramp.fesh_ramptime = 0.2;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = conductivityfb;
%         ramp.settling_time = 10;
% curtime = ramp_bias_fields(calctime(curtime,0), ramp);
curtime=calctime(curtime,300);    
    end

    

    Comp_Ramptime = 50;
    Comp_Power = 15;%unit is mW
    if seqdata.flags.compensation_in_modulation == 1
       %AOM direct control off
       setDigitalChannel(calctime(curtime,-50),'Compensation Direct',0); %0: off, 1: on
       %turn off compensation AOM initailly
       setDigitalChannel(calctime(curtime,-20),'Plug TTL',1); %0: on, 1: off
       %set compensation AOM power to 0
       setAnalogChannel(calctime(curtime,-10),'Compensation Power',-1);
       %turn On compensation Shutter
       setDigitalChannel(calctime(curtime,-5),'Compensation Shutter',0); %0: on, 1: off
       %turn on compensation AOM
       setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off       
       %ramp up compensation beam
curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, Comp_Power);
    end  %compensation_in_modulation == 1
    
    
%         setDigitalChannel(curtime,'XDT TTL',1);%0: ON; 1: OFF
% curtime=calctime(curtime,100);
% ramp compensate beam power
% curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),Comp_Ramptime,Comp_Ramptime,Comp_Power);
%%curtime=calctime(curtime,1000);    
%%curtime = calctime(curtime, max(xdt_ramp_time,lat_ramp_time+20));

% %Apply force in the rotating frame.
%     if enable_modulation
%         %Parameters for rotation-induced effective B field.
%         rot_freq_list = [1];
%         rot_freq = getScanParameter(rot_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rot_freq');
%         rot_amp_list = [2];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         rot_amp = 1*getScanParameter(rot_amp_list,seqdata.scancycle,seqdata.randcyclelist,'rot_amp');
%         rot_offset_list = [0];
%         rot_offset = getScanParameter(rot_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rot_offset');
%         rot_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         %These amplitudes and angles probably need to be tweaked!
%         rot_dev_chn1 = rot_amp;
%         rot_dev_chn2 = rot_amp*16.95/13.942;
%         rot_offset1 = rot_offset;
%         rot_offset2 = rot_offset*16.95/13.942;
%         rot_phase1 = 0;
%         rot_phase2 = 90;
%         
%         %Parameters for linearly-polarized conductivity modulation. This
%         %needs to rotate in time.
%         freq_list = [30];
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [0:200/mod_freq:2000/rot_freq];%[0:160/mod_freq:2000/mod_freq];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [1]; %Should probably be less than rot_amp.
%         mod_amp = 1*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         offset_list = [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         
%         mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_dev_chn1*16.95/13.942;%modulate along x_lat direction,when mod_angle=30
% %         mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;% %modulate along y_lat directio
%         mod_offset1 = mod_offset;
%         mod_offset2 = mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;%modulate along x_lat direction
% %       mod_offset2 =-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%modulate along y_lat direction
% 
%         mod_phase1 = 0;
%         mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
% 
%   
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn1,rot_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',rot_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn2,rot_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',rot_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);
% %         %-------------------------set Rigol DG1022 ---------
% %         str211=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
% %         str212=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
% %         str221=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
% %         str222=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
% %         str231=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
% %         str3=[str212,str211,str221,str222,str231];
% %         addVISACommand(3, str3);
%         
%         %-------------------------end:set Rigol-------------       
%         
%         %ramp the modulation amplitude
%         mod_ramp_time_list = [150];%150 sept28
%         mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         mod_wait_time = 50;
%         offset = 5; %XDT piezo offset
%                 
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity_modulation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
%         
%         %Need to use Adwin to generate linear modulation.
%         %Need to use Adwin to generate linear modulation.
%         XDT1_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * cos(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))) .* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         XDT2_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * sin(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))).* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         Drive_Time = mod_time+mod_ramp_time+mod_wait_time;
%         AnalogFunc(calctime(curtime,0),'XDT1 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT1_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn1,rot_freq/1000,mod_dev_chn1,mod_freq/1000,0,1,mod_ramp_time,offset);
%         AnalogFunc(calctime(curtime,0),'XDT2 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT2_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn2,rot_freq/1000,mod_dev_chn2,mod_freq/1000,0,1,mod_ramp_time,offset);
% 
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
% 
% curtime = calctime(curtime,mod_wait_time);
% 
% curtime = calctime(curtime,mod_time);
%         setAnalogChannel(curtime,'XDT1 Piezo',5);
%         setAnalogChannel(curtime,'XDT2 Piezo',5);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT
%         post_mod_wait_time_list = [0];  
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
%     end

% Modified to work with two rigols, modulation and rotation. Modulation
% parts are mostly the same as previous.

    if (DMD_on == 1)   
        if enable_modulation == 1
            DMD_power_val_list = 1.3;[1:0.05:1.5]; %Do not exceed 1.5 here
            DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
            DMD_ramp_time = 10;
            setAnalogChannel(calctime(curtime,-1),'DMD Power',0.3);
            setDigitalChannel(calctime(curtime,-1-220),'DMD TTL',0);%1 off 0 on
            setDigitalChannel(calctime(curtime,-1-100),'DMD TTL',1); %pulse time does not matter
            setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1); %0 off 1 on
            AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
            %     setDigitalChannel(calctime(curtime,50+DMD_on_time),'DMD AOM TTL',1);
        else
            DMD_power_val_list = 3.5;[1:0.05:1.5]; %Do not exceed 1.5 here
            DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
            DMD_ramp_time = 100;
%             setAnalogChannel(calctime(curtime,-1),'DMD Power',0.3);
            setDigitalChannel(calctime(curtime,-1-220-100),'DMD TTL',0);%1 off 0 on
            setDigitalChannel(calctime(curtime,-1-100-100),'DMD TTL',1); %pulse time does not matter
            setDigitalChannel(calctime(curtime,0-100),'DMD AOM TTL',1); %0 off 1 on
            AnalogFuncTo(calctime(curtime,0-100),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%             setAnalogChannel(calctime(curtime,0-100),'DMD Power',DMD_power_val);
            DMD_on_time_list = [0]; %Do not exceed 1.5 here
            DMD_on_time = getScanParameter(DMD_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_on_time');
            setAnalogChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD Power',-5);
             setDigitalChannel(calctime(curtime,DMD_on_time+DMD_ramp_time),'DMD AOM TTL',0); %0 off 1 on
    %         setAnalogChannel(calctime(curtime,1),'DMD Power',-5);
        end
    end

if enable_modulation
%         %Parameters for rotation-induced effective B field.
%         rot_freq_list = [120];
%         rot_freq = getScanParameter(rot_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rot_freq');
%         rot_amp_list = [1];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         rot_amp = 1*getScanParameter(rot_amp_list,seqdata.scancycle,seqdata.randcyclelist,'rot_amp');
%         rot_offset_list = [0];
%         rot_offset = getScanParameter(rot_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rot_offset');
%         rot_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         %These amplitudes and angles probably need to be tweaked!
%         rot_dev_chn1 = rot_amp;
%         rot_dev_chn2 = rot_amp*16.95/13.942;
%         rot_offset1 = rot_offset;
%         rot_offset2 = rot_offset*16.95/13.942;
%         rot_phase1 = 0;
%         rot_phase2 = 90;
%         if DMD_on == 1
%             DMD_power_val_list = 1.3;[1:0.05:1.5]; %Do not exceed 1.5 here
%             DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
%             DMD_ramp_time = 10;
%             setAnalogChannel(calctime(curtime,59),'DMD Power',0.3);
%             setDigitalChannel(calctime(curtime,59-220),'DMD TTL',0);%1 off 0 on
%             setDigitalChannel(calctime(curtime,59-100),'DMD TTL',1); %pulse time does not matter
%             setDigitalChannel(calctime(curtime,60),'DMD AOM TTL',1); %0 off 1 on
%             AnalogFuncTo(calctime(curtime,60),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%             %     setDigitalChannel(calctime(curtime,50+DMD_on_time),'DMD AOM TTL',1);
%         end
        %Parameters for linearly-polarized conductivity modulation.
        freq_list = [0.01]; %was 120
        mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
        time_list = [100];[0:160/mod_freq:2000/mod_freq];
        mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
        addOutputParam('mod_time',mod_time);
        amp_list = [0]; %displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
        mod_amp = 1.0*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp1');
        offset_list = [0];
        mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
        mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
        mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_amp*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85;16.95/13.942;%modulate along x_lat direction,when mod_angle=30
        mod_dev_chn2 = mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*0.85;  16.95/13.942;% %modulate along y_lat directio
        mod_offset1 = 0;mod_offset;
        %mod_offset2 = mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85; 16.95;16.95/13.942;%modulate along x_lat direction
        mod_offset2 = 0;-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*0.85;16.95/13.942;%modulate along y_lat direction
        mod_phase1 = 0;
        mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction

        %Provides modulation.
        %-------------------------set Rigol DG4162 ---------
        str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
        str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
        str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
        str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
        str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
        str2=[str112,str111,str121,str122,str131];
        addVISACommand(4, str2);


%         %Could provide rotation if desired.
%         %-------------------------set Rigol DG1022 ---------
%         str211=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn1,rot_offset1);
%         str212=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',rot_phase1);
%         str221=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn2,rot_offset2);
%         str222=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',rot_phase2);
%         str231=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str3=[str212,str211,str221,str222,str231];
%         addVISACommand(3, str3);
        
        %-------------------------end:set Rigol-------------        
        %ramp the modulation amplitude
        mod_ramp_time_list = [150];%150 sept28
        mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
%         mod_ramp_time = mod_ramp_time/3*2;
        final_mod_amp = 1;
        addOutputParam('mod_amp',mod_amp*final_mod_amp);
        setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
curtime = calctime(curtime,10);
ScopeTriggerPulse(curtime,'conductivity_modulation');
        setDigitalChannel(curtime,'ScopeTrigger',1);
        setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',1);  %send trigger to Rigol for modulation
        %====================================
if ramp_up_FB_during_mod_ramp == 1
        clear('ramp');       
        ramp.xshim_final_list = 0.1585; %0.1585;
        ramp.xshim_final = getScanParameter(ramp.xshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'xshim');
        ramp.yshim_final_list = -0.0432;  %-0.0432;
        ramp.yshim_final = getScanParameter(ramp.yshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'yshim');
        ramp.zshim_final_list = -0.0865;  %-0.0865;
        ramp.zshim_final = getScanParameter(ramp.zshim_final_list,seqdata.scancycle,seqdata.randcyclelist,'zshim');     
        
        shiftfb_list = 200;%[0,20,60,100,140,180,200];
        shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        

        ramp.fesh_ramptime = mod_ramp_time;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = shiftfb-0.06;                
        ramp.settling_time = 40;
        ramp_bias_fields(calctime(curtime,0), ramp);
end   
        %====================================

curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
        mod_wait_time =0;50;

        
        
DMD_start_time = curtime;
curtime = calctime(curtime,mod_wait_time);

curtime = calctime(curtime,mod_time);


        if (adiabatic_ramp_down == 1)%ramp down lattice and ramp down modulation to test the adibatic loading
            %ramp down the modulation
curtime = calctime(curtime,mod_wait_time);
curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, 0); 
            %ramp down the lattice
            
curtime = calctime(curtime,3000-2*lat_ramp_time);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, 0.15);
curtime =  AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), xdt_ramp_time, xdt_ramp_time, 0.062);

    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);      
    AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);

curtime = calctime(curtime,100);
        end

        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
        setAnalogChannel(curtime,'Modulation Ramp',0);
%         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT

% if (DMD_on_during_modulation==1)
%     DMD_end_time = curtime;
%     setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
%     DMD_shine_time = (DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit)
%     
%     if (((DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit))>1000)
%         error('DMD MAY BE ON FOR TOO LONG')
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        post_mod_wait_time_list = 50;[0:5:60];
        post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        addOutputParam('post_mod_wait_time',post_mod_wait_time);
curtime = calctime(curtime,post_mod_wait_time);
    
end


%%turn off DMD
if (DMD_on == 1)
    if (enable_modulation == 0)
        DMD_start_time = curtime;
curtime = calctime(curtime,DMD_on_time+DMD_ramp_time-20);
    end
    if enable_modulation == 1
        setAnalogChannel(calctime(curtime,0),'DMD Power',-10);
        setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
    end
%     setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
    DMD_end_time = curtime;
    DMD_shine_time = DMD_ramp_time + (DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit)
    
    if (((DMD_end_time - DMD_start_time)*(seqdata.deltat/seqdata.timeunit))>1000)
        error('DMD MAY BE ON FOR TOO LONG')
    end
end



    if Post_Mod_Lat_Ramp
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);
curtime=AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0);    
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);
curtime=AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,15);    
curtime = calctime(curtime,1);
    end

% % 	ramp up pin lattice
    if Lattices_to_Pin
        setDigitalChannel(calctime(curtime,-0.5),'yLatticeOFF',0);%0: ON
        AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60); 
        AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60)
curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60);
%     ramp down xdt
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
       AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
    end  
    
    
   % ramp up pin lattice with expansion
%     if Lattices_to_Pin
%         setDigitalChannel(calctime(curtime,-0.5),'Z Lattice TTL',0);%0: ON
%         AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 00/atomscale); 
%         AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 30/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 00/atomscale);
%         Expansion_hold_time_list = [50];
%         Expansion_hold_time = getScanParameter(Expansion_hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'Expansion_hold_time');
% curtime=calctime(curtime,Expansion_hold_time);
%         AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale); 
%         AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 60/atomscale);
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
%     end  
    
    %turn off compensate beam
    if seqdata.flags.compensation_in_modulation == 1
       Comp_Ramptime = 50;
       %ramp down compensation beam
       AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, 0);

       %turn off compensation AOM
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Plug TTL',1); %0: on, 1: off
       %set compensation AOM power to 0
       setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',-5);
       %turn off compensation Shutter
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Shutter',1); %0: on, 1: off
       %turn on compensation AOM
       setDigitalChannel(calctime(curtime,Comp_Ramptime+2000),'Plug TTL',0); %0: on, 1: off 
       %set compensation AOM power to max for thermalization
       setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',9.9,1);
       %AOM direct control on
       setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Direct',1); %0: off, 1: on
    end  %compensation_in_modulation == 1   
    
         %====================================
% if ramp_up_FB_during_mod_ramp == 1
%         clear('ramp');       
%         ramp.xshim_final = 0.1585; %0.1585;
%         ramp.yshim_final = -0.0432;  %-0.0432;
%         ramp.zshim_final = -0.0865;  %-0.0865;
%         
%         shiftfb_list = 5;%[0,20,60,100,140,180,200];
%         shiftfb = getScanParameter(shiftfb_list,seqdata.scancycle,seqdata.randcyclelist,'shiftfb');        
% 
%         ramp.fesh_ramptime = mod_ramp_time;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = shiftfb-0.06;                
%         ramp.settling_time = 200;
%         ramp_bias_fields(calctime(curtime,0), ramp);
%         
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, 0);         
%         
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);      
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% 
%         
%         
% end   
        %====================================
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);      
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);
% curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),lat_ramp_time,lat_ramp_time,lat_ramp_tau,0/atomscale);

%     ramp down 
    if ((ramp_up_FB_after_evap == 1 || ...
            ramp_up_FB_after_latt_loading ==1 || ...
            ramp_up_FB_during_mod_ramp == 1 ) && ...
            (do_plane_selection == 0))
curtime = calctime(curtime,20);
     % Turn the FB up to 20G before loading the lattice, so that large field
        % ramps in the lattice can be done more quickly
%         clear('ramp');
%         % FB coil settings for spectroscopy
%         ramp.xshim_final = 0.1585;
%         ramp.yshim_final = -0.0432; 
%         ramp.zshim_final = -0.0865;
%         
%         ramp.fesh_ramptime = 0.1;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 180;%before 2017-1-6 0.25*22.6; %22.6
%         ramp.settling_time = 10;
%         addOutputParam('FB_Scale',ramp.fesh_final)
%      curtime = ramp_bias_fields(calctime(curtime,0), ramp);

        clear('ramp');
            % FB coil settings for spectroscopy
            ramp.xshim_final = 0.1585;
            ramp.yshim_final = -0.0432; 
            ramp.zshim_final = -0.0865;
            ramp.QP_final = 0;
            ramp.fesh_ramptime = 50;%100
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 20;%before 2017-1-6 0.25*22.6; %22.6
            ramp.settling_time = 10;
            addOutputParam('FB_Scale',ramp.fesh_final)
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
     holdtime = 500;
curtime = calctime(curtime,holdtime);  
    end
    
    time_out_cond = curtime;
    if (((time_out_cond - time_in_cond)*(seqdata.deltat/seqdata.timeunit))>3000)
        error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
    end
    

end

