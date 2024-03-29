{{ MotorArbiter.spin }}

' ==============================================================================
'
'   File...... MotorArbiter.spin
'   Purpose... Arbiter for Motor Drive
'   Author.... (C) 2010 Steven R. Norris
'   E-mail.... steve@norrislabs.com
'   Started... 05/20/2010
'   Updated... 05/21/2010
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
  Mov_Halt      = Drive#Mov_Halt
  Mov_Fwd       = Drive#Mov_Fwd
  Mov_Rev       = Drive#Mov_Rev
  Mov_SpinCW    = Drive#Mov_SpinCW
  Mov_SpinCCW   = Drive#Mov_SpinCCW

  DefaultSpeed  = Drive#DefaultSpeed

  ' Move Operator Codes
  Mop_Nop       = 0  
  Mop_Halt      = 1
  Mop_HaltClr   = 2
  Mop_Fwd       = 3
  Mop_Rev       = 4
  Mop_SpinCW    = 5
  Mop_SpinCCW   = 6
  Mop_TurnRight = 7
  Mop_TurnLeft  = 8
  Mop_StopTurn  = 9
  Mop_SetSpeed  = 10
  Mop_Pause     = 11
  Mop_PowerOn   = 12
  Mop_PowerOff  = 13

  ' Behavior request queue array
  MaxBehaviors     = 16
  MaxMops          = 8
  MopLength        = 3
  BehSize          = MaxMops * MopLength
  RequestArraySize = MaxBehaviors * BehSize
  

VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long  Requests[RequestArraySize]
  long  NextMopIP[MaxBehaviors] 
  

OBJ

  Drive         : "MotorDrive"

  
PUB Start(Pin_Drive, Pin_Power)

  Drive.Start(Pin_Drive, Pin_Power)
      

PUB Stop

  Drive.Stop
    

PUB GetDirection : dir

  dir := Drive.GetDirection
  

PUB GetSpeed : speed

  speed := Drive.GetSpeed


PUB GetWheelPos(Wheel) : pos

  pos := Drive.GetWheelPos(Wheel)


PUB HasArrived : yesno

  yesno := Drive.HasArrived

        
' ------------------------------------------------------------------------------
' Drive Power Functions
' ------------------------------------------------------------------------------

PUB IsPower : yesno

  yesno := Drive.IsPower


' ------------------------------------------------------------------------------
' Main Arbitor Functions
' ------------------------------------------------------------------------------

PUB Arbitrate : winner | BehID, MopIP

  repeat BehID from 0 to MaxBehaviors-1
    if RequestsInQueue(BehID) > 0
      repeat MopIP from 0 to MaxMops-1
        case GetRequestData(BehID, MopIP, 0)
          Mop_Nop:
            quit
            
          Mop_Halt:
            Drive.Halt
            
          Mop_HaltClr:
            Drive.HaltClear
            
          Mop_Fwd:
            Drive.Forward(GetRequestData(BehID, MopIP, 1), GetRequestData(BehID, MopIP, 2))

          Mop_Rev:
            Drive.Reverse(GetRequestData(BehID, MopIP, 1), GetRequestData(BehID, MopIP, 2))

          Mop_SpinCW:
            Drive.SpinCW(GetRequestData(BehID, MopIP, 1), GetRequestData(BehID, MopIP, 2))

          Mop_SpinCCW:
            Drive.SpinCCW(GetRequestData(BehID, MopIP, 1), GetRequestData(BehID, MopIP, 2))

          Mop_TurnRight:
            Drive.TurnRight(GetRequestData(BehID, MopIP, 1))

          Mop_TurnLeft:
            Drive.TurnLeft(GetRequestData(BehID, MopIP, 1))

          Mop_StopTurn:
            Drive.StopTurn
            
          Mop_SetSpeed:
            Drive.SetSpeed(GetRequestData(BehID, MopIP, 1))

          Mop_Pause:
            Pause_ms(GetRequestData(BehID, MopIP, 1))

          Mop_PowerOn:
            Drive.PowerOn

          Mop_PowerOff:
            Drive.PowerOff
      quit
      
  ClearRequests


PUB ClearRequests | i

  repeat i from 0 to RequestArraySize-1
    Requests[i] := Mop_Nop
    
  repeat i from 0 to MaxBehaviors-1
    NextMopIP[i] := 0


PUB RequestsInQueue(BehID) : count

  count := NextMopIP[BehID]
  if count > MaxMops
    count := -1
      

' ------------------------------------------------------------------------------
' Arbitrated Request Functions
' ------------------------------------------------------------------------------

PUB SetSpeed(BehID, speed) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_SetSpeed)
    SetRequestData(BehID, NextMopIP[BehID], 1, speed)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
      

PUB Pause(BehID, delay) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_Pause)
    SetRequestData(BehID, NextMopIP[BehID], 1, delay)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB PowerOn(BehID) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_PowerOn)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB PowerOff(BehID) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_PowerOff)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB TurnRight(BehID, bias) : reqcount
  
  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_TurnRight)
    SetRequestData(BehID, NextMopIP[BehID], 1, bias)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB TurnLeft(BehID, bias) : reqcount
  
  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_TurnLeft)
    SetRequestData(BehID, NextMopIP[BehID], 1, bias)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB StopTurn(BehID) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_StopTurn)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    
  
PUB SpinCW(BehID, degrees, wait) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_SpinCW)
    SetRequestData(BehID, NextMopIP[BehID], 1, degrees)
    SetRequestData(BehID, NextMopIP[BehID], 2, wait)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB SpinCCW(BehID, degrees, wait) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_SpinCCW)
    SetRequestData(BehID, NextMopIP[BehID], 1, degrees)
    SetRequestData(BehID, NextMopIP[BehID], 2, wait)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB Forward(BehID, distance, wait) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_Fwd)
    SetRequestData(BehID, NextMopIP[BehID], 1, distance)
    SetRequestData(BehID, NextMopIP[BehID], 2, wait)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB Reverse(BehID, Distance, wait) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_Rev)
    SetRequestData(BehID, NextMopIP[BehID], 1, distance)
    SetRequestData(BehID, NextMopIP[BehID], 2, wait)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

PUB Halt(BehID) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_Halt)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    
  
PUB HaltClear(BehID) : reqcount

  if NextMopIP[BehID] < MaxMops
    SetRequestData(BehID, NextMopIP[BehID], 0, Mop_HaltClr)

  NextMopIP[BehID]++
  reqcount := RequestsInQueue(BehID)
    

' ------------------------------------------------------------------------------
' Request Queue Access Functions
' ------------------------------------------------------------------------------

PUB GetRequestData(BehID, MopIP, Offset) : data

  data := long[@Requests][(BehID * BehSize) + (MopIP * MopLength) + Offset]


PRI SetRequestData(BehID, MopIP, Offset, data)

  long[@Requests][(BehID * BehSize) + (MopIP * MopLength) + Offset] := data
  

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))


' ------------------------------------------------------------------------------
' Debug
' ------------------------------------------------------------------------------
{
PRI DumpRequestData(BehCount) | BehID,MopIP,data

  repeat BehID from 0 to BehCount-1
    RfLink.str(string("Behavior "))
    RfLink.dec(BehID)
    RfLink.str(string(", Requests "))
    RfLink.dec(Drive.RequestsInQueue(BehID))
    RfLink.tx(13)
    
    repeat MopIP from 0 to Drive#MaxMops-1
      RfLink.dec(MopIP)
      RfLink.str(string(". "))
      
      RfLink.str(Num.decx(Drive.GetRequestData(BehID, MopIP, 0),4))
      RfLink.tx(",")
      RfLink.str(Num.decx(Drive.GetRequestData(BehID, MopIP, 1),4))
      RfLink.tx(",")
      RfLink.str(Num.decx(Drive.GetRequestData(BehID, MopIP, 2),4))
      RfLink.tx(13)

    RfLink.tx(13)
}

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
      