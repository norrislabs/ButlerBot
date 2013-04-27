{{ Emic.spin }}

' ==============================================================================
'
'   File...... Emic.spin
'   Purpose... Emic TTS Object
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


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_Pin_EmicReset
  long m_Pin_EmicBusy
  

OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  Emic          : "FullDuplexSerial128"
  Num           : "Simple_Numbers"

  
PUB Start(Pin_EmicIn, Pin_EmicOut, Pin_EmicReset, Pin_EmicBusy)
' ------------------------------------------------------------------------------
' Public Procedures
' ------------------------------------------------------------------------------

  ' Initialize serial link to Emic (uses 1 cog)
  Emic.Start(Pin_EmicIn, Pin_EmicOut, 0, 2400)

  m_Pin_EmicBusy := Pin_EmicBusy
  m_Pin_EmicReset := Pin_EmicReset
  
  Reset
  
  
PUB Say(text)

  Emic.str(string("say="))
  Emic.str(text)
  Emic.str(string(";"))
  WaitBusy
  

PUB SayNumber(number)

  Emic.str(string("say="))
  Emic.str(Num.dec(number))
  Emic.str(string(";"))
  WaitBusy
  

PUB Setup(volume, speed, pitch)

  Reset
  WaitBusy
  
  Emic.str(string("volume="))
  Emic.str(Num.decf(volume, 1))
  Emic.str(string(";"))
  WaitBusy
  
  Emic.str(string("speed="))
  Emic.str(Num.decf(speed, 1))
  Emic.str(string(";"))
  WaitBusy
  
  Emic.str(string("pitch="))
  Emic.str(Num.decf(pitch, 1))
  Emic.str(string(";"))
  WaitBusy
  

PUB Reset

  outa[m_Pin_EmicReset]~~
  dira[m_Pin_EmicReset]~~    

  outa[m_Pin_EmicReset]~
  Pause_ms(10)
  outa[m_Pin_EmicReset]~~
  
  WaitBusy

  
PRI WaitBusy

  Pause_ms(200)
  repeat while ina[m_Pin_EmicBusy] == 1
  Pause_ms(100)


' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  