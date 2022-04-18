%ADwin_Debug_Mode_On  activates the debug mode. In debug mode, all function
%  calls are logged in log files.
%
%  Syntax:  ADwin_Debug_Mode_On (Filename, Size)
%
%  Parameters:
%    Filename        Path and name of the log file. Enter the file name without
%                    extension but with the absolute path name!
%    Size            Max file size in kByte (1000 = 1 MiB). If the given size is
%                    smaller than 1000 a warning is shown.
%                    
%    Return value    0 : OK
%                    -1: File name > 255 characters (cannot be processed).
%                    -2: Debug mode already activated (no effect)
%                    -3: Access to the registry is needed, but impossible.
%                    Probably the user does not have the necessary
%                    administration rights for access or the max. size of the
%                    registry is exceeded. Please call your administrator.
%
%  Notes:
%    We recommend not using this function in your application software. Instead,
%    run the tool <C:\ADwin\Tools\Test\DebugMode.exe>, which has the same
%    function.
%    If the debug mode is active the function calls to all ADwin systems and the
%    answers are logged. The log may be useful for error handling (please
%    contact the support division of Jaeger Computergesteuerte Messtechnik
%    GmbH).
%    If the size of the log file exceeds Size, additional files will be
%    generated. The file extension is a consecutive number (001...nnn), which is
%    automatically generated.
%    Please note:
%    - Set the file size to at least 1000 kByte.
%    - Deactive the debug mode with ADwin_Debug_Mode_Off, when you don't need it
%      any more.
%    Otherwise, you will get a lot of log files, which slows down file
%    management under Windows.
%
%  Example:
%    ADwin_Debug_Mode_On('C:\temp\log', 1000)
%    %In the <C:\temp> directory log files with the name <log.nnn> are
%    %generated.
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
