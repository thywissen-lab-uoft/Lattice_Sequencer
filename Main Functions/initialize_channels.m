%------
%Author: David McKay
%Created: July 2009
%Summary: Initalize all the channel parameters
%------
function initialize_channels()

global seqdata;

%define the analog channel structure array
%56 analog channels (numbered channel 1-56)
seqdata.analogchannels = repmat(struct('channel',0,...
    'voltagefunc',[],... %this allows a custom function for getting the channel voltage,, default to just the voltage.
    'defaultvoltagefunc',1,...
    'maxvoltage',10,...
    'minvoltage',-10),1,64);

%two digital channels of '32' bits each (numbered channel 1-64)
seqdata.digchannels = repmat(struct('channel',0,...
    'bitpos',0,...
    'cardid',0),1,64);

%set the digital channels
for i = 1:length(seqdata.digchannels)
    seqdata.digchannels(i).channel = i;
    seqdata.digchannels(i).name = sprintf('d%g',i); % 2013-03-02: added names
    seqdata.digchannels(i).resetvalue = 1i; % complex i means: do nothing at end
    seqdata.digchannels(i).bitpos = mod(i-1,32)+1;
    
    if i<33
        seqdata.digchannels(i).cardid = 1;
%     elseif (i>=33 && i<65)
%         seqdata.digchannels(i).cardid = 2;
    else 
%         seqdata.digchannels(i).cardid = 3;
        seqdata.digchannels(i).cardid = 2;
    end
    
end

% digital channel names
seqdata.digchannels(2).name = 'K Trap Shutter'; % 1: ON, 0: OFF
seqdata.digchannels(3).name = 'K Repump Shutter';% all repump power shutter, different from 0th order shutter
seqdata.digchannels(4).name = 'Rb Trap Shutter'; %1: ON, 0: OFF
seqdata.digchannels(5).name = 'Rb Repump Shutter'; % 1: ON, 0: OFF
seqdata.digchannels(6).name = 'K Trap TTL'; %AOM is before the TA, so this cannot turn the beam 100% off 0: ON 1:Off
seqdata.digchannels(7).name = 'K Repump TTL'; %AOM is before the TA
seqdata.digchannels(8).name = 'Rb Trap TTL'; %AOM is before the TA
% seqdata.digchannels(3).name = 'xLatticeOFF';
seqdata.digchannels(9).name = 'K Probe/OP TTL'; % 0: OFF; 1: ON
seqdata.digchannels(10).name = 'Plug Shutter'; %1: ON; 0: OFF
seqdata.digchannels(11).name = 'UV LED'; %No Longer Used, UV TTL
seqdata.digchannels(12).name = 'ScopeTrigger';
seqdata.digchannels(14).name = 'Rb uWave TTL'; %0 is off
seqdata.digchannels(15).name = 'Dimple Shutter'; %0 is off
seqdata.digchannels(16).name = 'MOT TTL'; %0 is on, 1 is off: What does this do? Why is it ever off?
seqdata.digchannels(17).name = 'RF/uWave Transfer'; %0 is RF, 1 is uWaves
seqdata.digchannels(17).resetvalue = 0;
seqdata.digchannels(18).name = 'DDS ADWIN Trigger';
seqdata.digchannels(19).name = 'RF TTL'; %0 is off
seqdata.digchannels(20).name = 'RaspPi Trig'; %1 Triggers
seqdata.digchannels(21).name = 'Coil 16 TTL'; %(fast switch) 1 is off - on control board, bypasses servo.
seqdata.digchannels(22).name = '15/16 Switch'; %15 Switch (A FET - beside coil short detector). Used for sending equal currents into both coils for QP.
seqdata.digchannels(23).name = 'D1 Shutter';
seqdata.digchannels(24).name = 'Rb Probe/OP TTL'; %0: laser ON; 1 laser OFF
seqdata.digchannels(25).name = 'Rb Probe/OP shutter';
seqdata.digchannels(26).name = 'PixelFly Trigger';
seqdata.digchannels(27).name = 'K High Field Probe'; %0: on, 1 off
seqdata.digchannels(28).name = 'Transport Relay'; %Relay to use one FET for two coils (3 & 11)
seqdata.digchannels(29).name = 'Kitten Relay'; %Physical relay to use different currents in coils 15 and 16.
seqdata.digchannels(30).name = 'K Probe/OP shutter';%0: OFF , 1: ON ;
seqdata.digchannels(31).name = 'fast FB Switch'; % 1 = on (make sure channel 37 is set to -0.5 before opening to avoid current spike, after opening set channel 37 to 0 to have a smooth ramp on from zero)
seqdata.digchannels(32).name = 'iXon Trigger';
seqdata.digchannels(33).name = 'Shim Relay'; %1 = on (MOT Shims)
seqdata.digchannels(34).name = 'yLatticeOFF'; %Controls all 3 lattice beams (i.e. Lattice TTL)
seqdata.digchannels(35).name = 'D1 TTL';
seqdata.digchannels(36).name = 'EIT Shutter';
seqdata.digchannels(37).name = 'Shim Multiplexer';  %0 = MOT Shims (unipolar), 1: Science shim coils ???
seqdata.digchannels(37).resetvalue = 0; 
seqdata.digchannels(38).name = 'FPump Direct'; %0 off, 1 on
seqdata.digchannels(39).name = 'K uWave TTL'; %0 off, 1 on
seqdata.digchannels(40).name = 'K/Rb uWave Transfer'; %0 = K, 1 = Rb
seqdata.digchannels(40).resetvalue = 0;
seqdata.digchannels(41).name = 'Lattice Direct Control'; 
seqdata.digchannels(42).name = 'FB Integrator OFF'; %0 = integrator enabled (DO NOT SET TO 1 - March 2014)
seqdata.digchannels(43).name = 'Bipolar Shim Relay'; %1 = shims on, 0 = shims off | temporary?
seqdata.digchannels(44).name = 'FB offset select'; % 1 = divide by 10 and add 6.6 V to 'FB current' voltage
seqdata.digchannels(45).name = 'DMD AOM TTL'; %1 on 0 off
seqdata.digchannels(45).resetvalue = 0;
seqdata.digchannels(46).name = 'Field sensor SR'; % Set/Reset of the field sensor inside thebucket (Minimag)
seqdata.digchannels(47).name = 'High Field Shutter';% 0: OFF, 1: ON
seqdata.digchannels(48).name = 'Rb Sci Repump'; %Rb repump in science chamber
seqdata.digchannels(48).resetvalue = 0;
seqdata.digchannels(49).name = 'Rb Source Transfer'; %Use Anritsu (0) or Sextupler (1) for Rb uWaves
seqdata.digchannels(49).resetvalue = 0;
seqdata.digchannels(50).name = 'Gray Molasses switch'; %switch between K D2 gray molasses, 0: MOT; 1: gray molasses
seqdata.digchannels(51).name = 'Lattice FM'; %Used to gate a frequency source which applies FM to the lattice beams (1 = on, 0 = off)
seqdata.digchannels(52).name = 'Remote field sensor SR'; % Set/Reset of the field sensor high above
seqdata.digchannels(53).name = 'K uWave Source'; %Switch to choose between two SRS generators (0: SRS A, 1: SRS B)
seqdata.digchannels(54).name = 'F Pump TTL'; %Seperate TTL for Vertical / Long beams 
seqdata.digchannels(55).name = 'Downwards D2 Shutter'; %Shutter for Rb and K repump in science cell. (0 = close, 1 = Open).
seqdata.digchannels(56).name = 'ACync Master'; %Master pulse for ACync Board
seqdata.digchannels(57).name = 'D1 OP TTL'; %0: off; 1: on;
seqdata.digchannels(58).name = 'Raman Shutter'; %0: off, 1: on
seqdata.digchannels(59).name = 'Kill TTL'; %0:off, 1: on. 
seqdata.digchannels(60).name = 'Raman TTL'; %0: off, 1: on
seqdata.digchannels(61).name = 'XDT TTL'; %0: on, 1: off
seqdata.digchannels(62).name = 'DMD TTL'; %0: on, 1:off
seqdata.digchannels(62).resetvalue = 1;
seqdata.digchannels(63).name = 'XDT Direct Control'; %0: off, 1:on
% seqdata.digchannels(63).name = 'Plug Mode Switch';%'plug mode switch'; %1: manual mode, 0:Auto mode
seqdata.digchannels(64).name = 'K Sci Repump'; %K repump in science chamber 

%set the analog channel numbers
for i = 1:length(seqdata.analogchannels)
    seqdata.analogchannels(i).channel = i;
    seqdata.analogchannels(i).name = sprintf('a%g',i); % 2013-03-02: added names
    seqdata.analogchannels(i).resetvalue = 1i; % complex i means: do nothing at end
    seqdata.analogchannels(i).voltagefunc{1} = @(a)(a);
end

%set individual channel properties
%analog channels 1-4 (AOM intensities)
for i = 1:4
    seqdata.analogchannels(i).minvoltage = 0;
    seqdata.analogchannels(i).maxvoltage = 1;
end

%old calibration for K-40 MOT (before switching AOMs around March 2, 2011)
%seqdata.analogchannels(5).voltagefunc{2} = @(a)((324.7-a/4)*0.060240-15.17200);

for i=7:17
    seqdata.analogchannels(i).minvoltage = -1;
    seqdata.analogchannels(i).maxvoltage = 10;
    seqdata.analogchannels(i).defaultvoltagefunc = 2;
    seqdata.analogchannels(i).voltagefunc{2} = @(a)(a*0.1+0.1);
end

    %channel 1 (6th vert--16)
    seqdata.analogchannels(1).name = 'Coil 16';
    seqdata.analogchannels(1).minvoltage = -1;
    seqdata.analogchannels(1).maxvoltage = 10;
    seqdata.analogchannels(1).defaultvoltagefunc = 2;
    %seqdata.analogchannels(1).voltagefunc{2} = @(a)(a*0.10455+0.08714);
    %seqdata.analogchannels(1).voltagefunc{2} = @(a)(a*0.1+0.1); %old sensor
    seqdata.analogchannels(1).voltagefunc{2} = @(a)(a*0.125+0.1125); %with FW Bell sensor %0.1125 instead of 0.1 July 06, 2018
     %seqdata.analogchannels(1).voltagefunc{2} = @(a)(-a*0.0095+0);
     %seqdata.analogchannels(1).voltagefunc{2} = @(a)(a*0.101+0.0926);
          
    %Rb repump
    seqdata.analogchannels(2).name = 'Rb Repump AM';
    seqdata.analogchannels(2).maxvoltage = 2;
    seqdata.analogchannels(2).voltagefunc{2} = @(a)(2*a);
    seqdata.analogchannels(2).defaultvoltagefunc = 2;
     
    %channel 3 ("kitten")
    seqdata.analogchannels(3).name = 'kitten';
    seqdata.analogchannels(3).minvoltage = -3;
    seqdata.analogchannels(3).maxvoltage = 10;
    seqdata.analogchannels(3).defaultvoltagefunc = 2;
    %seqdata.analogchannels(3).voltagefunc{2} = @(a)(a*0.10638+0.08156);
    %seqdata.analogchannels(3).voltagefunc{2} = @(a)(a*0.1+0.25); %old sensor
    seqdata.analogchannels(3).voltagefunc{2} = @(a)(a*0.11+0.25); %0.11+0.25 %FW Bell sensor
    %seqdata.analogchannels(3).voltagefunc{2} = @(a)(a*0.0984+0.08865);
    
    %channel 4 (Rb Trap AOM AM)
    seqdata.analogchannels(4).name = 'Rb Trap AM';
  
    %channel 5 (K trap frequency - MHz units)
    seqdata.analogchannels(5).name = 'K Trap FM';
    seqdata.analogchannels(5).minvoltage = -10;
    seqdata.analogchannels(5).maxvoltage = 10;
    %Make the conversion function detuning
    seqdata.analogchannels(5).defaultvoltagefunc = 4; %CHANGED FOR AOM TEST
    K_trap_freq_offset =-2000/1000;
    K_repump_freq_offset = 00/1000;
    %40MHz detuning is 105MHz, higher frequency is less detuned
    %seqdata.analogchannels(5).voltagefunc{2} = @(a)((-19.17+0.22514*(134-a/2)-2.48788E-4*(134-a/2)^2)); %for Stefan's homemoade VCO
    seqdata.analogchannels(5).voltagefunc{2} = @(a)((-2.22847+0.01884*(134-(a-K_trap_freq_offset)/2)));
    seqdata.analogchannels(5).voltagefunc{3} = @(a)((-15.66 + 0.1684*(134-(a-K_trap_freq_offset)/2)));
    %seqdata.analogchannels(5).voltagefunc{4} = @(a)(0.5*(-10.9 + 0.174*(134-a/2)))/1.05; %Can not request closer than 27.76MHz from 134. Updated with new AOM driver, (April 11, 2014 R.Day)
%     seqdata.analogchannels(5).voltagefunc{4} = @(a)(-5.04+0.0829*(134-(a-K_trap_freq_offset)/2)); %Can not request closer than 27.76MHz from 134. Updated with new AOM driver, (April 11, 2014 R.Day)
    seqdata.analogchannels(5).voltagefunc{4} = @(a)((-5.04+0.0829*(134-(a-K_trap_freq_offset)/2))*11.83-30.8)/6.03; %switched to a new box 2020-02-05
    seqdata.analogchannels(5).voltagefunc{5} = @(a)(a);
    
    
    %Push channel
    seqdata.analogchannels(6).name = 'Raman VVA';
    seqdata.analogchannels(6).minvoltage = 0;
    seqdata.analogchannels(6).maxvoltage = 10;
    
    %Push channel
    seqdata.analogchannels(7).name = 'Push Coil';
    seqdata.analogchannels(7).minvoltage = -1;
    seqdata.analogchannels(7).maxvoltage = 10;
    seqdata.analogchannels(7).defaultvoltagefunc = 2;
    %seqdata.analogchannels(7).voltagefunc{2} = @(a)(a*0.04647+0.29173);
    seqdata.analogchannels(7).voltagefunc{2} = @(a)(a*0.04717+0.28302);
    %Slope error = 6.63E-4
    %Intercept error = .0164
   
    %MOT channel
    seqdata.analogchannels(8).name = 'MOT Coil';
    seqdata.analogchannels(8).minvoltage = -1;
    seqdata.analogchannels(8).maxvoltage = 10;
    seqdata.analogchannels(8).defaultvoltagefunc = 2;
    %seqdata.analogchannels(8).voltagefunc{2} = @(a)(a*0.09385+0.2994);
    seqdata.analogchannels(8).voltagefunc{2} = @(a)(a*0.09133+0.31199);
    seqdata.analogchannels(8).voltagefunc{4} = @(a)(a*0.1+0.0);
    %Slope error = 3.347E-4
    %Intercept error = .00712
    
    %channel 8 (MOT - G/cm units)
    seqdata.analogchannels(8).defaultvoltagefunc = 3;
    seqdata.analogchannels(8).voltagefunc{3} = @(a)(a*0.01914+0.29);
    %seqdata.analogchannels(8).voltagefunc{3} = @(a)(a*0.022694+0.0810);

   
    %channel 9 - Coil 3
    seqdata.analogchannels(9).name = 'Coil 3';
    seqdata.analogchannels(9).minvoltage = -1;
    seqdata.analogchannels(9).maxvoltage = 10;
    seqdata.analogchannels(9).defaultvoltagefunc = 2;
    %seqdata.analogchannels(9).voltagefunc{2} = @(a)(a*0.09622+0.3255);
    seqdata.analogchannels(9).voltagefunc{2} = @(a)(a*0.09542+0.35115);
    
    %Slope error = 3.16E-4
    %Intercept error = 0.01077
    
    %channel 10 - Coil 4
    seqdata.analogchannels(10).name = 'Coil 4';
    seqdata.analogchannels(10).minvoltage = -1;
    seqdata.analogchannels(10).maxvoltage = 10;
    seqdata.analogchannels(10).defaultvoltagefunc = 2;
    %seqdata.analogchannels(10).voltagefunc{2} = @(a)(a*0.09622+0.3255);
    seqdata.analogchannels(10).voltagefunc{2} = @(a)(a*0.09328+0.34328);
    %Slope error = 5.02E-4
    %Intercept error = 0.0172
    
    %channel 11 - Coil 5
    seqdata.analogchannels(11).name = 'Coil 5';
    seqdata.analogchannels(11).minvoltage = -1;
    seqdata.analogchannels(11).maxvoltage = 10;
    seqdata.analogchannels(11).defaultvoltagefunc = 2;
    %seqdata.analogchannels(11).voltagefunc{2} = @(a)(a*0.09571+0.3152);
    seqdata.analogchannels(11).voltagefunc{2} = @(a)(a*0.09289+0.33227);
    %Slope error = 3.18E-4
    %Intercept error 1= 0.0109
    
    %channel 12 - Coil 6
    seqdata.analogchannels(12).name = 'Coil 6';
    seqdata.analogchannels(12).minvoltage = -1;
    seqdata.analogchannels(12).maxvoltage = 10;
    seqdata.analogchannels(12).defaultvoltagefunc = 2;
    %seqdata.analogchannels(12).voltagefunc{2} = @(a)(a*0.09449+0.32107);
    seqdata.analogchannels(12).voltagefunc{2} = @(a)(a*0.094+0.34);
    %Slope error = 5.08E-4
    %Intercept error = 0.0174
    
    %channel 13 - Coil 7
    seqdata.analogchannels(13).name = 'Coil 7';
    seqdata.analogchannels(13).minvoltage = -1;
    seqdata.analogchannels(13).maxvoltage = 10;
    seqdata.analogchannels(13).defaultvoltagefunc = 2;
    %seqdata.analogchannels(13).voltagefunc{2} = @(a)(a*0.09511+0.31947);
    seqdata.analogchannels(13).voltagefunc{2} = @(a)(a*0.094+0.34);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123

    
    %channel 14 - Coil 8
    seqdata.analogchannels(14).name = 'Coil 8';
    seqdata.analogchannels(14).minvoltage = -1;
    seqdata.analogchannels(14).maxvoltage = 10;
    seqdata.analogchannels(14).defaultvoltagefunc = 2;
    %seqdata.analogchannels(14).voltagefunc{2} = @(a)(a*0.0948+0.33117);
    seqdata.analogchannels(14).voltagefunc{2} = @(a)(a*0.094+0.34);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123
    
    %channel 15 - Coil 9
    seqdata.analogchannels(15).name = 'Coil 9';
    seqdata.analogchannels(15).minvoltage = -1;
    seqdata.analogchannels(15).maxvoltage = 10;
    seqdata.analogchannels(15).defaultvoltagefunc = 2;
    %seqdata.analogchannels(15).voltagefunc{2} = @(a)(a*0.09221+0.28607);
    seqdata.analogchannels(15).voltagefunc{2} = @(a)(a*0.0936+0.27715);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123
    
    %channel 16 - Coil 10
    seqdata.analogchannels(16).name = 'Coil 10';
    seqdata.analogchannels(16).minvoltage = -1;
    seqdata.analogchannels(16).maxvoltage = 10;
    seqdata.analogchannels(16).defaultvoltagefunc = 2;
    %seqdata.analogchannels(16).voltagefunc{2} = @(a)(a*0.09289+0.33027);
    seqdata.analogchannels(16).voltagefunc{2} = @(a)(a*0.094+0.34);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123
    
    %channel 17 - Coil 11
    seqdata.analogchannels(17).name = 'Coil 11';
    seqdata.analogchannels(17).minvoltage = -1;
    seqdata.analogchannels(17).maxvoltage = 10;
    seqdata.analogchannels(17).defaultvoltagefunc = 2;
    %seqdata.analogchannels(17).voltagefunc{2} = @(a)(a*0.09459+0.33128);
    seqdata.analogchannels(17).voltagefunc{2} = @(a)(a*0.094+0.34);
    %seqdata.analogchannels(17).voltagefunc{2} = @(a)(a*0.1+0);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123
    
    %channel 18 (This is the Feed Forward) // delta-supply back-plate
    seqdata.analogchannels(18).name = 'Transport FF';
    seqdata.analogchannels(18).minvoltage = -1;
    seqdata.analogchannels(18).maxvoltage = 10;
    seqdata.analogchannels(18).defaultvoltagefunc = 2;
    seqdata.analogchannels(18).voltagefunc{2} = @(a)(a/6.6+0); %@(a)(a/6.0+0);
    %Slope error = 3.85E-4
    %Intercept error = 0.0123
    
    %channel 19 ( Y (Quantizing) Shim - G units)
    seqdata.analogchannels(19).name = 'Y Shim';
    seqdata.analogchannels(19).minvoltage = -5;
    seqdata.analogchannels(19).maxvoltage = 10;
    %Current
    seqdata.analogchannels(19).voltagefunc{2} = @(a)(a/0.8+0.3);
    seqdata.analogchannels(19).defaultvoltagefunc = 3; %3 BIPOLAR SHIM SUPPLY CHANGE
    %'Field' in G (not well calibrated)
    seqdata.analogchannels(19).voltagefunc{3} = @(a)(a*1.1875+0.52); % calibration for Shimmer control
    %seqdata.analogchannels(19).voltagefunc{4} = @(a)(a*0.3692-0.02); % calibration for bip source control
    seqdata.analogchannels(19).voltagefunc{5} = @(a)(a*0.3692-0.006); % calibration for bip source control after replacing pos side transistor
    seqdata.analogchannels(19).voltagefunc{4} = @(a)(0.9271*a-0.0327); % Amps: new shim supplies, calibrated to match old shim supply voltagefunc
    %Bipolar Shims (Alan's Box)
    %Max Positive Current = 4A (Supply is HP 6286A)
    %Max Negative Current = -1A (supply limited by HP E3611A)

    %channel 20 (4th vert--14)
    seqdata.analogchannels(20).name = 'Coil 14';
    seqdata.analogchannels(20).minvoltage = -10;
    seqdata.analogchannels(20).maxvoltage = 10;
    seqdata.analogchannels(20).defaultvoltagefunc = 2;
    %seqdata.analogchannels(20).voltagefunc{2} = @(a)(a*0.102+0.11633*sign(a));
    seqdata.analogchannels(20).voltagefunc{2} = @(a)(a*0.1/0.8+0.1*sign(a));
    seqdata.analogchannels(20).voltagefunc{3} = @(a)(a*0.1/0.8+0.05*sign(a));
     %seqdata.analogchannels(20).voltagefunc{2} = @(a)(a*0.011+0);
     %seqdata.analogchannels(20).voltagefunc{2} = @(a)((a>0).*(a*0.1035+0.0942)+(a<=0).*(a*0.1011-0.1511));
     %seqdata.analogchannels(20).voltagefunc{2} = @(a)(a*0.1033+0.09628*sign(a));
     
    %channel 21 (5rd vert--15)
    seqdata.analogchannels(21).name = 'Coil 15';
    seqdata.analogchannels(21).minvoltage = -10;
    seqdata.analogchannels(21).maxvoltage = 10;
    seqdata.analogchannels(21).defaultvoltagefunc = 2;
    %seqdata.analogchannels(21).voltagefunc{2} = @(a)(a*0.09107+0.13497*sign(a));
    %seqdata.analogchannels(21).voltagefunc{2} = @(a)(a*0.1+0.1*sign(a));
    %seqdata.analogchannels(21).voltagefunc{2} = @(a)(a*0.01+0);
    %seqdata.analogchannels(21).voltagefunc{2} = @(a)(a*0.1039+0.1243*sign(a));
     %seqdata.analogchannels(21).voltagefunc{2} =@(a)((a>0).*(a*0.10287+0.0921)+(a<=0).*(a*0.10509-0.10776));
    %seqdata.analogchannels(21).voltagefunc{2} =@(a)((a>0).*(a*0.10+0.1 )+(a<=0).*(a*0.10-0.10)); %old sensor
    seqdata.analogchannels(21).voltagefunc{2} =@(a)((a>0).*(a*0.1234+0.06)+(a<=0).*(a*0.10-0.10));
       
    %channel 22 (1st vert--12a)
    seqdata.analogchannels(22).name = 'Coil 12a';
    seqdata.analogchannels(22).minvoltage = -1;
    seqdata.analogchannels(22).maxvoltage = 10;
    seqdata.analogchannels(22).defaultvoltagefunc = 2;
    %seqdata.analogchannels(22).voltagefunc{2} = @(a)(a*0.1021+0.10112);
    %seqdata.analogchannels(22).voltagefunc{2} = @(a)(a*0.1+0.2);
     %seqdata.analogchannels(22).voltagefunc{2} = @(a)(a*0.0095+0);
     %seqdata.analogchannels(22).voltagefunc{2} = @(a)(a*0.10328+0.05497); %old sensor
     seqdata.analogchannels(22).voltagefunc{2} = @(a)(a*0.1265+0.05); %FW Bell sensor
    
    %channel 23 (2nd vert--12b)
    seqdata.analogchannels(23).name = 'Coil 12b';
    seqdata.analogchannels(23).minvoltage = -10;
    seqdata.analogchannels(23).maxvoltage = 10;
    seqdata.analogchannels(23).defaultvoltagefunc = 2;
    %seqdata.analogchannels(23).voltagefunc{2} = @(a)(a*0.1036+0.06788*sign(a));
    seqdata.analogchannels(23).voltagefunc{2} = @(a)(a*0.1/0.8+0.1*sign(a));
     %seqdata.analogchannels(23).voltagefunc{2} = @(a)(-a*0.011+0);
     %seqdata.analogchannels(23).voltagefunc{2} = @(a)(a*0.10287+0.0693*sign(a));
     %seqdata.analogchannels(23).voltagefunc{2} = @(a)(a*0.1+0.0907*sign(a));
    
    %channel 24 (3rd vert--13)
    seqdata.analogchannels(24).name = 'Coil 13';
    seqdata.analogchannels(24).minvoltage = -10;
    seqdata.analogchannels(24).maxvoltage = 10;
    seqdata.analogchannels(24).defaultvoltagefunc = 2;
    %seqdata.analogchannels(24).voltagefunc{2} = @(a)(a*0.097+0.0727*sign(a));
    seqdata.analogchannels(24).voltagefunc{2} = @(a)(a*0.1/0.8+0.1*sign(a));
     %seqdata.analogchannels(24).voltagefunc{2} = @(a)(a*0.01+0);
      %seqdata.analogchannels(24).voltagefunc{2} = @(a)((a>0).*(a*0.10457+0.0639)+(a<=0).*(a*0.09615-0.0385)); 
      %seqdata.analogchannels(24).voltagefunc{2} = @(a)(a*0.10696+0.0128*sign(a));
  
    %channel 25 (Repump intensity)
    seqdata.analogchannels(25).name = 'K Repump AM';
    seqdata.analogchannels(25).minvoltage = 0;
    seqdata.analogchannels(25).maxvoltage = 8;
%     seqdata.analogchannels(25).defaultvoltagefunc = 2;
     seqdata.analogchannels(25).voltagefunc{1} = @(a)(a*10);
    
    %channel 26 (Trap intensity)
    seqdata.analogchannels(26).name = 'K Trap AM';
    seqdata.analogchannels(26).minvoltage = -1;
    seqdata.analogchannels(26).maxvoltage = 8;
    seqdata.analogchannels(26).voltagefunc{1} = @(a)(a*10); %%This needs to be changed
    
    %channel 27 (Shim Channel 2+5, X Shim)
    seqdata.analogchannels(27).name = 'X Shim';
    seqdata.analogchannels(27).minvoltage = -10;
    seqdata.analogchannels(27).maxvoltage = 10;
    seqdata.analogchannels(27).defaultvoltagefunc = 2;
    seqdata.analogchannels(27).voltagefunc{2} = @(a)(a/0.8+0.3);     %Amps: When used with Shimmer
    seqdata.analogchannels(27).voltagefunc{4} = @(a)((a-0.081)/0.91); %Amps: When used to control bipolar supply  a*0.506-0.013 for old supply
    seqdata.analogchannels(27).voltagefunc{3} = @(a)(1.0536*a-0.1132); % Amps: new shim supplies, calibrated to match old shim supply voltagefunc
    
    %channel 28 (Shim Channel 3+6, Z Shim)
    seqdata.analogchannels(28).name = 'Z Shim';
    seqdata.analogchannels(28).minvoltage = -10;
    seqdata.analogchannels(28).maxvoltage = 10;
    seqdata.analogchannels(28).defaultvoltagefunc = 2;
    seqdata.analogchannels(28).voltagefunc{2} = @(a)(a/0.8+0.3);
    seqdata.analogchannels(28).voltagefunc{4} = @(a)((a-0*0.115)/0.977);   %a*0.506-0.013 for old supply
    seqdata.analogchannels(28).voltagefunc{3} = @(a)(0.9271*a-0.0327); % Amps: new shim supplies, calibrated to match old shim supply voltagefunc
                                                    %((a-0.11)/0.97)
    %Ch 29/30 removed June 20, 2012
%       %channel 29 (Y Cube Shim Channel)
%    seqdata.analogchannels(29).minvoltage = -1;
%     seqdata.analogchannels(29).maxvoltage = 10;
%     seqdata.analogchannels(29).defaultvoltagefunc = 2;
%     seqdata.analogchannels(29).voltagefunc{2} = @(a)(a/0.8+0.3);
%     
%      %channel 30 (X Cube Shim Channel 3+6)
%    seqdata.analogchannels(30).minvoltage = -1;
%     seqdata.analogchannels(30).maxvoltage = 10;
%     seqdata.analogchannels(30).defaultvoltagefunc = 2;
%     seqdata.analogchannels(30).voltagefunc{2} = @(a)(a/0.8+0.3);

     %channel 29 (K Probe AM)
    seqdata.analogchannels(29).name = 'K Probe/OP AM';
    seqdata.analogchannels(29).minvoltage = -10;
    seqdata.analogchannels(29).maxvoltage = 7;
    seqdata.analogchannels(29).defaultvoltagefunc = 2;
%     seqdata.analogchannels(29).voltagefunc{2} =
%     @(a)(tan((3.4*10.5352*atan(14.87454*(a-0.18519))+3.4*12.75877-1.85*23.48502)/1.85/20.06546)/1.99853+1.34661);
    seqdata.analogchannels(29).voltagefunc{2} = @(a) tan((a-0.53011)/0.43454)/0.78831+4.55017;
    
    
     %channel 30 (K Probe FM - func(2) is desired freq in MHz)
    seqdata.analogchannels(30).name = 'K Probe/OP FM';
    seqdata.analogchannels(30).minvoltage = -10;
    seqdata.analogchannels(30).maxvoltage = 10;
    seqdata.analogchannels(30).defaultvoltagefunc = 2;
%     seqdata.analogchannels(30).voltagefunc{2} = @(a)(1.41911-0.09634*a+8.43139*10^(-4)*a^2-1.57057*10^(-6)*a^3);%@(a)((a*1-136.96864)/19.37436);%@(a)((a*1-184.2)/79.972);
    seqdata.analogchannels(30).voltagefunc{2} = @(a)(-28.25805+0.22225*a-2.54054*10^(-4)*a^2);
    
     %channel 31 (Coil 16 trigger)
    seqdata.analogchannels(31).name = 'Coil 16 Trigger';
    seqdata.analogchannels(31).minvoltage = -1;
    seqdata.analogchannels(31).maxvoltage = 10;
    seqdata.analogchannels(31).defaultvoltagefunc = 2;
    seqdata.analogchannels(31).voltagefunc{2} = @(a)(a);
    
    %channel 32 (Ramp on modulation)
    seqdata.analogchannels(32).name = 'Modulation Ramp';
    seqdata.analogchannels(32).minvoltage = -10;
    seqdata.analogchannels(32).maxvoltage = 10;
    seqdata.analogchannels(32).defaultvoltagefunc = 2;
    seqdata.analogchannels(32).voltagefunc{2} = @(a)max(min((20*a-10),10),-10);%@(a)((log10(a) + 1) * (-5/2)); %Roughly linearizing.
    seqdata.analogchannels(32).voltagefunc{3} = @(a)((a-151.64)/8.2101);
    
    % channel 33 (Plug beam AOM control)
    seqdata.analogchannels(33).name = 'Plug Beam';
    seqdata.analogchannels(33).minvoltage = -10;
    seqdata.analogchannels(33).maxvoltage = 10;
    seqdata.analogchannels(33).defaultvoltagefunc = 2; 
    seqdata.analogchannels(33).voltagefunc{2} = @(a)((a+2.99906)/32.91976);%a = power (mW), calibration 2017-2-8
    %seqdata.analogchannels(33).voltagefunc{2} = @(a)((a+3.04231)/33.0940);%a = power (mW), calibration 2017-1-24

%channel 34 (Rb Offset frequency)
seqdata.analogchannels(34).name = 'Rb Beat Note FM';
seqdata.analogchannels(34).minvoltage = 0;
seqdata.analogchannels(34).maxvoltage = 10;
seqdata.analogchannels(34).defaultvoltagefunc = 2;
Rb_Trap_Frequency_Offset = 3.0; 2.5;0;4.5;-2.5; %Frequency offset for all Rb trap/probe beams in MHz.
seqdata.analogchannels(34).voltagefunc{2} = @(a)((a*1-4418.47 + Rb_Trap_Frequency_Offset)/541.355);

%channel 35 (Rb Offset FF)
seqdata.analogchannels(35).name = 'Rb Beat Note FF';
seqdata.analogchannels(35).minvoltage = -10;
seqdata.analogchannels(35).maxvoltage = 10;
seqdata.analogchannels(35).defaultvoltagefunc = 2;
seqdata.analogchannels(35).voltagefunc{2} = @(a)((-a*0.00401));

%channel 36 (Rb Probe/OP AOM AM control)
seqdata.analogchannels(36).name = 'Rb Probe/OP AM';
seqdata.analogchannels(36).minvoltage = -10;
seqdata.analogchannels(36).maxvoltage = 10;
seqdata.analogchannels(36).defaultvoltagefunc = 2;
seqdata.analogchannels(36).voltagefunc{2} = @(a)(a*5 - 2.5); %a is percentage of max power, scaled to -2.5V to 2.5V for Rigol AM

%channel 37 (Feshbach Current)
    %set to -0.5 when 'resting' to avoid a current spike when the digital
    %switch opens
    %set to 0 after the digital switch opens AND at least 100ms before
    %ramping on the coil to ensure a smooth ramp
seqdata.analogchannels(37).name = 'FB current';
seqdata.analogchannels(37).minvoltage = -0.5;
seqdata.analogchannels(37).maxvoltage = 10;
seqdata.analogchannels(37).resetvalue = [-0.5 1];
seqdata.analogchannels(37).defaultvoltagefunc = 2; %2 (changed to 3 to try smoothing low fields)
seqdata.analogchannels(37).voltagefunc{2} = @(a)((a-0.03939)/27.8636);%before 2017-1-5, @(a)(a*0.0333-0.001); % use when [dch-44, dch-45] = [0,0]
%seqdata.analogchannels(37).voltagefunc{2} = @(a)(a*0.0333+0.00333); %karl servo calibration
seqdata.analogchannels(37).voltagefunc{3} = @(a)(11/30*a - 6.6667); % use when [dch-44, dch-45] = [1,0]
% seqdata.analogchannels(37).voltagefunc{4} = @(a)(a*0.0333*9+0.00); % use when [dch-44, dch-45] = [0,1]
seqdata.analogchannels(37).voltagefunc{4} = @(a)(a*0.03365*9+0.0); % use when [dch-44, dch-45] = [0,1]
seqdata.analogchannels(37).voltagefunc{5} = @(a)((11/30*a - 6.6667)*9); % use when [dch-44, dch-45] = [1,1]
seqdata.analogchannels(37).voltagefunc{6} = @(a)(a*0.0333*7+0.00); % use when inserting a 1/7 voltage divider
   
%channel 38 (dipole 2 trap power)
seqdata.analogchannels(38).name = 'dipoleTrap2';
seqdata.analogchannels(38).minvoltage = -10;
seqdata.analogchannels(38).maxvoltage = 10; 
seqdata.analogchannels(38).resetvalue = [-0.0,1];
seqdata.analogchannels(38).defaultvoltagefunc = 4;
%seqdata.analogchannels(38).voltagefunc{2} = @(a)(a*0.2831-0.0);
seqdata.analogchannels(38).voltagefunc{3} = @(a)((a-0.001)/2.845);  % calibrated: 2013-11-28 ; Power in Watts
seqdata.analogchannels(38).voltagefunc{2} = @(a)(a./2.98 + 0.0191);  % calibrated: 2014-04-16; P in W (after telescope); Monitor PD: P/mW = 2.356 V/mV + 0.1
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.03)/0.5674); %2017-06-19 P in W.
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.0551642)/0.5763587); %2018-07-11
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.04749)/0.79528); %2019-02-27
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.17373)/2.33592); %2019-11-18
seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.22626)/2.86651); %2020-01-28 1V/W
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.038098)/0.65312); %2017-04-06 P in W.
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.025229)/0.63677);%@(a)((a+0.03789111)/0.6599042); % calibrated 2017-02-23
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+0.03174855)/0.5196055); % calibrated 2017-02-17
% seqdata.analogchannels(38).voltagefunc{4} = @(a)(sqrt(max((a+.04389).^2-0.00165,0)/.39132)); % calibrated 2016-12-21; P in W (before telescope) (Low Gain FB)
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+.043)./0.6284); % calibrated 2016-12-21; P in W (before telescope) (Low Gain FB)
% seqdata.analogchannels(38).voltagefunc{4} = @(a)((a+.00594)./0.67339); % calibrated 2016-12-20; P in W (before telescope) (High Gain FB)
% seqdata.analogchannels(38).voltagefunc{4} = @(a)(a./0.5597 - 0.0212); % calibrated 2016-02-29; P in W (before telescope); 
   

%channel 39 (RF Gain control)
seqdata.analogchannels(39).name = 'RF Gain';
seqdata.analogchannels(39).minvoltage = -10;
seqdata.analogchannels(39).maxvoltage = 10;

    
%channel 40 (dipole 1 trap power)
seqdata.analogchannels(40).name = 'dipoleTrap1';
seqdata.analogchannels(40).minvoltage = -10;
seqdata.analogchannels(40).maxvoltage = 10;
seqdata.analogchannels(40).resetvalue = [-0.0,1];
seqdata.analogchannels(40).defaultvoltagefunc = 4;
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.00226)/0.60811); %calibrated 2019-07-27
seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.08475)/0.54452); %calibrated 2020-01-28 2V/W
% seqdata.analogchannels(40).voltagefunc{3} = @(a)((0.0485 + 0.9625*a)/0.88); % calibrated: 2013-11-28 ; Power in Watts
% seqdata.analogchannels(40).voltagefunc{2} = @(a)(a./1.060 + 0.0482); % calibrated 2014-04-16; P in W (after telescope); Monitor PD: P/mW = 1.127 V/mV - 1.2
% % seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.0275821)./0.325018); %2017-06-19 P in W.
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((0.05955 + a)/0.61664);%calibrated 2019-02-27
% % seqdata.analogchannels(40).voltagefunc{4} = @(a)((0.02489614 + a)/0.2892920);%calibrated 2018-07-11
% % seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.025483)./0.29704);
% %2017-04-06 P in W.
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.0584191)./0.641079);%@(a)((a+0.04824701)./0.6628841); %2017-02-23:
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.0537331)./0.65677); %2017-02-09:  P in W after shear mode AOM and prisms.
% seqdata.analogchannels(40).voltagefunc{4} = @(a)(sqrt(max((a+.0883).^2-0.00672,0)/.59068)); % calibrated 2016-12-21; P in W (before telescope) (Low Gain FB)
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.0724)./0.7618); % calibrated 2016-12-21; P in W (before telescope) (Low Gain FB)
% seqdata.analogchannels(40).voltagefunc{4} = @(a)((a+0.007)./0.80953); % calibrated 2016-12-20; P in W (before telescope) (High Gain FB)
% seqdata.analogchannels(40).voltagefunc{4} = @(a)(a./0.7806 - 0.0535); % calibrated 2016-02-29; P in W (before telescope); 

%Channel 41 (motorized waveplate for dipole/lattice power dist)
seqdata.analogchannels(41).name = 'latticeWaveplate';
seqdata.analogchannels(41).minvoltage = 0;
seqdata.analogchannels(41).maxvoltage = 5.5;
%Voltage Functions - Calibrated as of Jan 2013
    %Specify the angle to move from the home position, in degrees:
    seqdata.analogchannels(41).voltagefunc{2} = @(a)(a/9.36);
    %Specify the percent of power to transmit to the lattice AOMs:
    %   assumes that the home position (0V) is at min transmission to
    %   lattice AOMS (all reflected from PBS to dipole beams)
    %   argument is the desired transmission expressed in [0,1]
    seqdata.analogchannels(41).voltagefunc{3} = @(a)(0.5*asind(sqrt(a))/9.36); 
    
%channel 42 (Objective Piezo Z control)
seqdata.analogchannels(42).name = 'objective Piezo Z';
seqdata.analogchannels(42).minvoltage = -2;
seqdata.analogchannels(42).maxvoltage = 10;

%channel 43 (Z lattice AM control)
seqdata.analogchannels(43).name = 'zLattice';
seqdata.analogchannels(43).minvoltage = -10;
seqdata.analogchannels(43).maxvoltage = 10;
seqdata.analogchannels(43).resetvalue = [-0.1,1];
seqdata.analogchannels(43).defaultvoltagefunc = 2;
seqdata.analogchannels(43).voltagefunc{2} = @(a)((a+2)/337.96806); %change to linear feedback, From 16, Jan, 2018.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.23537*log10(max((a),1E-9))-3.65955,-10)); %From 17, Jan, 2018.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)((a+2.36732)/337.596); %change to linear feedback, From 16, Jan, 2018.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.2207*log10(max((a),1E-9))-1.203,-10)); %From 11, Jan, 2018.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.26812*log10(max((a),1E-9))-1.81445,-10)); %From 28, June, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.2880*log10(max((a/1.09046-0.0),1E-9))-1.8248,-10)); %From 22, June, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.31443*log10(max((a-0.0),1E-9))-2.04569,-10)); % May 18, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.40223*log10(max((a-0.02),1E-9))-2.28163,-10)); %From Mar30, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(3.31877*log10(max(a,1E-9))-2.05995,-10)); %Temp old z lattice alps Mar 20, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.5077*log10(max((a-0.05),1E-9))-2.2598,-10)); %From Mar9, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(2.54822*log10(max(a,1E-9))-2.2754,-10)); %From Feb 24, 2017.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(log10(max((2*a*1.612-0.37099)/35.01058,1e-9))/0.41173,-10)); %Extra factor of 2(*a) for larger beam waist.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(log10(max((2*a+0*1.05694)/15.82836,1e-9))/0.39335,-10)); 
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max(log10(max((2*a-0.02346)/14.94575,1e-9))/0.40035,-10)); %Extra factor of 2(*a) for larger beam waist.
%Extra factor of 2(*a) for larger beam waist.
% seqdata.analogchannels(43).voltagefunc{2} = @(a)(max((log(max((-0.18079 + 0.4744*a + 8.87096E-5 * a.^2)*0.00135,1e-9)*1000)/log(10)-0.5577)/0.29395,-10));

%channel 44 (Y lattice AM control)
seqdata.analogchannels(44).name = 'yLattice';
seqdata.analogchannels(44).minvoltage = -10;
seqdata.analogchannels(44).maxvoltage = 10;
seqdata.analogchannels(44).resetvalue = [-10,1]; %Issue in the circuit when asking for -10V, causes siren
seqdata.analogchannels(44).defaultvoltagefunc = 2;
seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(2.27178*log10(max(a,1E-9))-2.77493,-10));%28 June, 2017
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(2.12074*log10(max(a/0.82894,1E-9))-2.6451,-10));%22 June, 2017
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(2.25415*log10(max(a,1E-9))-2.9949,-10));%18 May, 2017
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(2.20848*log10(max(a,1E-9))-2.88427,-10));
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(log10(max((a-2.46193+2.4)/18.02319,1e-9))/0.44698,-10));
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max(log10(max((a-1.79364)/18.44795,1e-9))/0.44664,-10));
% seqdata.analogchannels(44).voltagefunc{2} = @(a)(max((log(max((-0.12792 + 0.30045*a - 6.32254E-6 * a.^2)*0.00137/1.69,1e-9)*1000)/log(10)-0.5577)/0.29395,-10));

%channel 45 (X lattice AM control)
seqdata.analogchannels(45).name = 'xLattice';
seqdata.analogchannels(45).minvoltage = -10;
seqdata.analogchannels(45).maxvoltage = 10;
seqdata.analogchannels(45).resetvalue = [-0.1,1];
seqdata.analogchannels(45).defaultvoltagefunc = 2;
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(a);
seqdata.analogchannels(45).voltagefunc{2} = @(a)((a-2.7+5.61047)/473.44593);
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(2.21374*log10(max((a),1E-9))-2.59682,-10)); %June 28, 2017.
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(2.19994*log10(max((a-0.29448)/0.96966,1E-9))-2.6174,-10)); %June 22, 2017.
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(2.20008*log10(max(a,1E-9))-2.66132,-10)); %May 18, 2017.
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(2.2302*log10(max(a,1E-9))-2.8148,-10)); %Feb 28, 2017.
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(log10(max((a-2.09029+2)/19.17685,1e-9))/0.45223,-10));
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max(log10(max((a-2.23564)/18.74356,1e-9))/0.45462,-10));
% seqdata.analogchannels(45).voltagefunc{2} = @(a)(max((log(max((0.67911*a + 1.28809E-4 * a.^2)*0.00041,1e-9)*1000)/log(10)-0.5577)/0.29395,-10));

%channel 46 (FM for uWave Source)
seqdata.analogchannels(46).name = 'uWave FM/AM';
seqdata.analogchannels(46).minvoltage = -2;
seqdata.analogchannels(46).maxvoltage = 2;
seqdata.analogchannels(46).resetvalue = [0,1];
seqdata.analogchannels(46).defaultvoltagefunc = 2; 
seqdata.analogchannels(46).voltagefunc{2} = @(a)(a); % Use a 10x Voltage Divider before connecting to SRS

% %channel 47 (D1 AM Control)
seqdata.analogchannels(47).name = 'D1 AM';
seqdata.analogchannels(47).minvoltage = 0;
seqdata.analogchannels(47).maxvoltage = 10;


%channel 48 (D1 FM Control)
seqdata.analogchannels(48).name = 'D1 FM';
seqdata.analogchannels(48).minvoltage = 0;
seqdata.analogchannels(48).maxvoltage = 10;
K_D1_freq_offset = 0/1000;
seqdata.analogchannels(48).defaultvoltagefunc = 2; 
% seqdata.analogchannels(48).voltagefunc{2} = @(a)((a+K_D1_freq_offset)*0.05226-7.16102); 
seqdata.analogchannels(48).voltagefunc{2} = @(a)((a+K_D1_freq_offset)-129.326)/21.222; %2020-03-12 

% bipolar
    %A voltage of 0.4V gives best diffraction, higher voltages overdrive
    %the AOM\
    
%channel 49 (D1 EOM Amplitude)
seqdata.analogchannels(49).name = 'D1 EOM';
seqdata.analogchannels(49).minvoltage = -1;
seqdata.analogchannels(49).maxvoltage = 10;

%channel 50 (K Repump FM)
seqdata.analogchannels(50).name = 'K Repump FM';
seqdata.analogchannels(50).minvoltage = 0;
seqdata.analogchannels(50).maxvoltage = 10;
% K_repump_offset_list = [5];
% K_repump_offset = getScanParameter(K_repump_offset_list,seqdata.scancycle,seqdata.randcyclelist,'K_trap_offset');
seqdata.analogchannels(50).voltagefunc{2} = @(a)(4.664 - 0.0285*(a-K_repump_freq_offset/2)); %Repump detuning (in real MHz) from typical set value

%channel 51 (F Pump)
seqdata.analogchannels(51).name = 'F Pump';
% seqdata.analogchannels(51).resetvalue = [-0.1,1];
seqdata.analogchannels(51).minvoltage = -10;
seqdata.analogchannels(51).maxvoltage = 10;

%channel 52 (Dimple Pwr)
seqdata.analogchannels(52).name = 'Dimple Pwr';
seqdata.analogchannels(52).minvoltage = -10;
seqdata.analogchannels(52).maxvoltage = 10;

%channel 53 (VVA for Ramping uWave Power)
seqdata.analogchannels(53).name = 'uWave VVA';
seqdata.analogchannels(53).minvoltage = -1;
seqdata.analogchannels(53).maxvoltage = 10;

%channel 54 (Piezo mirror controller, channel X)
seqdata.analogchannels(54).name = 'Piezo mirror X';
seqdata.analogchannels(54).minvoltage = -0.15;
seqdata.analogchannels(54).maxvoltage = 10;
seqdata.analogchannels(54).defaultvoltagefunc = 2; 
seqdata.analogchannels(54).voltagefunc{2} = @(a)((a-0.7)/15.18);

%channel 55 (Piezo mirror controller, channel Y)
seqdata.analogchannels(55).name = 'Piezo mirror Y';
seqdata.analogchannels(55).minvoltage = -0.15;
seqdata.analogchannels(55).maxvoltage = 10;
seqdata.analogchannels(55).defaultvoltagefunc = 2; 
seqdata.analogchannels(55).voltagefunc{2} = @(a)((a-1.7)/15.04);

%channel 56 (Piezo mirror controller, channel Z)
seqdata.analogchannels(56).name = 'Piezo mirror Z';
seqdata.analogchannels(56).minvoltage = -10;
seqdata.analogchannels(56).maxvoltage = 10;
seqdata.analogchannels(56).defaultvoltagefunc = 2; 
seqdata.analogchannels(56).voltagefunc{2} = @(a)(a);

%channel 57 (XDT1 Piezo Mirror Mod)
seqdata.analogchannels(57).name = 'XDT1 Piezo';
seqdata.analogchannels(57).minvoltage = -10;
seqdata.analogchannels(57).maxvoltage = 10;
seqdata.analogchannels(57).defaultvoltagefunc = 2; 
seqdata.analogchannels(57).voltagefunc{2} = @(a)(a);

%channel 58 (XDT2 Piezo Mirror Mod)
seqdata.analogchannels(58).name = 'XDT2 Piezo';
seqdata.analogchannels(58).minvoltage = -10;
seqdata.analogchannels(58).maxvoltage = 10;
seqdata.analogchannels(58).defaultvoltagefunc = 2; 
seqdata.analogchannels(58).voltagefunc{2} = @(a)(a);

%channel 59 (Not functional??)
seqdata.analogchannels(59).name = 'DMD Power';
seqdata.analogchannels(59).minvoltage = -10;
seqdata.analogchannels(59).maxvoltage = 10;
seqdata.analogchannels(59).defaultvoltagefunc = 2; 
seqdata.analogchannels(59).voltagefunc{2} = @(a)(a);
    
%channel 60 (Compensation Beam Power Control)
seqdata.analogchannels(60).name = 'UV Lamp 2'; % control K repump 0th order
seqdata.analogchannels(60).minvoltage = -10;
seqdata.analogchannels(60).maxvoltage = 10;
seqdata.analogchannels(60).defaultvoltagefunc = 2; 
seqdata.analogchannels(60).voltagefunc{2} = @(a)(a);% 
% % % % 
% % % % %channel 61 (MOT to Grey Molasses switch (temporary)) # This is supposed to
% % % % %be a digital channel. 
% % % % seqdata.analogchannels(61).name = 'Grey Molasses switch'; %0: MOT; 1: Gray Molasses
% % % % seqdata.analogchannels(61).minvoltage = -10;
% % % % seqdata.analogchannels(61).maxvoltage = 10;
% % % % seqdata.analogchannels(61).defaultvoltagefunc = 1; 
% % % % seqdata.analogchannels(61).voltagefunc{2} = @(a)(a);% 

% create cell arrays with channel names for lookup
for i = 1:length(seqdata.digchannels)
    seqdata.dignames{i} = seqdata.digchannels(i).name;
end
for i = 1:length(seqdata.analogchannels)
    seqdata.analognames{i} = seqdata.analogchannels(i).name;
end

%% Obsolete Channel Definitions


% %channel 47 (bipolar X Shim control --- so far only temporary)
% seqdata.analogchannels(47).name = 'bip Z Shim'; %Shim H-Bridge
% seqdata.analogchannels(47).minvoltage = -10; %0 for Shim H-bridge
% seqdata.analogchannels(47).maxvoltage = 10;
% seqdata.analogchannels(47).defaultvoltagefunc = 2; 
% seqdata.analogchannels(47).voltagefunc{2} = @(a)(a*0.506-0.013); 
%     %Bipolar Shim Calibrations
%     %X shim bipolar a*0.4568+0.0158 (May 24th)  a*0.4715-0.0035 (??)
%     %Y Shim bipolar a*0.3692-0.02
%     %Z Shim bipolar a*0.506-0.013

% %channel 48 (bipolar Z Shim control --- so far only temporary)
% seqdata.analogchannels(48).name = 'bip Z Shim'; %Shim H-Bridge
% seqdata.analogchannels(48).minvoltage = -10; %0 for Shim H-bridge
% seqdata.analogchannels(48).maxvoltage = 10;
% seqdata.analogchannels(48).defaultvoltagefunc = 2; 
% %seqdata.analogchannels(48).voltagefunc{2} = @(a)(a*0.3692-0.02); %Y shim bipolar
% seqdata.analogchannels(48).voltagefunc{2} = @(a)(a*0.4715-0.0035); %-0.013 %Z shim bipolar a*0.506-0.013

% %channel 47 (405nm FM Control)
% seqdata.analogchannels(47).name = '405nm FM';
% seqdata.analogchannels(47).minvoltage = 0;
% seqdata.analogchannels(47).maxvoltage = 10;
% seqdata.analogchannels(47).defaultvoltagefunc = 2;
% %Set to convert frequency to volts, calibrated June 17
%     % the offset changes if the FM knob is touched
%     seqdata.analogchannels(47).voltagefunc{2} = @(a)((a-125.6)/11.42);

% % %channel 47 (VVA Control)
% seqdata.analogchannels(47).name = 'VVA Control';
% seqdata.analogchannels(47).minvoltage = 0;
% seqdata.analogchannels(47).maxvoltage = 10;
% seqdata.analogchannels(47).defaultvoltagefunc = 1; 
%     %VoltageFunc2 - RF Power Desired as a fraction of max available power (0-1)
%     seqdata.analogchannels(47).voltagefunc{2} = @(a)(1.5457 + 16.9*a - 11.83*a.^2 + 3.384*a.^3);



end