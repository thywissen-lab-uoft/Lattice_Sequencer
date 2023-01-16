%------
%Author: S. Trotzky
%Created: May 2014
%Summary: Based on the current Load_MagTrap_sequence, goes through a number
%   of steps toward transport and eventually switches back to a MOT to
%   measure a recapture fraction via MOT fluorescence
%------
function timeout = MOT_recapture_sequence(timein)

curtime = timein;

%% Initialize seqdata
global seqdata;

seqdata.numDDSsweeps = 0;
seqdata.scanindex = -1;

%%

initialize_channels();

%% Make sure Coil 16 fast switch is open

%fast switch is gone
%setAnalogChannel(calctime(curtime,0),31,6);


%% Switches

    %It's preferable to add a switch here than comment out code!
    
    %Special flags (relics from Load_MagTrap_sequence -- using the same
    %functions for MOT preparation, MagTrap loading, etc here)
    MOT_abs_image = 0; %Absorption image of the MOT (no load in mag trap);
    transfer_recap_curve = 0; %Transport curve from MOT and back
        
    %Addtl Flags (relics from Load_MagTrap_sequence -- using the same
    %functions for MOT preparation, MagTrap loading, etc here)
    seqdata.flags. controlled_load = 0; %do a specific load time
    controlled_load_time = 20000;    
    seqdata.flags.Rb_Probe_Order = 1;
    seqdata.flags.image_type = 0;
    seqdata.flags.image_loc = 1;
    
    scope_trigger = 'MOT Recapture';
    

%% Make sure necessary shutters are open (some are just initialized for
%% plotting)

    %Open Rb RP shutter to Probe/OP fibers (is already open from previous cycle, just initializing value in update table here).
    setDigitalChannel(calctime(curtime,0),'Rb Repump Imaging',1); %1 = open, 0 = closed
   
%% Make sure Shim supply relay is on

%Turn on MOT Shim Supply Relay
    SetDigitalChannel(calctime(curtime,0),33,1);  

%% Prepare to Load into the Magnetic Trap

    if ( seqdata.flags.controlled_load == 1 )

        %turn off trap
        setAnalogChannel(curtime,8,0);
        setDigitalChannel(curtime,4,0);

        %turn trap back on
        curtime = Load_MOT(calctime(curtime,500),30);

        %wait fixed amount of time
        curtime = calctime(curtime,controlled_load_time);

    else

        %this has been here for historic reasons
        curtime = calctime(curtime,1500);

    end

curtime = Prepare_MOT_for_MagTrap(curtime);

    %Turn off extra repump light being coupled into MOT chamber.
    setDigitalChannel(calctime(curtime,0),'Rb Repump Imaging',0);

    %set Quantizing shim back after optical pumping
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.9);

%% Load into Magnetic Trap

    if ~( MOT_abs_image || seqdata.flags.image_type==4 )

        %same as molasses (assume this zero's external fields)

        yshim2 = 0.9; %0.9
        xshim2 = 0.1; %0.1
        zshim2 = 0.0; %0.3  0.0 Dec 4th 2013

        % optimized shims for loading into mag trap
        setAnalogChannel(calctime(curtime,0.01),'Y MOT Shim',yshim2,3); %1.25
        setAnalogChannel(calctime(curtime,0.01),'X MOT Shim',xshim2,2); %0.3 
        setAnalogChannel(calctime(curtime,0.01),'Z MOT Shim',zshim2,2); %0.2
        

curtime = Load_MagTrap_from_MOT(curtime);


        if transfer_recap_curve && (seqdata.flags.hor_transport_type == 2)
curtime     = calctime(curtime,1000);
        end

    end
        
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.0,2); %2
   

%% Transport 

% could do a (partial) round trip transport here.


%% Final hold time

%     holdtime_list = [1:7]*1000;
%     holdtime = getScanParameter(holdtime_list, seqdata.scancycle, 0, 'holdtime');
curtime     = calctime(curtime,20000);

%% Post-sequence -- e.g. do controlled field ramps, heating pulses, etc.

%% Reset analog and digital channels to default values

curtime = Reset_Channels(calctime(curtime,0));


%% Load MOT

    rb_MOT_detuning = 33; %33  34
    k_MOT_detuning = 33; %33

    mot_wait_time = 50;

    if seqdata.flags.image_type==5
        mot_wait_time = 0;
    end

curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);
ScopeTriggerPulse(curtime,'MOT Recapture')
      
%set relay back
curtime = setDigitalChannel(calctime(curtime,10),'Z MOT Shim',0);



%% Scope trigger selection

SelectScopeTrigger(scope_trigger);

%% Timeout

timeout = curtime;


end