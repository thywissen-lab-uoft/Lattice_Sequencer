%SetData_String  transfers a string into DATA array.
%
%  Syntax:  SetData_String (DataNo, String)
%
%  Parameters:
%    DataNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    String          String variable or text in quotes, which is to be
%                    transferred.
%    Return value    <>-1: OK
%                    -1: Error
%
%  Notes:
%    This function cannot be used in connection with ADsim T11.
%    SetData_String appends the termination char (ASCII character 0) to each
%    transferred string.
%
%  Example:
%    SetData_String(2,'Hello World');
%    %The string "Hello World" is written into the array DATA_2 and the
%    %termination char is added.
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
