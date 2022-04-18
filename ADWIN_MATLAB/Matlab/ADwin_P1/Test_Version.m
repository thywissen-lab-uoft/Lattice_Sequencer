function y = Test_Version()
%Test_Version  checks, if the correct operating system for the processor has
%  been loaded and if the processor can be accessed.
%
%  Syntax:  Test_Version ()
%
%  Parameters:
%    Return value    0: OK
%                    <>0: Error
%
%  Example:
%    % Test, if the processor system is loaded
%    ret_val = Test_Version()
%
%  See also  GET_LAST_ERROR, GET_LAST_ERROR_TEXT
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $


y=ADlab(301);



