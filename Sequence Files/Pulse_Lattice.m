%------
%Author: Dylan ( Ctrl-C/Ctrl-V )
%Created: March 2013
%Summary:   Pulse the lattice for diffraction alignment
%           Typically called after evaporation in ODT or QP trap
%------

function timeout = Pulse_Lattice(timein,tof_pulse)
global seqdata;

% timein 
    curtime = timein;
    
    if nargin <2
        %Default to diffraction pulses
        tof_pulse = 1;
    else
    end
    
    %curtime = calctime(curtime,1500);
    
    if tof_pulse ~= 4
    
     %Turn rotating waveplate to shift some power to the lattice beams
    rotation_time = 1000;   %The time to rotate the waveplate
    P_lattice = 0.98;    %The fraction of power that will be transmitted through the PBS to lattice beams
                        %0 = dipole, 1 = lattice
                        
    AnalogFunc(calctime(curtime,-100-rotation_time),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);

    else
        %Load Lattice has already been called, so don not need to rotate
        %waveplate
    end
    
    % tof_pulse Settings
    %1 = diffraction w BEC, 
    %2 = hot cloud align, 
    %3 = dipole force curve alignment, 
    %4 = diffraction with Z lattice only

    pulse_delay = 0.0; %How long to wait for pulse after XDT turnoff
    
    if tof_pulse == 2        
        %%%%%%%%%%%%%%%%%=====================================
        %Used to do 'hot cloud alignment' (used for z Lattice)
        %Drop a hot (~2MHz) cloud with the lattice beam on, and try to see
        %guiding
        
        lattice_before_on_time = -50;% -50 for rough alignment , -0.5 for K-D diffraction
        pulse_length_list =100;[0.01:0.01:0.15];0.02;[0.01:0.01:0.15];0.02;   [0.01:0.01:0.15];0.02;100;%[0.045]; % 100 for rough alignment, [0.01:0.01:0.1] for K-D diffraction
        pulse_length = getScanParameter(pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_length');

        %pulse the lattice on during TOF
        pulse_time_temp=calctime(curtime,lattice_before_on_time);        
        ScopeTriggerPulse(pulse_time_temp,'pulse_zlat');
        setDigitalChannel(pulse_time_temp,34,0);%0: lattice beam power on; 1: lattice beam power off;
        setDigitalChannel(calctime(pulse_time_temp,-25),'Lattice Direct Control',0); %0: direct off; 1: direct on (should not matter)
        pulse_time_temp=calctime(pulse_time_temp,pulse_length);
        setDigitalChannel(pulse_time_temp,34,1);%0: lattice beam power on; 1: lattice beam power off;
        setDigitalChannel(pulse_time_temp,'Lattice Direct Control',1); %0: direct off; 1: direct on (should not matter)
        
    elseif   tof_pulse == 3
        
        dipole_on_time = 0;
        pulse_time = 0.5;
        %pulse the lattice on during TOF
        DigitalPulse(calctime(curtime,dipole_on_time),34,dipole_on_time+pulse_time,0);
        
    elseif   tof_pulse == 1
        
        pulse_times = [70 160]/1000;
        lattice_pulse_time = getScanParameter(pulse_times,seqdata.scancycle,seqdata.randcyclelist,'pulse_lengths');
        
        addOutputParam('pulse_time',lattice_pulse_time)
        ScopeTriggerPulse(calctime(curtime,0),'pulse_zlat');
        %setAnalogChannel(calctime(curtime,-50),43,0.000);
        
        %turn off dipole beam
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.3,1);
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.3,1);
        
        %pulse lattice
        setDigitalChannel(calctime(curtime,pulse_delay-25),'Lattice Direct Control',0);
        DigitalPulse(calctime(curtime,pulse_delay),34,lattice_pulse_time,0);
        
        %Add 100us to account for any timing issues
        curtime = calctime(curtime,pulse_delay+lattice_pulse_time+0.1);
        
    elseif   tof_pulse == 4
            %Special Pulse for Z Lattice (need Dig Channel 50 plugged in)
        
        lattice_pulse_time = 0.02;
        
        addOutputParam('pulse_time',lattice_pulse_time)
        
        %turn off dipole beam
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.3,1);
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.3,1);
        
        %pulse lattice
        DigitalPulse(calctime(curtime,pulse_delay),50,lattice_pulse_time,0);
        
        %Add 100us to account for any timing issues
        curtime = calctime(curtime,pulse_delay+lattice_pulse_time+0.1);
        
    end 

    if tof_pulse == 5
                    
        lattice_before_on_time = -0.5;% -50 for rough alignment , 3 for K-D diffraction
        pulse_length_list = 5.5;%[0.045]; % 100 for rough alignment, [0.01:0.01:0.1] for K-D diffraction
        pulse_length = getScanParameter(pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'pulse_length');

        %pulse the lattice on during TOF
        pulse_time_temp=calctime(curtime,lattice_before_on_time);        
        ScopeTriggerPulse(pulse_time_temp,'pulse_zlat');
        setDigitalChannel(pulse_time_temp,34,0);%0: lattice beam power on; 1: lattice beam power off;
        setDigitalChannel(calctime(pulse_time_temp,-50),'Lattice Direct Control',0); %0: direct off; 1: direct on (should not matter)
        pulse_time_temp=calctime(pulse_time_temp,pulse_length);
        setDigitalChannel(pulse_time_temp,34,1);%0: lattice beam power on; 1: lattice beam power off;
        setDigitalChannel(pulse_time_temp,'Lattice Direct Control',1); %0: direct off; 1: direct on (should not matter)

    end
% timeout    
timeout = curtime;

end