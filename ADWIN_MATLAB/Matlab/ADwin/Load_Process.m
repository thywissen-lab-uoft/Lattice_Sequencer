%Load_Process  loads the binary file of a process into the ADwin system.
%
%  Syntax:  Load_Process (Filename)
%
%  Parameters:
%    Filename        Path and filename of the binary file to be loaded
%    Return value    1 OK
%                    <>1 Error
%
%  Notes:
%    This function cannot be used in connection with ADsim T11.
%    You generate binary files in ADbasic with "Make > Make Bin file".
%    If you switch off your ADwin system all processes are deleted: Load the
%    necessary processes again after power-up.
%    You can load up to 10 processes to an ADwin system. Running processes are
%    not influenced by loading additional processes (with different process
%    numbers).
%    Before loading the process into the ADwin system, you have to ensure that
%    no process using the same process number is already running. If there is
%    such a process yet, you first have to stop the running process using
%    Stop_Process.
%    If you load processes more than once, memory fragmentation can happen.
%    Please note the appropriate hints in the ADbasic manual.
%
%  Example:
%    % Load binary file Testprog.T91
%    % T91 = Processor type T9, process no. 1
%    Load_Process('C:\MyADbasic\Testprog.T91');
%
%  See also START_PROCESS, STOP_PROCESS, GET_DEVICENO, BOOT, FREE_MEM, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
