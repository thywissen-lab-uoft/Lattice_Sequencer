function y = Process_Status(ProcessNo)
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
%  Example:
%    % Return the status of process 2
%    ret_val = Process_Status(2);
%
%  See also GET_GLOBALDELAY, SET_PROCESSDELAY.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(38,900+ProcessNo);



