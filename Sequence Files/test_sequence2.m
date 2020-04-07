%------
%Author: Dylan
%Created: Sept 2013
%Summary: This is another test sequence
%------

function timeout = test_sequence2(timein)

curtime = timein;

global seqdata;

%% shims 
 curtime = calctime(curtime,100);
% 
% setAnalogChannel(curtime,47,0,2);
% 
% setAnalogChannel(curtime,46,0,1);
% 
% setDigitalChannel(calctime(curtime,100),37,1);
% 
% %Y
% curtime = setAnalogChannel(calctime(curtime,0),19,0,4);
% %Z
% curtime = setAnalogChannel(calctime(curtime,0),28,0.0,3);
% %X
% curtime = setAnalogChannel(calctime(curtime,0),27,0,3);
%           
% 
% %Y
% curtime = setAnalogChannel(calctime(curtime,100),19,0,4);
% %Z
% curtime = setAnalogChannel(calctime(curtime,0),28,0.0,3);
% %X
% curtime = setAnalogChannel(calctime(curtime,0),27,0,3);
% 
% %FB TTL
 setAnalogChannel(calctime(curtime,0),46,0,1);

%% D1
% setDigitalChannel(calctime(curtime,200),37,0);
% % 
% 
% setAnalogChannel(calctime(curtime,100),46,0,1);
% 
% setAnalogChannel(calctime(curtime,100),47,0,1);
% 
% setAnalogChannel(calctime(curtime,100),48,185,2);

%Set Detuning
%             setAnalogChannel(calctime(curtime,-10),48,200);

%% Rotating waveplate
%setDigitalChannel(calctime(curtime,200),37,0);
%setAnalogChannel(calctime(curtime,200),41,5,1);


%% multiple scan lists
% setAnalogChannel(calctime(curtime,100),32,1,1);
% testa_list = [1 2]
% testb_list = [3];
% % testc_list = [5 6];
% % testd_list = [10]
% testa = getmultiScanParameter(testa_list,seqdata.scancycle,seqdata.randcyclelist,'testa',1,2);
% testb = getmultiScanParameter(testb_list,seqdata.scancycle,seqdata.randcyclelist,'testb',2,1);
% % testc = getmultiScanParameter(testc_list,seqdata.scancycle,seqdata.randcyclelist,'testc',1,3);
% % testd = getmultiScanParameter(testd_list,seqdata.scancycle,seqdata.randcyclelist,'testd',1);
% fprintf('a = %g, b=%g\n',testa, testb);


%% End
timeout = curtime;


end

