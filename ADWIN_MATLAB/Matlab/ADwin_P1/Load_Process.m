function y = Load_Process(Filename)
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
%    You generate binary files in ADbasic with "Make > Make Bin file".
%    If you switch off your ADwin system all processes are deleted: Load the
%    necessary processes again after power-up.
%    You can load up to 10 processes to an ADwin system. Running processes are
%    not influenced by loading additional processes (with different process
%    numbers).
%
%  Example:
%    % Load binary file Testprog.T91
%    % T91 = Processor type T9, process no. 1
%    Load_Process('C:\MyADbasic\Testprog.T91')
%
%  See also START_PROCESS, STOP_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(310, Filename);



