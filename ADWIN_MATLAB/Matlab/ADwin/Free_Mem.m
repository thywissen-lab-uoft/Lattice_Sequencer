%Free_Mem  returns the free memory of the system for the different memory types.
%
%  Syntax:  Free_Mem (Mem_Spec)
%
%  Parameters:
%    Mem_Spec        Memory type:
%                    0 : all memory types; T2, T4, T5, T8 only
%                    1 : internal program memory (PM_LOCAL); T9...T11
%                    2: internal data memory (EM_LOCAL); T11 only
%                    3 : internal data memory (DM_LOCAL); T9...T11
%                    4 : external DRAM memory (DRAM_EXTERN); T9...T11
%                    5: Cacheable: Memory, which can provide data to the cache;
%                    T12/T12.1 only.
%                    6: Uncacheable: Memory, which cannot provide data to the
%                    cache; T12/T12.1 only.
%    Return value    <>255: Usable free memory (in bytes).With Mem_Spec =5/6,
%                    the value is given in units of kB.
%                    255: Error
%
%  Notes:
%    This function cannot be used in connection with ADsim T11.
%
%  Example:
%    % Query the free memory in the external DRAM
%    ret_val = Free_Mem (4);
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, BOOT, SET_DEVICENO, GET_DEVICENO, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
