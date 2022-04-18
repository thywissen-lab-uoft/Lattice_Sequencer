function y = Boot(Filename, Memsize)
%Boot  initializes the ADwin system and loads the file of the operating system.
%
%  Syntax:  Boot (Filename, MemSize)
%
%  Parameters:
%    Filename        Path and filename of the operating system file (see below).
%    MemSize         For ADSP processors: 0 (zero).
%                    For T2, T4, T5, T8: Memory size to be used; the following
%                    values are permitted:
%                      10000:     64 kB
%                     100000:      1 MB
%                     200000:      2 MB
%                     400000:      4 MB
%                     800000:      8 MB
%                    1000000:     16 MB
%                    2000000:     32 MB
%    Return value    Status:
%                    <1000: Error during boot process
%                     8000: Boot process o.k.; up from processor T9.
%                    >8000: Boot process o.k.; for T2...T8 only. The value is
%                           the size of physically installed memory.
%
%  Notes:
%    The initialization deletes all processes on the system and sets all global
%    variables to 0.
%    The operating system file to be loaded depends on the processor type of
%    the system you want to communicate with. The following table shows the
%    file names for the different processors. The files are located in the
%    directory <C:\ADwin\>.
%    ADwin-Type         Processor         Operating System File
%    ADwin-2            T225              ADwin2.btl
%    ADwin-4            T400              ADwin4.btl
%    ADwin-5            T450              ADwin5.btl
%    ADwin-8            T805              ADwin8.btl
%    ADwin-9            T9                ADwin9.btl
%    ADwin9s.btl1
%    ADwin-10           T10               ADwin10.btl
%    The computer will only be able to communicate with the ADwin system after
%    the operating system has been loaded. Load the operating system again after
%    each power up of the ADwin system.
%    Loading the operating system with Boot takes about one second. As an
%    alternative you can also load the operating system via ADbasic development
%    environment. (icon B).
%
%  Example
%    % Load the operating system for the T10 processor
%    ret_val = Boot ('C:\ADwin\ADwin10.btl', 0);
%
%  See also START_PROCESS, STOP_PROCESS, LOAD_PROCESS, SET_DEVICENO, GET_DEVICENO, FREE_MEM, WORKLOAD.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(300, Filename, Memsize);
