%GetData_Double  transfers parts of a DATA array from an ADwin system into a
%  row vector.
%
%  Syntax:  GetData_Double (DataNo, Startindex, Count)
%
%  Parameters:
%    DataNo          Number (1...200) of the source array DATA_1 ...DATA_200.
%    StartIndex      Number (>=1) of the first element in the source array to
%                    be transferred.
%    Count           Number (>=1) of the LONG data to be transferred.
%    Return value    Row vector with transferred values
%
%  Notes:
%    Even though an ADbasic array may be dimensioned 2-dimensional, the return
%    value is always a row vector. If needed, the vector may be transformed
%    into a matrix in MATLAB, e. g. using reshape.
%    There is more information about 2-dimensional arrays in chapter 4.4 on
%    page 7.
%    The function GetData_Double replaces the function Get_Data which was used
%    with former driver versions.
%
%  Example:
%    %Transfer 1 000 values from DATA_1 starting from index 100 into line
%    %vector x:
%    x=GetData_Double(1, 100, 1000)
%
%  See also  SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $