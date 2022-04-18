%GetData_String  transfers a string from a DATA array into a string variable.
%
%  Syntax:  GetData_String (DataNo, MaxCount)
%
%  Parameters:
%    DataNo          Number (1...200) of the array DATA_1 ... DATA_200.
%    MaxCount        Max. number (>=1) of the transferred characters without
%                    termination char.
%    Return value    String variable with the transferred chars.
%
%  Notes:
%    If the string in the DATA array contains a termination char, the transfer
%    stops exactly there, that is the termination char will not be transferred.
%
%  Example:
%    %Get a string of max. 100 characters from DATA_2:
%    GetData_String(2,100);
%    %If the DATA array in the ADwin system has the termination char at
%    %position 9, then 8 characters are read.
%
%  See also  STRING_LENGTH, SETDATA_STRING, GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $