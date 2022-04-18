% mat_dmo3.m
% This example requires an ADwin-Gold with DeviceNo = 1.
% Gets DATA_1 (the ADbasic Data array No. 1).
% The ADbasic process "Bas_dmo3.T91" will be
% loaded on the ADwin-system.
% It is located normally in : 
%   c:\ADwin\ADbasic\samples_ADwin\
%
% Initializes Matlab to communicate with ADwin.
ADwin_Init(); % Function sets the DeviceNo = 1. To set a different value, see function Set_DeviceNo.
Boot('c:\adwin\adwin9.btl', 0);
Load_Process('c:\ADwin\ADbasic\samples_ADwin\Bas_dmo3.T91');
Start_Process(1) ;		% start ADbasic process 1
x = 0;
while x~=1,
   x = Get_Par(10)
end
y1 = GetData_Double(1,1,1000);% get ADbasic Data array 1
plot(y1) ;

ADwin_Unload(); %Unload the ADwin library from memory.