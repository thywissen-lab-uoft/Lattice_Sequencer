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
%  See also SET_DEVICENO, GET_DEVICENO, GET_LAST_ERROR, GET_LAST_ERROR_TEXT.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $