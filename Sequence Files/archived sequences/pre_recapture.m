%------
%Author: DM
%Created: March 2011
%Summary: This function recaptures just before taking an image
%------

function timeout=pre_recapture(timein)

curtime = timein;

prerecap_opt_pump = 0;
    prerecap_mag_trap = 0;
    prerecap_atom_dunk = 0;
    
   %wait 500 us and turn the MOT back on to 7.2MHz detuning
    curtime = Load_MOT(calctime(curtime,1),20.2,1);
        
    curtime = calctime(curtime,50); %50
    
    %turn down the repump at the end (CMOT?)
    setAnalogChannel(calctime(curtime,-10),25,0.2);
    
    %turn the mag trap off
    curtime = setDigitalChannel(curtime,16,1);
    
       
    %turn the trap light off
    %analog
    setAnalogChannel(curtime,3,0.0);
    %TTL
    setDigitalChannel(curtime,6,1);
    %shutter
    setDigitalChannel(curtime,2,0);

    %turn the repump light off
    %analog
    setAnalogChannel(curtime,1,0);
    %TTL
    setDigitalChannel(curtime,7,1);
    %shutter
    curtime = setDigitalChannel(curtime,3,0);
    
    
    
      
    if prerecap_opt_pump
        
        %turn the Y (quantizing) shim on after magnetic trapping
        setAnalogChannel(calctime(curtime,0),19,3.5); %had this at 3.5, timing at 1 for abs from MOT
        
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,0),27,0.0); 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,0),28,0.0);
        
        %set optical pumping detuning
        setAnalogChannel(calctime(curtime,-2),5,26); 
            
        %Open OP Shutter
        setDigitalChannel(calctime(curtime,-10),5,1);
        
        %Open Repump Shutter
        setDigitalChannel(calctime(curtime,-5),5,1);

        %Prepare OP light
        %analog
        setAnalogChannel(calctime(curtime,-10),2,0.12); %0.08
        %TTL
        setDigitalChannel(calctime(curtime,-10),9,1);
        
        %Turn on Repump light
        %shutter
        setDigitalChannel(calctime(curtime,-10),3,1);
        

        %300us OP pulse after 1.5ms for Shim coil to turn on
        %TTL
        DigitalPulse(calctime(curtime,0.8),9,0.3,0); %1.5
        %Repump Pulse
        DigitalPulse(calctime(curtime,0.8),7,0.3,0);

        %turn the OP light off
        %analog
        setAnalogChannel(calctime(curtime,5),2,0);
        %TTL
        setDigitalChannel(calctime(curtime,5),9,1);
        %shutter
        setDigitalChannel(calctime(curtime,5),5,0);
        
        %turn the Y (quantizing) shim off after absorption imaging
        curtime = setAnalogChannel(calctime(curtime,1.2),19,0.00); %1.9
        
    end
    
    if prerecap_mag_trap
        
        %optimize loading back into the trap
        
        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,0),19,0.5); 
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,0),27,0.75); 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,0),28,0.0);
        
        curtime = calctime(curtime,0.5);
        
        %turn off the kitten and channel 15
        setAnalogChannel(curtime,21,1,1);
        setAnalogChannel(curtime,3,0,1);
        
        %turn ttl back on
        curtime = setDigitalChannel(curtime,16,0); 
        
        prerecap_ramptime1 = 3;
        prerecap_initialcurrent = 12.4;
        prerecap_holdtime1 = 100;
        
        %ramp up channel 16
        AnalogFunc(calctime(curtime,0.0),1,@(t,a)(a+minimum_jerk(t,prerecap_ramptime1,prerecap_initialcurrent)),prerecap_ramptime1,0);
        setAnalogChannel(calctime(curtime,0.0+prerecap_ramptime1),1,prerecap_initialcurrent);
    
        %hold
        curtime = calctime(curtime,prerecap_holdtime1);
        
        if prerecap_atom_dunk
            
            %down
            curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+174),ver_transport_time,ver_transport_time,174-0.1);
            
            %back up
            curtime = AnalogFunc(calctime(curtime,100),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+0.1),ver_transport_time,ver_transport_time,174-0.1);

        end
        
        %turn off
        setDigitalChannel(curtime,16,1); 
        setAnalogChannel(curtime,1,0,1);
            
        
    end

timeout=curtime;

end
