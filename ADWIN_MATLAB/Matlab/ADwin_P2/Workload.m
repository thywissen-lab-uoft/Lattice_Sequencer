%Workload  returns the average processor workload since the last call of
%  Workload.
%
%  Syntax:  Workload (Priority)
%
%  Parameters:
%    Priority        0: Current total workload of the processor.
%                    <>0: is not supported at the moment
%    Return value    <>255: Processor workload (in percent)
%                    255: Error
%
%  Notes:
%    The processor workload is evaluated for the period between the last and
%    the current call of Workload. If you need the current processor workload,
%    you must call the function twice and in a short time interval (approx. 1
%    ms).
%
%  Example:
%    % Query the processor workload
%    ret_val = Workload (0)
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $