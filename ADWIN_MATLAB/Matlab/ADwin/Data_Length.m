%Data_Length  returns the length of an ADbasic array of data type LONG, FLOAT,
%  FLOAT32, or FLOAT64, that is the number of elements.
%
%  Syntax:  Data_Length (DataNo)
%
%  Parameters:
%    DataNo          Array number (1...200).
%    return value    >0: Declared length of the array (= number of elements)
%                    0: Error - Array is not declared.
%                    -1: Other error.
%
%  Notes:
%    To determine the length of a string in a DATA array of the type STRING you
%    use the instruction String_Length.
%
%  Example:
%    %In ADbasic, DATA_2 is dimensioned as:
%    DIM DATA_2[2000] AS LONG
%    
%    %In MATLAB, you will have the length of the array DATA_2:
%    >> Data_Length(2)
%    ans =
%        2000
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
