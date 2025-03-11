function timeout = xdt_piezo_scramble(curtime)

global seqdata

%% Scramble Flags
% These flags should be read in programatically --> only scramble if the
% piezos have been moved. Or something like that.

% doScramble_ODT1_H = true; % hard to implement with Rigols, think about it
doScramble_ODT1_V = 1;
doScramble_ODT1_HV = 1;

% doScramble_ODT2_H = true; % hard to implement with Rigols, think about it
doScramble_ODT2_V = 1;
doScramble_ODT2_HV = 1;

%% Ramp Timings

tReset = 200;   % How long to reset the piezo to
tRamp = 50;     % Duration of each ramp
Vc = 5;         % "Anneal" value 

%% Final Ramp
% Should the final ramp be done in a scramble at all/
ODT1_V_val = 5;
ODT1_HV_val = 5;

ODT2_V_val = 5;
ODT2_HV_val = 5;


%% Reset Piezos to 0V
% Send all piezos to the zero value

if doScramble_ODT1_V
    AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tReset,tReset,0);
end

if doScramble_ODT1_HV
    AnalogFuncTo(calctime(curtime,0),'ODT1 Piezo HV',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tReset,tReset,0);
end

if doScramble_ODT2_V
    AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tReset,tReset,0);
end

if doScramble_ODT2_HV
    AnalogFuncTo(calctime(curtime,0),'ODT2 Piezo HV',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tReset,tReset,0);
end

% Wait for piezos to reset
curtime= calctime(curtime,tReset+50);
%% Begin scramble
% "Standard Scramble" 
% 
% The standard scramble is ramp to the maximum value, then oscillate back
% and forth until until to 5V
% Go to max, go to min, these slowly anneal to 5V
% ramp to final value;

amps = linspace(5,0,50);


for kk=1:length(amps)
    if doScramble_ODT1_V
        AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tRamp,tRamp,Vc+amps(kk)*(-1)^kk);
    end   
    
    if doScramble_ODT1_HV
        AnalogFuncTo(calctime(curtime,0),'ODT1 Piezo HV',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tRamp,tRamp,Vc+amps(kk)*(-1)^kk);
    end   
    

    if doScramble_ODT2_V
        AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tRamp,tRamp,Vc+amps(kk)*(-1)^kk);
    end   
    
    if doScramble_ODT2_HV
        AnalogFuncTo(calctime(curtime,0),'ODT2 Piezo HV',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tRamp,tRamp,Vc+amps(kk)*(-1)^kk);
    end   
    
    curtime=calctime(curtime,tRamp);
end
%% Additional Wait
    curtime=calctime(curtime,50);

%% End it
timeout = curtime;
end

