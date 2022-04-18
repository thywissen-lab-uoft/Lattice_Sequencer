%Show_Errors  enables or disables the display of error messages in a message
%  box.
%
%  Syntax:  Show_Errors (OnOff)
%
%  Parameters:
%    OnOff           0: Do not show any error messages.
%                    1: Show error messages in a message box (default).
%
%  Notes:
%    The function Show_Errors refers to all functions that may display error
%    messages in a message box. These are:
%    - Boot
%    - Test_Version
%    - Load_Process
%    If message boxes are disabled with Show_Errors, the program keeps on
%    running when an error occurs. The user cannot and does not have to confirm
%    any error messages.
%
%  Example:
%    % Show error messages
%    Show_Errors(1);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
