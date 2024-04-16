function timeout = lattice_load(timein)

global seqdata
curtime = timein;
if curtime==0
    main_settings;
    curtime = calctime(curtime,1000);
end
%% Rotate the waveplate before/during loading

if seqdata.flags.lattice_rotate_waveplate_1
    dispLineStr('Rotating waveplate',curtime);
    
    tr = getVar('lattice_rotate_waveplate1_duration');
    td = getVar('lattice_rotate_waveplate1_delay');
    value = getVar('lattice_rotate_waveplate1_value');
    
    disp(['     Rotation Time : ' num2str(tr) ' ms']);
    disp(['     Delay    Time : ' num2str(td) ' ms']);
    disp(['     Power         : ' num2str(100*P_RotWave_I) '%']);

    AnalogFunc(calctime(curtime,td),'latticeWaveplate',...
        @(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),...
        tr,tr,value);    
end

end

