%------
%Author: DJ
%Created: Sep 2009
%Summary: This function makes an Optical Pumping sequence
%------

%-----Update List-------
%Aug 12, 2010: Put code from Load_MagTrap_sequence into here (DCM)
%-----------------------

function timeout = optical_pumping(timein,image_loc)

global seqdata;

curtime = timein;

if nargin < 2
   image_loc = 1; 
end

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


%Turn repump back up
    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
        setAnalogChannel(curtime,25,0.3);
    end

    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
        setAnalogChannel(curtime,2,0.3);
    end


%Identify the channels for K and Rb 
k_opanalogid = 29;
k_opshutter = 30;
k_opttl = 9;
k_op_am = 0.15;%0.5

rb_opanalogid = 36;
rb_opshutter = 25;
rb_opttl = 24;
rb_op_am = 1*0.4;

 
%% Prepare OP Light

%K
if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %shutter
    setDigitalChannel(calctime(curtime,-10),k_opshutter,1);
    %analog
    setAnalogChannel(calctime(curtime,-5),k_opanalogid,k_op_am); %0.11
    %TTL
    setDigitalChannel(calctime(curtime,-10),k_opttl,1);
    %detuning
end


%Rb
if (seqdata.atomtype==3 || seqdata.atomtype==4)
    %shutter
    setDigitalChannel(calctime(curtime,-10),rb_opshutter,1);
    %analog
    setAnalogChannel(calctime(curtime,-5),rb_opanalogid,rb_op_am); %0.11
    %TTL
    setDigitalChannel(calctime(curtime,-10),rb_opttl,1);
    %detuning
end


%% Change detunings

%K40
if (seqdata.atomtype == 1 || seqdata.atomtype == 4)

    k_op_detuning = 200; 
        
    %set OP detuning
    setAnalogChannel(calctime(curtime,-0.5),30,k_op_detuning); %780
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,-0.5),5,20); %60
end


%Rb
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)

    rb_op_detuning = 32; %32

    %these were for Rb
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,0.5),35,0.15+rb_op_detuning*(-0.005),1); %-1.1
    %offset detuning ... should be close to the MOT detuning
    setAnalogChannel(calctime(curtime,0.5),34,6590+rb_op_detuning);
end


%% OP

%300us OP pulse after 1.5ms for Shim coil to turn on
%TTL


%K
if (seqdata.atomtype == 1 || seqdata.atomtype == 4)
    DigitalPulse(calctime(curtime,0.0),k_opttl,0.5,0); %1.5
end

%Rb
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
    DigitalPulse(calctime(curtime,1.0),rb_opttl,1.0,0); %1.5
end


curtime = calctime(curtime,0.6); %0.6

%curtime = calctime(curtime,0.5);

%% Finish OP

curtime = calctime(curtime,0.1);

%turn the OP light off

    %K
    if (seqdata.atomtype == 1 || seqdata.atomtype == 4)
        %analog
        %setAnalogChannel(calctime(curtime,0),k_opanalogid,0);
        %ttl
        setDigitalChannel(calctime(curtime,0),k_opttl,1);
        %close shutter if transporting to science cell
        if image_loc == 1
        setDigitalChannel(calctime(curtime,2),k_opshutter,0);
        end
    end
    
    %Rb
    if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
        %analog
        %setAnalogChannel(calctime(curtime,0),rb_opanalogid,0);
        %ttl
        setDigitalChannel(calctime(curtime,0),rb_opttl,1);
        %close shutter if transporting to science cell
        if image_loc == 1
        setDigitalChannel(calctime(curtime,2),rb_opshutter,0);
        end
    end    

%set Rb trap laser back
if (seqdata.atomtype == 3 || seqdata.atomtype == 4)
    %offset pizeo FF
    setAnalogChannel(calctime(curtime,1.0),35,0); 
    %offset detuning
    setAnalogChannel(calctime(curtime,1.0),34,6590+25);
end

%digital trigger
    DigitalPulse(calctime(curtime,0),12,0.1,1);
            
timeout = curtime;

end