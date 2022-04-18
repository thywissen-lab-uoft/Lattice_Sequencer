% mat_dmo1.m
% This example requires an ADwin-Gold with DeviceNo = 336. 
% Gets PAR_1 and PAR_2 from the ADwin-system (5 times).
% The ADbasic process "Bas_dmo1.T91" will be
% loaded on the ADwin-system.
% It is located normally in : 
%   c:\ADwin\ADbasic\samples_ADwin\
%
% Initializes Matlab to communicate with ADwin.
ADwin_Init(); % Function sets the DeviceNo = 1. To set a different value, see function Set_DeviceNo.
Boot('c:\adwin\adwin9.btl', 0);
Load_Process('c:\ADwin\ADbasic\samples_ADwin\bas_dmo1.T91');
Start_Process(1) ;	% start ADbasic process 1
for i=1:5,
   min = Get_Par(1)	% get PAR_1 (minimum value)
   max = Get_Par(2)	% get PAR_2 (maximum value)
	pause ;
end ;
Stop_Process(1) ;		% stop ADbasic process 1

ADwin_Unload(); %Unload the ADwin library from memory.