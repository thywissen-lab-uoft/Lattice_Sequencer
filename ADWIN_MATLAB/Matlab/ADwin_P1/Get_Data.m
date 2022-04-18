function  v=Get_Data(DataNo, Startindex, Count)
%Get_Data  is obsolete, use GetData_Double instead.
%  Get_Data transfers parts of a DATA array from an ADwin system into a row vector.
%
%  Syntax:  Get_Data(DataNo, Startindex, Count)
%
%  Parameters:
%    DataNo          Number (1...200) of the source array DATA_1 ...DATA_200.
%    StartIndex      Number (>=1) of the first element in the source array to
%                    be transferred.
%    Count           Number (>=1) of the LONG data to be transferred.
%    Return value    row vector with transferred values
%
%  Notes:
%    Even though an ADbasic array may be dimensioned 2-dimensional, the return
%    value is always a row vector. If needed, the vector may be transformed
%    into a matrix in MATLAB, e. g. using reshape.
%    There is more information about 2-dimensional arrays in chapter 4.4 on
%    page 7.
%
%  Example:
%    %Transfer 1 000 values from DATA_1 starting from index 100 into line
%    %vector x:
%    x=Get_Data(1, 100, 1000)
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

v=ADlab(106, DataNo, Count, Startindex);
