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
%    This function cannot be used in connection with ADsim T11.
%    If the string in the DATA array contains a termination char, the transfer
%    stops exactly there, that is the termination char will not be transferred.
%    If MaxCount is greater than the number of string chars defined in ADbasic,
%    you will receive the error "Data too small" via Get_Last_Error().
%    If you set MaxCount to a high value, the function will have an
%    appropriately long execution time, even if the transferred string is
%    short.For time-critical applications with large strings, it may be faster
%    to proceed as follows:
%    - You determine the actual number of chars in the string using
%      String_Length().
%    - You read the string with Getdata_String() and pass the actual number of
%      chars as MaxCount.
%
%  Example:
%    %Get a string of max. 100 characters from DATA_2:
%    string = GetData_String(2,100);
%    %If the DATA array in the ADwin system has the termination char at position
%    %9, then 8 characters are read.
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
