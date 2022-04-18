function  y=Set_DeviceNo(DeviceNo)
%Set_DeviceNo  sets the device number.
%
%  Syntax:  Set_DeviceNo (DeviceNo)
%
%  Parameters:
%    DeviceNo        board address or DeviceNo in decimal notation. Typical
%                    DeviceNo's are 336 (= 150h hexadecimal), 400 (=190h), etc.
%                    The default setting is 336.
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

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(200, DeviceNo);



