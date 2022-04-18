%Stop_Process  stops a process.
%
%  Syntax:  Stop_Process (ProcessNo)
%
%  Parameters:
%    ProcessNo       Process number (1...10, 15).
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    The function has no effect, if you indicate the number of a process, which
%    - has already been stopped or
%    - has not yet been loaded to the ADwin system.
%
%  Example:
%    % stop process 2
%    ret_val = Stop_Process (2);
%
%  See also START_PROCESS, LOAD_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $