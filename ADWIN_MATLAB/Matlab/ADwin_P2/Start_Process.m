%Start_Process  starts a process.
%
%  Syntax:  Start_Process (ProcessNo)
%
%  Parameters:
%    ProcessNo       Number of the process (1...10, 15).
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    The function has no effect, if you indicate the number of a process, which 
%    - is already running or
%    - has the same number as the calling process or
%    - has not yet been loaded to the ADwin system.
%
%  Example:
%    % Start Process 2
%    Start_Process (2)
%
%  See also STOP_PROCESS, LOAD_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $