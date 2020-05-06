%------
%Summary: This is another test sequence
%------

function timeout = test_sequence3(timein)

curtime = timein;

curtime = calctime(curtime, 1000);

global seqdata;

%% 
%     setAnalogChannel(calctime(curtime,-10),'Plug Beam',1);
%% multi GPIB/VISA test
% % SRS A
%     SRSAddressA = 27;
% % SRS B
%     SRSAddressB = 28;
%     
% %     addmultiGPIBCommand(addr, GPIBtimein, str, varargin)
%     addGPIBCommand(SRSAddressA,sprintf(['FREQ %fMHz;'],1.111));
%  
% 
% 
%% getmultiScanParameter
%         setAnalogChannel(curtime,46,0);
%     a_list = [3 4]; %560
%     apara = getmultiScanParameter(a_list,seqdata.scancycle,'apara',1,2);
%     
%     b_list = [2:1:apara]; %560
%     bpara = getmultiScanParameter(b_list,seqdata.scancycle,'bpara',1,1);
%     
%         
%         fprintf('cycle = %d, apara = %d, bpara = %d\n', seqdata.scancycle,apara, bpara);
%               
%% rigol setting
%     setAnalogChannel(curtime,46,0);
%     fm_dev_chn1=100;%unit is kHz;
%     fm_dev_chn2=100;%unit is kHz;    
%     str111=sprintf(':SOUR1:APPL:SIN 40MHz,1.4,0,0');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
%     str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%     str121=sprintf(':SOUR2:APPL:SIN 40MHz,0.8,0,0');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%     str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%     str2=[str111,str112,str121,str122];
%     addVISACommand(2, str2); 
%     
%     mod_freq=100;
%     str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
%     str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
%     str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
%     str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
%     str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%     str1=[str011, str012,str021,str022,str031];
%     addVISACommand(3,str1); 
%     setDigitalChannel(curtime,'Lattice FM',1);
%         setDigitalChannel(calctime(curtime,1000),'Lattice FM',0);
%% conductivity modulation

%         scope_trigger = 'conductivity modulation';
%         freq_list = [80];
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [100];
%         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         amp_list =[500];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         mod_angle = 60;%unit is deg, fluo.image x-direction is 0; fluo.image y-direction is 90;
%         mod_dev_chn1 = mod_amp/(sind(61.4+mod_angle)+cosd(61.4+mod_angle)/sind(32-mod_angle));
%         mod_dev_chn2 = mod_dev_chn1*cosd(61.4+mod_angle)/sind(32-mod_angle);
%         fm_dev_chn1 = mod_dev_chn1/0.2273;%unit is kHz;
%         fm_dev_chn2 = mod_dev_chn2/0.2265;%unit is kHz;
%         %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,4,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
%         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,4,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
%         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012,str021,str022,str031];
%         addVISACommand(3,str1);  
%         %-------------------------set Rigol DG4162 ---------        
%         str111=sprintf(':SOUR1:APPL:SIN 40MHz,1.4,0,0');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
%         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%         str113=sprintf(':SOUR1:BURS OFF;');%no burst
%         str121=sprintf(':SOUR2:APPL:SIN 40MHz,0.8,0,0');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn1, FM modulation, external,deviation is xxx
%         str123=sprintf(':SOUR2:BURS OFF;');%no burst
%         str2=[str111,str112,str113,str121,str122,str123];
%         addVISACommand(2, str2);              
        %-------------------------end:set Rigol---------
        %ramp the modulation amplitude
%         mod_ramp_time = 100;
%         final_mod_amp=1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 0;
%         curtime = calctime(curtime,mod_wait_time);
%         curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);        
        %% test GPIB dev2 control
%         scope_trigger = 'd20 test';
%         ScopeTriggerPulse(calctime(curtime,0),'d20 test');
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %         strgpib1=sprintf(':BURS:STAT ON;:BURS:MODE GAT;');
% %         strgpib2=sprintf(':APPL:RAMP 0.1MHz, 1Vpp, 0 V;');
% %         strgpib=[strgpib2,strgpib1];
%        strlxi1=sprintf(':BURS:STAT ON;:BURS:MODE GAT;:APPL:RAMP %f, 1Vpp, 0 V;',100);
%        addmultiGPIBCommand(2,strlxil);
% %         addGPIBCommand(2,strgpib);
%         setDigitalChannel(curtime,'d20',1);
%         setdigitalChannel(calctime(curtime,1000),'d20',0);        
%%
% conductivity_modulation=1;
%    if conductivity_modulation
%         freq_list = [70];
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [50];
%         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         amp_list = [15];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
% %         mod_angle = 30;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
% %         mod_dev_chn1 = mod_amp/(cosd(180+118.6-mod_angle)-cosd(32-mod_angle)*sind(180+118.6-mod_angle)/sind(32-mod_angle));
% %         mod_dev_chn2 = -mod_dev_chn1*sind(180+118.6-mod_angle)/sind(32-mod_angle);
% %         fm_dev_chn1 = abs(mod_dev_chn1)/0.2273;%unit is kHz;
% %         fm_dev_chn2 = abs(mod_dev_chn2)/0.2265;%unit is kHz;
%         fm_dev_chn1 = mod_amp/0.2394;%unit is kHz;
%         fm_dev_chn2 = mod_amp/0.2394;
% %         fm_dev_chn1=30;
%         phase1 = 0;
%         phase2 = 0;
%         
% %         if mod_dev_chn1<0
% %             phase1 = 180;
% %         else
% %             phase1 = 0;
% %         end
% %         if mod_dev_chn2<0;
% %             phase2 = 180;
% %         else
% %             phase2 = 0;
% %         end
% 
%         %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012];%,str021,str022,str031];
%         addVISACommand(3,str1);  
%         %-------------------------set Rigol DG4162 ---------
% % %         str111=sprintf(':SOUR1:APPL:SIN 40MHz,0.8,0,0');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
% % %         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%         str121=sprintf(':SOUR2:APPL:SIN 40MHz,1.4,0,0');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn2, FM modulation, external,deviation is xxx
% % %         str2=[str112,str111,str122,str121];
%         str2=[str121,str122];
%         addVISACommand(2, str2);              
%         %-------------------------end:set Rigol-------------
%         
%         %ramp the modulation amplitude
%         mod_ramp_time = 50; %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 0;
% curtime = calctime(curtime,mod_wait_time);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%     end
%% shear mod AOM point stability
%     atomscale = 0.4; %0.4 for 40K, 1.0 for Rb
% scope_trigger = 'conductivity modulation';
% 
% 
% conductivity_modulation=1;
% setAnalogChannel(curtime,'xLattice',0);
% setAnalogChannel(curtime,'yLattice',0);
% setAnalogChannel(curtime,'zLattice',0);
% 
%    % %    Lattices to some set depth and XDT to some power for modulating.
%     Lattices_to_Pin = 1;
%     XDT1_Power = 0.5;
%     XDT2_Power = ((sqrt(XDT1_Power*1000)*3.29116-15.03525+6.23525)/3.4119)^2/1000;
%     addOutputParam('xdt1power',XDT1_Power);
%     addOutputParam('xdt2power',XDT2_Power);
%     
%     Trap_Ramp_Time = 100;
%     XY_Lattice_Depth = 2;
%     Z_Lattice_Depth = 10;
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale);
%     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth/atomscale);
%     AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT1_Power);
% curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT2_Power);
%    
% 
%     
%     if conductivity_modulation
%         freq_list = [5];        mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [300];
%         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         amp_list = [20];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
% %         mod_angle = 30;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
% %         mod_dev_chn1 = mod_amp/(cosd(180+118.6-mod_angle)-cosd(32-mod_angle)*sind(180+118.6-mod_angle)/sind(32-mod_angle));
% %         mod_dev_chn2 = -mod_dev_chn1*sind(180+118.6-mod_angle)/sind(32-mod_angle);
% %         fm_dev_chn1 = abs(mod_dev_chn1)/0.2273;%unit is kHz;
% %         fm_dev_chn2 = abs(mod_dev_chn2)/0.2265;%unit is kHz;
%         fm_dev_chn1 = mod_amp/0.2394;%unit is kHz;
%         fm_dev_chn2 = mod_amp/0.2394;
% %         fm_dev_chn1=30;
%         phase1 = 0;
%         phase2 = 0;
%         
% %         if mod_dev_chn1<0
% %             phase1 = 180;
% %         else
% %             phase1 = 0;
% %         end
% %         if mod_dev_chn2<0;
% %             phase2 = 180;
% %         else
% %             phase2 = 0;
% %         end
% 
%         %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012];
%         addVISACommand(3,str1);  
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN 40MHz,0.8,0,0;');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
%         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%         str121=sprintf(':SOUR2:APPL:SIN 40MHz,1.4,0,0;');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn2, FM modulation, external,deviation is xxx
%         str2=[str112,str111,str122,str121];
% %         str2=[str121,str122];
%         addVISACommand(2, str2);              
%         %-------------------------end:set Rigol-------------
%         
%         %ramp the modulation amplitude
%         mod_ramp_time = 100; %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 0;
% curtime = calctime(curtime,mod_wait_time);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%     end
%     
% %Lattices to pin. 
%     if Lattices_to_Pin
%         AnalogFuncTo(calctime(curtime,-0.1),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 200/atomscale); 
%         AnalogFuncTo(calctime(curtime,-0.1),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 200/atomscale)
%     curtime = AnalogFuncTo(calctime(curtime,-0.1),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.1, 0.1, 200/atomscale);
%     
% %     ramp down xdt
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, -0.2);
%        AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, -0.2);
%     end
% curtime=calctime(curtime,0);
%     AnalogFuncTo(calctime(curtime,50),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale); 
%     AnalogFuncTo(calctime(curtime,50),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,50),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 0/atomscale);
    %% buring a hole
%     xdtpower1=0.6;
%     xdtpower2=xdtpower1;
%     setAnalogChannel(curtime,'dipoleTrap1',-1);
%     setAnalogChannel(curtime,'dipoleTrap2',-1);
%     setDigitalChannel(calctime(curtime,0),'XDT TTL',0);
%  	AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, xdtpower1);
% curtime=AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, xdtpower2);
% curtime=calctime(curtime,3000);
% AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, -1);
% curtime=AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, -1);
% setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    %     AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT2_Power);
%    
%% 
% scope_trigger = 'conductivity modulation';
%         freq_list = [70];       
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [100];
%         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         amp_list = [5];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
% %         mod_angle = 30;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
% %         mod_dev_chn1 = mod_amp/(cosd(180+118.6-mod_angle)-cosd(32-mod_angle)*sind(180+118.6-mod_angle)/sind(32-mod_angle));
% %         mod_dev_chn2 = -mod_dev_chn1*sind(180+118.6-mod_angle)/sind(32-mod_angle);
% %         fm_dev_chn1 = abs(mod_dev_chn1)/0.2273;%unit is kHz;
% %         fm_dev_chn2 = abs(mod_dev_chn2)/0.2265;%unit is kHz;
% %         fm_dev_chn1 = mod_amp/0.2394;%unit is kHz;
% %         fm_dev_chn2 = mod_amp/0.2394;
% %         fm_dev_chn1=30;
%         phase1 = 0;
%         phase2 = 0;
%         
% %         if mod_dev_chn1<0
% %             phase1 = 180;
% %         else
% %             phase1 = 0;
% %         end
% %         if mod_dev_chn2<0;
% %             phase2 = 180;
% %         else
% %             phase2 = 0;
% %         end
% 
%         %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,mod_amp,0,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012];
%         addVISACommand(3,str1);  
%         %-------------------------set Rigol DG4162 ---------
% % %         str111=sprintf(':SOUR1:APPL:SIN 40MHz,0.8,0,0;');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
% % %         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
% %         str121=sprintf(':SOUR2:APPL:SIN 40MHz,1.4,0,0;');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
% %         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn2, FM modulation, external,deviation is xxx
% % %         str2=[str112,str111,str122,str121];
% %         str2=[str121,str122];
% %         addVISACommand(2, str2);              
%         %-------------------------end:set Rigol-------------
%         
%         %ramp the modulation amplitude
%         mod_ramp_time = 100; %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 0;
% curtime = calctime(curtime,mod_wait_time);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);  
%% plug shutter
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);
% %     setDigitalChannel(calctime(curtime,0),'Plug TTL',0);
% setDigitalChannel(calctime(curtime,0),11,1);
% % setDigitalChannel(calctime(curtime,5000),11,0);
%% xdt pzt mirror phase delay
% scope_trigger = 'conductivity modulation';
% conductivity_modulation=1;
% setDigitalChannel(calctime(curtime,-100),'XDT TTL',0);
%         setAnalogChannel(curtime,'dipoleTrap1',0);
%                 setAnalogChannel(curtime,'dipoleTrap2',0);
%     XDT1_Power = 0.5;
%     XDT2_Power = (((sqrt(XDT1_Power)*79.53844+2.75255)+2.38621)/140.61417)^2;
%     addOutputParam('xdt1power',XDT1_Power);
%     addOutputParam('xdt2power',XDT2_Power);
%     
%     Trap_Ramp_Time = 50;
%     XY_Lattice_Depth = 0;
%     Z_Lattice_Depth = 0;
%     dip_rampstart=0;
% %     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale); 
% %     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale);
% %     AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth/atomscale);
%     AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT1_Power);
% curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XDT2_Power);
% %     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale); 
% %     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, XY_Lattice_Depth/atomscale);
% % curtime =
% % AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, Z_Lattice_Depth/atomscale);
% curtime = calctime(curtime,50);
% 
% 
%     if conductivity_modulation
%         freq_list = [130];       
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [0];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [1.5];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         offset_list = [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
% %         mod_angle = 30;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
% %         mod_dev_chn1 = mod_amp/(cosd(180+118.6-mod_angle)-cosd(32-mod_angle)*sind(180+118.6-mod_angle)/sind(32-mod_angle));
% %         mod_dev_chn2 = -mod_dev_chn1*sind(180+118.6-mod_angle)/sind(32-mod_angle);
% %         fm_dev_chn1 = abs(mod_dev_chn1)/0.2273;%unit is kHz;
% %         fm_dev_chn2 = abs(mod_dev_chn2)/0.2265;%unit is kHz;
% %         fm_dev_chn1 = mod_amp/0.2394;%unit is kHz;
% %         fm_dev_chn2 = mod_amp/0.2394;
% %         fm_dev_chn1=30;
%         phase1 = 0;
%         phase2 = 0;
%         
% %         if mod_dev_chn1<0
% %             phase1 = 180;
% %         else
% %             phase1 = 0;
% %         end
% %         if mod_dev_chn2<0;
% %             phase2 = 180;
% %         else
% %             phase2 = 0;
% %         end
% 
%         %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,mod_amp,mod_offset,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012];
%         addVISACommand(3,str1);           
%         %-------------------------end:set Rigol-------------        
%         %ramp the modulation amplitude
%         mod_ramp_time = 10; %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 200;
% curtime = calctime(curtime,mod_wait_time);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%         post_mod_wait_time_list = [0];  
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
% curtime = calctime(curtime,post_mod_wait_time);
% 
% 
%     AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, 0);
% curtime = AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Trap_Ramp_Time, Trap_Ramp_Time, 0);
% curtime = setDigitalChannel(calctime(curtime,100),'XDT TTL',0);
%% kill beam controll test

%             kill_probe_pwr = 0.1;
%             kill_time = 10; %10           
%             kill_detuning = 40; %27 for 80G
%             addOutputParam('kill_detuning',kill_detuning);
%             addOutputParam('kill_time',kill_time);
% 
%             pulse_offset_time = -5; %Need to step back in time a bit to do the kill pulse
%                                       % directly after transfer, not after the subsequent wait times
% 
% %             %set probe detuning
% %             setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Probe/OP FM',170); %195
%             %set trap AOM detuning to change probe
%             setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Trap FM',kill_detuning); %54.5
% 
%             %open K probe shutter
%             setDigitalChannel(calctime(curtime,pulse_offset_time-10),'Downwards D2 Shutter',1); %0=closed, 1=open
%             %turn up analog
%             setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
%             %set TTL off initially
%             setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',1);
% 
% %             %pulse beam with TTL
% %             setDigitalChannel(calctime(curtime,pulse_offset_time),'Kill TTL',)
% %             
% %             DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);
% % 
% %             %close K probe shutter
% %             setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),'Downwards D2 Shutter',0);
% %             
% %             %set kill AOM back on
% %             setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 5),'Kill TTL',1);
%% xdt modulation test
%         curtime = calctime(curtime,1000);
%         freq_list = [0.001];       
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [0];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [0];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         offset_list = [2];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         
%         
%          mod_angle = 0;%unit is deg, fluo.image x-direction is 0 deg; fluo.image y-direction is 90 deg;
%          mod_dev_chn1 = mod_amp;
%          mod_dev_chn2 = 0;mod_dev_chn1*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;% 
%          %modulate along x_lat direction
% %          mod_dev_chn2 = mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%
%         %modulate along y_lat direction
%          mod_offset1 = mod_offset;
%          mod_offset2 = 0;mod_offset1*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;
% 
%         %modulate along x_lat direction
%          %          mod_offset2 =  mod_offset1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;
%         %modulate along y_lat direction
%         phase1 = 0;
%         phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
        
%         if mod_dev_chn1<0
%             phase1 = 180;
%         else
%             phase1 = 0;
%         end
%         if mod_dev_chn2<0;
%             phase2 = 180;
%         else
%             phase2 = 0;
%         end

        %-------------------------set Rigol DG1022Z---------
%         str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,mod_amp,mod_offset,phase1);%freq = mod_freq,amp = 1, offset =0,phase =0;
%         str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% %         str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,2,0,phase2);%freq = mod_freq,amp = 1, offset =0,phase =0;
% %         str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% %         str031=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase
%         str1=[str011, str012];
%         addVISACommand(3,str1);  
        %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);
%         
% %         str111=sprintf(':SOUR1:APPL:SIN 40MHz,0.8,0,0;');%ch1, 40MHz, 1.4Vpp,0V offset, 0 deg phase
% %         str112=sprintf(':SOUR1:FM:STAT ON; :SOUR1:FM:SOUR EXT; :SOUR1:FM %fkHz;',fm_dev_chn1);% Chn1, FM modulation, external,deviation is xxx
%         str121=sprintf(':SOUR2:APPL:SIN 40MHz,1.4,0,0;');%ch2, 40MHz, 0.8Vpp,0V offset, 0 deg phase
%         str122=sprintf(':SOUR2:FM:STAT ON; :SOUR2:FM:SOUR EXT; :SOUR2:FM %fkHz;',fm_dev_chn2);% Chn2, FM modulation, external,deviation is xxx
% %         str2=[str112,str111,str122,str121];
%         str2=[str121,str122];
%         addVISACommand(2, str2);              
        %-------------------------end:set Rigol-------------
        
        %ramp the modulation amplitude
%         mod_ramp_time = 150; %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity modulation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
%         setDigitalChannel(curtime,'Lattice FM',1);
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time = 50;
% curtime = calctime(curtime,mod_wait_time);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%         post_mod_wait_time_list = [0:3:40];  
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
% curtime = calctime(curtime,post_mod_wait_time);
%         curtime = calctime(curtime,1000);
%% probe beam test
% 
% curtime = calctime(curtime, 1000);
% pulse_length = 0.1;
%         setAnalogChannel(curtime,'Modulation Ramp',0);
%         k_detuning = 57;
%         
%         k_probe_scale = 1;
%         rb_probe_scale = 0;
%         k_probe_pwr = k_probe_scale*0.50;
%         
%         
%         %prepare detuning, power, etc...
%         k_detuning_shift_time = 0.5;%4
%         tof=15;
%         %set probe detuning
%         setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Probe/OP FM',180); %195
%         %SET trap AOM detuning to change probe
%         setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',k_detuning-20.5);%54.5
%         %shutter
%         setDigitalChannel(calctime(curtime, -10),'K Probe/OP shutter',1);% 1: beam on; 0: beam off
% curtime = calctime(curtime,20);
%         %set probe power
%         %Analog
%         setAnalogChannel(calctime(curtime,-1),'K Probe/OP AM',k_probe_pwr,1); %1
%         
%         curtime = calctime(curtime,20);
%         %TTL
%         setDigitalChannel(calctime(curtime,-1),'K Probe/OP TTL',1);%1:off
%         
%         setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0);
%         setDigitalChannel(calctime(curtime,0.1),'K Probe/OP TTL',1);%1:off
%         setDigitalChannel(calctime(curtime,0.2),'K Probe/OP TTL',0);
%         setDigitalChannel(calctime(curtime,0.3),'K Probe/OP TTL',1);%1:off
%         %1st pulse
% %         do_abs_pulse(curtime,pulse_length);
%         
% curtime = calctime(curtime,200);
%         %2nd pulse
% %         do_abs_pulse(curtime,pulse_length); 
%         
% %       turn off probe
% %         setDigitalChannel(calctime(curtime, -10),'K Probe/OP shutter',0);% 1: beam on; 0: beam off
% 
% curtime = calctime(curtime,2000);
%         %% Absorption pulse function -- triggers cameras and pulses probe/repump
% function do_abs_pulse(curtime,pulse_length)
% 
%     %Camera triggers
%     ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);
%     DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
% 
%     %Probe pulse with TTL
%     DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,0);
%         
% end
%% Load MOT

%  rb_MOT_detuning = 33; %before2016-11-25:33
% %  k_MOT_detuning_list =[ 22]; 20; %before2016-11-25:20 %20
%  
% k_MOT_detuning_list = [20];
% k_MOT_detuning = getScanParameter(k_MOT_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_MOT_detuning');        
%  
% %  addOutputParam('k_MOT_detuning',k_MOT_detuning);
% k_repump_shift = 0;  %before2016-11-25:0 %0
% 
% mot_wait_time = 50;
%   
% % if seqdata.flags.image_type==5
% %    mot_wait_time = 0;
% % end
%         
% %call Load_MOT function
% curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);
%         
% setAnalogChannel(curtime,'K Repump FM',k_repump_shift,2)
%       
% % if ( seqdata.flags.do_dipole_trap == 1 )
% %         curtime = calctime(curtime,dip_holdtime);
% %         
% %     elseif mag_trap_MOT || MOT_abs_image
% % 
% %         curtime = calctime(curtime,100);
% %         
% %     else
% %         curtime = calctime(curtime,1*500);%25000
% % end
% 
% %set relay back
% curtime = setDigitalChannel(calctime(curtime,10),28,0);


% setAnalogChannel(curtime,'Modulation Ramp',0);
% setDigitalChannel(calctime(curtime,100),'ScopeTrigger',1);
% setDigitalChannel(calctime(curtime,100),'K Trap Shutter',1);
% setDigitalChannel(calctime(curtime,100),'Rb Trap Shutter',1);
%% kill beam control
%      setAnalogChannel(calctime(curtime,0),'Compensation Power',0);
% % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     kill_probe_pwr = 1;
%     kill_time = 10;
%     pulse_offset_time = 0;
% 
% %     set TTL off initially
%     setDigitalChannel(calctime(curtime,-20),'Kill TTL',0); % 0 = power off; 1=  power on
% %     open K probe shutter
%     setDigitalChannel(calctime(curtime,-10),'Downwards D2 Shutter',1); %0=closed, 1=open
% 
%     % turn AOM on
%     setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
%     
%     curtime=calctime(curtime,kill_time);
% % 
%     
%     
%     %take Ixon image
%     setAnalogChannel(calctime(curtime,0),'objective Piezo Z',6.5,1);
%     curtime=calctime(curtime,6000);
%     iXon_FluorescenceImage(curtime,'ExposureOffsetTime',20,'ExposureDelay',0,'FrameTime',20,'NumFrames',1)
%     curtime=calctime(curtime,3000);
%     
% %     turn AOM off
%     setDigitalChannel(calctime(curtime,0),'Kill TTL',0);    
% %     close K probe shutter
%     setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0); %0=closed, 1=open
% %     turn AOM on
%     setDigitalChannel(calctime(curtime,500),'Kill TTL',1); 
% %     
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compensate feedback control
% % turn on compensate shutter
%     setDigitalChannel(calctime(curtime,0),'Compensation Shutter',0); %0: on, 1: off
% % turn on compensate AOM TTL
%     setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off
% % turn on compensate AOM Direct control off
%     setDigitalChannel(calctime(curtime,-1000),'Compensation Direct',0); %0: off, 1: on
% % set compensate power ref
%     setAnalogChannel(calctime(curtime,0),'Compensation Power',40);
% % ramp compensate power ref
% %     Comp_Power=3;
% %     Comp_Ramptime=200;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),Comp_Ramptime,Comp_Ramptime,Comp_Power);
% % ramp off compensate power ref
% %     Comp_Power=0;
% %     Comp_Ramptime=200;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),Comp_Ramptime,Comp_Ramptime,Comp_Power);
% %Turn off compensate AOM TTL
%     setDigitalChannel(calctime(curtime,5000),'Plug TTL',1); %0: on, 1: off
% %Turn off compensate Shutter
%     curtime = setDigitalChannel(calctime(curtime,5000),'Compensation Shutter',1); %0: on, 1: off
% % turn on AOM for thermalization
%     setAnalogChannel(calctime(curtime,500),'Compensation Power',2.5);
%     setDigitalChannel(calctime(curtime,500),'Plug TTL',0); %0: on, 1: off
%% F-pump beam control
%  repump_power = 
%     setAnalogChannel(calctime(curtime,0),'F Pump',repump_power);
%     setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
%     setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
%     
%% Lattice beam pulse control
% lattice_before_on_time = -0.5;% -50 for rough alignment , 3 for K-D diffraction
% pulse_length = 0.02;
% 
% %pulse the lattice on during TOF
%  pulse_time_temp=calctime(curtime,lattice_before_on_time);        
%  ScopeTriggerPulse(pulse_time_temp,'pulse_zlat');
%  setDigitalChannel(pulse_time_temp,34,0);%0: lattice beam power on; 1: lattice beam power off;
%  setDigitalChannel(calctime(pulse_time_temp,-25),'Lattice Direct Control',0); %0: direct off; 1: direct on (should not matter)
%  pulse_time_temp=calctime(pulse_time_temp,pulse_length);
%  setDigitalChannel(pulse_time_temp,34,1);%0: lattice beam power on; 1: lattice beam power off;
%  setDigitalChannel(pulse_time_temp,'Lattice Direct Control',1); %0: direct off; 1: direct on (should not matter)
% %         
%% temp
% % % % % % % compensation_in_modulation=1;
% % % % % % % Comp_Ramptime=50;
% % % % % % % Comp_Power=50;
% % % % % % % curtime=calctime(curtime,1000);
% % % % % % %     if compensation_in_modulation == 1
% % % % % % %         %AOM direct control off
% % % % % % %        setDigitalChannel(calctime(curtime,-50),'Compensation Direct',0); %0: off, 1: on
% % % % % % %        %turn off compensation AOM initailly
% % % % % % %        setDigitalChannel(calctime(curtime,-20),'Plug TTL',1); %0: on, 1: off
% % % % % % %        %set compensation AOM power to 0
% % % % % % %        setAnalogChannel(calctime(curtime,-10),'Compensation Power',0);
% % % % % % %        %turn On compensation Shutter
% % % % % % %        setDigitalChannel(calctime(curtime,-5),'Compensation Shutter',0); %0: on, 1: off
% % % % % % %        %turn on compensation AOM
% % % % % % %        setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off       
% % % % % % %        %ramp up compensation beam
% % % % % % %        AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, Comp_Power);
% % % % % % %     end  %compensation_in_modulation == 1
% % % % % % % 
% % % % % % % curtime=calctime(curtime,3000);
% % % % % % % 
% % % % % % % %     if compensation_in_modulation == 1
% % % % % % % %        %ramp down compensation beam
% % % % % % % %        AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, 0);
% % % % % % % % 
% % % % % % % %        %turn off compensation AOM
% % % % % % % %        setDigitalChannel(calctime(curtime,Comp_Ramptime),'Plug TTL',1); %0: on, 1: off
% % % % % % % %        %set compensation AOM power to 0
% % % % % % % %        setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',0);
% % % % % % % %        %turn off compensation Shutter
% % % % % % % %        setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Shutter',1); %0: on, 1: off
% % % % % % % %        %turn on compensation AOM
% % % % % % % %        setDigitalChannel(calctime(curtime,Comp_Ramptime+2000),'Plug TTL',0); %0: on, 1: off 
% % % % % % % %        %set compensation AOM power 50mW for thermalization
% % % % % % % %        setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',50);
% % % % % % % %     end  %compensation_in_modulation == 1
% % % % % % % curtime=calctime(curtime,1000);
%% compensate beam test
%     compensation_in_modulation = 1;
%     if compensation_in_modulation == 1
% 
%         %Turn it on to some power.    
%         Comp_Ramptime = 50;
%         Comp_Power = 10;%unit is mW
%         %AOM direct control off
%         setDigitalChannel(calctime(curtime,-50),'Compensation Direct',0); %0: off, 1: on
%         %turn off compensation AOM initailly
%         setDigitalChannel(calctime(curtime,-20),'Plug TTL',1); %0: on, 1: off
%         %set compensation AOM power to 0
%         setAnalogChannel(calctime(curtime,-10),'Compensation Power',-1);
%         %turn On compensation Shutter
%         setDigitalChannel(calctime(curtime,-5),'Compensation Shutter',0); %0: on, 1: off
%         %turn on compensation AOM
%         setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off       
%         %ramp up compensation beam
% curtime = AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, Comp_Power);
%         
%         %hold briefly
% curtime = calctime(curtime,200);
% 
%         %ramp down compensation beam
%         AnalogFuncTo(calctime(curtime,0),'Compensation Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), Comp_Ramptime, Comp_Ramptime, 0);
% 
%         %turn off compensation AOM
%         setDigitalChannel(calctime(curtime,Comp_Ramptime),'Plug TTL',1); %0: on, 1: off
%         %set compensation AOM power to 0
%         setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',-5);
%         %turn off compensation Shutter
%         setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Shutter',1); %0: on, 1: off
%         %turn on compensation AOM
%         setDigitalChannel(calctime(curtime,Comp_Ramptime+2000),'Plug TTL',0); %0: on, 1: off 
%         %set compensation AOM power to max for thermalization
%         setAnalogChannel(calctime(curtime,Comp_Ramptime),'Compensation Power',9.9,1);
%         %AOM direct control on
%         setDigitalChannel(calctime(curtime,Comp_Ramptime),'Compensation Direct',1); %0: off, 1: on
%     end  %compensation_in_modulation == 1   
%% Feshbach coil heating test
% ramp_up_FB_after_evap = 1; %enable b field ramp
% 
% %ramp Feshbach field
%     SetDigitalChannel(calctime(curtime,-100),31,1); %switch Feshbach field on
%     setAnalogChannel(calctime(curtime,-95),37,0.0); %switch Feshbach field closer to on
%     SetDigitalChannel(calctime(curtime,-100),'FB Integrator OFF',0); %switch Feshbach integrator on 
% curtime = calctime(curtime,100);
% 
%     if ramp_up_FB_after_evap
%         clear('ramp');
%         ramp.fesh_ramptime = 100;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 100;
%         ramp.settling_time = 10;
% curtime = ramp_bias_fields(calctime(curtime,0), ramp);
% 
% %         conductivityfb_list = [205];
% %         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
% %         clear('ramp');
% %         ramp.xshim_final = 0.1585;
% %         ramp.yshim_final = -0.0432;
% %         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
% %         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
% %         ramp.fesh_ramptime = 0.2;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = conductivityfb;
% %         ramp.settling_time = 10;
% % curtime = ramp_bias_fields(calctime(curtime,0), ramp);
%     end
%     holdtime=1000;
%     curtime = calctime(curtime,holdtime);
%     
%     
%         if ramp_up_FB_after_evap
%         clear('ramp');
%         ramp.fesh_ramptime = 100;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 0;
%         ramp.settling_time = 10;
% curtime = ramp_bias_fields(calctime(curtime,0), ramp);
% 
% %         conductivityfb_list = [205];
% %         conductivityfb = getScanParameter(conductivityfb_list,seqdata.scancycle,seqdata.randcyclelist,'conductivity_fb');        
% %         clear('ramp');
% %         ramp.xshim_final = 0.1585;
% %         ramp.yshim_final = -0.0432;
% %         ramp.zshim_final = -0.0865;%-0.0865; %0.747625;2.01821;
% %         %if fb = 205, shim z value for different B field: 205G: -0.0865206G: 0.32400;  207G: 0.747625;  210G: 2.01821;
% %         ramp.fesh_ramptime = 0.2;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = conductivityfb;
% %         ramp.settling_time = 10;
% % curtime = ramp_bias_fields(calctime(curtime,0), ramp);
%     end
%     
% curtime = calctime(curtime,5000);
%% Acync test
% setDigitalChannel(curtime,'Shim Multiplexer',1);%%0 = MOT Shims (unipolar)
% curtime = calctime(curtime,500);
% curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);
% curtime = calctime(curtime,500);
% setAnalogChannel(calctime(curtime,0),'X Shim',0.11,3);
% setAnalogChannel(calctime(curtime,0),'Y Shim',-0.09,4);
% setAnalogChannel(calctime(curtime,0),'Z Shim',-0.208,3);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),'ScopeTrigger',1);
% setDigitalChannel(calctime(curtime,1),'ScopeTrigger',0);  
% 
%         %Do RF Sweep
%         clear('sweep');
%        rf_list = 31.37;
%        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%         sweep_pars.power = 0;-5.7; %-7.7
%         sweep_pars.delta_freq = 0;-0.05;-0.2; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 0.05; % also is sweep length  0.5
%         
%         addOutputParam('RF_Pulse_Length',sweep_pars.freq);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),4,sweep_pars);%3: sweeps, 4: pulse
% 
% %             do_ACync_plane_selection = 1;
% %             if do_ACync_plane_selection
% %                 ACync_start_time = calctime(curtime,-40);
% %                 ACync_end_time = calctime(curtime,40);
% %                 setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
% %                 setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
% %             end
% 
% % setDigitalChannel(calctime(curtime,100),19,1);
% % setDigitalChannel(calctime(curtime,110),19,0);
% curtime = calctime(curtime,500);

%% End
% SelectScopeTrigger(scope_trigger);
timeout = curtime;


end

