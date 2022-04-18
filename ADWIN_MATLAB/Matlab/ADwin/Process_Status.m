%Process_Status  returns the status of a process.
%
%  Syntax:  Process_Status (ProcessNo)
%
%  Parameters:
%    ProcessNo       Process number (1...10, 15).
%    return value    Status of the process:
%                    1 : Process is running.
%                    0 : Process is not running, that means, it has not been
%                    loaded, started or stopped.
%                    -1: Process has been stopped, that means, it has received
%                    Stop_Process, but still waits for the last event.
%
%  Notes:
%    This function cannot be used in connection with ADsim T11.
%
%  Example:
%    % Return the status of process 2
%    ret_val = Process_Status(2);
%
%  See also SET_PROCESSDELAY, GET_PROCESSDELAY.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
