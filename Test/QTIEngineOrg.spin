{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐               
│ Charge Transfer Infrared Engine                                                                                             │
│                                                                                                                             │
│ Author: Kwabena W. Agyeman                                                                                                  │                              
│ Updated: 2/28/2010                                                                                                          │
│ Designed For: P8X32A - No Port B.                                                                                           │
│                                                                                                                             │
│ Copyright (c) 2010 Kwabena W. Agyeman                                                                                       │              
│ See end of file for terms of use.                                                                                           │               
│                                                                                                                             │
│ Driver Info:                                                                                                                │
│                                                                                                                             │ 
│ The driver is only guaranteed and tested to work at an 80Mhz system clock or higher.                                        │
│ Also this driver uses constants defined below to setup pin input and output ports.                                          │
│                                                                                                                             │
│ Additionally the driver spin function library is designed to be acessed by only one spin interpreter at a time.             │
│ To acess the driver with multiple spin interpreters at a time use hub locks to assure reliability.                          │
│                                                                                                                             │
│ Finally the driver is designed to be included only once in the object tree.                                                 │  
│ Multiple copies of this object require multiple copies of the source code.                                                  │
│                                                                                                                             │
│ Nyamekye,                                                                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 
}}

CON
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_0_Pin = 10 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_1_Pin = 11 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_2_Pin = 12 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_3_Pin = 13 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_4_Pin = 14 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_5_Pin = 15 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_6_Pin = 17 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
                '' 3.3V
                '' 
                '' └── QTI Sensor Power
  QTI_7_Pin = 18 '' ── QTI Sensor Signal 
                '' ┌── QTI Sensor Ground
                '' 
                ''
  charge_Time = 49 ' Sample time in 10µs units. Adjust this value based on your setup for best results.

VAR

  long sensorValues[8]

PUB readSensorAnalog(number) '' 4 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns a value proportional to the amount of light reflected off the surface below the QTI line sensor. (0 to 255).     │
'' │                                                                                                                          │
'' │ Number - The number of the line sensor to return the current value of. (0 - 7).                                          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (255 - ((((sensorValues[(number <# 7) #> 0] << 8) / chargeTime) <# 255) #> 0))

PUB readSensorDigital(number, threshold) '' 9 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns true or false if the analog value returned by the QTI sensor is greater than or equal to a threshold.            │
'' │                                                                                                                          │
'' │ Number    - The number of the line sensor to return the current value of. (0 - 7).                                       │
'' │ Threshold - A threshold between 0 and 255 to use to see if the value of the sensor is greater than or equal to.          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (readSensorAnalog(number) => ((threshold <# 255) #> 0))
                                          
PUB QTIEngine '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Initializes the QTI driver to run on a new cog.                                                                          │
'' │                                                                                                                          │
'' │ Returns the new cog's ID on sucess or -1 on failure.                                                                     │ 
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  dischargeTime := (clkfreq / 100000) 
  chargeTime := ((clkfreq / 100000) * constant((charge_Time <# 100) #> 0))

  return cognew(@initialization, @sensorValues) 

DAT

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       QTI Line Sensor Driver
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

                        org
                        
' //////////////////////Initialization///////////////////////////////////////////////////////////////////////////////////////// 

initialization          mov     outa,                  outputMask                ' Setup outputs.
                        
                        mov     counter,               #8                        ' Setup addresses.
                        mov     buffer,                par                       '
initializationLoop      mov     sensorValuesAddresses, buffer                    '
                        add     initializationLoop,    #$100                     '
                        add     initializationLoop,    #$100                     '
                        add     buffer,                #4                        '   
                        djnz    counter,               #initializationLoop       '

                        mov     frqa,                  #1                        ' Setup counters.
                        mov     frqb,                  #1                        ' 
                        movi    ctra,                  #%0_01000_000             '
                        movi    ctrb,                  #%0_01000_000             '

                        mov     counter,               dischargeTime             ' Setup timers. 
                        add     counter,               cnt                       '
                        
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Update Sensors
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                       
loop                    mov     channelAPin,           #((QTI_0_Pin <# 31) #> 0) ' Update channels 0 and 7.
                        mov     channelBPin,           #((QTI_7_Pin <# 31) #> 0) '
                        mov     channelAAddress,       sensorValuesAddresses + 0 '
                        mov     channelBAddress,       sensorValuesAddresses + 7 '
                        call    #checkSensor
                        
                        mov     channelAPin,           #((QTI_2_Pin <# 31) #> 0) ' Update channels 2 and 5.
                        mov     channelBPin,           #((QTI_5_Pin <# 31) #> 0) '
                        mov     channelAAddress,       sensorValuesAddresses + 2 '
                        mov     channelBAddress,       sensorValuesAddresses + 5 '
                        call    #checkSensor

                        mov     channelAPin,           #((QTI_1_Pin <# 31) #> 0) ' Update channels 1 and 6.
                        mov     channelBPin,           #((QTI_6_Pin <# 31) #> 0) '
                        mov     channelAAddress,       sensorValuesAddresses + 1 '
                        mov     channelBAddress,       sensorValuesAddresses + 6 '
                        call    #checkSensor

                        mov     channelAPin,           #((QTI_3_Pin <# 31) #> 0) ' Update channels 3 and 4.
                        mov     channelBPin,           #((QTI_4_Pin <# 31) #> 0) '
                        mov     channelAAddress,       sensorValuesAddresses + 3 '
                        mov     channelBAddress,       sensorValuesAddresses + 4 '
                        call    #checkSensor

                        jmp     #loop                                            ' Loop.
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Check Sensors.
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                      

checkSensor             mov     dira,                  outputMask                ' Set pins to outputs and wait.
                        waitcnt counter,               chargeTime                '

                        movs    ctra,                  channelAPin               ' Set counters to the correct pins.         
                        movs    ctrb,                  channelBPin               '

                        mov     dira,                  #0                        ' Set pins to inputs and wait.
                        mov     phsa,                  #0                        '
                        mov     phsb,                  #0                        '
                        waitcnt counter,               dischargeTime             '
                        
                        mov     buffer,                phsa                      ' Update sensor channels.
                        wrlong  buffer,                channelAAddress           '
                        mov     buffer,                phsb                      '
                        wrlong  buffer,                channelBAddress           '

checkSensor_ret         ret                                                      ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Data
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                        

dischargeTime           long    0                                                ' Discharge time.
chargeTime              long    0                                                ' Charge time.    

' //////////////////////Pin Masks//////////////////////////////////////////////////////////////////////////////////////////////
                      
outputMask              long    (   (|<((QTI_0_Pin <# 31) #> 0)) {               ' Line sensor output mask.
                                } | (|<((QTI_1_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_2_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_3_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_4_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_5_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_6_Pin <# 31) #> 0)) {               '
                                } | (|<((QTI_7_Pin <# 31) #> 0)) )               '
   
' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////

buffer                  res     1
counter                 res     1

channelAPin             res     1
channelBPin             res     1

channelAAddress         res     1
channelBAddress         res     1

' //////////////////////Line Sensor Variables//////////////////////////////////////////////////////////////////////////////////

sensorValuesAddresses   res     8

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        fit     496

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                      