%Clear_Process  deletes a process from memory.
%
%  Syntax:  Clear_Process (ProcessNo)
%
%  Parameters:
%    ProcessNo       Process number (1...10, 15).
%    Return value    <>1: OK
%                    1: Error
%
%  Notes:
%    Loaded processes need memory space in the system. With Clear_Process you
%    can delete processes from the program memory to get more space for other
%    processes.
%    If you want to delete a process, proceed as follows:
%    - Stop the running process with Stop_Process. A running process cannot be
%      deleted.
%    - Check with Process_Status, if the process has really stopped.
%    - Delete the process from the memory with Clear_Process.
%    Process 15 in Gold and Pro systems is responsible for flashing the LED;
%    after deleting this process the LED does not flash any more.
%
%  Example:
%    % Delete process 2 from memory.
%    % Declared DATA and FIFO arrays remain.
%    ret_val = Clear_Process(2);
%
%  See also  START_PROCESS, STOP_PROCESS, LOAD_PROCESS.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $