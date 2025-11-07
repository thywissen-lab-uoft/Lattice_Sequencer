function  timeout = do_Raman_spectroscopy(timein, type, opts)
% This function does some form of Raman manipulation. Can do a pulse or
% sweep, and change different parameters

curtime = timein;
global seqdata;

        
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
        
        % R3 DP beam settings
        switch type
            case 'sweep'
                
                if ~seqdata.flags.lattice_FB_double_raman_spec && ~seqdata.flags.lattice_FB_triple_raman_spec
                    Pulse_Time          = opts.time; 
                    Raman_on_time       = Pulse_Time; %ms
                elseif seqdata.flags.lattice_FB_double_raman_spec && ~seqdata.flags.lattice_FB_triple_raman_spec
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2; 
                    pulse_wait_time     = opts.pulse_wait;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2; %ms
                else
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2;
                    Pulse_Time3         = opts.time3;
                    pulse_wait_time     = opts.pulse_wait;
                    pulse_wait_time2    = opts.pulse_wait2;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2 + pulse_wait_time2 + Pulse_Time3; %ms
                end
                
                Sweep_Range = opts.sweep_range/1000;  %in MHz
                str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                    Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                str2 = sprintf('SOURce1:SWEep:STATe ON;SOURce1:SWEep:TRIGger:SOURce: EXTernal;SOURce1:SWEep:TIME %gMS;SOURce1:FREQuency:CENTer %gMHZ;SOURce1:FREQuency:SPAN %gMHZ;SOURce1:VOLT %g;', ...
                    Pulse_Time, Raman_AOM3_freq2, Sweep_Range, Raman_AOM3_pwr_alt);


            case 'pulse'
                
                if ~seqdata.flags.lattice_FB_double_raman_spec && ~seqdata.flags.lattice_FB_triple_raman_spec
                    Pulse_Time          = opts.time; 
                    Raman_on_time       = Pulse_Time; %ms
                elseif seqdata.flags.lattice_FB_double_raman_spec && ~seqdata.flags.lattice_FB_triple_raman_spec
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2; 
                    pulse_wait_time     = opts.pulse_wait;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2; %ms
                else
                    Pulse_Time          = opts.time; 
                    Pulse_Time2         = opts.time2;
                    Pulse_Time3         = opts.time3;
                    pulse_wait_time     = opts.pulse_wait;
                    pulse_wait_time2    = opts.pulse_wait2;
                    Raman_on_time       = Pulse_Time + pulse_wait_time + Pulse_Time2 + pulse_wait_time2 + Pulse_Time3; %ms
                end
                    
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
                str2 = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF; SOURce1:FREQuency %gMHZ;SOURce1:VOLT %gVPP;', ...
                    Raman_AOM3_freq2, Raman_AOM3_pwr_alt);
        end

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
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
%                 DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',...
%                     Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
% 
%                 DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
%                     Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep
%          

        %%%% First pulse for double pulse sequence %%%%%
        elseif seqdata.flags.lattice_FB_double_raman_spec && (Pulse_Time ~= 0)
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
            %%%%%%%%
%             DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 1',raman_buffer_time,0); %turn off R2 temporarily for shutter
            
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter
            
            % Set the source for the pulse
            if opts.Source1
                setDigitalChannel(calctime(curtime,0),'Raman 3 Source',1); %0 default, 1 alt
            else
                setDigitalChannel(calctime(curtime,0),'Raman 3 Source',0); %0 default, 1 alt
            end
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter

            % Set the shutter timings
            if opts.doReversal && opts.isForward
                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                2*Raman_on_time+opts.post_hold+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)
            elseif opts.isForward
                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)
                setDigitalChannel(calctime(curtime,Raman_on_time),'Raman 3 Source',0); %0 default, 1 alt
            end
            
            %%%% Second pulse for double pulse sequence %%%%%
            if ~seqdata.flags.lattice_FB_triple_raman_spec
                
                if pulse_wait_time ~= 0   

                    ScopeTriggerPulse(calctime(curtime,Pulse_Time),'Raman_spec'); 

                    %Turn off the Raman beams in between the two pulses
%                      DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 1',pulse_wait_time,0); 
                     
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2',pulse_wait_time,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2a',pulse_wait_time,0);

                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3',pulse_wait_time,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',pulse_wait_time,0); 

                    % If desired, ramp the lattices between the pulses
                    if seqdata.flags.lattice_FB_double_raman_lattice_ramp
                       dT = pulse_wait_time;
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

                %Turn off the Raman beams after the second pulse until shutter
                %closes
%                 DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 1',raman_buffer_time,0);
                
                DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                if opts.Source2
                    setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman 3 Source',1); %0 default, 1 alt
                else
                    setDigitalChannel(calctime(curtime,Pulse_Time+pulse_wait_time/2),'Raman 3 Source',0); %0 default, 1 alt
                end
                DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                setDigitalChannel(calctime(curtime,2*Raman_on_time+ ...
                    raman_buffer_time+pulse_wait_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended
                
              
            else 
                %%%% Second pulse for triple pulse sequence %%%%% 
                if pulse_wait_time ~= 0   

                    ScopeTriggerPulse(calctime(curtime,Pulse_Time),'Raman_spec'); 

                    %Turn off the Raman beams in between the two pulses
                    %%%%%%%
%                     DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 1',pulse_wait_time,0); 
                    
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2',pulse_wait_time,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2a',pulse_wait_time,0);

                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3',pulse_wait_time,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',pulse_wait_time,0); 

                    if seqdata.flags.lattice_FB_double_raman_lattice_ramp
                       dT = pulse_wait_time;
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
%                     DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 1',pulse_wait_time2,0); 

                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 2',pulse_wait_time2,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 2a',pulse_wait_time2,0);

                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3',pulse_wait_time2,0); 
                    DigitalPulse(calctime(curtime,Pulse_Time+Pulse_Time2+pulse_wait_time),'Raman TTL 3a',pulse_wait_time2,0); 

                end

                %Turn off the Raman beams after the third pulse until shutter closes
                %%%%%%%%
%                 DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 1',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                setDigitalChannel(calctime(curtime,2*Raman_on_time+ ...
                    raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended
            
            end
        
        else
            
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman 3 Source',0); %0 default, 1 alt
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Pulse_Time+shutter_buffer_time,1);% open shutter 100ms before and close when TTL closes (takes 3 ms)

            DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            
%             setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman 3 Source',1); %0 default, 1 alt
%             setDigitalChannel(calctime(curtime,Pulse_Time),'Raman 3 Source',0); %0 default, 1 alt
            DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Pulse_Time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

            setDigitalChannel(calctime(curtime,Pulse_Time+ ...
                raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

        end
        
% curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);
curtime = calctime(curtime,Raman_on_time);
curtime = calctime(curtime,opts.post_hold);
timeout = curtime;
    
end