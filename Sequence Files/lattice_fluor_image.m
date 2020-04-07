%------
%Author: DJ
%Created: Oct 2013
%Summary: This function takes a fluorescent image of atoms in lattice
%------

function timeout=lattice_fluor_image(timein,molasses_offset)

%Expose with iXon?
use_iXon = 1;

%Molasses_offset signifies how far back in time the molasses started (this
%function is called when the trap shuts off)

curtime = timein;
global seqdata;

%choose time after D1 start time to expose
cam_expose_start_time = 0+500+5; %5 for AM ramp, 50 to wait for atom loss

if use_iXon
    %Expose iXon Once to Clear Buffer
    DigitalPulse(calctime(curtime,-molasses_offset+cam_expose_start_time-6000),'iXon Trigger',1,1);
end
    
% Camera trigger at start of D1 molasses
if use_iXon
    DigitalPulse(calctime(curtime,-molasses_offset+cam_expose_start_time ),'iXon Trigger',1,1);
end
ScopeTriggerPulse(calctime(curtime,-molasses_offset+cam_expose_start_time ),'Start Fluorescence Capture',0.1);


% %Wait 4s
 curtime = calctime(curtime,6000);
 if use_iXon
    % %Camera trigger 
     DigitalPulse(calctime(curtime,0 ),'iXon Trigger',1,1);
end
 % %Wait 4s
 curtime = calctime(curtime,6000);
 
% 
% % %Load Lattice
 curtime = Load_Lattice(calctime(curtime,0));
 [curtime,molasses_offset_B] = imaging_molasses(curtime);
molasses_offset_B = molasses_offset;

% 
if use_iXon
    % %Camera trigger 
     DigitalPulse(calctime(curtime,-molasses_offset_B+cam_expose_start_time ),'iXon Trigger',1,1);
end
     
%  add time so that load lattice shuts off lattice
    curtime = calctime(curtime,500);
    
%     % eventually set all shims to zero (50ms after image was taken)
%     %set FB channel to 0 as well to keep from getting errors in
%     %AnalogFuncTo
%     setAnalogChannel(calctime(curtime,50),'X Shim',0,3);
%     setAnalogChannel(calctime(curtime,50),'Y Shim',0,4);
%     setAnalogChannel(calctime(curtime,50),'Z Shim',0,3);
%     setAnalogChannel(calctime(curtime,50),'FB current',0,1);



timeout=curtime;

end
