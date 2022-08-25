'======================================================================='

' Title: Code Lock
' Last Updated :  02.2022
' Author : A.Hossein.Khalilian
' Program code  : BASCOM-AVR 2.0.8.5
' Hardware req. : Atmega8 + Keypad 4x3 + 16x2 Character lcd display

'======================================================================='

$regfile = "m8def.dat"
$crystal = 1000000

$hwstack = 64
$swstack = 64
$framesize = 64


Config Lcdpin = Pin , Db4 = Pinc.3 , Db5 = Pinc.2 , Db6 = Pinc.1 , Db7 = _
Pinc.0 , E = Pinc.4 , Rs = Pinc.5
Config Lcd = 16 * 2
Cls : Home : Cursor Off


Deflcdchar 0 , 32 , 4 , 12 , 31 , 12 , 4 , 32 , 32


Config Kbd = Portb


Config Pind.0 = Output                                      'Active
Config Pind.1 = Output                                      'Relay
Config Pind.2 = Input                                       'Default
Config Pind.3 = Output                                      'Speaker


Set Portd.2


Active Alias Portd.0
Relay Alias Portd.1
Default Alias Pind.2
Speaker Alias Pind.3


Dim Digits As Byte , Key As Byte , Result As Byte , Num As String * 4
Dim Pass(8) As String * 1 , Pass1(8) As String * 1 , Pass2(8) As String * 1
Dim Pass_eeprom(8) As Eram String * 1 , Rcv(8) As String * 1
Dim Temp As Byte , Sel As Byte


Declare Sub Main
Declare Sub Default_pass
Declare Sub Load2ram
Declare Sub Getpass
Declare Sub Check
Declare Sub Menu
Declare Sub Change_pass
Declare Sub Confirm
Declare Sub Check1



Declare Function Is_num(byval Num As String) As Byte


Call Main
End

'_______________________________________________________________________________


Sub Main
   Sound Speaker , 120 , 20                                 'Startup Sound
   Active = 1                                               'Red LED=1
   If Default = 0 Then Call Default_pass
   Call Load2ram
   Call Getpass
End Sub

''''''''''''''''''''''''''''''

'Set Default Password (11 11 11 11)
Sub Default_pass
   Sound Speaker , 120 , 30
   'Clear Pass
   For Temp = 1 To 8
      Pass_eeprom(temp) = "1"
      Waitms 20
   Next Temp
   Cursor Off
   Cls : Home : Lcd "Memoey Erased!"
   Lowerline : Lcd "Pass=11111111"
   Sound Speaker , 120 , 60
   Waitms 1500
End Sub

''''''''''''''''''''''''''''''

'Load Pass to SRAM
Sub Load2ram
   For Temp = 1 To 8
      Pass(temp) = Pass_eeprom(temp)
      Waitms 20
   Next Temp
End Sub

''''''''''''''''''''''''''''''

'Get Password
Sub Getpass
   Cls : Home : Lcd "Password?  Cls=" ; Chr(0)
   Home L : Cursor Blink
   Sound Speaker , 120 , 60
   Digits = 0
   Waitms 500
   Do
      Key = Getkbd()
      Num = Lookupstr(key , Decode)
      If Num = "Cls" Then Call Getpass
      If Is_num(num) = 1 Then
         Sound Speaker , 120 , 50
         Sound Speaker , 120 , 40
         Incr Digits
         Locate 2 , Digits : Lcd "*"
         Rcv(digits) = Num
         If Digits = 8 Then                                 'Pass Entered
            Call Check
            If Result <> 8 Then
               'Error Pass
               Sound Speaker , 120 , 80
               Cls : Home : Lcd "Error!"
               Cursor Noblink
               Waitms 500
               Call Getpass
            Else
               'Successful Pass
               Call Menu
            End If
         End If
         Waitms 300
      End If
   Loop
End Sub

''''''''''''''''''''''''''''''

'Check Pressed Key Is A Number(0-9)? If Yes Is-num = 1 In No Is_num=0
Function Is_num(byval Num As String) As Byte
   If Num = "0" Or Num = "1" Or Num = "2" Or Num = "3" Or Num = "4" _
    Or Num = "5" Or Num = "6" Or Num = "7" Or Num = "8" Or Num = "9" then
      Is_num = 1
   Else
      Is_num = 0
   End If
End Function

''''''''''''''''''''''''''''''

'Password Checker
Sub Check
   Result = 0
   For Temp = 1 To 8
      If Rcv(temp) = Pass(temp) Then Incr Result
   Next Temp
End Sub

''''''''''''''''''''''''''''''

'Sub Menu (Open Door Or Cahnge pass)
Sub Menu
   Cls : Home : Cursor Noblink : Lcd "1=Relay     Exit"
   Lowerline : Lcd "2=Change"
   Sound Speaker , 120 , 100
   Sound Speaker , 120 , 80
   Sound Speaker , 120 , 60
   Waitms 500
   Do
      Key = Getkbd()
      Num = Lookupstr(key , Decode)
      If Num = "1" Then
         Toggle Relay
         If Relay = 0 Then
            Sound Speaker , 120 , 20
         Else
            Sound Speaker , 120 , 40
         End If
         Waitms 500
      End If
      If Num = "Exit" Then Call Getpass
      If Num = "2" Then Call Change_pass
   Loop
End Sub

''''''''''''''''''''''''''''''

'Change Password
Sub Change_pass
   Cls : Home : Lcd "New Pass?  Cls=" ; Chr(0)
   Lowerline : Lcd "            Exit"
   Sound Speaker , 120 , 60
   Home L : Cursor Blink
   Digits = 0
   Waitms 500
   Do
      Key = Getkbd()
      Num = Lookupstr(key , Decode)
      If Num = "Cls" Then Call Change_pass
      If Num = "Exit" Then Call Getpass
      If Is_num(num) = 1 Then
         Sound Speaker , 120 , 50
         Sound Speaker , 120 , 40
         Incr Digits
         Pass1(digits) = Num
         Locate 2 , Digits : Lcd "*"
         Waitms 300
         If Digits = 8 Then Call Confirm
      End If
   Loop
End Sub

''''''''''''''''''''''''''''''

'Confirm Password
Sub Confirm
   Digits = 0
   Cls : Home : Lcd "Confirm:   Cls=" ; Chr(0)
   Sound Speaker , 120 , 60
   Home L
   Waitms 500
   Do
      Key = Getkbd()
      Num = Lookupstr(key , Decode)
      If Num = "Cls" Then Call Confirm
      If Is_num(num) = 1 Then
         Sound Speaker , 120 , 50
         Sound Speaker , 120 , 40
         Incr Digits
         Pass2(digits) = Num
         Locate 2 , Digits : Lcd "*"
         Waitms 300
         If Digits = 8 Then
            Call Check1
            Cursor Noblink
            If Result = 8 Then
               Cls : Home : Lcd "Pass Changed!"
               Sound Speaker , 120 , 100
               Sound Speaker , 120 , 80
               Sound Speaker , 120 , 60
               For Temp = 1 To 8
                  Pass_eeprom(temp) = Pass1(temp)
                  Waitms 20
               Next Temp
               Call Load2ram
               Call Getpass
            Else
               Sound Speaker , 120 , 80
               Cls : Home : Lcd "Error!"
               Waitms 500
               Call Change_pass
            End If
         End If
      End If
   Loop
End Sub

''''''''''''''''''''''''''''''

'Confirm Pass Checker
Sub Check1
   Result = 0
   For Temp = 1 To 8
      If Pass1(temp) = Pass2(temp) Then Incr Result
   Next Temp
End Sub

''''''''''''''''''''''''''''''

'Keypad Decode Data Table
Decode:
Data "1" , "2" , "3" , ""
Data "4" , "5" , "6" , ""
Data "7" , "8" , "9" , ""
Data "Exit" , "0" , "Cls" , "" , ""

'_______________________________________________________________________________