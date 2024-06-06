function timeout = default_channels(timein)
% -----
% Set all channels to their default values(start MOT loading and switch off unnecessary items)
% Fudong Wang, Feb-2017
% -----
curtime=timein;

%digital channels
setDigitalChannel(curtime,'d1',);%1
setDigitalChannel(curtime,'K Trap Shutter',1);%2
setDigitalChannel(curtime,'K Repump Shutter',1);%3
setDigitalChannel(curtime,'Rb Trap Shutter',1);%4
setDigitalChannel(curtime,'Rb Repump Shutter',1);%5
setDigitalChannel(curtime,'K Trap TTL',1);%6
setDigitalChannel(curtime,'K Repump TTL',1);%7
setDigitalChannel(curtime,'Rb Trap TTL',1);%8
setDigitalChannel(curtime,'K Probe/OP TTL',1);%9
setDigitalChannel(curtime,'Plug Shutter',0);%10
setDigitalChannel(curtime,'xLatticeOFF',1);%11
setDigitalChannel(curtime,'ScopeTrigger',0);%12
setDigitalChannel(curtime,'d13',);%13
setDigitalChannel(curtime,'Rb uWave TTL',0);%14
setDigitalChannel(curtime,'Dimple Shutter',0);%15
setDigitalChannel(curtime,'d16',);%16
setDigitalChannel(curtime,'RF/uWave Transfer',10);%17
setDigitalChannel(curtime,'DDS ADWIN Trigger',0);%18
setDigitalChannel(curtime,'RF TTL',0);%19
setDigitalChannel(curtime,'d20',);%20
setDigitalChannel(curtime,'Coil 16 TTL',);%21
setDigitalChannel(curtime,'15/16 Switch',);%22
setDigitalChannel(curtime,'D1 Shutter',0);%23
setDigitalChannel(curtime,'Rb Probe/OP TTL',1);%24
setDigitalChannel(curtime,'Rb Probe/OP Shutter',0);%25
setDigitalChannel(curtime,'PixelFly Trigger',0);%26
setDigitalChannel(curtime,'TiSapph Shutter',0);%27
setDigitalChannel(curtime,'Transport Relay',);%28
setDigitalChannel(curtime,'Kitten Relay',);%29
setDigitalChannel(curtime,'K Probe/OP shutter',0);%30
setDigitalChannel(curtime,'fast FB Switch',);%31
setDigitalChannel(curtime,'iXon Trigger',0);%32
setDigitalChannel(curtime,'Shim Relay',1);%33
setDigitalChannel(curtime,'yLatticeOFF',1);%34
setDigitalChannel(curtime,'EIT Probe TTL',1);%35
setDigitalChannel(curtime,'EIT Shutter',0);%36
setDigitalChannel(curtime,'Channel 37',0);%37
setDigitalChannel(curtime,'405nm TTL',1);%38
setDigitalChannel(curtime,'K uWave TTL',0);%39
setDigitalChannel(curtime,'K/Rb uWave Transfer',1);%40
setDigitalChannel(curtime,'Lattice Direct Control',1);%41
setDigitalChannel(curtime,'FB Integrator OFF',0);%42
setDigitalChannel(curtime,'Bipolar Shim Relay',0);%43
setDigitalChannel(curtime,'FB offset select',0);%44
setDigitalChannel(curtime,'FB sensitivity select',0);%45
setDigitalChannel(curtime,'Field sensor SR',);%46
setDigitalChannel(curtime,'60Hz sync',0);%47
setDigitalChannel(curtime,'Rb Repump Imaging',1);%48
setDigitalChannel(curtime,'Rb Source Transfer',1);%49
setDigitalChannel(curtime,'Z Lattice TTL',1);%50
setDigitalChannel(curtime,'Lattice FM',0);%51
setDigitalChannel(curtime,'Remote field sensor SR',0);%52
setDigitalChannel(curtime,'K uWave Source',0);%53
setDigitalChannel(curtime,'F Pump TTL',0);%54
setDigitalChannel(curtime,'Downwards D2 Shutter',0);%55
setDigitalChannel(curtime,'ACync Master',);%56
setDigitalChannel(curtime,'D1 OP TTL',1);%57
setDigitalChannel(curtime,'Raman Shutter',1);%58
setDigitalChannel(curtime,'Kill TTL',1);%59
setDigitalChannel(curtime,'Raman TTL',1);%60
setDigitalChannel(curtime,'XDT TTL',1);%61
setDigitalChannel(curtime,'Dimple TTL',1);%62
setDigitalChannel(curtime,'Plug Mode Switch',0);%63
setDigitalChannel(curtime,'Plug TTL',1);%64

%analog channels
setAnalogChannel(curtime,'Coil 16',);%1
setAnalogChannel(curtime,'Rb Repump AM',);%2
setAnalogChannel(curtime,'kitten',);%3
setAnalogChannel(curtime,'Rb Trap AM',);%4
setAnalogChannel(curtime,'K Trap FM',20);%5
setAnalogChannel(curtime,'Raman VVA',9.9);%6
setAnalogChannel(curtime,'Push Coil',);%7
setAnalogChannel(curtime,'MOT Coil',10);%8
setAnalogChannel(curtime,'Coil 3',);%9
setAnalogChannel(curtime,'Coil 4',);%10
setAnalogChannel(curtime,'Coil 5',);%11
setAnalogChannel(curtime,'Coil 6',);%12
setAnalogChannel(curtime,'Coil 7',);%13
setAnalogChannel(curtime,'Coil 8',);%14
setAnalogChannel(curtime,'Coil 9',);%15
setAnalogChannel(curtime,'Coil 10',);%16
setAnalogChannel(curtime,'Coil 11',);%17
setAnalogChannel(curtime,'Transport FF',10);%18
setAnalogChannel(curtime,'Y Shim',0,1);%19
setAnalogChannel(curtime,'Coil 14',);%20
setAnalogChannel(curtime,'Coil 15',);%21
setAnalogChannel(curtime,'Coil 12a',);%22
setAnalogChannel(curtime,'Coil 12b',);%23
setAnalogChannel(curtime,'Coil 13',);%24
setAnalogChannel(curtime,'K Repump AM',);%25
setAnalogChannel(curtime,'K Trap AM',);%26
setAnalogChannel(curtime,'X Shim',0,1);%27
setAnalogChannel(curtime,'Z Shim',0,1);%28
setAnalogChannel(curtime,'K Probe/OP AM',);%29
setAnalogChannel(curtime,'K Probe/OP FM',);%30
setAnalogChannel(curtime,31,0);%31
setAnalogChannel(curtime,'Modulation Ramp',0.1);%32
setAnalogChannel(curtime,'Plug Beam',);%33
setAnalogChannel(curtime,'Rb Beat Note FM',);%34
setAnalogChannel(curtime,'Rb Beat Note FF',);%35
setAnalogChannel(curtime,'Rb Probe/OP AM',);%36
setAnalogChannel(curtime,'FB current',);%37
setAnalogChannel(curtime,'dipoleTrap2',0,1);%38
setAnalogChannel(curtime,'RF Gain',);%39
setAnalogChannel(curtime,'dipoleTrap1',0,1);%40
AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);%41
setAnalogChannel(curtime,'objective Piezo Z',);%42
setAnalogChannel(curtime,'zLattice',0,2);%43
setAnalogChannel(curtime,'yLattice',0,2);%44
setAnalogChannel(curtime,'xLattice',0,2);%45
setAnalogChannel(curtime,'uWave FM/AM',0);%46
setAnalogChannel(curtime,'D1 OP AM',);%47
setAnalogChannel(curtime,'D1 FM',);%48
setAnalogChannel(curtime,'D1 EOM',);%49
setAnalogChannel(curtime,'K Repump FM',);%50
setAnalogChannel(curtime,'F Pump',-1);%51
setAnalogChannel(curtime,'Dimple',0);%52
setAnalogChannel(curtime,'uWave VVA',10);%53
% setAnalogChannel(curtime,'Piezo mirror X',0);%54
setAnalogChannel(curtime,'Piezo mirror Y',0);%55
setAnalogChannel(curtime,'Piezo mirror Z',0);%56
setAnalogChannel(curtime,'a57',0);%57
setAnalogChannel(curtime,'a58',0);%58
setAnalogChannel(curtime,'a59',0);%59
setAnalogChannel(curtime,'a60',0);%60
setAnalogChannel(curtime,'a61',0);%61
setAnalogChannel(curtime,'X MOT Shim',0.5,1);%62
setAnalogChannel(curtime,'Y MOT Shim',0.95,1);%63
setAnalogChannel(curtime,'Z MOT Shim',0.42,1);%64




end

