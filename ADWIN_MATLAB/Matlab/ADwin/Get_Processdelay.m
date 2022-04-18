%Get_Processdelay  returns the parameter Processdelay for a process.
%
%  Syntax:  Get_Processdelay (ProcessNo)
%
%  Parameters:
%    ProcessNo       Process number (1...10); with ADsim T11: ...2.
%    Return value    <>255: The currently set value (1...231-1) for the
%                    parameter Processdelay.
%                    255: Error
%
%  Notes:
%    The parameter Processdelay controls the time interval between two events of
%    a time-controlled process (see Set_Processdelay as well as the manual or
%    online help of ADbasic).
%    For ADsim users: The parameter Processdelay corresponds to the fixed-step
%    size in Simulink. While the fixed-step size is set in seconds, the
%    Processdelay is a multiple of processor cycles, see Set_Processdelay.
%
%  Example:
%    % Get Processdelay of process 1
%    x = Get_Processdelay(1);
%
%  See also SET_PROCESSDELAY, PROCESS_STATUS.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
