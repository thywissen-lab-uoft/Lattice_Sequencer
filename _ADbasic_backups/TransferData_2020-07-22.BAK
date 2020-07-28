'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 1
' Initial_Processdelay           = 1000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 6.3.0
' Optimize                       = No
' Stacksize                      = 1000
' Info_Last_Save                 = 40K  40K\Dysprosium
'<Header End>
#include adwinpro_all.inc
dim i,j,k,lightcount,litup,eventcount,delaymultinuse as long
dim DATA_1[5000000] as long
dim DATA_2[5000000] as long
dim data_3[5000000] as long
dim data_5[5000000] as long
dim data_4[1000] as long  ' a list of which channels are reset to zero on completion
dim value as float
dim counts,maxcount,updates as long
dim ch as long
dim val,val_lower,val_upper,val_lower2,val_upper2 as long
dim tempval as long 
dim dataline,clock, ioupdate,ioreset,masterreset as long
dim dataline9858,clock9858,ioupdate9858,ioreset9858,masterreset9858 as long
dim digitallow as long
dim delay,delayinuse as long
dim numbertoskip as long
dim leddelay as float
dim digitalactive,digital2active as long


Function V(value) as float
  V=(value+10)/20*65535
ENDFUNCTION

SUB Light_LED(lit) as  
  SELECTCASE lit
    CASE 1
      P2_SET_LED(6,0)
      SETLED(1,DIO,1) 'different function for Rev B model   
    CASE 2    
      SETLED(1,DIO,0) 'different function for Rev B model
      P2_SET_LED(2,1)
    CASE 3
      P2_SET_LED(2,0)  
      P2_SET_LED(5,1)
    CASE 4
      P2_SET_LED(5,0)
      P2_SET_LED(6,1)
    CASE 5
      P2_SET_LED(6,0)
      P2_SET_LED(7,1)
    CASE 6
      P2_SET_LED(7,0)
      P2_SET_LED(8,1)
    CASE 7
      P2_SET_LED(8,0)

  ENDSELECT
ENDSUB



INIT:

  'Jan 16/2004
  'expecting 3 arrays.
  'Data_1:  A list which specifies how many channels will be updated per event
  'Data_2:  A list of channels to be updates
  'Data_3:  A list of values for the channels

  'Data_2 and Data_3 have a 1:1 correspondence.  
  'Stepping through data2 and 3 is controlled by Data 1
  'Computer send an integer to Par_1.  This tells us how many
  'events to write. )
  'Channels 1-16 refer to Analog output lines
  'Channel 101,102 refers to Digital output lines (16 bit word x2)
  'Channel 103,104 refer to Digital output lines (16 bit word X2)

  delay=PAR_2 ' 40000=>1ms (Enable cyclic update to see PAR values (clock icon))
  GlobalDelay=delay


  'Set Card 1 to output (card 1 is older - rev B - so different syntax)
  'This is given in hexadecimal notation This is the conversion
  'to binary (0FFh = 11111111b). Only the first and 8th bit are used for Rev B.
  'the rest are ignored. (bit = 1 is output, bit = 0 is input)
  DIGPROG1(1,0FFh) 
  DIGPROG2(1,0FFh) 

  'P2_DIGPROG(1,011111111111111111111111111111111b) <--- old
  'Can only set channels to input or output in groups of 8. For 32 channels
  'only 4 bits are required. 1111b sets them all to output.
  P2_DIGPROG(2,1111b)
  P2_DIGPROG(3,1111b)

  'Configure cards for synchronous output
  'P2_SYNC_ENABLE(1,011111111111111111111111111111111b) <--- old
  'This is for the digital channels
  SYNCENABLE(1,DIO,1) 'card 1 syntax (Rev B)
  P2_SYNC_ENABLE(2,1b) 'For Rev E digital channels, only one bit is required
  P2_SYNC_ENABLE(3,1b) 'For Rev E digital channels, only one bit is required
  'P2_SYNC_ENABLE enables or disbles the synchronizing option for selected inputs, outputs or function groups on the specified module
  'Syntax: P2_SYNC_ENABLE(module, channel) 
  
  'This is for analog channels
  P2_SYNC_ENABLE(5,0FFh)
  P2_SYNC_ENABLE(6,0FFh)
  P2_SYNC_ENABLE(7,0FFh)
  P2_SYNC_ENABLE(8,0FFh)
  P2_SYNC_ENABLE(9,0FFh)
  P2_SYNC_ENABLE(10,0FFh)
  P2_SYNC_ENABLE(11,0FFh)
  P2_SYNC_ENABLE(12,0FFh)

  numbertoskip=0
  counts=1
  maxcount=Par_1
  updates=1
  lightcount=0
  eventcount=0
  litup=0
  leddelay=8000000/GLOBALDELAY
  Par_11=Data_1[1]
  Par_12=Data_1[2]
  Par_13=Data_1[3]
  FPar_11=Data_2[1]
  FPar_12=Data_2[2]
  FPar_13=Data_2[3]



EVENT:

  SYNCALL() 'card 1 syntax (Rev B)
  P2_SYNC_ALL(111111110110b)    'Force synchronized output now.  We are sending out the data programmed in the last cycle.
  ' THis way all the outputs are updated at the beginning of an event, which is well timed.
  ' Doing Syncall() at the end of an event causes the channel outputs to move around in time, depending on how many channels
  ' are being programmed. (There is no module 4 so set bit 3 to zero and module 1 is 
  'a Rev B module so ignore it in P2_SYNC_ALL by setting bit 0 to 0. The highest
  'module address we have is 12, so we only need 12 bits. This may be wrong.

  eventcount=eventcount+delaymultinuse
  if(eventcount>leddelay) then
    eventcount=0      
    if(litup=7) then 
      litup=0
    endif
    litup=litup+1
    Light_LED(litup)    
  endif

  delayinuse=delay   ' reset the GlobalDelay
  if(Data_1[counts]<0) then    ' if we see a negative number, interpret it as a multiplicative factor on the delay
    delayinuse=delay*(-1*Data_1[counts])
    delaymultinuse=-1*Data_1[counts]
  endif
  GLOBALDELAY=delayinuse


  ' reset the variables controlling digital output.
  digitalactive=0
  digital2active=0
  val_lower=0
  val_upper=0
  val_lower2=0
  val_upper2=0
  counts=counts+1  'Number of events so far


  IF((99>DATA_1[counts]) and (DATA_1[counts]>=1)) then  'A:Check each elementof DATA_1 for an update
    For i=1 to Data_1[counts] 'B: Loop over number of updates at this time
      updates=updates+1
      ch=Data_2[updates]
    
      if(litup=7) then 
        litup=0
      endif
      litup=litup+1
      Light_LED(litup)  
    
      '*****************Analog outs***********************      
      if((ch>=1) and (ch<=64)) then
        AnalogWrite(ch,Data_3[updates])
      endif

      '***********************Digital outs**********
      'Use 4 channels to resolve a data type issue
      if(ch=101) then
        P2_DIG_WRITE_LATCH(2,Data_3[updates]) 'Writes Digital Channels 1-32
      endif
      
      if(ch=104) then
        val_lower=Data_3[updates]+10000000000000000000000000000000b
        P2_DIG_WRITE_LATCH(2,val_lower) 'Writes Digital Channels 1-32
      endif
      
      if(ch=102) then
        DIG_WRITELATCH32(1,Data_3[updates]) 'Writes Digital Channels 33-64 (card 1 syntax)
        'DIGOUT_WORD1(1,1)
      endif
      
      if(ch=105) then
        val_upper=Data_3[updates]+10000000000000000000000000000000b
        DIG_WRITELATCH32(1,val_upper) 'Writes Digital Channels 33-64 (card 1 syntax)
        'DIGOUT_WORD1(1,1)
      endif
      
      if(ch=103) then
        P2_DIG_WRITE_LATCH(3,Data_3[updates]) 'Writes Digital Channels 65-96
      endif
      
      if(ch=106) then
        val_lower=Data_3[updates]+10000000000000000000000000000000b
        P2_DIG_WRITE_LATCH(3,val_lower) 'Writes Digital Channels 65-96
      endif
      
            
    NEXT i            'B for loop  
  ENDIF        'A:
  If(counts>=maxcount+1) then end


FINISH:
  'Clear all channels
  Par_3=counts
  Par_4=maxcount

  'If (Data_4[27]=0) then
  '  For i= 1 to 8
  '    if(Data_4[i]=1) then
  '      P2_WRITE_DAC(5,i,V(0))   
  '    ENDIF
  '    if(Data_4[i+8]=1) then
  '      P2_WRITE_DAC(6,i,V(0))   
  '    ENDIF
  '  Next i
  For i= 1 to 64
    if(Data_4[i]=1) then
      AnalogWrite(i, 0)
    ENDIF
  Next i
  'set line 28 high... forget why...
  '  P2_DIG_WRITE_LATCH(1,2^28)
  'ENDIF

  
  if(Data_4[65]=1) then
    P2_DIG_WRITE_LATCH(2,0)
  ENDIF
  
  'P2_DIG_WRITE_LATCH transfers digital information from inputs to input latches and from output latches to ouputs on the specified module
 
  
  if(Data_4[66]=1) then
    DIG_WRITELATCH32(1,0) 'card 1 syntax
  ENDIF
   
  
  if(Data_4[67]=1) then
    P2_DIG_WRITE_LATCH(3,0)
  ENDIF

  P2_SYNC_ALL(111111110110b)
  SYNCALL() 'card 1 syntax

  '***************************************************
SUB AnalogWrite(achannel, avalue) 
  if((achannel>=1)and(achannel<=8)) then
    P2_WRITE_DAC(5,achannel,avalue)       
  endif
  'P2_WRITE_DAC writes a digital value into the output register of DAC on the specified module
  'Syntax:  P2_WRITE_DAC(module,dac_no,value)    
  if((achannel>=9)and(achannel<=16)) then
    P2_WRITE_DAC(6,achannel-8,avalue)
  endif

  if((achannel>=17)and(achannel<=24)) then
    P2_WRITE_DAC(7,achannel-16,avalue)
  endif

  if((achannel>=25)and(achannel<=32)) then
    P2_WRITE_DAC(8,achannel-24,avalue)
  endif
  
  if((achannel>=33)and(achannel<=40)) then
    P2_WRITE_DAC(9,achannel-32,avalue)
  endif
  
  if((achannel>=41)and(achannel<=48)) then
    P2_WRITE_DAC(10,achannel-40,avalue)
  endif
  
  if((achannel>=49)and(achannel<=56)) then
    P2_WRITE_DAC(11,achannel-48,avalue)
  endif
  
  if((achannel>=57)and(achannel<=64)) then
    P2_WRITE_DAC(12,achannel-56,avalue)
  endif
ENDSUB
