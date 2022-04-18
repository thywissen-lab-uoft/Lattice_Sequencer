/*************************************************************
* Include File zum einbinden der Aufrufe an 
* die ADwin-Systeme.
*	Erstellt am : 14.09.2005 von Marcus Sanna
*
* V1.1
*	geändert am : 30.01.2008 von MS
*		Die Prototypen in der adwin32.dll sind "FAR PASCAL", dies entspricht einem "__stdcall"!
*		Diese "__stdcall" waren nicht in dieser H-Datei, somit wurde dadurch automatisch "__cdecl" benutzt, was nicht korrekt war!
*		In der R2008a führte dies mit den alten Prototypen in ADwin_Proto.m zu einer Segmentation violation!
*		Datentyp von fGet_Par geändert: double->float (in Absprache mit MG)
*
* V1.2
*	geändert am : 22.02.2008 von MS
* 		Beim Laden der adwin32.dll gab es Warnings durch nicht verwendete Funktionen z.B. "Type 'BOOL' was not found.  Defaulting to type error. " usw. 
*   	Deshalb BOOL Funktionen und Structe entfernt , die nicht genutzt wurden!
*
**************************************************************/

#ifndef __adwin_h__
#define __adwin_h__

#ifdef __cplusplus
extern "C" {
#endif  /* __cplusplus */




short __stdcall ISERVER(   char *dateiname,short Linkaddresse,long iboardsize);
long __stdcall NEUISERVER(char *dateiname,short Linkaddresse,long iboardsize);

short __stdcall Starte(char *dateiname,short Linkaddresse);

short __stdcall Test_Version(short Linkaddresse);
short __stdcall ProzessorTyp(short Linkaddresse);
short __stdcall lAuslastung (short Linkaddresse);
long __stdcall   lMemory     (short Linkaddresse);

unsigned short __stdcall ADC        (short nadc, short nadr);
short __stdcall Set_DAC    (short ndac, short iw, short nadr);
short __stdcall Set_Digout (short iw, short nadr);
long __stdcall   Get_Digout (short nadr);
long __stdcall   Get_Digin  (short nadr);
short __stdcall Set_DigoutX(short iw, short nadr);
long __stdcall   Get_DigoutX(short nadr);
long __stdcall   Get_DiginX (short nadr);

short __stdcall Start   (short np, short nadr);
short __stdcall Stop    (short np, short nadr);
short __stdcall Set_Par (short np, long iw, short nadr);
short __stdcall fSet_Par(short np, float fw, short nadr);
long __stdcall Get_Par (short np, short nadr);
float __stdcall fGet_Par(short np,short nadr);

short __stdcall Get_List (void *tarr,short typ, short nadc, short proc,long il, short nadr);
short __stdcall Set_List (void *tarr,short typ,short ndac, long il, short nadr );

long __stdcall GetDataLength(short nr,short nadr);
short __stdcall Get_Data (void *tarr,short typ, short nadc, long lstart, long il ,short nadr);
short __stdcall Set_Data (void *tarr,short typ, short nadc, long lstart,long il ,short nadr);

long __stdcall Get_Fifo_Count (short nadc, short nadr );
long __stdcall Get_Fifo_Empty (short nadc, short nadr );
short __stdcall Clear_Fifo     (short nadc, short nadr );
short __stdcall Get_Fifo (void *tarr,short typ, short nadc, long il ,short nadr);
short __stdcall Set_Fifo (void *tarr,short typ, short nadc, long il ,short nadr);  

long __stdcall ADoszi_Get_Messung(short *wert,short adc,short mode,long anzahl,short nadr);


short __stdcall AD_Net_Connect(const char * pszProtocolSequence,
						 const char * pszNetworkAddress,
						 const char * pszEndpoint,const char * pszpassword,short msgbox);

short __stdcall AD_Net_Disconnect();



long __stdcall  ADboot(const char *dateiname,short Linkaddresse,long iboardsize,short msgbox);
short __stdcall ADBload(const char *dateiname,short Linkaddresse,short msgbox);
short __stdcall ADTest_Version(short Linkaddresse,short msgbox);
short __stdcall ADProzessorTyp(short Linkaddresse);
void __stdcall AD_Set_Timeout(long zeit);
long __stdcall  AD_Get_Timeoutcount (short reset);

// Eingefügt am 21.05.1997
short __stdcall AD_Auslastung (short Linkaddresse);
long __stdcall  AD_Memory (short Linkaddresse);

long __stdcall  AD_Memory_all (short typ,short Linkaddresse);

short __stdcall Get_Data_fast (void *tarr,short typ, short nadc, long lstart, long il ,short nadr);
short __stdcall SaveFast(char *dateiname,short Datanr,long startindex,long anzahldaten,short anhaengen,short linkaddresse);
short __stdcall SaveFast_fast(char *dateiname,short Datanr,long startindex,long anzahldaten,short anhaengen,short linkaddresse);

short __stdcall Get_ADBPar_All (short np,short anzahl,long *pData, short nadr);
short __stdcall Get_ADBFPar_All (short np,short anzahl,float *pData,short nadr);
long __stdcall  Clear_Process(short proc_nr , short nadr);

long __stdcall  AD_Version();
long __stdcall  ADGetErrorCode();
long __stdcall  ADGetErrorText(long errorcode, char *text, long textlaenge);


short __stdcall ADB_Start (short np, short nadr);
short __stdcall ADB_Stop (short np, short nadr);

// Eingefügt am 11.09.2001 wegen MatLab
short __stdcall Get_Data_packed(void *tarr, short typ, short nadc, long lstart, long il ,short nadr);

//Eingefügt für pfiles am 12.9.2005
int __stdcall    adwin_debug_mode_on(const char *Filename, long Size);
int __stdcall    adwin_debug_mode_off(void);
long __stdcall   Get_Data_String(char *Data, long MaxCount, short DataNo, short Device_No);
long __stdcall   Get_Data_String_Length(short DataNo, short Device_No);
long __stdcall   AD_Memory_all_byte(short Mem_Spec,short Device_No);
long __stdcall   Set_Data_String(char *Data,short DataNo, short Device_No);
short __stdcall GetDataTyp(short datanr,short nadr);
long __stdcall   ADSetLanguage(long language);

#ifdef __cplusplus
}
#endif 	

#endif //__adwin_h__
