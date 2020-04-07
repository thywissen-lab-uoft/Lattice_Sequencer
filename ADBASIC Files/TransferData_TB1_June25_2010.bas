'<ADbasic Header, Headerversion 001.001>
' Process_Number                 = 1
' Initial_Processdelay           = 1000
' Eventsource                    = Timer
' Control_long_Delays_for_Stop   = No
' Priority                       = High
' Version                        = 1
' ADbasic_Version                = 5.0.5
' Optimize                       = No
' Info_Last_Save                 = LATTICECONTROL  LATTICECONTROL\Lattice
'<Header End>
#include adwinpro_all.inc
dim i,j,k,lightcount,litup,eventcount,delaymultinuse as long
dim DATA_1[5000000] as long
dim DATA_2[5000000] as long
dim data_3[5000000] as float
dim data_5[5000000] as long
dim data_4[1000] as long	' a list of which channels are reset to zero on completion
dim value as float
dim counts,maxcount,updates,i,j,k as long
dim ch as long
dim val,val_lower,val_upper,val_lower2,val_upper2 as float
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
      P2_SET_LED(1,1)		
    CASE 2		
      P2_SET_LED(1,0)
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

  delay=PAR_2 ' 40000=>1ms
  GlobalDelay=delay



  P2_DIGPROG(1,011111111111111111111111111111111b)
  P2_DIGPROG(2,011111111111111111111111111111111b)

  'Configure cards for synchronous output
  P2_SYNC_ENABLE(1,011111111111111111111111111111111b)
  P2_SYNC_ENABLE(2,011111111111111111111111111111111b)

  P2_SYNC_ENABLE(5,0FFh)
  P2_SYNC_ENABLE(6,0FFh)
  P2_SYNC_ENABLE(7,0FFh)
  P2_SYNC_ENABLE(8,0FFh)

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

  P2_SYNC_ALL(0FFFFFFFFh)    'Force synchronized output now.  We are sending out the data programmed in the last cycle.
  ' THis way all the outputs are updated at the beginning of an event, which is well timed.
  ' Doing Syncall() at the end of an event causes the channel outputs to move around in time, depending on how many channels
  ' are being programmed.

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
      if((ch>=1) and (ch<=32)) then
        AnalogWrite(ch,Data_3[updates])
      endif

      '***********************Digital outs**********
      if(ch=101) then
        val_lower=Data_3[updates]
        P2_DIG_WRITE_LATCH(1,val_lower) 'Writes Digital Channels 1-32
      endif
      if(ch=102) then
        val_upper=Data_3[updates]
        P2_DIG_WRITE_LATCH(2,val_upper) 'Writes Digital Channels 101-132
      endif
						
    NEXT i						'B for loop	
  ENDIF				'A:
  If(counts>=maxcount+1) then end


FINISH:
  'Clear all channels
  Par_3=counts
  Par_4=maxcount

  'If (Data_4[27]=0) then
  '	For i= 1 to 8
  '		if(Data_4[i]=1) then
  '			P2_WRITE_DAC(5,i,V(0)) 	
  '		ENDIF
  '		if(Data_4[i+8]=1) then
  '			P2_WRITE_DAC(6,i,V(0)) 	
  '		ENDIF
  '	Next i
  For i= 1 to 32
    if(Data_4[i]=1) then
      AnalogWrite(i, 0)
    ENDIF
  Next i
  'set line 28 high... forget why...
  '	P2_DIG_WRITE_LATCH(1,2^28)
  'ENDIF

  For i= 33 to 34
    if(Data_4[i]=1) then
      P2_DIG_WRITE_LATCH(i-32,0)
    ENDIF
  Next i 

  P2_SYNC_ALL(0FFFFh) 

  '***************************************************
SUB AnalogWrite(achannel, avalue) 
  if((achannel>=1)and(achannel<=8)) then
    P2_WRITE_DAC(5,achannel,V(avalue))
  endif
			
  if((achannel>=9)and(achannel<=16)) then
    P2_WRITE_DAC(6,achannel-8,V(avalue))
  endif

  if((achannel>=17)and(achannel<=24)) then
    P2_WRITE_DAC(7,achannel-16,V(avalue))
  endif

  if((achannel>=25)and(achannel<=32)) then
    P2_WRITE_DAC(8,achannel-24,V(avalue))
  endif
ENDSUB
