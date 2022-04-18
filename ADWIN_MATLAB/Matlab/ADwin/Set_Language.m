%Set_Language  sets the language for the error messages.
%
%  Syntax:  Set_Language (language)
%
%  Parameters:
%    language        Languages for error messages:
%                    0: Language set in Windows
%                    1: English
%                    2: German
%    Return value    0
%
%  Notes:
%    The instruction changes the language setting for the error messages of the
%    interface adwin32.dll / adwin64.dll and for the function
%    Get_Last_Error_Text.
%    If a different language than English and German is set under Windows, the
%    error messages are displayed in English.
%
%  Example:
%    % set english language for error messages
%    Set_Language(1);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
