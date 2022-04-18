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
%    Further information can be found in the online help of the program ADconfig
%    or in the manual "ADwin Installation".
%
%  Example:
%    % Set the device number 3
%    Set_DeviceNo(3);
%
%  See also GET_DEVICENO, START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, FREE_MEM, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
