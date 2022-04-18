function  v=Free_Mem(varargin)
%Free_Mem  returns the free memory of the system for the different memory types.
%
%  Syntax:  Free_Mem (Mem_Spec)
%
%  Parameters:
%    Mem_Spec        Memory type:
%                    0 : all memory types; T2, T4, T5, T8 only
%                    1 : internal program memory (PM_LOCAL); up from T9
%                    3 : internal data memory (DM_LOCAL); up from T9
%                    4 : external DRAM memory (DRAM_EXTERN); up from T9
%    Return value    <>255: Usable free memory (in bytes)
%                    255: Error
%
%  Example:
%    % Query the free memory in the external DRAM
%    ret_val = Free_Mem (4);
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

numargs = length(varargin);
if numargs == 0
    v=ADlab(253);               %Free_Mem for T2, T4, T5, T8
else
    Mem_Spec = varargin{1}(1);
    if Mem_Spec == 0
        v=ADlab(253);           %Free_Mem for T2, T4, T5, T8
    else
        v=ADlab(256, Mem_Spec); %Free_Mem for T9, T10, T11
    end
end


