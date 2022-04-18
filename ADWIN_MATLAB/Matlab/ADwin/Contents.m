% ADSIM
%
% Files
%  ADwin_Init                - initializes Matlab for communication with ADwin systems.
%  ADwin_Unload              - deletes all ADwin functions from PC memory and releases its memory space.
%  Set_DeviceNo              - sets the device number.
%  Get_DeviceNo              - returns the current device number.
%  Boot                      - initializes the ADwin system and loads the file of the operating system.
%  Test_Version              - checks, if the correct operating system for the processor has been loaded and if
%  Processor_Type            - returns the processor type of the system.
%  Workload                  - returns the average processor workload since the last call of Workload.
%  Free_Mem                  - returns the free memory of the system for the different memory types.
%  Load_Process              - loads the binary file of a process into the ADwin system.
%  Start_Process             - starts a process.
%  Stop_Process              - stops a process.
%  Clear_Process             - deletes a process from memory.
%  Process_Status            - returns the status of a process.
%  Set_Processdelay          - sets the parameter Processdelay for a process
%  Get_Processdelay          - returns the parameter Processdelay for a process.
%  Set_Par                   - sets a global variable PAR to the specified value.
%  Get_Par                   - returns the value of a global variable PAR.
%  Get_Par_Block             - transfers a specified number of consecutive global variables PAR into a row
%  Get_Par_All               - transfers all 80 global variables PAR_1... PAR_80 into a row vector (data type
%  Set_FPar                  - sets a global variable FPAR to a specified single value.
%  Set_FPar_Double           - sets a global variable FPAR to a specified double value.
%  Get_FPar                  - returns the single value of a global variable FPAR.
%  Get_FPar_Block            - transfers a specified number of consecutive global variables FPAR into a row
%  Get_FPar_All              - transfers all global variables FPAR_1...FPAR_80 into a row vector (data type
%  Get_FPar_Double           - returns the double value of a global variable FPAR.
%  Get_FPar_Block_Double     - transfers the specified number of global variables FPAR into a row vector (data
%  Get_FPar_All_Double       - transfers all global variables FPAR_1...FPAR_80 into a row vector (data type
%  Data_Length               - returns the length of an ADbasic array of data type LONG, FLOAT, FLOAT32, or
%  SetData_Double            - transfers data from a row vector of data type double into a DATA array of the
%  GetData_Double            - transfers parts of a DATA array from an ADwin system into a row vector of data
%  Data2File                 - saves data of type Long, Float/Float32, or Float64 from a DATA array of the
%  File2Data                 - copies data from a file (on the hard disk) into a DATA array of the ADwin
%  Fifo_Empty                - returns the number of empty elements in a FIFO array.
%  Fifo_Full                 - returns the number of used elements in a FIFO array.
%  Fifo_Clear                - initializes the write and read pointers of a FIFO array. Now the data in the
%  SetFifo_Double            - transfers data from a row vector into a FIFO array.
%  GetFifo_Double            - transfers FIFO data from a FIFO array to a row vector.
%  String_Length             - returns the length of a data string in a DATA array.
%  SetData_String            - transfers a string into DATA array.
%  GetData_String            - transfers a string from a DATA array into a string variable.
%  Show_Errors               - enables or disables the display of error messages in a message box.
%  Get_Last_Error            - returns the number of the error that occurred last in the interface adwin32.dll
%  Get_Last_Error_Text       - returns the error text to a given error number.
%  Set_Language              - sets the language for the error messages.
%  ADwin_Debug_Mode_On       - activates the debug mode. In debug mode, all function calls are logged in log
%  ADwin_Debug_Mode_Off      - deactivates the debug mode.
