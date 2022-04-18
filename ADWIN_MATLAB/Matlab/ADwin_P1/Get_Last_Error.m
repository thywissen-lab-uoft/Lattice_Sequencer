function y = Get_Last_Error()
%Get_Last_Error  returns the number of the error that occured last in the
%  adwin32.dll.
%
%  Syntax:  Get_Last_Error ()
%
%  Parameters:
%    return value    0: no error
%                    <>0: error number
%
%  Notes:
%    To each error number you will get the text with the function
%    Get_Last_Error_Text. You will find a list of all error messages in chapter
%    A.2 of the Appendix.
%    After the function call the error number is automatically reset to 0.
%    Even if several errors occur, Get_Last_Error only will only return the
%    number of the error that occured last.
%
%  Example:
%    % Die letzte Fehlernummer lesen
%    Error = Get_Last_Error()
%
%  See also  GET_LAST_ERROR_TEXT, TEST_VERSION
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(400);



