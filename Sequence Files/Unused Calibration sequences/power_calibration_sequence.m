%------
%Author: Stefan Trotzky
%Created: April 2014
%Summary: Pulsing/ramping od dipole beams / lattice beams for power
%calibration
%------

function timeout = test_sequence(timein)

curtime = timein;

global seqdata;


    %turn off dipole trap beams
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.3,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.3,1);
    
    %turn off lattice beams
    setAnalogChannel(calctime(curtime,0),'xLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'yLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'zLattice',0,2);
    
    setDigitalChannel(calctime(curtime,0),'xLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
    
    %set rotating waveplate
     setAnalogChannel(curtime,'latticeWaveplate',0.0,3);
     
     curtime = calctime(curtime,50);
     
     pulse_length = 500;
     dipole_power = [0,0];
     
     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',dipole_power(1));
     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',dipole_power(2));
     
     setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',1); %-10
     ScopeTriggerPulse(curtime,'Pulse');
          
     curtime = calctime(curtime,pulse_length);
     setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0); %-10
     
    %turn off dipole trap beams
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.3,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.3,1);
    
    %turn off lattice beams
    setAnalogChannel(calctime(curtime,0),'xLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'yLattice',0,2);
    setAnalogChannel(calctime(curtime,0),'zLattice',0,2);
    
    setDigitalChannel(calctime(curtime,0),'xLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
    
    %set rotating waveplate
     setAnalogChannel(curtime,'latticeWaveplate',0.0,3);
     
     
    curtime = calctime(curtime,100);
    


     

%% 
%% End
timeout = curtime;

        
end
