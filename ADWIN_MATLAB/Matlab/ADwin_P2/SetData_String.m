%SetData_String  transfers a string into DATA array.
%
%  Syntax:  SetData_String (DataNo, String)
%
%  Parameters:
%    DataNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    String          String variable or text in quotes which is to be
%                    transferred.
%    Return value    <>-1: OK
%                    -1: Error
%
%  Notes:
%    SetData_String appends the termination char (ASCII character 0) to each
%    transferred string.
%
%  Example:
%    SetData_String(2,'Hello World')
%    %The string "Hello World" is written into the array DATA_2 and the
%    %termination char is added.
%
%  See also  STRING_LENGTH, GETDATA_STRING, GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $