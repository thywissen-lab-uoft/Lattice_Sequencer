function y = Set_Globaldelay(ProcessNo, Globaldelay)
%Set_Globaldelay  is obsolete, use Set_Processdelay instead.
%  Set_Globaldelay sets the parameter Globaldelay for a process
%
%  Syntax:  Set_Globaldelay(ProcessNo, Globaldelay)
%
%  Parameters:
%    ProcessNo       Process number (1...10).
%    Processdelay   Value (1...231-1) to be set for the parameter Globaldelay
%                    of the process (see table below).
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    The parameter Globaldelay controls the time interval between two events
%    of a time-controlled process (see manual ADbasic or online help). The
%    parameter Globaldelay replaces the former parameter Globaldelay.
%    For each process there is a minimum time interval: If you fall below the
%    minimum time interval you will get an overload of the ADwin processor and
%    communication will fail.
%    The time interval is specified in a time unit that depends on processor
%    type and process priority:
%    Processor type          Process priority
%                            high                     low
%    T2, T4, T5, T8          1 000 ns                 64 탎
%    T9                      25 ns                    100 탎
%    T10                     25 ns                    50 탎
%    T11                     3.3 ns                   0.003 탎 = 3.3 ns
%
%  Example:
%    % Set Globaldelay 2000 of process 1
%    ret_val = Set_Globaldelay(1,2000);
%    %If process 1 is time-controlled, has high priority and runs on a T9
%    %processor, process cycles are called every 50  탎 (=2 000 * 25 ns).
%
%  See also PROCESS_STATUS, SET_PROCESSDELAY, GET_PROCESSDELAY.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(34, 910+ProcessNo, Globaldelay);