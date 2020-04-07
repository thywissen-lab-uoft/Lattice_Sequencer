function timeout = do_fast_plane_selection(timein, varargin)
%This function performs the plane selection sequence, taking inputs
%corresponding to the desired types of kills, sweeps, and associated
%parameters.  Unneccessary wait times have been trimmed, to try to reduce
%any loss of atoms shelved in F=7/2

%Written for selection of atoms in |9/2,-9/2>, with optical removal of
%unwanted atoms in F=9/2.  Field sweeps are used for plane selection.

%GE

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;
curtime = timein;

% the number of necessary input arguments (including timein)
narginfix = 1;

% Define valid options for this function and their default values here.
opt = struct('X_Shim_Offset', [], ... offset for the X Shim.
             'Y_Shim_Offset', [], ... offset for the Y Shim.
             'Z_Shim_Offset', [], ... offset for the Z Shim.
             'Ramp_Fields_Up', 1, ... to ramp the fields, or not to ramp them.
             'Ramp_Fields_Down',1, ... to ramp the fields back down after selection
             'QP_Selection_Gradient', 7*1.78, ... gradient for plane selection.
             'Feshbach_Level', 2*22.6, ... feshbach level for plane selection.
             'Selection_Range', 10/1000, ... range of sweep for plane selection.
             'Selection__Frequency', 1388.550, ... frequency for plane selection from |9/2,-9/2>.
             'SRS_Selection', 0, ... Which of the two SRS generators to use (0: SRS A, 1: SRS B)
             'Microwave_Power_For_Selection', -12, ... microwave power for selection.
             'Sweep_About_Central_Frequency', 1, ... set to 1 to have plane selection be centred on input frequency. Else, it is start frequency. 
             'Microwave_Pulse_Length', 16.7, ... length of time for micrwave pulse. Often multiple of a period of 60Hz AC.
             'Resonant_Light_Removal', 1, ... Whether to use D2 light tuned to resonance in 40G to remove unwanted atoms 
             'Final_Transfer', 1, ... Whether to transfer atoms back to F=9/2 after removal of unwanted planes
             'Final_Transfer_Range',400/1000, ... %Frequency range for the global transfer
             'Fake_Pulse', 0 ... Whether to fake the plane selection pulse by keeping uWave switch closed
         );
     
%Define useful frequency units (program SRS in MHz)
    kHz = 1/1000;
    MHz = 1;

%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input is timein')
elseif (nargin >= narginfix)
    % an appropriate number of input arguments -- check their validity
end

% checking the optional input arguments
if ( ~isempty(varargin) )
    optnames = {};
    optvalues = {};

    % if first optional arguments are structures, read in their fields first
    while ( isstruct(varargin{1}) )
        addnames = fieldnames(varargin{1});
        for j = 1:length(addnames)
            optnames{end+1} = addnames{j};
            optvalues{end+1} = varargin{1}.(addnames{j});
        end
        varargin = varargin(2:end); % remove first argument from list
        if ( isempty(varargin) ); break; end
    end 

    % check that there is an even number of remaining optional arguments
    if mod(length(varargin),2)
        error('Optional arguments must be given in pairs ...''name'',value,... !');
    else
        for j = 1:(length(varargin)/2)
            % check that the first part of each pair is a string
            if ~ischar(varargin{2*j-1})
                error('Optional arguments must be given in pairs ...''name'',value,... !');
            else
                optnames{end+1} = varargin{2*j-1};
                optvalues{end+1} = varargin{2*j};
            end
        end
    end

    % assigning values to optional arguments to fields of structure 'opt',
    % provided that these fields were initialized above
    for j =1:length(optnames)
        % check that the option is valid; i.e. defined as a field of the
        % structure opt. Make it an error if needed.
        if ~isfield(opt,optnames{j})
            disp([mename '::Unknown option ''' optnames{j} ''' !']);
            % error('Unknown option ''' optnames{j} ''' !'); 
        else
            opt.(optnames{j}) = optvalues{j};
        end
    end

    clear('varargin','optnames','optvalues');
    
end

%% Plane Selection

% Ramp up gradient and Feshbach field   
    FB_init = getChannelValue(seqdata,37,1,0);
    if opt.Ramp_Fields_Up

        newramp = struct('FeshValue',opt.Feshbach_Level,'QPValue',opt.QP_Selection_Gradient,'SettlingTime',200);

curtime = rampMagneticFields(calctime(curtime,0), newramp);

    end
        
        
%Settings for plane selection

    spect_pars.freq = opt.Selection__Frequency;
    spect_pars.SRS_select = opt.SRS_Selection;
    spect_pars.power = opt.Microwave_Power_For_Selection;
    spect_pars.delta_freq = opt.Selection_Range;
    spect_pars.mod_dev = max([ 200*kHz, (opt.Selection_Range/2 + 5*kHz) , (opt.Final_Transfer_Range/2 + 5*kHz) ]);
    spect_pars.pulse_length = opt.Microwave_Pulse_Length;
    spect_pars.uwave_delay = 0; 
    spect_type = 2;             %Pulse uWave source
    spect_pars.pulse_type = 1;  %Ramp up/down the uWave power
    spect_pars.AM_ramp_time = 15;
    spect_pars.fake_pulse = opt.Fake_Pulse;
    
    if(~opt.Sweep_About_Central_Frequency)
        spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
    end
    
%Select desired atoms with field sweep

    ScopeTriggerPulse(curtime,'Plane Select');

    
    %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
    dBz = spect_pars.delta_freq / (5.714);  % sweeping over a large range (equiv to 1800kHz) to transfer the full cloud.
    field_shift_time = 20;                  % time to shift the field to the initial value for the sweep (and from the final value)
    field_shift_settle = 40;                % settling time after initial and final field shifts
    
    if (opt.Sweep_About_Central_Frequency)
        %Shift field down and up by half of the desired width
        z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
        z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
        z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
    else %Start at current field and ramp up
        z_shim_sweep_start = getChannelValue(seqdata,28,1,0);
        z_shim_sweep_center = z_shim_sweep_start+dBz/2;
        z_shim_sweep_final = z_shim_sweep_start+1*dBz;
    end
    
    %Ramp shim to start value before generator turns on
    clear('ramp');
    ramp.shim_ramptime = field_shift_time;
    ramp.shim_ramp_delay = -field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
    ramp.zshim_final = z_shim_sweep_start;
    
    ramp_bias_fields(calctime(curtime,0), ramp);
    
    %Ramp shim during uwave pulse to transfer atoms
    ramp.shim_ramptime = spect_pars.pulse_length;
    ramp.shim_ramp_delay = 0;
    ramp.zshim_final = z_shim_sweep_final;
    
    ramp_bias_fields(calctime(curtime,0), ramp);
    
    if opt.Final_Transfer
        %Ramp shim far away to prep for final transfer
        
        %Take frequency range in MHz, convert to shim range in Amps
        %(-5.714 MHz/A on Jan 29th 2015)
        dBz_final = opt.Final_Transfer_Range / (5.714);
        
        final_sweep_time = 80*opt.Final_Transfer_Range; %Seems to give good LZ transfer for power = -12dBm peak
        field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
        field_shift_settle = 10; % settling time after initial and final field shifts
           
        z_shim_sweep_start = z_shim_sweep_center-1*dBz_final/2;
        z_shim_sweep_final = z_shim_sweep_center+1*dBz_final/2;
        
        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_start;
        
        ramp_bias_fields(calctime(curtime,0), ramp);
    else
        %Ramp shim back to initial value after selection is complete
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_start;

        ramp_bias_fields(calctime(curtime,0), ramp);
    end
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);  
    
%Remove unwanted atoms with resonant D2 light down through the microscope
if opt.Resonant_Light_Removal
    
    kill_probe_pwr = 0.05;
    kill_time = 5;
    kill_detuning = 108; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field
                         %110 MHz to be resonant with |9/2,-9/2> -> |11/2,-11/2> transition in 40G field

    pulse_offset_time = 1; %Need to step back in time a bit to do the kill pulse
                            % directly after transfer, not after the subsequent wait times
    %set probe detuning
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
    %set trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5

    %open K probe shutter
    setDigitalChannel(calctime(curtime,pulse_offset_time-10),'Downwards D2 Shutter',1); %0=closed, 1=open
    %turn up analog
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
    %set TTL off initially
    setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);

    %pulse beam with TTL
curtime = DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);

    %close K probe shutter
    setDigitalChannel(calctime(curtime,2),'Downwards D2 Shutter',0);
    
end

%Transfer atoms back into F=9/2 after removal of unselected planes
if opt.Final_Transfer
    % wait time (code related -- need to accomodate for AnalogFuncTo calls to the past in ramp_bias_fields)
    curtime = calctime(curtime,0);

    %SRS in pulsed mode with amplitude modulation
    spect_type = 2;
    spect_pars.pulse_type = 0; %Don't need to ramp up and down for this transfer

    %Ramp shim during uwave pulse to transfer atoms
    ramp.shim_ramptime = final_sweep_time;
    ramp.shim_ramp_delay = 0;
    ramp.zshim_final = z_shim_sweep_final;
    ramp_bias_fields(calctime(curtime,0), ramp);

    %Ramp shim back to initial value after pulse is complete
    ramp.shim_ramptime = field_shift_time;
    ramp.shim_ramp_delay = final_sweep_time+field_shift_settle; %offset from the beginning of uwave pulse
    ramp.zshim_final = z_shim_sweep_center;
    ramp_bias_fields(calctime(curtime,0), ramp);
            
    %Set SRS AM to high for return sweep
    setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
    
    spect_pars.pulse_length = final_sweep_time;
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);  
    plane_select_finish_time = calctime(curtime,spect_pars.pulse_length);

    %Set SRS AM back to normal
    setAnalogChannel(calctime(curtime,0),'uWave FM/AM',-1);
    
    %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_time+5); 

    %Follow up uWave transfer with a repumping pulse to empty F=7/2
        % (do this during as soon as selection pulse is finished)
        % (would be great to use FM to get the repump to resonance in the 40G field)
                
    repump_delay = 2;       %How long to wait after uWave pulse is over
    repump_pulse_time = 5;  %How long to pulse repump light
    repump_pulse_power = 0.7;

    %Open Repump Shutter
    setDigitalChannel(calctime(plane_select_finish_time,-10),3,1);
    %turn repump back up
    setAnalogChannel(calctime(plane_select_finish_time,-10),25,repump_pulse_power);
    %repump TTL
    setDigitalChannel(calctime(plane_select_finish_time,-10),7,1);

    %Repump pulse
    DigitalPulse(calctime(plane_select_finish_time,repump_delay),7,repump_pulse_time,0);

    %Close Repump Shutter
    setDigitalChannel(calctime(plane_select_finish_time,repump_delay+repump_pulse_time+5),3,0);


end
        

%Ramp Feshbach field and QP gradient back to original values after plane selection
if opt.Ramp_Fields_Down
    clear('ramp');

    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = FB_init;

    % QP coil settings for spectroscopy
    ramp.QP_ramptime = 50;
    ramp.QP_ramp_delay = -0;
    ramp.QP_final =  0;

    ramp.settling_time = 200; %200
       
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
end
        
%% assigning outputs (edit with care!)
    timeout = curtime;
