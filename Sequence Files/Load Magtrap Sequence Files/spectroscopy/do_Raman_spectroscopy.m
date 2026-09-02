function  timeout = do_Raman_spectroscopy(timein,opts)
% This function does some form of Raman manipulation. Can do a pulse or
% sweep, and change different parameters



%%%%% OLD FUNCTION %%%%%
% In April 2026 we added two new Raman beams and changed the naming
% convention. AOM1 is now Raman V, AOM2 is Raman SP1/Raman 1, AOM3 is Raman
% DP

curtime = timein;
global seqdata;

%% Default options

if ~isfield(opts,'double_pulse')
    opts.double_pulse = 0;
end

if ~isfield(opts,'triple_pulse')
    opts.triple_pulse = 0;
end

        
%% Initialize settings

   % Calculate energy of transition
        Bfb = getChannelValue(seqdata,'FB Current',1);    
        Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
        Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
%         Boff = 0.1238; % 190+ G November 2024
        Boff = 0.107; % 130 G April 2025
        Bguess = Bfb + Boff + Bz_shim;

        if (abs((BreitRabiK(Bguess,9/2,-7/2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        % AOM Settings
        
        % Double pass frequency should be
        % Zeeman + lattice gap + single pass
        % Lattice band gaps is 88 kHz for 300 Er, 76 kHz for 200 Er
        % this assumes the other Rigol is set to 80 MHz
        Raman_AOM3_freq =  opts.dF*1e-3/2+(80+...
            abs((BreitRabiK(Bguess,9/2,opts.mF2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6))/2;
        %Alternate frequency source for the Raman H2 DP AOM
        Raman_AOM3_freq2 =  opts.dF2*1e-3/2+(80+...
            abs((BreitRabiK(Bguess,9/2,opts.mF2_alt) - BreitRabiK(Bguess,9/2,opts.mF1_alt))/6.6260755e-34/1E6))/2;
        
        Raman_AOM3_pwr     =opts.Raman_AOM3_power;
        Raman_AOM3_pwr_alt =opts.Raman_AOM3_power_alt;
        
        defVar('Raman_DP_freq',Raman_AOM3_freq,'MHz');
        defVar('Raman_DP_freq_alt',Raman_AOM3_freq2,'MHz');
        
%% Program Rigol

        % calculate timings
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
        
        % R3 DP beam settings for default source
        if opts.Raman_type % do a pulse
            str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        else %do a sweep
            Sweep_Range = opts.sweep_range/1000;  %in MHz
                
            if ~opts.double_pulse % only one sweep, use first pulse time
                    str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr); 
            else
                if opts.Source1 == 0 % first sweep uses default source
                    str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                else
                    str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Pulse_Time2, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                
                end
            end
            
        end
        
        % R3 DP beam settings for alternate source
        if opts.Raman_type_alt % do a pulse
            str2 = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;', ...
                Raman_AOM3_freq2, Raman_AOM3_pwr_alt);
        else % do a sweep
            Sweep_Range_alt = opts.sweep_range_alt/1000;  %in MHz
                
            if ~opts.double_pulse
                    str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time, Raman_AOM3_freq2, Sweep_Range_alt, Raman_AOM3_pwr_alt);
            else
                if opts.Source1 == 0 % first sweep uses default source, so assume second uses alt
                    str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time2, Raman_AOM3_freq2, Sweep_Range_alt, Raman_AOM3_pwr_alt);
                else
                    str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                        Pulse_Time, Raman_AOM3_freq2, Sweep_Range_alt, Raman_AOM3_pwr_alt);
                end
            end
        end        
        
%         switch type
%             case 'sweep'
%                 
%                 if ~opts.double_pulse && ~opts.triple_pulse
%                     Pulse_Time          = opts.time; 
%                     Raman_on_time       = Pulse_Time; %ms
%                     
%                     Sweep_Range = opts.sweep_range/1000;  %in MHz
%                     Sweep_Range_alt = opts.sweep_range_alt/1000;  %in MHz
%                     str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
%                         Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
%                     str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
%                         Pulse_Time, Raman_AOM3_freq2, Sweep_Range_alt, Raman_AOM3_pwr_alt);
%                 
%                 elseif opts.double_pulse && ~opts.triple_pulse
%                     Pulse_Time          = opts.time; 
%                     Pulse_Time2         = opts.time2; 
%                     pulse_wait_time     = opts.pulse_wait;
%                     Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2; %ms
%                     
%                     Sweep_Range = opts.sweep_range/1000;  %in MHz
%                     Sweep_Range_alt = opts.sweep_range_alt/1000;  %in MHz
%                     str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
%                         Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
%                     str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
%                         Pulse_Time2, Raman_AOM3_freq2, Sweep_Range_alt, Raman_AOM3_pwr_alt);
%                 else
%                     Pulse_Time          = opts.time; 
%                     Pulse_Time2         = opts.time2;
%                     Pulse_Time3         = opts.time3;
%                     pulse_wait_time     = opts.pulse_wait;
%                     pulse_wait_time2    = opts.pulse_wait2;
%                     Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2 + pulse_wait_time2 + Pulse_Time3; %ms
%                 end
%                 
%              
% 
% 
%             case 'pulse'
%                 
%                 if ~opts.double_pulse && ~opts.triple_pulse
%                     Pulse_Time          = opts.time; 
%                     Raman_on_time       = Pulse_Time; %ms
%                 elseif opts.double_pulse && ~opts.triple_pulse
%                     Pulse_Time          = opts.time; 
%                     Pulse_Time2         = opts.time2; 
%                     pulse_wait_time     = opts.pulse_wait;
%                     Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2; %ms
%                 else
%                     Pulse_Time          = opts.time; 
%                     Pulse_Time2         = opts.time2;
%                     Pulse_Time3         = opts.time3;
%                     pulse_wait_time     = opts.pulse_wait;
%                     pulse_wait_time2    = opts.pulse_wait2;
%                     Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2 + pulse_wait_time2 + Pulse_Time3; %ms
%                 end
%                     
%                 str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
%                     Raman_AOM3_freq, Raman_AOM3_pwr);
%                 str2 = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;', ...
%                     Raman_AOM3_freq2, Raman_AOM3_pwr_alt);
%         end

% Add second channel string
 % Raman SP3

        Raman_AOM2_freq = 80*1E6;
        Raman_AOM2_pwr = 0.1;opts.Raman_SP3_power;
        Raman_AOM2_offset = 0;
        strSP3=sprintf(' :SOURce2:APPL:SIN %f,%f,%f;',...
            Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);
        
        str2 = [str2,strSP3];


        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman DP (labeled AOM3 in Matlab) (Ch. 2). Do not change any Ch. 1 settings here. 
        Device_id2 = 4; %Rigal for Raman H2 DP Alt Frequency Source (Ch.1)
        if opts.doProgram
            addVISACommand(Device_id, str);
            addVISACommand(Device_id2, str2);
        end
        
        % R2 beam settings
        Device_id = 1;
        Raman_AOM2_freq = 80*1E6;
        Raman_AOM2_pwr = opts.Raman_AOM2_power;
        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
            Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);
        if opts.doProgram
            addVISACommand(Device_id, str);
        end
        
        % Raman SP2 + SP4
        Device_id = 13;
        Raman_AOM2_freq = 40*1E6;
        Raman_AOM2_pwr = 0.1;opts.Raman_SP2_power;
        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',...
            Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);
        
        Raman_AOM2_freq = 40.5*1E6;
        Raman_AOM2_pwr = 0.1;opts.Raman_SP4_power;
        Raman_AOM2_offset = 0;
        str2=sprintf(' :SOURce2:APPL:SIN %f,%f,%f;',...
            Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);
        
        str = [str,str2];
        addVISACommand(Device_id, str);
        
        
        
%% Do the pulse        

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
%         defVar('Raman_buffer',[3 3.05 3.1 3.2 3.5 4 5],'ms');
        raman_buffer_time = 6; %minimum 5 ms after we ask shutter to close
        %defVar('Raman_buffer',[3],'ms');
        shutter_buffer_time = 3;%getVar('Raman_shutter_buffer');5; minimum 3 ms

        if Pulse_Time == 0
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 1',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R1 temporarily for shutter
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter
% 
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman DP Rigol',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
% 
%                 DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
%                     Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep
%          

        %%%% First pulse for double and triple pulse sequence %%%%%
        elseif opts.double_pulse && (Pulse_Time ~= 0)
            
%             if opts.Source1
%                         setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',1); %0 default, 1 alt
%                     else
%                         setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',0); %0 default, 1 alt
%             end
            
            ScopeTriggerPulse(calctime(curtime,Pulse_Time),'Raman_spec');
            
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman V TTL',0); %turn off R1
            %%%%%%%%
%             DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman V TTL',raman_buffer_time,0); %turn off R2 temporarily for shutter
            
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman SP1 Rigol',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman SP1 switch',raman_buffer_time,0); %turn off R2 temporarily for shutter
            
            % Set the source for the pulse
            if opts.Source1
                setDigitalChannel(calctime(curtime,0),'Raman DP source',1); %0 default, 1 alt
            else
                setDigitalChannel(calctime(curtime,0),'Raman DP source',0); %0 default, 1 alt
            end
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman DP Rigol',raman_buffer_time,0); %turn off R3 temporarily for shutter
%             DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter

            % Set the shutter timings
            if opts.doReversal && opts.isForward
                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                2*Raman_on_time+opts.post_hold+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)
            elseif opts.isForward
                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)
                setDigitalChannel(calctime(curtime,Raman_on_time),'Raman DP source',0); %0 default, 1 alt
            end
            
            %%%% Second pulse for double pulse sequence %%%%%
            if ~opts.triple_pulse
                
                if pulse_wait_time ~= 0   

                    if Pulse_Time2 == 0
                        
                        %turn off beams until shutter opens
                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 Rigol',pulse_wait_time+raman_buffer_time,0); 
                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 switch',pulse_wait_time+raman_buffer_time,0);

                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman DP Rigol',pulse_wait_time+raman_buffer_time,0); 
%                         DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',pulse_wait_time+raman_buffer_time,0); 
                        
           
                    else         
                        %Turn off the Raman beams in between the two pulses
    %                      DigitalPulse(calctime(curtime,Pulse_Time),'Raman V TTL',pulse_wait_time,0); 

                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 Rigol',pulse_wait_time,0); 
                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 switch',pulse_wait_time,0);

                        DigitalPulse(calctime(curtime,Pulse_Time),'Raman DP Rigol',pulse_wait_time,0); 
%                         DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',pulse_wait_time,0); 
                    end

                    % If desired, ramp the lattices between the pulses
                    if seqdata.flags.lattice_FB_double_raman_lattice_ramp
%                        dT = pulse_wait_time;
                       dT = lattice_time;
                       Ux = opts.Ux;
                       Uy = opts.Uy;
                       Uz = opts.Uz;

                        % Define Ramp Ups
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'xLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Ux); 
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'yLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uy);
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'zLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uz);   
                    end
                end
                
                if Pulse_Time2 > 0

                    %Turn off the Raman beams after the second pulse until shutter
                    %closes
    %                 DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman V TTL',raman_buffer_time,0);

                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman SP1 Rigol',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman SP1 switch',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                    if opts.Source2
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',1); %0 default, 1 alt
                    else
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',0); %0 default, 1 alt
                    end
                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman DP Rigol',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
%                     DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                end
                
                setDigitalChannel(calctime(curtime,2*Raman_on_time+ ...
                        raman_buffer_time+pulse_wait_time),'Raman V TTL',1); %turn on R1 150ms after the sweep has ended
                
              
            else 
                %%%% Second pulse for triple pulse sequence %%%%% 
                if pulse_wait_time ~= 0   

                    ScopeTriggerPulse(calctime(curtime,Pulse_Time),'Raman_spec'); 

                    %Turn off the Raman beams in between the two pulses
                    %%%%%%%
%                     DigitalPulse(calctime(curtime,Pulse_Time),'Raman V TTL',pulse_wait_time,0); 
                    
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 Rigol',pulse_wait_time,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 switch',pulse_wait_time,0);

                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman DP Rigol',pulse_wait_time,0); 
%                     DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',pulse_wait_time,0); 
                    
                    if opts.Source2
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',1); %0 default, 1 alt
                    else
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman DP source',0); %0 default, 1 alt
                    end

                    if seqdata.flags.lattice_FB_double_raman_lattice_ramp
%                        dT = pulse_wait_time;
                       dT = lattice_time;
                       Ux = opts.Ux;
                       Uy = opts.Uy;
                       Uz = opts.Uz;

                        % Define Ramp Ups
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'xLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Ux); 
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'yLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uy);
                        AnalogFuncTo(calctime(curtime,Pulse_Time),'zLattice',...
                            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uz);   
                    end
                end
                
                 %%%% Third pulse for triple pulse sequence %%%%% 
                if pulse_wait_time2 ~= 0   

%                     ScopeTriggerPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman_spec'); 

                    %Turn off the Raman beams in between the two pulses
                    %%%%%%%
%                     DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman V TTL',pulse_wait_time2,0); 

                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman SP1 Rigol',pulse_wait_time2,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman SP1 switch',pulse_wait_time2,0);

                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman DP Rigol',pulse_wait_time2,0); 
%                     DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3a',pulse_wait_time2,0); 

                end
                
                if opts.Source3
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time+Pulse_Time2+pulse_wait_time2/2),'Raman DP source',1); %0 default, 1 alt
                    else
                        setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time+Pulse_Time2+pulse_wait_time2/2),'Raman DP source',0); %0 default, 1 alt
                end

                %Turn off the Raman beams after the third pulse until shutter closes
                %%%%%%%%
%                 DigitalPulse(calctime(curtime,Raman_on_time),'Raman V TTL',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman SP1 Rigol',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman SP1 switch',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman DP Rigol',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
%                 DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                setDigitalChannel(calctime(curtime,2*Raman_on_time+ ...
                    raman_buffer_time),'Raman V TTL',1); %turn on R1 150ms after the sweep has ended
            
            end
        
        % Single pulse    
        else
            
            if opts.Source1
                        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',1); %0 default, 1 alt
                    else
                        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman DP source',0); %0 default, 1 alt
            end
            
            ScopeTriggerPulse(calctime(curtime,Pulse_Time),'Raman_spec');
            
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman V TTL',0); %turn off R1
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman SP1 Rigol',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman SP1 switch',raman_buffer_time,0); %turn off R2 temporarily for shutter


            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman DP Rigol',raman_buffer_time,0); %turn off R3 temporarily for shutter
%             DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Pulse_Time+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)

            DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 Rigol',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Pulse_Time),'Raman SP1 switch',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            
%             setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman DP source',1); %0 default, 1 alt
%             setDigitalChannel(calctime(curtime,Pulse_Time),'Raman DP source',0); %0 default, 1 alt
            DigitalPulse(calctime(curtime,Pulse_Time),'Raman DP Rigol',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
%             DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

            setDigitalChannel(calctime(curtime,Pulse_Time+ ...
                raman_buffer_time),'Raman V TTL',1); %turn on R1 150ms after the sweep has ended

        end
        
% curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);
curtime = calctime(curtime,Raman_on_time);
curtime = calctime(curtime,opts.post_hold);
timeout = curtime;
    
end