function y = Processor_Type()
%Processor_Type  returns the processor type of the system.
%
%  Syntax:  Processor_Type ()
%
%  Parameters:
%    Return value    Parameter for the processor type of the system.
%                    0: Error                     8: T8
%                                                 9: T9
%                                                 1010:  T10
%
%  Example:
%    % Query the processor type
%    ret_val = Processor_Type ()
%
%  See also
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(54);



