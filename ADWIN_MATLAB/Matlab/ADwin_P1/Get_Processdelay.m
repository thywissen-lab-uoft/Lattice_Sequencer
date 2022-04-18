function y = Get_Processdelay(ProcessNo)
%Get_Processdelay  returns the parameter Processdelay for a process.
%
%  Syntax:  Get_Processdelay (ProcessNo)
%
%  Parameters:
%    ProcessNo       Process number (1...10).
%    Return value    <>255: The currently set value (1...231-1) for the
%                    parameter Processdelay.
%                    255: Error
%
%  Notes:
%    The parameter Processdelay controls the time interval between two events
%    of a time-controlled process (see Set_Processdelay as well as the manual
%    or online help of ADbasic).
%
%  Example:
%    % Get Processdelay of process 1
%    x = Get_Processdelay(1)
%
%  See also PROCESS_STATUS, SET_PROCESSDELAY
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(38,910+ProcessNo);



