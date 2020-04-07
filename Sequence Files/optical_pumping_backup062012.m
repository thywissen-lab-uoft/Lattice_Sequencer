%------
%Author: DJ
%Created: Sep 2009
%Summary: This function makes an Optical Pumping sequence
%------

%-----Update List-------
%Aug 12, 2010: Put code from Load_MagTrap_sequence into here (DCM)
%-----------------------

function timeout = optical_pumping(timein)

global seqdata;

curtime = timein;

%% Prepare OP

%digital trigger  (beginning of OP function)
DigitalPulse(calctime(curtime,0),12,0.1,1);
% 
% %digital trigger (start of OP pulse)
% DigitalPulse(calctime(curtime,1.0),12,0.1,1);
% 
% %digital trigger  (end of OP pulse)
% DigitalPulse(calctime(curtime,1.3),12,0.1,1);


%turn on the Y (quantizing) shim on after 400us (the MOT turn-off time)
setAnalogChannel(calctime(curtime,0.0),19,3.5); %setAnalogChannel(calctime(curtime,0.4),19,3.5);


%turn repump back up
if seqdata.atomtype==1 
    setAnalogChannel(curtime,25,0.3);
elseif seqdata.atomtype==3
    setAnalogChannel(curtime,2,0.3);
elseif seqdata.atomstype==4
    setAnalogChannel(curtime,25,0.3);
    setAnalogChannel(curtime,2,0.3);
end


if seqdata.atomtype==1 
    opanalogid = 29;
    opshutter = 30;
    opttl = 9;
elseif seqdata.atomtype==3
    opanalogid = 36;
    opshutter = 25;
    opttl = 24;
elseif seqdata.atomtype==4
    opanalogid = 36;
    opshutter = 25;
    opttl = 24;    
end

 op_am = 0.4;

%Prepare OP light
%shutter
setDigitalChannel(calctime(curtime,-10),opshutter,1);
%analog
setAnalogChannel(calctime(curtime,-5),opanalogid,op_am); %0.11
%TTL
setDigitalChannel(calctime(curtime,-10),opttl,1);
%detuning

if seqdata.atomtype == 1 %K40

op_offset_detuning = 782; %6905 at room temp
MOT_detuning = 755;

    %offset piezo FF
        %set to value for OP
        setAnalogChannel(calctime(curtime,0.5),35,-2.97+0.004*op_offset_detuning,1);
        %set back to previous value (MOT detuning) for absorption 
        %setAnalogChannel(calctime(curtime,2.0),35,0,1);

    %offset detuning
    setAnalogChannel(calctime(curtime,0.5),34,op_offset_detuning); %780

elseif seqdata.atomtype == 2

    op_amp = 10;
    setAnalogChannel(curtime,5,op_amp); %27.5

elseif seqdata.atomtype == 3  %Rb87


    op_detuning = 32; %32

%     %list
% op_detuning_list=[ 15:2:25 ];
% 
% %Create linear list
% %index=seqdata.cycle;
% 
% %Create Randomized list
% index=seqdata.randcyclelist(seqdata.cycle);
% 
% op_detuning = op_detuning_list(index)
% addOutputParam('op_detuning',op_detuning);

    %these were for Rb
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,0.5),35,0.15+op_detuning*(-0.005),1); %-1.1
    %offset detuning ... should be close to the MOT detuning
    setAnalogChannel(calctime(curtime,0.5),34,6590+op_detuning);

end

%% OP

%300us OP pulse after 1.5ms for Shim coil to turn on
%TTL

curtime = DigitalPulse(calctime(curtime,1.0),opttl,1.0,0); %1.5



%% Finish OP

curtime = calctime(curtime,0.1);

%turn the OP light off
    %analog
    %setAnalogChannel(calctime(curtime,0),opanalogid,0);
    %ttl
    setDigitalChannel(calctime(curtime,0),opttl,1);
    %close shutter
    setDigitalChannel(calctime(curtime,2),opshutter,0);


%set trap laser back
if seqdata.atomtype == 1
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,1.0),35,0.06); 
    %offset detuning
    setAnalogChannel(calctime(curtime,1.0),34,756);
elseif seqdata.atomtype == 3
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,1.0),35,0); 
    %offset detuning
    setAnalogChannel(calctime(curtime,1.0),34,6590+25);
end


%digital trigger
    DigitalPulse(calctime(curtime,0),12,0.1,1);

            
timeout = curtime;

end