function  timeout = uwave_singleshot_spectroscopy(timein, pars)
%Function call:    timeout = uwave_singleshot_spectroscopy(timein, pars)
%Author: Stefan
%Created: Apr 2014
% ------ Currently only written for Rb ----------------------------------
%Summary: Does a sequence of uwave pulses with a (sextupled) SRS
%       generator to do spectroscopy between different hyperfine states. 
%       Inbetween these pulses, a Rf sweep moves population between
%       differemt Zeeman levels of the target F state. This is repeated to
%       perform a cycled "transfer & shift" sequence using the target 
%       hyperfine manifold as a register for single-cycle spectroscopy 
%       that can be read out simply with SG imaging. The argument 'pars'
%       contains the parameters for this sequence. Default values aim at
%       single-shot spectroscopy with shims at field-zeroing values and FB
%       at 22.6. See April 23rd/24th 2014 in Labbook 12/13 for details.
% 
% Fields contained in pars and their default values:
%   uwave_ctrfreq (6874.906) -- The reference frequency for the microwave
%       pulses (in MHz)
%   uwave_freqs ([-4 -2 0 2 4]*1e-3) -- The individual pulse frequencies 
%       with respect to the reference frequency (in MHz)
%   uwave_power (5) -- The SRS output power (in dBm).
%   uwave_pulse_length (40) -- The length of the uwave pulses. When doing
%       line-synchronized pulses, this value becomes the time window in
%       which a pulse is to be completed
%   linesync (1) -- A flag signaling whether to do line-synchronized rf
%       pulses
%   rf_freqs ([13.56 13.21]) -- Start and end frequency for the register
%       shifting RF sweeps (in MHz).
%   rf_power (-7.9) -- RF "gain" (is attenuation with a linearized VVA) for
%       the register shifting RF sweeps.
%   rf_sweep_length (5) -- Length of the RF sweeps (note: always also doing
%       a 10ms sweep back to the start frequency).
%   nsweeps (3) -- How many Rf sweeps to do between uwave pulses


global seqdata

curtime = timein;

    if ~exist('pars','var')
        pars.uwave_ctrfreq = 6877.244;%6982.339;%6977.25; % will be added to the pulse frequencies in the next line
        pars.uwave_freqs = [-4 -2 0 2 4]*1e-3; % in MHz
        pars.uwave_power = 5; %dBm for uwave, "gain" for rf; 5dBm together with 5ms works great for a 2kHz frequency spacing
        pars.uwave_pulse_length = 22; % for synchronized pulses: length of window in which pulse should happen (set to 40 for 5ms pulse to be safe)
        pars.linesync = 1; % whether to synchronize to AC line
        pars.targetB = FrequencyToField(pars.uwave_ctrfreq*1e6,[2,2],[1,1]); % B-field corresponding to center freq from Breit Rabi
        pars.rf_freqs = [TransitionFrequency(pars.targetB,[2,-2],[2,-1]) ...
            TransitionFrequency(pars.targetB,[2,1],[2,2])]*1e-6+[0.07 -0.07]; % frequencies for the rf-sweeps assuming resonance is at center frequency
        pars.rf_power = -7.9; % together with sweep range and length a compromise between adiabatic transfer and no false transfer from 35kHz sidebands
        pars.rf_sweep_length = 5; %ms (fast, but not too fast)
        pars.nsweeps = 3; % shifting the mF states by 3 between the u-wave pulses
    end
    
    % adding relative pulse frequencies to reference frequency. Making sure
    % that mF states will eventually be populated in order of entered
    % frequencies.
    pulse_order = @(j,m,n)(mod((m-j)*n,5)+1); % m: number of pulses, n: number of sweeps, j: index of pulse
%     uwave_freqs = pars.uwave_ctrfreq ...
%         + pars.uwave_freqs(pulse_order(1:length(pars.uwave_freqs),pars.uwave_freqs,pars.nsweeps));
    uwave_freqs = pars.uwave_ctrfreq + pars.uwave_freqs([1 5 2 4 3]);   %3 5 2 4 1 for mF order = freq order
    uwave_range = (max(uwave_freqs)-min(uwave_freqs))/2; % is used to set SRS modulation deviation
    uwave_center = (max(uwave_freqs)+min(uwave_freqs))/2; % is used to set SRS center frequency
    
    

    % preparing the SRS for voltage-controlled frequency modulation
    rf_on = 1;
    SRSfreq = uwave_center/6;
    SRSmod_dev = max(uwave_range/6,1e-3);     %Mod Dev Setting on SRS in MHz
    SRSpower = pars.uwave_power;
    addGPIBCommand(27,sprintf(['FREQ %fMHz; TYPE 1; FDEV %gMHz; MFNC 5; ' ...
            'AMPR %gdBm; MODL 1; DISP 2; ENBR %g;'],SRSfreq,SRSmod_dev,SRSpower,rf_on)); % Externally controlled frequency modulation (see SRS manual on GPIB commands)
        
    addOutputParam('SRSmod_dev',SRSmod_dev);
    addOutputParam('freq_val',pars.uwave_ctrfreq);
        
    % switch to sextupled SRS as Rb uwave source if this is not the case yet
    if (getChannelValue(seqdata,'Rb Source Transfer',0) == 0)
        setDigitalChannel(calctime(curtime,-50),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler
    end        
    
    % cycle through u-wave pulses and do register sweeps inbetween
    for i = 1:length(uwave_freqs)
        
        ScopeTriggerPulse(calctime(curtime,0),sprintf('Register shift #%g',i));
        
curtime = calctime(curtime,60); % time for transfer switches and frequency adjustment
        
        % tune SRS frequency with external voltage control
        SRSdev_val = (uwave_freqs(i)/6-SRSfreq)/SRSmod_dev;
        setAnalogChannel(calctime(curtime,-50),46,SRSdev_val,1);
        
        %Open uWave switch and transfer switch; do uwave pulse
        if ( pars.linesync )
            do_linesync_uwave_pulse(calctime(curtime,0), 0, 0*1E6, pars.uwave_pulse_length,0,0);
        else
            do_uwave_pulse(calctime(curtime,0), 0, 0*1E6, pars.uwave_pulse_length,0,0);
        end
        ScopeTriggerPulse(calctime(curtime,0),'Rb uwave spectroscopy pulse');
        
%         addOutputParam(sprintf('uwave_freq%g',i),pars.uwave_freqs(i)-pars.uwave_ctrfreq);
%         addOutputParam(sprintf('SRS_mod%g',i),SRSdev_val);
        
curtime = calctime(curtime,pars.uwave_pulse_length+60); % time for transfer switches again

        % register sweeps
        if i<length(uwave_freqs)
            for j = 1:pars.nsweeps
curtime =       do_rf_sweep(calctime(curtime,0),0,pars.rf_freqs*1e6,pars.rf_sweep_length,pars.rf_power); % sweep there
curtime =       DDS_sweep(calctime(curtime,0),1,pars.rf_freqs(2)*1e6,pars.rf_freqs(1)*1e6,10); % sweep back
curtime =       calctime(curtime,2); % let settle
            end
        end

    end
         
    
    
timeout = curtime;
    
end