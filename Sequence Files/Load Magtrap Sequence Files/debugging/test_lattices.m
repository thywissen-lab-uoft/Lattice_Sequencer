function test_lattices(timein)
%TEST_LATTICES Summary of this function goes here
%   Detailed explanation goes here
curtime = timein;

global seqdata;

curtime = calctime(curtime,500);


doRotateWaveplate = 1;

% Set lattice feedback offset (double PD configuration)
setAnalogChannel(calctime(curtime,-60),'Lattice Feedback Offset', -9.8,1);

% Send request powers to -10V to rail the PID at the lower end
setAnalogChannel(calctime(curtime,-60),'xLattice',-10,1);
setAnalogChannel(calctime(curtime,-60),'yLattice',-10,1);
setAnalogChannel(calctime(curtime,-60),'zLattice',-10,1);

% Enable AOMs on the lattice beams
setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off

if doRotateWaveplate
    wp_Trot1 = 600; % Rotation time during XDT
    wp_Trot2 = 150; 
    P_RotWave_I = 0.8;
    P_RotWave_II = 1;    
%     P_RotWave_II = 0.01;    

    dispLineStr('Rotate waveplate again',curtime)    
        %Rotate waveplate again to divert the rest of the power to lattice beams
curtime = AnalogFunc(calctime(curtime,0),41,...
        @(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
        wp_Trot2,wp_Trot2,P_RotWave_I,P_RotWave_II);             
end



end

