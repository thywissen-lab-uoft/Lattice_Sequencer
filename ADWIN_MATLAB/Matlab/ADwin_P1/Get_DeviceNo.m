function  y=Get_DeviceNo()
%Get_DeviceNo  returns the current device number.
%
%  Syntax:  Get_DeviceNo ()
%
%  Parameters:
%    None.
%
%  Notes:
%    The PC distinguishes and accesses the ADwin systems by the device number.
%    Systems with link adapter are already configured in factory (default
%    setting: 336).
%    Further information can be found in the online help of the program
%    ADconfig or in the manual "ADwin Installation".
%
%  Example:
%    % Query the current device number
%    num = Get_DeviceNo()
%
%  See also SET_DEVICENO, START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $


y=ADlab(201);



