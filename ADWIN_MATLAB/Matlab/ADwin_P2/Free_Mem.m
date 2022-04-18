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

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $