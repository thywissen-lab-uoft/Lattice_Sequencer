%SetData_Double  transfers data from a row vector of data type double into a
%  DATA array of the ADwin system.
%
%  Syntax:  SetData_Double (DataNo, Vector, Startindex)
%
%  Parameters:
%    DataNo          Number (1...200) of destination array DATA_1 ...DATA_200.
%                    DATA may have data type Long, Float, Float32, or Float64.
%    Vector          Row vector, from which data are transferred.
%    StartIndex      Number (>=1) of the first element in the destination array,
%                    into which data is transferred.
%    Return value    <>255: OK
%                    255: Error or array is not declared.
%
%  Notes:
%    The Data array must be greater than the number of values in the MATLAB
%    vector plus Startindex.
%    If the data type of the DATA array has 32-bit precision, the 64-bit double
%    values from Vector are converted, which causes a loss of decimal places.
%    Until T11, please note: float values in the ADwin system have 32-bit
%    precision. You should therefore display data of Vector only with single
%    precision to avoid misunderstandings. 
%    If MATLAB data from more dimensional matrices is to be transferred the data
%    has to be copied into a row vector first. In a column vector, the first
%    data element will be transferred only.
%    The function SetData_Double replaces the function Set_Data, which was used
%    with former driver versions.
%
%  Example:
%    %Write the complete row vector x into DATA_1, beginning at the array
%    %element DATA_1[100]:
%    SetData_Double(1,x,100);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
