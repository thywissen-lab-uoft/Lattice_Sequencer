function y = Set_Processdelay(ProcessNo, Processdelay)
%Set_Processdelay  sets the parameter Processdelay for a process
%
%  Syntax:  Set_Processdelay (ProcessNo, Processdelay)
%
%  Parameters:
%    ProcessNo       Process number (1...10).
%    Processdelay    Value (1...231-1) to be set for the parameter Processdelay
%                    of the process (see table below).
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    The parameter Processdelay controls the time interval between two events
%    of a time-controlled process (see manual ADbasic or online help). The
%    parameter Processdelay replaces the former parameter Globaldelay.
%    For each process there is a minimum time interval: If you fall below the
%    minimum time interval you will get an overload of the ADwin processor and
%    communication will fail.
%    The time interval is specified in a time unit that depends on processor
%    type and process priority:
%    Processor type          Process priority
%                            high                     low
%    T2, T4, T5, T8          1 000 ns                 64 �s
%    T9                      25 ns                    100 �s
%    T10                     25 ns                    50 �s
%
%  Example
%    % Set Processdelay 2000 of process 1
%    ret_val = Set_Processdelay(1,2000);
%    % If process 1 is time-controlled, has high priority and runs on a T9 processor,
%    % process cycles are called every 50 �s (=2000 * 25 ns).

%
%  See also PROCESS_STATUS, GET_PROCESSDELAY.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(34, 910+ProcessNo, Processdelay);

