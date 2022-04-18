%Get_Last_Error  returns the number of the error that occurred last in the
%  interface adwin32.dll / adwin64.dll.
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
%    number of the error that occurred last.
%
%  Example:
%    % Reading the previous error number
%    Error = Get_Last_Error();
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
