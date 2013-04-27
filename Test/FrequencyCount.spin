''Demonstration of the counter used as a frequency counter
CON 
        _clkmode = xtal1 + pll16x
        _XinFREQ = 5_000_000

  Pin_Led       = 0
  Pin_Lcd       = 8
  Pin_IR        = 16


OBJ
  Lcd           : "debug_lcd"


VAR
        long length
        long Stack[50]


PUB Go

  ' Initialize the LCD
  Lcd.init(Pin_Lcd, 19200, 2)                          
  Lcd.cls
  Lcd.home
  Lcd.cursor(0)                                     
  Lcd.backLight(true)

  dira[Pin_Led]~~
  outa[Pin_Led]~
  
  cognew(Measure, @Stack)

  repeat
    SetLcdPos(0,0)
    Lcd.clrln(0)
    Lcd.decf(length,8)

    if length > 60 and length < 70
      outa[Pin_Led]~~
    else
      outa[Pin_Led]~
        
    Pause_ms(250)                  


PRI Measure | ct,p

  dira[Pin_IR]~
  
  ctra[30..26] := %11111
  frqa := 1
  
  ctrb := %01110 << 26 + Pin_IR
  frqb := 1

  ct := clkfreq / 8
  repeat
    p := 0
    repeat 3
      phsa := 0
      phsb := 0

      repeat until phsa > ct
      p += phsb

   length := p / 3
    

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
