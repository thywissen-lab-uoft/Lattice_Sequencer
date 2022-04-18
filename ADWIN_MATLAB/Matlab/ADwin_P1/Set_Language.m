function y = Set_Language(language)
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
%    adwin32.dll and for the function Get_Last_Error_Text.
%    If a different language than English and German is set under Windows, the
%    error messages are displayed in English.
%
%  Example:
%    % set english language for error messages
%    Set_Language(1);
%
%  See also
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(53, language);



