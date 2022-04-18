function  Set_Data(DataNo, Data, Startindex)
%Set_Data  is obsolete, use SetData_Double instead.
%  Set_Data transfers data from a row vector into a DATA array of the ADwin system.
%
%  Syntax:  Set_Data(DataNo, Vector, Startindex)
%
%  Parameters:
%    DataNo          Number  (1...200) of destination array DATA_1 ...DATA_200.
%    Vector          row vector from which data are transferred.
%    StartIndex      Number (>=1) of the first element in the destination
%                    array, into which data is transferred.
%    Return value    <>255: OK
%                    255: Error or array is not declared.
%
%  Notes:
%    The Data array must be greater than the number of values in the MATLAB
%    vector plus Startindex.
%    If the DATA array is dimensioned of type LONG (integer) the transferred
%    values will be changed into this format. If existing, decimal places will
%    then be lost.
%    If MATLAB data from more dimensional matrices is to be transferred the
%    data has to be copied into a row vector first.
%    In a column vector the first data element will be transferred only.
%
%  Example:
%    %Write the complete row vector x into DATA_1, beginning at element
%    %DATA_1[100]:
%    Set_Data(1,x,100)
%
%  See also  SETDATA_DOUBLE, GETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(107, DataNo, Data, Startindex);
