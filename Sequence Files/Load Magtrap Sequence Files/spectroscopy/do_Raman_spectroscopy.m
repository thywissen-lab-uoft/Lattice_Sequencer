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

        if (abs((BreitRabiK(Bguess,9/2,opts.mF2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        % AOM Settings
        
        % Double pass frequency should be
        % Zeeman + lattice gap + single pass
        % Lattice band gaps is 88 kHz for 300 Er, 76 kHz for 200 Er
        % this assumes the other Rigol is set to 80 MHz
        Raman_AOM3_freq =  opts.dF*1e-3/2+(80+...
            abs((BreitRabiK(Bguess,9/2,opts.mF2) - BreitRabiK(Bguess,9/2,opts.mF1))/6.6260755e-34/1E6))/2;
        
        Raman_AOM3_pwr =opts.Raman_AOM3_power;
        
        
%% Program Rigol
        
        % R3 DP beam settings
        switch type
            case 'sweep'
                Sweep_Range = opts.sweep_range/1000;  %in MHz
                Pulse_Time = opts.time; %1 in ms
                str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                    Pulse_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                Raman_on_time = Pulse_Time;

            case 'pulse'
                Pulse_Time = opts.time;
                Raman_on_time = Pulse_Time; %ms
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        end

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
        addVISACommand(Device_id, str);

        % R2 beam settings
        Device_id = 1;
        Raman_AOM2_freq = 80*1E6;
        Raman_AOM2_pwr = opts.Raman_AOM2_power;
        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
            Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

        addVISACommand(Device_id, str);
        
        
%% Do the pulse        

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
        raman_buffer_time = 10;
        shutter_buffer_time = 5;

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
        else
            setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
            DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


            DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
            DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

            setDigitalChannel(calctime(curtime,Raman_on_time+ ...
                raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

        end
        
curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);
timeout = curtime;
    
end