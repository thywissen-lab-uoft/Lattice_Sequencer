function  timeout = do_Raman_spectroscopy_new(timein,opts)
% This function does some form of Raman manipulation. Can do a pulse or
% sweep, and change different parameters
% This particular version was written after adding new Raman beams in
% 04/2026 and uses the naming convention with Raman V, Raman DP, Raman
% SP1-4

curtime = timein;
global seqdata;

%% Default options

if ~isfield(opts,'double_pulse')
    opts.double_pulse = 0;
end

if ~isfield(opts,'triple_pulse')
    opts.triple_pulse = 0;
end

%% Pulse timings
        if ~opts.double_pulse && ~opts.triple_pulse
            % single pulse
                    Pulse_Time          = opts.time; 
                    Raman_on_time       = Pulse_Time; %ms
        elseif opts.double_pulse && ~opts.triple_pulse
            % double pulse
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2; 
                    pulse_wait_time     = opts.pulse_wait;
                    lattice_time        = opts.lattice_time;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2; %ms
        else
            % triple pulse
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2;
                    Pulse_Time3         = opts.time3;
                    pulse_wait_time     = opts.pulse_wait;
                    lattice_time        = opts.lattice_time;
                    pulse_wait_time2    = opts.pulse_wait2;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2 + pulse_wait_time2 + Pulse_Time3; %ms
        end

        
%% Initialize AOM settings

%%%%%%%%% DP Settings %%%%%
   % Calculate energy of transition
        Bfb = getChannelValue(seqdata,'FB Current',1);    
        Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
        Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
        Boff = 0.107; % 130 G April 2025
        Bguess = Bfb + Boff + Bz_shim;

        if (abs((BreitRabiK(Bguess,9/2,-7/2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        % Double pass frequency should be
        % Zeeman + lattice gap + single pass
        % Lattice band gaps is 88 kHz for 300 Er, 76 kHz for 200 Er
        % this assumes SP1/SP3 is set to 80 MHz, and SP2/SP4 is set to -40
        % MHz
        Raman_DP_freq =  opts.dF*1e-3/2+(120+...
            abs((BreitRabiK(Bguess,9/2,opts.mF2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6))/2;
        %Alternate frequency source for the Raman DP AOM
        Raman_DP_freq_alt =  opts.dF2*1e-3/2+(120+...
            abs((BreitRabiK(Bguess,9/2,opts.mF2_alt) - BreitRabiK(Bguess,9/2,opts.mF1_alt))/6.6260755e-34/1E6))/2;
        
        Raman_DP_pwr     = opts.Raman_DP_power;
        Raman_DP_pwr_alt = opts.Raman_DP_power_alt;
        
        defVar('Raman_DP_freq',Raman_DP_freq,'MHz');
        defVar('Raman_DP_freq_alt',Raman_DP_freq_alt,'MHz');
        

    % Settings for sweep/pulse for DP AOM
    
        % DP AOM settings for default source
        if opts.Raman_type % do a pulse
            strDP = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_DP_freq, Raman_DP_pwr);
        else %do a sweep
            Sweep_Range = opts.sweep_range/1000;  %in MHz
                
            if ~opts.double_pulse % only one sweep, use first pulse time
                    strDP = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time, Raman_DP_freq, Sweep_Range, Raman_DP_pwr); 
            else
                if opts.Source1 == 0 % first sweep uses default source
                    strDP = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time, Raman_DP_freq, Sweep_Range, Raman_DP_pwr);
                else % assume second sweep uses default source
                    strDP = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time2, Raman_DP_freq, Sweep_Range, Raman_DP_pwr);
                end
            end
        end
        
        % DP AOM settings for alternate source
        if opts.Raman_type_alt % do a pulse
            strDP_alt = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;', ...
                Raman_DP_freq_alt, Raman_DP_pwr_alt);
        else % do a sweep
            Sweep_Range_alt = opts.sweep_range_alt/1000;  %in MHz
                
            if ~opts.double_pulse
                    strDP_alt = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time, Raman_DP_freq_alt, Sweep_Range_alt, Raman_DP_pwr_alt);
            else
                if opts.Source1 == 0 % first sweep uses default source, so assume second uses alt
                    strDP_alt = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time2, Raman_DP_freq_alt, Sweep_Range_alt, Raman_DP_pwr_alt);
                else % assume first sweep uses alt source
                    strDP_alt = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time, Raman_DP_freq_alt, Sweep_Range_alt, Raman_DP_pwr_alt);
                end
            end
        end        
        
        
%%%%%%%%% SP Settings %%%%%
        % SP1
        Raman_SP1_freq = 80*1E6;
        Raman_SP1_pwr = opts.Raman_SP1_power;
        Raman_SP1_offset = 0;
        strSP1=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
            Raman_SP1_freq,Raman_SP1_pwr,Raman_SP1_offset);
        
        % SP3
        Raman_SP3_freq = 80*1E6;
        Raman_SP3_pwr = opts.Raman_SP3_power;
        Raman_SP3_offset = 0;
        strSP3=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
            Raman_SP3_freq,Raman_SP3_pwr,Raman_SP3_offset);
        
        % SP2
        Raman_SP2_freq = 40*1E6;
        Raman_SP2_pwr = opts.Raman_SP2_power;
        Raman_SP2_offset = 0;
        strSP2=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',...
            Raman_SP2_freq,Raman_SP2_pwr,Raman_SP2_offset);
        
        % SP4 
        Raman_SP4_freq = 40*1E6;
        Raman_SP4_pwr = opts.Raman_SP4_power;
        Raman_SP4_offset = 0;
        strSP4=sprintf(' :SOUR2:APPL:SIN %f,%f,%f;',...
            Raman_SP4_freq,Raman_SP4_pwr,Raman_SP4_offset);
        
        
%% Program Rigol
    if opts.doProgram
        %Rigol for DP Alt Source (Ch.1) ad SP3 (Ch.2)
        Device_id = 4;
        addVISACommand(Device_id,[strDP_alt,strSP3]);
        
        %Rigol for D1 lock (Ch.1) and Raman DP(Ch.2). Do not change any Ch. 1 settings here. 
        Device_id = 7; 
        addVISACommand(Device_id, strDP);
        
        %Rigol for Raman V (Ch.1) and Raman SP1 (Ch.2)
        Device_id = 1;
        addVISACommand(Device_id, strSP1);
        
        %Rigol for Raman SP2 and SP4
        Device_id = 13;
        addVISACommand(Device_id, [strSP2,strSP4]);  
    end
    
%% Buffer timings

% Measured 09.04.2025

% time required to keep TTL off before opening/after closing shutter
raman_buffer_time = 6; %minimum 5 ms after we ask shutter to close

% time it takes to open shutter after request
shutter_buffer_time = 3;%getVar('Raman_shutter_buffer');5; minimum 3 ms


%% Do the pulse        
        %Raman spectroscopy AOM-shutter sequence
        %we have TTLs to independatly control all beams. 
        %We leave the DP on, and just control the light using the SP AOMs
       
        % Trigger oscilloscope
        ScopeTriggerPulse(calctime(curtime,0),'Raman_spec');

        %%%% FIRST PULSE %%%%
        % set DP source
        if opts.Source1
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',1); %0 default, 1 alt
        else
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',0); %0 default, 1 alt
        end

        % turn off beams before opening shutter
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman V TTL',0); 
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP Rigol',0); 
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman SP1 switch',0);
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman SP2 switch',0); 
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman SP3 switch',0); 
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman SP4 switch',0); 

        % open the shutter
        setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman Shutter',1);

       

        % 1st pulse: uses opts.SP_select to choose pair
        if (Pulse_Time > 0)
            % trigger both DP Rigols for sweep
            DigitalPulse(curtime,'Raman DP Rigol',Pulse_Time/2,1);
            
            B1 = ['Raman SP',num2str(opts.SP_select(1,1)),' switch'];
            B2 = ['Raman SP',num2str(opts.SP_select(1,2)),' switch'];
            DigitalPulse(curtime,B1,Pulse_Time,1);
            DigitalPulse(curtime,B2,Pulse_Time,1);
        end
        
        %%%% SECOND PULSE %%%%
        % do a second pulse, if desired
        if opts.double_pulse
            
            % If desired, ramp the lattices between the pulses
            if opts.ramp_lattice%seqdata.flags.lattice_FB_double_raman_lattice_ramp
               dT = opts.lattice_time;
               Ux = opts.Ux;
               Uy = opts.Uy;
               Uz = opts.Uz;

                % Ramp the lattice at the end of the first pulse
                AnalogFuncTo(calctime(curtime,Pulse_Time),'xLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Ux); 
                AnalogFuncTo(calctime(curtime,Pulse_Time),'yLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uy);
                AnalogFuncTo(calctime(curtime,Pulse_Time),'zLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uz);   
            end

            % set the DP source for the second pulse
            if opts.Source2
                setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',1); %0 default, 1 alt
            else
                setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',0); %0 default, 1 alt
            end

            % 2nd pulse: uses opts.SP_select to choose pair
            if (Pulse_Time2 > 0)
                % trigger both DP Rigols for sweep 
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time),'Raman DP Rigol',Pulse_Time2/2,1);

                B1 = ['Raman SP',num2str(opts.SP_select(2,1)),' switch'];
                B2 = ['Raman SP',num2str(opts.SP_select(2,2)),' switch'];
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time),B1,Pulse_Time2,1);
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time),B2,Pulse_Time2,1);
            end
        end

        %%%% THIRD PULSE %%%%
        % do a 3rd pulse
        if opts.triple_pulse
            % If desired, ramp the lattices between the pulses
            if opts.ramp_lattice
               dT = opts.lattice_time;
               Ux = opts.Ux;
               Uy = opts.Uy;
               Uz = opts.Uz;

                % Ramp the lattice at the end of the first pulse
                AnalogFuncTo(calctime(curtime,Pulse_Time),'xLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Ux); 
                AnalogFuncTo(calctime(curtime,Pulse_Time),'yLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uy);
                AnalogFuncTo(calctime(curtime,Pulse_Time),'zLattice',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uz);   
            end

            % set the DP source for the third pulse
            if opts.Source3
                setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time...
                    +Pulse_Time2+pulse_wait_time2/2),'Raman DP source',1); %0 default, 1 alt
            else
                setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time...
                    +Pulse_Time2+pulse_wait_time2/2),'Raman DP source',0); %0 default, 1 alt
            end
            
            % 3rd pulse: uses opts.SP_select to choose pair
            if (Pulse_Time3 > 0)
                 % trigger both DP Rigols for sweep 
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time...
                    +Pulse_Time2+pulse_wait_time2),'Raman DP Rigol',Pulse_Time3/2,1); %turn off R3 after the sweep and turn on 150ms later

                B1 = ['Raman SP',num2str(opts.SP_select(3,1)),' switch'];
                B2 = ['Raman SP',num2str(opts.SP_select(3,2)),' switch'];
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time...
                    +Pulse_Time2+pulse_wait_time2),B1,Pulse_Time3,1);
                DigitalPulse(calctime(curtime,Pulse_Time+pulse_wait_time...
                    +Pulse_Time2+pulse_wait_time2),B2,Pulse_Time3,1);
            end
        end

        %%%% END OF PULSES %%%%
        % close the shutter after pulse(s) over (takes 3 ms)
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman Shutter',0);

        % turn all beams on after shutter closes
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman V TTL',1); 
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman DP Rigol',1); 
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman SP1 switch',1);
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman SP2 switch',1); 
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman SP3 switch',1); 
        setDigitalChannel(calctime(curtime,Raman_on_time+raman_buffer_time),'Raman SP4 switch',1);   
        
curtime = calctime(curtime,Raman_on_time);
curtime = calctime(curtime,opts.post_hold);
timeout = curtime;
    
end