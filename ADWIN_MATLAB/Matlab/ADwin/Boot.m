%Boot  initializes the ADwin system and loads the file of the operating system.
%
%  Syntax:  Boot (Filename, MemSize)
%
%  Parameters:
%    Filename        Path and filename of the operating system file (see below).
%    MemSize         For processors up from T9: 0 (zero).
%                    For T2, T4, T5, T8: Memory size to be used; the following
%                    values are permitted:
%                       10000:     64 KiB
%                      100000:     1 MiB
%                      200000:     2 MiB
%                      400000:     4 MiB
%                      800000:     8 MiB
%                     1000000:    16 MiB
%                     2000000:    32 MiB
%    Return value    Status:
%                    <1000: Error during boot process
%                     8000: Boot process o.k.; up from processor T9.
%                    >8000: Boot process o.k.; for T2...T8 only. The value is
%                    the size of physically installed memory.
%
%  Notes:
%    The initialization deletes all processes on the system and sets all global
%    variables to 0.
%    The operating system file to be loaded depends on the processor type of the
%    system you want to communicate with. The following table shows the file
%    names for the different processors. The files are located in the directory
%    <C:\ADwin\>.
%    Processor                Operating System File
%    T225 (T2)                ADwin2.btl
%    T400 (T4)                ADwin4.btl
%    T450 (T5)                ADwin5.btl
%    T805 (T8)                ADwin8.btl
%    T9                       ADwin9.btl
%                             ADwin9s.btl Optimized operating system with
%                             smaller memory needs.
%    T10                      ADwin10.btl
%    T11                      ADwin11.btl
%    T12                      ADwin12.btl
%    T12.1                    ADwin121.btl
%    The computer will only be able to communicate with the ADwin system after
%    the operating system has been loaded. Load the operating system again after
%    each power up of the ADwin system.
%    For users of ADsim T11:
%    - As Filename you enter the Simulink model being compiled via ADsimDesk,
%      which also contains the operating system for the processor. The model
%      file is stored in the model folder in the sub-folder
%      <model>_ert_rtw/ADwin/ with the name <model>11c.btl.
%    - <model> stands for the name of the Simulink model. The notation 11c
%      refers to the processor type T11 of the ADwin hardware.
%    - Please note that ADbasic processes and a compiled Simulink model (from
%      ADsim T11) run on the ADwin hardware at the same time.
%    Loading the operating system with Boot takes about one second. As an
%    alternative you can also load the operating system via ADbasic or ADsimDesk
%    development environment.
%
%  Example:
%    % Load the operating system for the T10 processor
%    ret_val = Boot ('C:\ADwin\ADwin10.btl', 0);
%    
%    % Load a Simulink model being compiled with ADsim T11
%    path = 'C:\ADwin\ADsim\Developer\Examples\';
%    subpath = 'ADsim32_DLL_Example_ert_rtw\ADwin\';
%    Boot([path,subpath,'ADsim32_DLL_Example11c.btl'], 0);
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
