%String_Length  returns the length of a data string in a DATA array.
%
%  Syntax:  String_Length (DataNo)
%
%  Parameters:
%    DataNo          Number (1...200) of the array DATA_1 ... DATA_200.
%    Return value    <>-1: String length = number of characters
%                    -1: Error
%
%  Notes:
%    String_Length counts the characters in a DATA array up to the termination
%    char (ASCII character 0). The termination char is not counted as character.
%
%  Example:
%    %In ADbasic DATA_2 is dimensioned as:
%    DIM DATA_2[2000] AS STRING
%    DATA_2 = "Hello World"
%    
%    %In MATLAB you will get the length of the array DATA_2:
%    >> String_Length(2)
%    ans =
%        11
%
%  See also  SETDATA_STRING, GETDATA_STRING, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $