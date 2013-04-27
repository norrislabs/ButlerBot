{{ TestQTI.spin }}

' ==============================================================================
'
'   File...... TestDockSensor.spin
'   Purpose... Test harness for Dock Detect sensor
'   Author.... (C) 2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 05/15/2010
'   Updated...
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{
  This is a description of the program.
}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  1019a - First version
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000


  ' Pins
  Pin_Led       = 16
  Pin_Lcd       = 17
  Pin_Dock      = 24
  

VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------


DAT
        Title     byte "Test Dock",0



OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  Lcd           : "debug_lcd"

  
PUB Init | c,a,d
' ------------------------------------------------------------------------------
' Public Procedures
' ------------------------------------------------------------------------------

  ' Initialize the LCD
  Lcd.init(Pin_Lcd, 19200, 4)                          
  Lcd.cls
  Lcd.home
  Lcd.cursor(0)                                     
  Lcd.backLight(true)
  
  SetLcdPos(0,0)
  Lcd.str(@Title)

  dira[Pin_Led]~~
  repeat
    outa[Pin_Led] := ina[Pin_Dock]
    Pause_ms(100)
    

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  