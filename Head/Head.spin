{{ Head.spin }}

' ==============================================================================
'
'   File...... Head.spin
'   Purpose... Head application for N25-ButlerBot
'   Author.... (C) 2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 02/28/2010
'   Updated... 03/29/2010
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
  1012a - This is the first version
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Pins
  Pin_IR        = 5
  
  Pin_ServoIR   = 6
  Pin_ServoLid  = 7
  
  Pin_DataIn    = 22
  Pin_DataOut   = 23
  
  Pin_Led       = 16

  ' Lid servo positions
  Lid_Close     = 1540
  Lid_Open      = 750

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
  

DAT
        Title     byte "N25-ButlerBot-Head",0
        Version   byte "1013a",0


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_CurrentMode
  long m_CurrentLidPos

  byte m_CmdBuf[8]
  byte m_ResultBuf[8]


OBJ

  Link          : "FullDuplexSerial128"
  PWM           : "Pwm_32_V2"
  ADF           : "ADF2"
  
  
PUB Init
' ------------------------------------------------------------------------------
' Initialize
' ------------------------------------------------------------------------------

  ' Initialize serial link to Body (uses 1 cog)
  Link.Start(Pin_DataIn, Pin_DataOut, 0, 19200)

  ' Initialize PWM for lid servo
  PWM.Start
  PWM.Servo(Pin_ServoLid, Lid_Close)
  m_CurrentLidPos := Lid_Close

  ' Start ADF
  ADF.Start(Pin_IR, Pin_ServoIR, Pin_Led)

  ' Main loop
  repeat
    ProcessCommand
                

PRI ProcessCommand  | i,char,count 

  char := Link.rxcheck
  if char == "!"
    ' Receive command
    i := 0
    m_CmdBuf[0] := Cmd_Nop
    count := Link.rxtime(10)
    if count <> -1 and count =< 8
      repeat count
        m_CmdBuf[i++] := Link.rxtime(10)

    ' Process command
    case m_CmdBuf[0]
      Cmd_GetParam:
        GetParameter(m_CmdBuf[1])

      Cmd_SetParam:
        SetParameter(m_CmdBuf[1])

      Cmd_Reset:
        MasterReset
        SendResult(0)
        
      Cmd_LidOpen:
        LidOpen
        SendResult(0)
        
      Cmd_LidClose:
        LidClose
        SendResult(0)
        
      Cmd_AdfManualMode:
        m_CurrentMode := Cmd_AdfManualMode
        ADF.Halt
        ADF.SetPosition(90)
        outa[Pin_Led]~
        SendResult(0)
        
      Cmd_AdfScanMode:
        m_CurrentMode := Cmd_AdfScanMode
        ADF.Halt
        ADF.Scan
        outa[Pin_Led]~
        SendResult(0)
        
      Cmd_AdfHalt:
        m_CurrentMode := Cmd_Nop
        ADF.Halt
        ADF.SetPosition(90)
        outa[Pin_Led]~
        SendResult(0)
        
      other:        
        SendResult(0)


PRI GetParameter(ParmID) | i

  case ParmID
    Parm_AdfBearing:
      i := ADF.GetBearing
      if i > 0
        m_ResultBuf[0] := i
      else
        m_ResultBuf[0] := 0
      SendResult(1)
      
    Parm_AdfScanning:
      if ADF.IsScanning
        m_ResultBuf[0] := 1
      else
        m_ResultBuf[0] := 0
      SendResult(1)
      
    Parm_AdfLocked:
      if ADF.IsLocked
        m_ResultBuf[0] := 1
      else
        m_ResultBuf[0] := 0
      SendResult(1)
      
    Parm_AdfBeaconInScan:
      if ADF.IsBeaconInScan
        m_ResultBuf[0] := 1
      else
        m_ResultBuf[0] := 0
      SendResult(1)
      
    Parm_AdfIsBeacon:
      if ADF.IsBeacon
        m_ResultBuf[0] := 1
      else
        m_ResultBuf[0] := 0
      SendResult(1)
      
    other:
      SendResult(0)
      

PRI SetParameter(ParmID)

  case ParmID
    Parm_AdfScanRange:
      ADF.SetScanRange(m_CmdBuf[2], m_CmdBuf[3])

    Parm_AdfLockWidth:
      ADF.SetScanLockWidth(m_CmdBuf[2])

    Parm_AdfPosition:
      ADF.SetPosition(m_CmdBuf[2])

  SendResult(0)
      

PRI SendResult(Count) | i

  Link.tx("!")
  Link.tx(Count)

  repeat i from 1 to Count
    Link.tx(m_ResultBuf[i - 1])
    

PRI MasterReset

  m_CurrentMode := Cmd_Nop

  ADF.Halt
  ADF.SetPosition(90)
  ADF.SetScanRange(1,180)
  ADF.SetScanLockWidth(30)

  outa[Pin_Led]~
   
    
' ------------------------------------------------------------------------------
' Lid Functions
' ------------------------------------------------------------------------------

PRI LidOpen | pos

  repeat pos from m_CurrentLidPos to Lid_Open step 10
    PWM.Servo(Pin_ServoLid, pos)
    Pause_ms(10)
  m_CurrentLidPos := Lid_Open

    
PRI LidClose | pos

  repeat pos from m_CurrentLidPos to Lid_Close step 10
    PWM.Servo(Pin_ServoLid, pos)
    Pause_ms(10)
  m_CurrentLidPos := Lid_Close

    
' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
      