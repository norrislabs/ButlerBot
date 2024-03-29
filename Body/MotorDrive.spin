{{ MotorDrive.spin }}

' ==============================================================================
'
'   File...... MotorDrive.spin
'   Purpose... Motor Drive object for Parallax Motor Mount Kit
'   Author.... (C) 2010 Steven R. Norris
'   E-mail.... steve@norrislabs.com
'   Started... 05/20/2010
'   Updated... 
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{


}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  1020a - This is the first version
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  ' Move Directions
  Mov_Halt      = 0
  Mov_Fwd       = 1
  Mov_Rev       = 2
  Mov_SpinCW    = 3
  Mov_SpinCCW   = 4

  DefaultSpeed  = 10
  

VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_PinDrive
  long m_PinPower

  long m_PowerOn
  long m_CurrentSpeed
  long m_CurrentDir
  long m_LastTurn


OBJ

  Drive         : "Wheel_Controller"

  
PUB Start(Pin_Drive, Pin_Power)

  m_PinDrive := Pin_Drive
  m_PinPower := Pin_Power

  m_PowerOn := false
  m_CurrentSpeed := DefaultSpeed
  m_CurrentDir := Mov_Halt
    

PUB Stop

  Drive.Close
    

PUB SetSpeed(speed)

  m_CurrentSpeed := speed


PUB GetSpeed : speed

  speed := m_CurrentSpeed

  
PUB GetDirection : dir

  dir := m_CurrentDir
  

PUB HasArrived : yesno

  yesno := Drive.arrival_check
  if yesno
    m_CurrentDir := Mov_Halt
      

PUB IsPower : yesno

  yesno := m_PowerOn

  
' ------------------------------------------------------------------------------
' Drive Power Functions
' ------------------------------------------------------------------------------

PUB PowerOn

  ' Energize the lift/drive power relay
  dira[m_PinPower]~~
  outa[m_PinPower]~~
  m_PowerOn := true
  Pause_ms(2000)
  
  ' Initialize drive/position system (uses 1 cog)
  if(Drive.Open(m_PinDrive) <> 0)
    if(Drive.start <> 0)
      if(Drive.get_Status == 1)
        Drive.set_WheelSpeed(Drive#ALL_WHEELS, 100)
        

PUB PowerOff
  
  HaltClear

' De-energize the lift/drive power relay
  dira[m_PinPower]~~
  outa[m_PinPower]~
  m_PowerOn := false
  Pause_ms(500)
  
  Drive.Close
  

' ------------------------------------------------------------------------------
' Motor Functions
' ------------------------------------------------------------------------------

PUB TurnRight(bias)

  Drive.turn(bias)
  m_LastTurn := bias
  

PUB TurnLeft(bias)

  Drive.turn(-bias)
  m_LastTurn := -bias
  

PUB StopTurn

  if m_LastTurn < 0
    Drive.turn(1)
  else
    Drive.turn(-1)
  Drive.throttle(m_CurrentSpeed)
  
  
PUB SpinCW(degrees, wait)

  Drive.throttle(m_CurrentSpeed)
  Drive.spin_turn(Drive#RIGHT_TURN, degrees)

  if wait
    Drive.arrival_wait
    m_CurrentDir := Mov_Halt
  else
    m_CurrentDir := Mov_SpinCW
   

PUB SpinCCW(degrees, wait)

  Drive.throttle(m_CurrentSpeed)
  Drive.spin_turn(Drive#LEFT_TURN, degrees)

  if wait
    Drive.arrival_wait
    m_CurrentDir := Mov_Halt
  else
    m_CurrentDir := Mov_SpinCCW
   

PUB Forward(Distance, wait)

  Drive.turn(0)
  Drive.throttle(m_CurrentSpeed)
  Drive.go_Distance(Distance, Drive#FORWARD)

  if wait
    Drive.arrival_wait
    m_CurrentDir := Mov_Halt
  else
    m_CurrentDir := Mov_Fwd
    Pause_ms(100)


PUB Reverse(Distance, wait)

  Drive.turn(0)
  Drive.throttle(m_CurrentSpeed)
  Drive.go_Distance(Distance, Drive#REVERSE)

  if wait
    Drive.arrival_wait
    m_CurrentDir := Mov_Halt
  else
    m_CurrentDir := Mov_Rev


PUB Halt

  Drive.Stop
  Pause_ms(2000)
  m_CurrentDir := Mov_Halt

  
PUB HaltClear

  Drive.Clear
  Pause_ms(1000)
  m_CurrentDir := Mov_Halt


PUB GetWheelPos(Wheel) : distance | num,rem

  num := (Drive.get_Wheel_Position(Wheel) * Drive#UNIT_INCHES) / 1000
  rem := (Drive.get_Wheel_Position(Wheel) * Drive#UNIT_INCHES) // 1000
  if rem > 500
    num++
  distance := num


PRI WaitDistance(Distance, Wheel) | c,d,dist,rem

  dist := Distance * 1000
  rem := dist // Drive#UNIT_INCHES
  dist := dist / Drive#UNIT_INCHES
  if rem > (Drive#UNIT_INCHES / 2)
    dist++

  c := Drive.get_Wheel_Position(Wheel)
  d := c + dist

  repeat until c => d
    c := Drive.get_Wheel_Position(Wheel)
  
    
PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))


DAT
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