{{ iHead.spin }}

' ==============================================================================
'
'   File...... iHead.spin
'   Purpose... Head Interface object 
'   Author.... (C) 2010 Steven R. Norris
'   E-mail.... steve@norrislabs.com
'   Started... 03/04/2010
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
  1009a - This is the first version
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

   ' Pins
  Pin_DataIn        = 25
  Pin_DataOut       = 26

  ' Commands
  Cmd_Nop           = 0
  Cmd_Reset         = 1
  Cmd_GetParam      = 2
  Cmd_SetParam      = 3
  Cmd_LidOpen       = 4
  Cmd_LidClose      = 5
  Cmd_AdfManualMode = 6
  Cmd_AdfScanMode   = 7
  Cmd_AdfHalt       = 8

  ' Parameters
  Parm_Null            = 0
  Parm_AdfBearing      = 1
  Parm_AdfScanning     = 2
  Parm_AdfLocked       = 3
  Parm_AdfScanRange    = 4
  Parm_AdfLockWidth    = 5
  Parm_AdfPosition     = 6
  Parm_AdfBeaconInScan = 7
  Parm_AdfIsBeacon     = 8
  
 
VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_ResultBuf[8]
  

OBJ

  Link  : "FullDuplexSerial128"

  
PUB Init
' ------------------------------------------------------------------------------
' Initialize
' ------------------------------------------------------------------------------

  ' Start the serial communications to the Head (use 1 cog)
  Link.Start(Pin_DataIn, Pin_DataOut, 0, 19200)


PUB Reset : okay

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_Reset)
  return WaitResult
  

PUB LidOpen

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_LidOpen)
  WaitResult


PUB LidClose

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_LidClose)
  WaitResult


PUB GetAdfBearing : data

  if GetHeadParameter(Parm_AdfBearing)
    data := m_ResultBuf[0]
  else
    data := 0
  

PUB GetAdfIsScanning : data

  if GetHeadParameter(Parm_AdfScanning)
    data := m_ResultBuf[0]
  else
    data := 0
  

PUB GetAdfIsLocked : data

  if GetHeadParameter(Parm_AdfLocked)
    data := m_ResultBuf[0]
  else
    data := 0
  

PUB GetAdfIsBeaconInScan : data

  if GetHeadParameter(Parm_AdfBeaconInScan)
    data := m_ResultBuf[0]
  else
    data := 0
  

PUB GetAdfIsBeacon : data

  if GetHeadParameter(Parm_AdfIsBeacon)
    if m_ResultBuf[0] == 1
      data := true
    else
      data := false
  else
    data := false
    

PUB SetAdfScanRange(LeftPos, RightPos)

  Link.tx("!")
  Link.tx(4)
  Link.tx(Cmd_SetParam)
  Link.tx(Parm_AdfScanRange)
  Link.tx(LeftPos)
  Link.tx(RightPos)
  WaitResult
  

PUB SetAdfLockWidth(Width)

  Link.tx("!")
  Link.tx(3)
  Link.tx(Cmd_SetParam)
  Link.tx(Parm_AdfLockWidth)
  Link.tx(Width)
  WaitResult
  

PUB SetAdfPosition(Pos)

  Link.tx("!")
  Link.tx(3)
  Link.tx(Cmd_SetParam)
  Link.tx(Parm_AdfPosition)
  Link.tx(Pos)
  WaitResult
  

PUB AdfManualMode

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_AdfManualMode)
  WaitResult


PUB AdfScanMode

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_AdfScanMode)
  WaitResult
  

PUB AdfHalt

  Link.tx("!")
  Link.tx(1)
  Link.tx(Cmd_AdfHalt)
  WaitResult


PRI GetHeadParameter(ParmID) : okay | i,char,count

  Link.tx("!")
  Link.tx(2)
  Link.tx(Cmd_GetParam)
  Link.tx(ParmID)
  return WaitResult


PRI WaitResult : okay | i,char,count

  longfill(@m_ResultBuf, 0, 8)

  char := 0
  repeat until char == "!"
    char := Link.rxtime(3000)
    if char == -1
      return false

  count := Link.rxtime(10)
  if count == -1
    return false
    
  if count > 8
    return false
  else
    i := 0
    repeat count
      char := Link.rxtime(10)
      if char == -1
        return false
      else
        m_ResultBuf[i++] := char
         
  return true


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