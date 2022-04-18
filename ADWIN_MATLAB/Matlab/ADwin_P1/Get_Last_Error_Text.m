function y = Get_Last_Error_Text(Last_Error)
%Get_Last_Error_Text  returns the error text to a given error number.
%
%  Syntax:  Get_Last_Error_Text (Last_Error)
%
%  Parameters:
%    Last_Error      Error number
%    Return value    Error text
%
%  Notes:
%    Usually, the return value of the function Get_Last_Error is used as error
%    number Last_Error.
%
%  Example:
%    errnum = Get_Last_Error();
%    if errnum!=0
%     pErrText = Get_Last_Error_Text(errnum);
%    end
%
%  See also  GET_LAST_ERROR, TEST_VERSION
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(401, Last_Error);



