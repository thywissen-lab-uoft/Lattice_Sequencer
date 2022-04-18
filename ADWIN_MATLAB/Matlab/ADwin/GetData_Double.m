%GetData_Double  transfers parts of a DATA array from an ADwin system into a row
%  vector of data type double.
%
%  Syntax:  GetData_Double (DataNo, Startindex, Count)
%
%  Parameters:
%    DataNo          Number (1...200) of the source array DATA_1 ...DATA_200.
%                    DATA may have data type Long, Float, Float32, or Float64.
%    StartIndex      Number (>=1) of the first element in the source array to be
%                    transferred.
%    Count           Number (>=1) of the data to be transferred.
%    Return value    Row vector with transferred values of data type double.
%
%  Notes:
%    Until T11, please note: float values in the ADwin system have 32-bit
%    precision. You should therefore display data of the returned row vector
%    only with single precision to avoid misunderstandings.
%    Even though an ADbasic array may be dimensioned 2-dimensional, the return
%    value is always a row vector. If needed, the vector may be transformed into
%    a matrix in MATLAB, e. g. using reshape.
%    There is more information about 2-dimensional arrays in chapter 4.4 on page
%    11.
%    The function GetData_Double replaces the function Get_Data, which was used
%    with former driver versions.
%
%  Example:
%    %Transfer 1000 values from DATA_1 starting from index 100 into row vector
%    %x:
%    x = GetData_Double(1, 100, 1000);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
