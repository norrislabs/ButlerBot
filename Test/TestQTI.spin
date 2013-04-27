{{ TestQTI.spin }}

' ==============================================================================
'
'   File...... TestQTI.spin
'   Purpose... Test harness for QTI object
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
  Pin_Lcd       = 17


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------


DAT
        Title     byte "Test QTI",0



OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  QTI           : "QTIEngine"
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
  
'  SetLcdPos(0,0)
'  Lcd.str(@Title)

  ' Start QTI Engine
  QTI.QTIEngine

  repeat
    Lcd.clrln(0)
    Lcd.clrln(1)

    repeat c from 0 to 2     
      a := QTI.readSensorAnalog(c)
      d := QTI.readSensorDigital(c, 20)

      SetLcdPos(0, c * 4)
      Lcd.dec(a)
    
      SetLcdPos(1, c * 4)
      if d == true
        Lcd.dec(1)
      else
        Lcd.dec(0)
      
    Pause_ms(250)
    

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  