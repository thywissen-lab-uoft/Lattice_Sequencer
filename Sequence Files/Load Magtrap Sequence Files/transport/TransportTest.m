function curtime = TransportTest(timein)
curtime = timein;

test_type = 'Blah';

curtime = calctime(curtime,100);

%% Initialize

% Voltage Function indeces that convert current to request voltage
func_12a = 3;
func_12b = 3;
func_13 = 3;
func_14 = 3;
func_15 = 5;
func_16 = 5;
func_k = 4;

        
% Initialize.
setAnalogChannel(curtime,'MOT Coil',0);

setAnalogChannel(curtime,'15/16 GS',0,1); 
setDigitalChannel(curtime,'Kitten Relay',1); % Kitten Relay off 0: OFF, 1: ON

setAnalogChannel(curtime,'Coil 16',0,func_16);
setAnalogChannel(curtime,'Coil 15',0,func_15);
setAnalogChannel(curtime,'Coil 14',0,func_14);
setAnalogChannel(curtime,'Coil 13',0,func_13);
setAnalogChannel(curtime,'Coil 12a',0,func_12a);
setAnalogChannel(curtime,'Coil 12b',0,func_12b);

setAnalogChannel(curtime,'kitten',0,func_k);

%%

trigger_offset=0;
trigger_length = 50;
DigitalPulse(calctime(curtime,trigger_offset-trigger_length),...
    'LabJack Trigger Transport',trigger_length,1);      
    
    
switch test_type
    case 'Blah'
        
        Vt = 13;                
        curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, 0,Vt);   
        
        tramp = 1000;
        I13 = 0;
        I14 = 30;
        I15 = 30;

        AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I13,func_13);  
        AnalogFunc(calctime(curtime,tramp),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            2*tramp, 2*tramp, I13,-I13,func_13); 
        AnalogFunc(calctime(curtime,3*tramp),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, -I13,0,func_13); 
        
        AnalogFunc(calctime(curtime,tramp),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I14,func_14); 
        AnalogFunc(calctime(curtime,2*tramp),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            2*tramp, 2*tramp, I14,-I14,func_14); 
        AnalogFunc(calctime(curtime,4*tramp),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, -I14,0,func_14); 
        
        
                
        AnalogFunc(calctime(curtime,1*tramp),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,6,func_k);         
        AnalogFunc(calctime(curtime,2*tramp),'Coil 15',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I15,func_15);         
       AnalogFunc(calctime(curtime,2*tramp),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 6,6+I15,func_k);
        
        
        
        AnalogFunc(calctime(curtime,3*tramp),'Coil 15',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, I15,0,func_15);         
       AnalogFunc(calctime(curtime,3*tramp),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 4.5+I15,4.5,func_k);
        

       AnalogFunc(calctime(curtime,4*tramp),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 4.5,0,func_k);
        
        curtime = calctime(curtime,8*tramp);
        
        
%         
%        curtime = AnalogFunc(calctime(curtime,0),'Coil 13',...
%             @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
%             tramp, tramp, -I13,0,func_13); 
        
      curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, Vt,0);   
        
        
    case 'Coil 13'
        Vt = 11;                
        curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, 0,Vt);   
        
        tramp = 200;
        I13 = 30;
        curtime = AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I13,func_13);  
        
        curtime = AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            2*tramp, 2*tramp, I13,-I13,func_13); 
        
       curtime = AnalogFunc(calctime(curtime,0),'Coil 13',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, -I13,0,func_13); 
        
      curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, Vt,0);   
        
    case 'Coil 14'
        Vt = 11;                
        curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, 0,Vt);   
        
        tramp = 100;
        I14 = 30;
        curtime = AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I14,func_14);  
        
        curtime = AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            2*tramp, 2*tramp, I14,-I14,func_14); 
        
       curtime = AnalogFunc(calctime(curtime,0),'Coil 14',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, -I14,0,func_14); 
        
      curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, Vt,0);   
        
    case 'Coil 15'
        Vt = 11;                
      curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, 0,Vt);   
        
        Ik_offset = 4.5;
        curtime = AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, 0,Ik_offset,func_k);  

        I15 = 25;
        tramp = 500;
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, 0,I15,func_15);  
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, Ik_offset,I15+Ik_offset,func_k);  
        curtime = calctime(curtime,tramp);
        
        curtime = calctime(curtime,500);
        
        
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, I15,0,func_15);  
        AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) Ik_offset+ramp_minjerk(t,tt,y1,y2), ...
            tramp, tramp, I15,0,func_k);  
        curtime = calctime(curtime,tramp);
        
        curtime = AnalogFunc(calctime(curtime,0),'kitten',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, Ik_offset,0,func_k);  
        
      curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            200, 200, Vt,0);   
    otherwise
        

end
% % Wait
% setAnalogChannel(curtime,'kitten',60); 
% setAnalogChannel(curtime,'MOT Coil',0); 
% 
% % setDigitalChannel(curtime,'15/16 Switch',1); % Turn on 15/16 Switch 0: OFF, 1: ON
% 
% % Wait
% curtime = calctime(curtime,500);
%  
% % Turn up FF
% curtime = AnalogFunc(calctime(curtime,0),'Transport FF',@(t,tt,y1,y2)...
%     (ramp_linear(t,tt,y1,y2)),1000,1000,0,12.25);
% curtime = calctime(curtime,1000);
% 
%     DigitalPulse(calctime(curtime,-10),...
%         'LabJack Trigger Transport',10,1);
%     curtime = calctime(curtime,500);
%     
% curtime = AnalogFunc(calctime(curtime,0),'Coil 16',@(t,tt,y1,y2)...
%     (ramp_linear(t,tt,y1,y2)),1000,1000,0,30,5);
% curtime = calctime(curtime,1000);
% curtime = AnalogFunc(calctime(curtime,0),'Coil 16',@(t,tt,y1,y2)...
%     (ramp_linear(t,tt,y1,y2)),1000,1000,30,0,5);
% 
% 
% curtime = AnalogFunc(calctime(curtime,0),'Transport FF',@(t,tt,y1,y2)...
%     (ramp_linear(t,tt,y1,y2)),1000,1000,12.25,0);

end
