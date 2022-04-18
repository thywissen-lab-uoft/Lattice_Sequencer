% ADwin functions
%
% Files
%   ADwin_Debug_Mode_Off - ADwin_Debug_Mode_Off  deactivates the debug mode.
%   ADwin_Debug_Mode_On  - ADwin_Debug_Mode_On  activates the debug mode. In the debug mode all function
%   Boot                 - Boot  initializes the ADwin system and loads the file of the operating system.
%   Clear_Process        - Clear_Process  deletes a process from memory.
%   Data2File            - Data2File  saves data from a DATA array of the ADwin system into a file (on
%   Data_Length          - Data_Length  returns the length of an ADbasic array, that is the number of
%   Fifo_Clear           - Fifo_Clear  initializes the write and read pointers of a FIFO array. Now the
%   Fifo_Empty           - Fifo_Empty  returns the number of empty elements in a FIFO array.
%   Fifo_Full            - Fifo_Full  returns the number of used elements of a FIFO array.
%   Free_Mem             - Free_Mem  returns the free memory of the system for the different memory types.
%   GetData_String       - GetData_String  transfers a string from a DATA array into a string variable.
%   GetData_Double       - GetData_Double  transfers parts of a DATA array from an ADwin system into a
%   GetFifo_Double       - GetFifo_Double  transfers FIFO data from a FIFO array to a row vector.
%   Get_DeviceNo         - Get_DeviceNo  returns the current device number.
%   Get_FPar             - Get_FPar  Get_Par returns the value of a global FLOAT variable.
%   Get_FPar_All         - Get_FPar_All  transfers all global float variables (FPAR_1...FPAR_80) into a
%   Get_FPar_Block       - Get_FPar_Block  transfers a number of global FLOAT variables, which is to be
%   Get_Last_Error       - Get_Last_Error  returns the number of the error that occured last in the
%   Get_Last_Error_Text  - Get_Last_Error_Text  returns the error text to a given error number.
%   Get_Par              - Get_Par  returns the value of a global LONG variable.
%   Get_Par_All          - Get_Par_All  transfers all global long variables into a row vector.
%   Get_Par_Block        - Get_Par_Block  transfers a specified number of global LONG variables into a
%   Get_Processdelay     - Get_Processdelay  returns the parameter Processdelay for a process.
%   Load_Process         - Load_Process  loads the binary file of a process into the ADwin system.
%   Process_Status       - Process_Status  returns the status of a process.
%   Processor_Type       - Processor_Type  returns the processor type of the system.
%   SetData_String       - SetData_String  transfers a string into DATA array.
%   SetData_Double       - SetData_Double  transfers data from a row vector into a DATA array of the
%   SetFifo_Double       - SetFifo_Double  transfers data from a row vector into a FIFO array.
%   Set_DeviceNo         - Set_DeviceNo  sets the device number.
%   Set_FPar             - Set_FPar  sets a global FLOAT variable to a specified value.
%   Set_Language         - Set_Language  sets the language for the error messages.
%   Set_Par              - Set_Par  sets a global LONG variable to the specified value.
%   Set_Processdelay     - Set_Processdelay  sets the parameter Processdelay for a process
%   Show_Errors          - Show_Errors  enables or disables the display of error messages in a message
%   Start_Process        - Start_Process  starts a process.
%   Stop_Process         - Stop_Process  stops a process.
%   String_Length        - String_Length  returns the length of a data string in a DATA array.
%   Test_Version         - Test_Version  checks, if the correct operating system for the processor has
%   Workload             - Workload  returns the average processor workload since the last call of

