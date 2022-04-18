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
%    This function cannot be used in connection with ADsim T11.
%    The function has no effect, if you indicate the number of a process, which 
%    - is already running or
%    - has the same number as the calling process or
%    - has not yet been loaded to the ADwin system.
%
%  Example:
%    % Start Process 2
%    Start_Process (2);
%
%  See also STOP_PROCESS, LOAD_PROCESS, SET_DEVICENO, GET_DEVICENO, BOOT, FREE_MEM, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
