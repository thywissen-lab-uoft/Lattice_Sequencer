%ADwin_Init  initializes Matlab to communicate with ADwin.
%
%  Syntax:  ADwin_Init ()
%
%  Parameters:
%    None.
%
%  Notes:
%    This function sets two default values
%       1. DeviceNo = 1. To set a different value, see function Set_DeviceNo.
%       2. Show error messages in a message box. To set a different value,
%          see function Show_Errors.
%
%    The PC distinguishes and accesses the ADwin systems by the device number.
%    Systems with link adapter are already configured in factory (default
%    setting: 336).
%    Further information can be found in the online help of the program
%    ADconfig or in the manual "ADwin Installation".
%
%  Example:
%    % Initialize the ADwin communication with Matlab and set the device number 1 
%    % and show errors (default).
%    ADwin_Init();
%
%  See also  ADWIN_UNLOAD, SHOW_ERRORS, SET_DEVICENO, GET_DEVICENO.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $