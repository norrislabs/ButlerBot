{{ TestEmic.spin }}

' ==============================================================================
'
'   File...... TestEmic.spin
'   Purpose... Test harness for Emic TTS
'   Author.... (C) 2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 05/16/2010
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
  Pin_Lcd       = 16

  Pin_Reset     = 22
  Pin_Busy      = 23
  Pin_DataIn    = 24
  Pin_DataOut   = 25


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------


DAT
        Title     byte "Test Emic",0



OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  Lcd           : "debug_lcd"
  Emic          : "Emic"

  
PUB Init | x
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

  ' Initialize Emic (uses 1 cog)
  Emic.Start(Pin_DataIn, Pin_DataOut, Pin_Reset, Pin_Busy)

  ' Male sounding voice
  Emic.Setup(3, 2, 0)
  
  repeat
    Emic.Say(string("I will count from 1 to 1000"))

    repeat x from 1 to 1000
      Emic.SayNumber(x)
    

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  