function timeout = do_horizontal_plane_selection(timein, varargin)
%This function performs a horizontal plane selection sequence, taking inputs
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
opt = struct('Offset_Field',4, ... field (in G) to horizontally offset the QP gradient
             'X_Shim_Offset', (seqdata.params. shim_zero(1)-1.120)*7/11, ... offset for the X Shim. (seqdata.params. shim_zero(1)+0.240)*7/11
             'Y_Shim_Offset', (seqdata.params. shim_zero(2)+0.15-0.025)*7/11, ... offset for the Y Shim. (seqdata.params. shim_zero(2)-1.4525)*7/11
             'Selection_Angle', 0, ... some angle (in deg) to select w.r.t x lattice
             'Z_Shim_Offset', -0.2, ... offset for the Z Shim.
             'Ramp_Fields_Up', 1, ... to ramp the fields, or not to ramp them.
             'Ramp_Fields_Down',1, ... to ramp the fields back down after selection
             'QP_Selection_Gradient', 7*1.78, ... gradient for plane selection.
             'Feshbach_Level', 0.01, ... feshbach level for plane selection.
             'Selection_Range', 100/1000, ... range of sweep for plane selection.
             'Selection_Frequency', 1285.8+10.750, ... frequency for plane selection from |9/2,-9/2>.
             'Raman_AOM_Frequency', 110, ... Frequency of Raman excitation AOM.
             'Rigol_Mode', 'Pulse', ... Whether to pulse, sweep, or modulate the Rigol output.
             'Modulation_Time', 1, ... Period of modulation of Rigol in 'modulate' mode.
             'SRS_Selection', 1, ... Which of the two SRS generators to use (0: SRS A, 1: SRS B)
             'Microwave_Or_Raman', 1, ... Whether to use microwaves or Raman beams to transfer atoms.
             'Microwave_Power_For_Selection', 8, ... microwave power for selection.
             'Sweep_About_Central_Frequency', 1, ... set to 1 to have plane selection be centred on input frequency. Else, it is start frequency. 
             'Microwave_Pulse_Length', 16.7, ... length of time Sfor micrwave pulse. Often multiple of a period of 60Hz AC.
             'Resonant_Light_Removal', 1, ... Whether to use D2 light to remove unwanted atoms 
             'Final_Transfer', 1, ... Whether to transfer atoms back to F=9/2 after removal of unwanted planes
             'Final_Transfer_Range',1500/1000, ... %Frequency range for the global transfer
             'Repump_Pulse', 0, ... %A repump pulse after final transfer to make sure everything is back in F=9/2
             'Post_Selection_Wait_Time', 10, ... wait time after doing plane selection, letting fields settle
             'Fake_Pulse', 0, ... Whether to fake the plane selection pulse by keeping uWave switch closed
             'Double_Selection', 0, ... Whether to do two selections and kill pulses back to back
             'Selection_Angle_B', 0, ... Angle to rotate for the second selection
             'Selection_Range_B', 100/1000, ... Width of the second sweep (MHz)
             'Final_Transfer_Range_B', 1500/1000, ... %Frequency range for the global transfer after second selection
             'Shim_Rotation_Time', 40, ... Time taken to rotate to the second field (ms)
             'Field_Shift', 0, ... Small change in field for the first selection (for moving a selected region around)
             'Field_Shift_B', 0, ... Change in field for the second selection
             'Fake_Pulse_B', 0, ... Whether to fake the plane second selection pulse
             'Num_Frames', 1, ... How many frames in a fluorescence image.
             'Fluorescence_Image', 0, ... Whether to take a fluorescence image during RSC.
             'F_Pump_Power', 0, ... F pump power for RSC.
             'Raman_Power1', 0, ... Voltage sent to Raman AOMS.
             'Raman_Power2', 0, ... Voltage sent to Raman AOMS.
             'Use_EIT_Beams', 0, ... Whether to turn on EIT beams.
             'Enable_FPump', 0, ...
             'Enable_EITProbe', 0, ...
             'Enable_Raman', 0 ...
         );
     
     
     
%Define useful frequency units (program SRS in MHz)
    kHz = 1/1000;
    MHz = 1;

%% Check inputs
% Process the varargins. After timein it could either be a structure with
% field names and values, or it could be a set of string and value pairs.

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

    % varargin is a structure
    while ( isstruct(varargin{1}) )
        
        addnames = fieldnames(varargin{1});
        for j = 1:length(addnames)
            optnames{end+1} = addnames{j};
            optvalues{end+1} = varargin{1}.(addnames{j});
        end
        varargin = varargin(2:end); % remove first argument from list
        if ( isempty(varargin) ); break; end
    end 

    % varargin is an even length string and value pairs
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

    % Assign the processed varargins to the opt struct
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

%% Calculate X and Y shim values for selection
%Selection Angle allows us to rotate the horizontal cut around the z axis
%Selection Angle = 0 corresponds to an X shim field, which points along the Y Lattice

% Convert the quantization magnetic field to frequency (|9,-9>->|7,-7>)
frequency_shift = (opt.Offset_Field + opt.Field_Shift)*2.4889; % MHz

% Coefficients that convert from XY shim current (A) to frequency (MHz) 
Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2]; % MHz/A

%Determine how much to turn on the X and Y shims to get this frequency
%shift at the requested angle
X_Shim_Value = frequency_shift * cosd(opt.Selection_Angle) / Shim_Calibration_Values(1);
Y_Shim_Value = frequency_shift * sind(opt.Selection_Angle) / Shim_Calibration_Values(2);


%% Plane Selection

% Ramp up gradient and Feshbach field  
    if opt.Ramp_Fields_Up
        newramp = struct('ShimValues',seqdata.params.shim_zero + ...
            [X_Shim_Value+opt.X_Shim_Offset, ...
            Y_Shim_Value+opt.Y_Shim_Offset, ...
            opt.Z_Shim_Offset],...
            'FeshValue',opt.Feshbach_Level,...
            'QPValue',opt.QP_Selection_Gradient,...
            'SettlingTime',100);
curtime = rampMagneticFields(calctime(curtime,0), newramp);
    end
        
field_shift_time = 20;                  % time to shift the field to the initial value for the sweep (and from the final value)
field_shift_settle = 40;                % settling time after initial and final field shifts
 

    if (opt.Microwave_Or_Raman == 1)
%%   

        %Settings for plane selection
        spect_pars.freq = opt.Selection_Frequency;
        spect_pars.SRS_select = opt.SRS_Selection;
        spect_pars.power = opt.Microwave_Power_For_Selection;
        spect_pars.delta_freq = opt.Selection_Range;
        spect_pars.mod_dev = max([ 200*kHz, (opt.Selection_Range/2 + 5*kHz) , ...
            (opt.Double_Selection*opt.Selection_Range_B/2 + 5*kHz)]);
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
        dBx = spect_pars.delta_freq * cosd(opt.Selection_Angle) / Shim_Calibration_Values(1);
        dBy = spect_pars.delta_freq * sind(opt.Selection_Angle) / Shim_Calibration_Values(2);

        if (opt.Sweep_About_Central_Frequency)
            %Shift field down and up by half of the desired width
            x_shim_sweep_center = getChannelValue(seqdata,'X Shim',1,0);
            x_shim_sweep_start = x_shim_sweep_center-1*dBx/2;
            x_shim_sweep_final = x_shim_sweep_center+1*dBx/2;

            y_shim_sweep_center = getChannelValue(seqdata,'Y Shim',1,0);
            y_shim_sweep_start = y_shim_sweep_center-1*dBy/2;
            y_shim_sweep_final = y_shim_sweep_center+1*dBy/2;
        else %Start at current field and ramp up
            x_shim_sweep_center = getChannelValue(seqdata,'X Shim',1,0);
            x_shim_sweep_start = x_shim_sweep_center;
            x_shim_sweep_final = x_shim_sweep_center+1*dBx;

            y_shim_sweep_center = getChannelValue(seqdata,'Y Shim',1,0);
            y_shim_sweep_start = y_shim_sweep_center;
            y_shim_sweep_final = y_shim_sweep_center+1*dBy;
        end
    
        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = -field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_start;
        ramp.yshim_final = y_shim_sweep_start;
        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim during uwave pulse to transfer atoms
        ramp.shim_ramptime = spect_pars.pulse_length;
        ramp.shim_ramp_delay = 0;
        ramp.xshim_final = x_shim_sweep_final;
        ramp.yshim_final = y_shim_sweep_final;

        ramp_bias_fields(calctime(curtime,0), ramp);
    
        if (opt.Final_Transfer && ~opt.Double_Selection)
            %Ramp shim far away to prep for final transfer

            %Take frequency range in MHz, convert to shim range in Amps
            %(-5.714 MHz/A on Jan 29th 2015)
            dBx = opt.Final_Transfer_Range * cosd(opt.Selection_Angle) / Shim_Calibration_Values(1);
            dBy = opt.Final_Transfer_Range * sind(opt.Selection_Angle) / Shim_Calibration_Values(2);

            final_sweep_time = 150*opt.Final_Transfer_Range; %Seems to give good LZ transfer for power = -12dBm peak
            field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = max([field_shift_time, spect_pars.AM_ramp_time]); % settling time after initial and final field shifts

            x_shim_sweep_start = x_shim_sweep_center-1*dBx/2;
            x_shim_sweep_final = x_shim_sweep_center+1*dBx/2;

            y_shim_sweep_start = y_shim_sweep_center-1*dBy/2;
            y_shim_sweep_final = y_shim_sweep_center+1*dBy/2;

            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.xshim_final = x_shim_sweep_start;
            ramp.yshim_final = y_shim_sweep_start;

            ramp_bias_fields(calctime(curtime,0), ramp);
        
        elseif opt.Double_Selection
            %Rotate to the new selection field (Kill pulses will be done in
            %   the second selection field)

            %Determine the requested frequency offset from zero-field resonance
            frequency_shift_B = (opt.Offset_Field + opt.Field_Shift_B )*2.4889;

            %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
            Shim_Calibration_Values = [2.4889*2, 0.994*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to

            %Determine how much to turn on the X and Y shims to get this frequency
            %shift at the requested angle
            X_Shim_Value_B = frequency_shift_B * cosd(opt.Selection_Angle_B) / Shim_Calibration_Values(1);
            Y_Shim_Value_B = frequency_shift_B * sind(opt.Selection_Angle_B) / Shim_Calibration_Values(2);

            x_shim_sweep_center = seqdata.params.shim_zero(1) + X_Shim_Value_B + opt.X_Shim_Offset;
            y_shim_sweep_center = seqdata.params.shim_zero(2) + Y_Shim_Value_B + opt.Y_Shim_Offset;

            if opt.Final_Transfer
                %We will do the final transfer in the rotated coordinates

                final_sweep_time = 150*opt.Final_Transfer_Range; %Seems to give good LZ transfer for power = -12dBm peak
                field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
                field_shift_settle = max([field_shift_time, spect_pars.AM_ramp_time]); % settling time after initial and final field shifts

                dBx_B_Final = opt.Final_Transfer_Range * cosd(opt.Selection_Angle_B) / Shim_Calibration_Values(1);
                dBy_B_Final = opt.Final_Transfer_Range * sind(opt.Selection_Angle_B) / Shim_Calibration_Values(2);

                dBx_B = opt.Selection_Range_B * cosd(opt.Selection_Angle_B) / Shim_Calibration_Values(1);
                dBy_B = opt.Selection_Range_B * sind(opt.Selection_Angle_B) / Shim_Calibration_Values(2);

                %Shift field down and up by half of the desired width
                x_shim_sweep_start = x_shim_sweep_center-1*dBx_B_Final/2;
                x_shim_sweep_final = x_shim_sweep_center+1*dBx_B_Final/2;

                y_shim_sweep_start = y_shim_sweep_center-1*dBy_B_Final/2;
                y_shim_sweep_final = y_shim_sweep_center+1*dBy_B_Final/2;

            else
                %No final transfer, just set shims for next selection pulse

                dBx_B = opt.Selection_Range_B * cosd(opt.Selection_Angle_B) / Shim_Calibration_Values(1);
                dBy_B = opt.Selection_Range_B * sind(opt.Selection_Angle_B) / Shim_Calibration_Values(2);

                if (opt.Sweep_About_Central_Frequency)
                    %Shift field down and up by half of the desired width
                    x_shim_sweep_start = x_shim_sweep_center-1*dBx_B/2;
                    x_shim_sweep_final = x_shim_sweep_center+1*dBx_B/2;

                    y_shim_sweep_start = y_shim_sweep_center-1*dBy_B/2;
                    y_shim_sweep_final = y_shim_sweep_center+1*dBy_B/2;
                else %Start at current field and ramp up
                    x_shim_sweep_start = x_shim_sweep_center;
                    x_shim_sweep_final = x_shim_sweep_center+1*dBx_B;

                    y_shim_sweep_start = y_shim_sweep_center;
                    y_shim_sweep_final = y_shim_sweep_center+1*dBy_B;
                end

            end
        
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = opt.Shim_Rotation_Time;
            ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.xshim_final = x_shim_sweep_start;
            ramp.yshim_final = y_shim_sweep_start;

            ramp_bias_fields(calctime(curtime,0), ramp);


        else
            %Ramp shim back to initial value after selection is complete

            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.xshim_final = x_shim_sweep_center;
            ramp.yshim_final = y_shim_sweep_center;

            ramp_bias_fields(calctime(curtime,0), ramp);
        end       
       
%Execute the transfer pulse
% DigitalPulse(calctime(curtime,-2),'Raman TTL',opt.Microwave_Pulse_Length+4,1);
% DigitalPulse(calctime(curtime,0),'Raman TTL',spect_pars.pulse_length,0);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
%         F_Pump_Time = 0.02;
%         %F-mF pump AOM-shutter sequence.
%         setAnalogChannel(calctime(curtime,0),'F Pump',opt.F_Pump_Power);
%         DigitalPulse(calctime(curtime,-10),'F Pump TTL',10,1);
%         DigitalPulse(calctime(curtime,-5),'D1 Shutter',F_Pump_Time+10,1);
%         DigitalPulse(calctime(curtime,F_Pump_Time),'F Pump TTL',10,1);
%         setAnalogChannel(calctime(curtime,F_Pump_Time),'F Pump',-1);

%%
    elseif (opt.Microwave_Or_Raman == 2)
        % Program Rigol generator
        if strcmp(opt.Rigol_Mode, 'Sweep')
            str = sprintf(['SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce ' ...
                'EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer ' ...
                '%gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;SOURce2:VOLT %g;'], ...
                opt.Modulation_Time, opt.Raman_AOM_Frequency, opt.Selection_Range, ...
                opt.Raman_Power1, opt.Raman_Power2);      
        elseif strcmp(opt.Rigol_Mode, 'Pulse')
            str = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;SOURce2:VOLT %gVPP;', ...
                opt.Raman_AOM_Frequency, opt.Raman_Power1, opt.Raman_Power2);
        elseif strcmp(opt.Rigol_Mode, 'Modulate')
            str = sprintf('SOURce1:MOD:STATe ON;SOURce1:MOD:TYPe FM;SOURce1:MOD:FM:INTernal:FUNCtion TRIangle;SOURce1:MOD:FM:INTernal:FREQuency %gKHZ;SOURce1:FREQuency %gMHZ;SOURce1:MOD:FM:DEViation %gMHZ;SOURce1:VOLT %g;SOURce2:VOLT %g;', ...
                1/opt.Modulation_Time, opt.Raman_AOM_Frequency, abs(opt.Selection_Range), opt.Raman_Power1, opt.Raman_Power2);            
        end
        
        if opt.Microwave_Pulse_Length>0

            addVISACommand(1, str); 
            if opt.Use_EIT_Beams
                %Turn on EIT beams.
                %Turn off F-Pump and probe AOMs before use. 
                setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
                setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);


                setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);

                %Open shutters just before beams turn on.
                setDigitalChannel(calctime(curtime,-5),'EIT Shutter',1);
                setDigitalChannel(calctime(curtime,-5),'D1 Shutter',1);

                %Set F-pump on and enable feedback, turn on probe AOM also.
                setAnalogChannel(calctime(curtime,0),'F Pump',opt.F_Pump_Power);
                setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
                setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
                setDigitalChannel(calctime(curtime,0),'D1 TTL',1);            
            end
            %Raman excitation beam AOM-shutter sequence.
            DigitalPulse(calctime(curtime,-150),'Raman TTL 1',150,0);
            DigitalPulse(calctime(curtime,-150),'Raman TTL 2',150,0);
            DigitalPulse(calctime(curtime,-150),'Raman TTL 2a',150,0);

            DigitalPulse(calctime(curtime,-150),'Raman TTL 3',5200,0);
            DigitalPulse(calctime(curtime,-150),'Raman TTL 3a',5200,0);

            DigitalPulse(calctime(curtime,-100),'Raman Shutter',...
                opt.Microwave_Pulse_Length+3100,1);% CF 2021/03/30 new shutter

            DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 1',3050,0);
            DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 2',3050,0);
            DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 2a',3050,0);


            if opt.Use_EIT_Beams
                %Turn off EIT beams.
                %Turn off AOMs.
                setAnalogChannel(calctime(curtime,opt.Microwave_Pulse_Length),'F Pump',-1);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length),'F Pump TTL',1);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length),'FPump Direct',1);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length),'D1 TTL',0);
                %Close shutters after AOMs off.
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length+5),'EIT Shutter',0);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length+5),'D1 Shutter',0);            
                %Turn AOMs back on for stability. 
                setAnalogChannel(calctime(curtime,opt.Microwave_Pulse_Length+10),'F Pump',9.99);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length+10),'F Pump TTL',0);
                setDigitalChannel(calctime(curtime,opt.Microwave_Pulse_Length+10),'D1 TTL',1);
    %             DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'D1 OP TTL',10,0);
    curtime =   calctime(curtime,opt.Microwave_Pulse_Length);
            end        
        end
        
        
        
        if (opt.Fluorescence_Image == 1)
            iXon_FluorescenceImage(curtime,'ExposureOffsetTime',opt.Microwave_Pulse_Length,'ExposureDelay',0,'FrameTime',opt.Microwave_Pulse_Length/opt.Num_Frames,'NumFrames',opt.Num_Frames)
        end     
        
        
        
    elseif (opt.Microwave_Or_Raman == 3)  %doing Raman transfers with field sweeps
        %%
        spect_pars.pulse_length = opt.Microwave_Pulse_Length;
        
        
        str = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;SOURce2:VOLT %gVPP;', opt.Raman_AOM_Frequency, opt.Raman_Power1, opt.Raman_Power2);
        addVISACommand(1, str);
        
        
        %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
        dBx = opt.Selection_Range * cosd(opt.Selection_Angle) / Shim_Calibration_Values(1);
        dBy = opt.Selection_Range * sind(opt.Selection_Angle) / Shim_Calibration_Values(2);

        if (opt.Sweep_About_Central_Frequency)
            %Shift field down and up by half of the desired width
            x_shim_sweep_center = getChannelValue(seqdata,'X Shim',1,0);
            x_shim_sweep_start = x_shim_sweep_center-1*dBx/2;
            x_shim_sweep_final = x_shim_sweep_center+1*dBx/2;

            y_shim_sweep_center = getChannelValue(seqdata,'Y Shim',1,0);
            y_shim_sweep_start = y_shim_sweep_center-1*dBy/2;
            y_shim_sweep_final = y_shim_sweep_center+1*dBy/2;
        else %Start at current field and ramp up
            x_shim_sweep_center = getChannelValue(seqdata,'X Shim',1,0);
            x_shim_sweep_start = x_shim_sweep_center;
            x_shim_sweep_final = x_shim_sweep_center+1*dBx;

            y_shim_sweep_center = getChannelValue(seqdata,'Y Shim',1,0);
            y_shim_sweep_start = y_shim_sweep_center;
            y_shim_sweep_final = y_shim_sweep_center+1*dBy;
        end
    
        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = -field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_start;
        ramp.yshim_final = y_shim_sweep_start;
        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim during uwave pulse to transfer atoms
        ramp.shim_ramptime = spect_pars.pulse_length;
        ramp.shim_ramp_delay = 0;
        ramp.xshim_final = x_shim_sweep_final;
        ramp.yshim_final = y_shim_sweep_final;

        ramp_bias_fields(calctime(curtime,0), ramp);
        
  
        %Ramp shim back to initial value after selection is complete

        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_center;
        ramp.yshim_final = y_shim_sweep_center;

        ramp_bias_fields(calctime(curtime,0), ramp);      
                
        
        %Raman excitation beam AOM-shutter sequence.
        DigitalPulse(calctime(curtime,-150),'Raman TTL 1',150,0);
        DigitalPulse(calctime(curtime,-150),'Raman TTL 2',10,0);
        DigitalPulse(calctime(curtime,-150),'Raman TTL 2a',150,0);


        
%         DigitalPulse(calctime(curtime,-100),'Raman Shutter',opt.Microwave_Pulse_Length+3100,0);
        DigitalPulse(calctime(curtime,-100),'Raman Shutter',opt.Microwave_Pulse_Length+3100,1);% CF 2021/03/30 new shutter

        DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 1',3050,0);
        DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 2',3050,0);
        DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 2a',3050,0);


        
        % add some wait time for the shims to ramp back
        curtime = calctime(curtime,25);
    
    
    end
%%
   
if opt.Double_Selection
    %Leave extra time for the large change in shim field
    curtime = calctime(curtime,opt.Shim_Rotation_Time+field_shift_settle);
end

%%
    
%Remove unwanted atoms with resonant D2 light down through the microscope
if opt.Resonant_Light_Removal
    
    kill_probe_pwr = 0.06;
    kill_time = 100;
    kill_detuning = 54; %56 MHz to be resonant with |9/2,-9/2> -> |11/2,-11/2> transition in 4G field

    pulse_offset_time = 1; %Need to step back in time a bit to do the kill pulse
                            % directly after transfer, not after the subsequent wait times
    %set probe detuning
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
    %set trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5

    %open K probe shutter
    setDigitalChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP shutter',1); %0=closed, 1=open
    %turn up analog
    setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
    %set TTL off initially
    setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);

    %pulse beam with TTL
curtime = DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);

    %close K probe shutter
    setDigitalChannel(calctime(curtime,2),'K Probe/OP shutter',0);
    
end

%%

%Transfer atoms back into F=9/2 after removal of unselected planes
if opt.Final_Transfer
    % wait time (code related -- need to accomodate for AnalogFuncTo calls to the past in ramp_bias_fields)
    curtime = calctime(curtime,10);

    final_sweep_time = 150*opt.Final_Transfer_Range;
    
    %SRS in pulsed mode with amplitude modulation
    spect_type = 2;
    spect_pars.pulse_type = 0; %Don't need to ramp up and down for this transfer
    spect_pars.fake_pulse = opt.Fake_Pulse;

    %Ramp shim during uwave pulse to transfer atoms
    ramp.shim_ramptime = final_sweep_time;
    ramp.shim_ramp_delay = 0;
    ramp.xshim_final = x_shim_sweep_final;
    ramp.yshim_final = y_shim_sweep_final;
    ramp_bias_fields(calctime(curtime,0), ramp);

    %Ramp shim back to initial value after pulse is complete
    ramp.shim_ramptime = field_shift_time;
    ramp.shim_ramp_delay = final_sweep_time+field_shift_settle; %offset from the beginning of uwave pulse
    ramp.xshim_final = x_shim_sweep_center;
    ramp.yshim_final = y_shim_sweep_center;
    ramp_bias_fields(calctime(curtime,0), ramp);
            
    %Set SRS AM and VVA to high for return sweep
    setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
    setAnalogChannel(calctime(curtime,-5),'uWave VVA',10);
    
    spect_pars.pulse_length = final_sweep_time;
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);  
    plane_select_finish_time = calctime(curtime,spect_pars.pulse_length);

    %Set SRS AM and VVA back to normal
    setAnalogChannel(calctime(curtime,0),'uWave FM/AM',-1);
    setAnalogChannel(calctime(curtime,0),'uWave VVA',0);
    
    %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_time+5); 

    
    if opt.Repump_Pulse
        %Follow up uWave transfer with a repumping pulse to empty F=7/2
        % (do this as soon as selection pulse is finished)
        
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

end
  
%% Double Selection
if opt.Double_Selection
    %Second field sweep, kill pulse, and transfer
    
    spect_pars.freq = opt.Selection_Frequency;
    spect_pars.SRS_select = opt.SRS_Selection;
    spect_pars.power = opt.Microwave_Power_For_Selection;
    spect_pars.delta_freq = opt.Selection_Range_B;
    spect_pars.pulse_length = opt.Microwave_Pulse_Length;
    spect_pars.uwave_delay = 0; 
    spect_type = 2;             %Pulse uWave source
    spect_pars.pulse_type = 1;  %Ramp up/down the uWave power
    spect_pars.AM_ramp_time = 15;
    spect_pars.fake_pulse = opt.Fake_Pulse_B;
    
    if(~opt.Sweep_About_Central_Frequency)
        spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
    end
    
    field_shift_time = 20;                  % time to shift the field to the initial value for the sweep (and from the final value)
    field_shift_settle = 40;                % settling time after initial and final field shifts
    curtime = calctime(curtime,field_shift_time+field_shift_settle); %Adjust time to work with the code below
    
    if (opt.Sweep_About_Central_Frequency)
        %Shift field down and up by half of the desired width
        x_shim_sweep_start = x_shim_sweep_center-1*dBx_B/2;
        x_shim_sweep_final = x_shim_sweep_center+1*dBx_B/2;
        
        y_shim_sweep_start = y_shim_sweep_center-1*dBy_B/2;
        y_shim_sweep_final = y_shim_sweep_center+1*dBy_B/2;
    else %Start at current field and ramp up
        x_shim_sweep_start = x_shim_sweep_center;
        x_shim_sweep_final = x_shim_sweep_center+1*dBx_B;
        
        y_shim_sweep_start = y_shim_sweep_center;
        y_shim_sweep_final = y_shim_sweep_center+1*dBy_B;
    end
    
    %Ramp shim to start value before generator turns on
    clear('ramp');
    ramp.shim_ramptime = field_shift_time;
    ramp.shim_ramp_delay = -field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
    ramp.xshim_final = x_shim_sweep_start;
    ramp.yshim_final = y_shim_sweep_start;
    
    ramp_bias_fields(calctime(curtime,0), ramp);
    
    %Ramp shim during uwave pulse to transfer atoms
    ramp.shim_ramptime = spect_pars.pulse_length;
    ramp.shim_ramp_delay = 0;
    ramp.xshim_final = x_shim_sweep_final;
    ramp.yshim_final = y_shim_sweep_final;
    
    ramp_bias_fields(calctime(curtime,0), ramp);
    
    if opt.Final_Transfer
        %Ramp shim far away to prep for final transfer
        
        %Take frequency range in MHz, convert to shim range in Amps
        %(-5.714 MHz/A on Jan 29th 2015)
        dBx = opt.Final_Transfer_Range_B * cosd(opt.Selection_Angle_B) / Shim_Calibration_Values(1);
        dBy = opt.Final_Transfer_Range_B * sind(opt.Selection_Angle_B) / Shim_Calibration_Values(2);
        
        final_sweep_time = 150*opt.Final_Transfer_Range; %Seems to give good LZ transfer for power = -12dBm peak
        field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
        field_shift_settle = max([field_shift_time, spect_pars.AM_ramp_time]); % settling time after initial and final field shifts
        
        x_shim_sweep_start = x_shim_sweep_center-1*dBx/2;
        x_shim_sweep_final = x_shim_sweep_center+1*dBx/2;
        
        y_shim_sweep_start = y_shim_sweep_center-1*dBy/2;
        y_shim_sweep_final = y_shim_sweep_center+1*dBy/2;
        
        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_start;
        ramp.yshim_final = y_shim_sweep_start;
        
        ramp_bias_fields(calctime(curtime,0), ramp);  
        
    else
        %Ramp shim back to initial value after selection is complete
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_center;
        ramp.yshim_final = y_shim_sweep_center;
        
        ramp_bias_fields(calctime(curtime,0), ramp);
    end
    
    %Execute the transfer pulse
    curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
    
    curtime = calctime(curtime,field_shift_time+field_shift_settle); 
    
    
    %Remove unwanted atoms with resonant D2 light down in the probe path
    if opt.Resonant_Light_Removal
        
        kill_probe_pwr = 0.04;
        kill_time = 100;
        kill_detuning = 52; %56 MHz to be resonant with |9/2,-9/2> -> |11/2,-11/2> transition in 4G field
        
        pulse_offset_time = 1; %Need to step back in time a bit to do the kill pulse
        % directly after transfer, not after the subsequent wait times
        %set probe detuning
        setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
        %set trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5
        
        %open K probe shutter
        setDigitalChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP shutter',1); %0=closed, 1=open
        %turn up analog
        setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
        %set TTL off initially
        setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);
        
        %pulse beam with TTL
        curtime = DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);
        
        %close K probe shutter
        setDigitalChannel(calctime(curtime,2),'K Probe/OP shutter',0);
        
    end
    
    %Transfer atoms back into F=9/2 after removal of unselected planes
    if opt.Final_Transfer
        % wait time (code related -- need to accomodate for AnalogFuncTo calls to the past in ramp_bias_fields)
        curtime = calctime(curtime,10);
        
        %SRS in pulsed mode with amplitude modulation
        spect_type = 2;
        spect_pars.pulse_type = 0; %Don't need to ramp up and down for this transfer
        spect_pars.fake_pulse = opt.Fake_Pulse_B;
        
        %Ramp shim during uwave pulse to transfer atoms
        ramp.shim_ramptime = final_sweep_time;
        ramp.shim_ramp_delay = 0;
        ramp.xshim_final = x_shim_sweep_final;
        ramp.yshim_final = y_shim_sweep_final;
        ramp_bias_fields(calctime(curtime,0), ramp);
        
        %Ramp shim back to initial value after pulse is complete
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = final_sweep_time+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.xshim_final = x_shim_sweep_center;
        ramp.yshim_final = y_shim_sweep_center;
        ramp_bias_fields(calctime(curtime,0), ramp);
        
        %Set SRS AM to high for return sweep
        setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
        setAnalogChannel(calctime(curtime,-5),'uWave VVA',10);
        
        spect_pars.pulse_length = final_sweep_time;
        
        curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
        plane_select_finish_time = calctime(curtime,spect_pars.pulse_length);
        
        %Set SRS AM back to normal
        setAnalogChannel(calctime(curtime,0),'uWave FM/AM',-1);
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);
        
        %Wait for shim field to return to initial value
        curtime = calctime(curtime,field_shift_time+5);
        
        if opt.Repump_Pulse
            %Follow up uWave transfer with a repumping pulse to empty F=7/2
            % (do this as soon as selection pulse is finished)
            
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
        
    end
    
    
end

%% Final Field Rampdown
%Ramp Feshbach field and QP gradient back to original values after plane selection
if opt.Ramp_Fields_Down
    
    if ~(opt.Final_Transfer)
        curtime = calctime(curtime,field_shift_time+field_shift_settle); 
    end
        
    clear('ramp');

    % Shims go back to field-zero values
    ramp.shim_ramptime = 50;
    ramp.shim_ramp_delay = 0;
    ramp.xshim_final = seqdata.params. shim_zero(1);
    ramp.yshim_final = seqdata.params. shim_zero(2);
    ramp.zshim_final = seqdata.params. shim_zero(3);
    
    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 0.25*22.6;

    % QP coil settings for spectroscopy
    ramp.QP_ramptime = 50;
    ramp.QP_ramp_delay = -0;
    ramp.QP_final =  0;

    ramp.settling_time = 200; %200

dispLineStr('TIME!!!!',curtime);
curtime = ramp_bias_fields(calctime(curtime,0), ramp);

else
curtime = calctime(curtime,5); %Added March 19,2021 to shorten the lattice time for Raman transfers
end
        
%% assigning outputs (edit with care!)
    timeout = curtime;
