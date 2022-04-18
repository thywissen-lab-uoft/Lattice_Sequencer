%Set_DeviceNo  sets the device number.
%
%  Syntax:  Set_DeviceNo (DeviceNo)
%
%  Parameters:
%    DeviceNo        board address or DeviceNo in decimal notation. 
%                    The default setting is 1.
%
%  Notes:
%    The PC distinguishes and accesses the ADwin systems by the device number.
%    Systems with link adapter are already configured in factory (default
%    setting: 336).
%    Further information can be found in the online help of the program
%    ADconfig or in the manual "ADwin Installation".
%
%  Example:
%    % Set the device number 3
%    Set_DeviceNo(3)
%
%  See also GET_DEVICENO, START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $