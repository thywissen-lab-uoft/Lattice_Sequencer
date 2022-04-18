function  v = Workload(varargin)
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

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $


numargs = length(varargin);
if numargs == 0
    v=ADlab(254);               % Workload obsolete
else
    Mem_Spec = varargin{1}(1);
    if Mem_Spec == 0
        v=ADlab(257, Mem_Spec); % Workload actual
    else
        v=ADlab(257, Mem_Spec); % Workload for future
    end
end



