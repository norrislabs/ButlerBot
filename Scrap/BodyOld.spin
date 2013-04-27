{{ Mission.spin }}

' ==============================================================================
'
'   File...... Mission.spin
'   Purpose... Mission application for N25-ButlerBot
'   Author.... (C) 2009-2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 12/29/2009
'   Updated... 05/19/2010
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

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Pins
  Pin_DataIn    = 0
  Pin_DataOut   = 1

  Pin_QTILeft   = 2
  Pin_QTICenter = 3
  Pin_QTIRight  = 4
  
  Pin_Drive     = 6
  Pin_Power     = 7

  Pin_IrLT      = 8
  Pin_IrRT      = 9
  Pin_IrLB      = 10
  Pin_IrRB      = 11

  Pin_SDA       = 12
  Pin_SCL       = 13
  
  Pin_Led       = 16
  Pin_Lcd       = 17
  Pin_BtnSelect      = 22
  Pin_BtnGo      = 23

  ' SRF02 Sonar IDs
  Sonar_Top     = 0
  Sonar_Bottom  = 1

  Turn_None     = 0
  Turn_Left     = 1
  Turn_Right    = 2

  ' Turn rates
  TR_Veer       = 40
  TR_Quick      = 60
  TR_Sharp      = 80

  ' Avoid codes
  Avoid_None    = 0
  Avoid_Left    = 1
  Avoid_Right   = 2
  Avoid_Both    = 3

  ' Route Operators
  Op_Nop        = 0
  Op_FindBeacon = 1
  Op_GotoBeacon = 2
  Op_Stop       = 3
  Op_Pause      = 4
  Op_Repeat     = 5
  Op_LidOpen    = 6
  Op_LidClose   = 7

  ' Function return codes
  Ret_None      = 0
  Ret_Continue  = 1
  Ret_Complete  = 2

  ' QTI channels
  QTI_Left      = 0
  QTI_Center    = 1
  QTI_Right     = 2
  QTI_EOL       = 3
  
  LineThreshold    = 10
  LineThresholdEOL = 50
  MaxLostLineCt    = 500


DAT
        Title     byte "ButlerBot",0
        Version   byte "1020a",0

        ' Routes
        Goto      long Op_GotoBeacon
                  long $FF

        PingPong  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCCW
                  long Op_Repeat
                  long $FF

        Left_L    long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCCW
                  long Op_Repeat
                  long $FF

        Right_L   long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCW
                  long Op_GotoBeacon, Op_FindBeacon, Drive#Mov_SpinCW
                  long Op_Repeat
                  long $FF


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_PowerOn

  ' Current behavior values
  long m_CurrentPriority

  ' Current sensor values
  long m_DistTop
  long m_DistBottom
  long m_DistClosest
  long m_Avoid

  long m_AvoidLeft
  long m_AvoidRight

  ' Line Following
  long m_LastLine
  long m_LostLineCt
  long m_IgnoreEOL
  
  ' Route execution engine
  long m_Route
  long m_Index
  long m_IsNav
  
  byte m_Buffer[32]
  long Stack[50]


OBJ

  Head          : "iHead"
  RfLink        : "FullDuplexSerial128"
  Sonar         : "SRF02"
  Drive         : "MotorDrive"
  QTI           : "QTIEngine"
  Lcd           : "debug_lcd"

  
PUB Init | x
' ------------------------------------------------------------------------------
' Initialize
' ------------------------------------------------------------------------------

  ' LED on
  dira[Pin_Led]~~
  outa[Pin_Led]~~

  ' Initialize the LCD
  Lcd.init(Pin_Lcd, 19200, 2)                          
  Lcd.cls
  Lcd.home
  Lcd.cursor(0)                                     
  Lcd.backLight(true)
  
  SetLcdPos(0,0)
  Lcd.str(@Title)
  SetLcdPos(1,0)
  Lcd.str(@Version)

  ' Initialize RF serial link (uses 1 cog)
  RfLink.Start(Pin_DataIn, Pin_DataOut, 0, 9600)

  ' Initialize SRF02 ultrasonic senor I2C bus
  Sonar.init(Pin_SDA, Pin_SCL)

  ' Initialize Head serial interface (uses 1 cog)
  Head.Init
    
  ' Init line following sensors (QTI) (uses 1 cog)
  QTI.QTIEngine

  ' Initialize motor drive (uses 1 cog when powered on)
  Drive.Start(Pin_Drive, Pin_Power)

  m_Route := 0
  m_Index := 0
  m_IsNav := false

  ' Start sensor scan (uses 1 cog)
  cognew(SensorScan, @Stack)
  Pause_ms(1000)
  
  ' LED off
  outa[Pin_Led]~

  ' Main loop
  repeat
    ProcessRF
    ProcessButtons
    FollowLine(1)
    

' ------------------------------------------------------------------------------
' Process RF Commands
' ------------------------------------------------------------------------------
PRI ProcessRF | x 

  if CheckRF
    if GetCmd
    ' Power on
      if strcomp(@m_Buffer, string("F1"))
        if not Drive.IsPower
          Drive.PowerOn
        
    ' Power off
      if strcomp(@m_Buffer, string("F2"))
        if Drive.IsPower
          Drive.PowerOff
     
    ' Lid Open
      if strcomp(@m_Buffer, string("F3"))
        m_Route := @PingPong
        m_Index := 0

    ' Lid Close
      if strcomp(@m_Buffer, string("F4"))
        StopNav
        m_Route := 0
                    
    ' Forward
      if strcomp(@m_Buffer, string("FW"))
        if not Drive.IsPower
          Drive.PowerOn
        if Drive.GetDirection <> Drive#Mov_Halt and Drive.GetDirection <> Drive#Mov_Fwd
          Drive.Halt
        Drive.Forward(1000, false)
   
    ' Reverse
      if strcomp(@m_Buffer, string("BK"))
        if not Drive.IsPower
          Drive.PowerOn
        if Drive.GetDirection <> Drive#Mov_Halt and Drive.GetDirection <> Drive#Mov_Rev
          Drive.Halt
        Drive.Reverse(1000, false)
                
    ' Stop
      if strcomp(@m_Buffer, string("ST"))
        if(Drive.GetDirection == Drive#Mov_SpinCCW or Drive.GetDirection == Drive#Mov_SpinCW)
          Drive.HaltClear
        else
          Drive.Halt
        RfLink.rxflush
          
    ' Emergency Stop
      if strcomp(@m_Buffer, string("ES"))
        Drive.HaltClear
        RfLink.rxflush
          
    ' Left
      if strcomp(@m_Buffer, string("LF"))
        if Drive.GetDirection == Drive#Mov_Fwd
          Drive.TurnLeft(TR_Veer)
        elseif Drive.GetDirection == Drive#Mov_Rev
          Drive.TurnRight(TR_Veer)
        elseif Drive.GetDirection == Drive#Mov_Halt
          Drive.SpinCCW(360, false)
                       
    ' Left More
      if strcomp(@m_Buffer, string("L2"))
        if Drive.GetDirection == Drive#Mov_Fwd
          Drive.TurnLeft(TR_Quick)
        elseif Drive.GetDirection == Drive#Mov_Rev
          Drive.TurnRight(TR_Quick)
        elseif Drive.GetDirection == Drive#Mov_Halt
          Drive.SpinCCW(360, false)
                       
    ' Right
      if strcomp(@m_Buffer, string("RT"))
        if Drive.GetDirection == Drive#Mov_Fwd
          Drive.TurnRight(TR_Veer)
        elseif Drive.GetDirection == Drive#Mov_Rev
          Drive.TurnLeft(TR_Veer)
        elseif Drive.GetDirection == Drive#Mov_Halt
          Drive.SpinCW(360, false)
   
    ' Right
      if strcomp(@m_Buffer, string("R2"))
        if Drive.GetDirection == Drive#Mov_Fwd
          Drive.TurnRight(TR_Quick)
        elseif Drive.GetDirection == Drive#Mov_Rev
          Drive.TurnLeft(TR_Quick)
        elseif Drive.GetDirection == Drive#Mov_Halt
          Drive.SpinCW(360, false)
   
   
PRI CheckRF : yesno | data

    data := RfLink.rxcheck
    if data == "*"
      yesno := true
    else
      yesno := false
      

PRI GetCmd : status | data,i

  i := 0
  data := 0
  repeat while data <> -1
    data := RfLink.rxtime(5000)

    if data == 13
      m_Buffer[i] := 0
      status := true
      return

    m_Buffer[i] := data

    i++
    m_Buffer[i] := 0
    if i == 31
      quit

  status := false


' ------------------------------------------------------------------------------
' Follow Line Behavior
' ------------------------------------------------------------------------------
PRI FollowLine(Priority) | line

  line := GetLine
  
  SetLcdPos(0, 12)
  Lcd.decf(line, 2)

  if Drive.GetDirection == Drive#Mov_Fwd
    if m_IgnoreEOL > 0
      m_IgnoreEOL--
    else
      if line => 8
        TurnAround
        return

    line &= $7
    if line == 0
      m_LostLineCt++
    else
      m_LostLineCt := 0

    if m_LostLineCt > MaxLostLineCt
      Drive.Halt
      Pause_ms(1000)
      m_LastLine := 0
      return   
  
    case line
      0:  ' No line
        if m_LastLine == 1 or m_LastLine == 3
          Drive.TurnRight(50)
        elseif m_LastLine == 4 or m_LastLine == 6
          Drive.TurnLeft(50)
        elseif m_LastLine == 2
          ' No more line
          Drive.Halt
     
      1:  ' Far Right
        Drive.TurnRight(8)

      2:  ' Center
        Drive.StopTurn
        
      3:  ' Near Right
        Drive.TurnRight(2)
        
      4:  ' Far Left
        Drive.TurnLeft(8)
     
      6:  ' Near Left
        Drive.TurnLeft(2)      
     
  m_LastLine := line


PRI TurnAround

  outa[Pin_Led]~~

  Drive.StopTurn
  Pause_ms(500)
  Drive.Halt

  Drive.SpinCCW(180, true)
  Drive.Forward(1000, false)

  m_IgnoreEOL := 250
  m_LostLineCt := 0

  outa[Pin_Led]~


' ------------------------------------------------------------------------------
' Blocked Behavior
' ------------------------------------------------------------------------------
PRI Blocked(Priority) | av

  if m_CurrentPriority => Priority
    if m_DistBottom < 8
      if m_CurrentDir == Mov_Fwd
        if m_DistBottom < 6
          HaltClear
        else
          Halt
      Inhibit(Priority)
        
    else
      Release(Priority)
      
          
' ------------------------------------------------------------------------------
' Avoid Behavior
' ------------------------------------------------------------------------------
PRI Avoid(Priority) | av

  if m_CurrentPriority => Priority and m_IsNav
    av := m_Avoid
    if av == Avoid_Left or av == Avoid_Right
      if m_CurrentDir == Mov_Fwd
        Halt
        
      if m_CurrentDir == Mov_Halt
        ' Turn left or right
        if av == Avoid_Left
          SpinCW(30, true)
        elseif av == Avoid_Right
          SpinCCW(30, true)
                        
      Inhibit(Priority)
        
    else
      Release(Priority)
      
          
 ' ------------------------------------------------------------------------------
' Navigate Behavior (Route Execution Engine)
' ------------------------------------------------------------------------------
PRI Navigate(Priority) | opcode,status

  if m_CurrentPriority => Priority and m_Route > 0
    opcode := LONG[m_Route][m_Index]
    case opcode
      Op_GotoBeacon:
        status := GotoBeacon
        if status == Ret_Complete
          m_Index++
        
      Op_FindBeacon:
        m_Index++
        FindBeacon(LONG[m_Route][m_Index])
        m_Index++

      Op_Stop:
        StopNav
        m_Index++

      Op_Pause:
        Head.AdfHalt
        m_Index++
        Pause_ms(LONG[m_Route][m_Index])
        m_Index++

      Op_Repeat:
        m_Index := 0


PRI GotoBeacon : status | bearing,error,corr 

  ' Start beacon navigation if not running
  StartNav
  
  ' Arrived at the beacon?
  if m_DistTop < 16 and Head.GetAdfIsBeaconInScan == 1
    StopNav
    return Ret_Complete

  ' Steer towards the beacon
  bearing := Head.GetAdfBearing
  if bearing > 0
  ' Start up if we are stopped
    if m_CurrentDir == Mov_Halt
      Forward(1000, false)

    ' Calculate drive (proportional) correction
    error := ((bearing - 90) / 3)
    corr := ||error
    corr <#= 30
      
    ' Correct for any error              
    if corr > 0
      if error > 0
        ' Right turn
        TurnRight(corr)
      else
        ' Left turn 
        TurnLeft(corr)
  else
    Halt
            
  return Ret_Continue

           
PRI FindBeacon(Turn) | dir,timeout

  ' Move away from the current beacon
  if Turn == Mov_SpinCW
    SpinCW(360, false)
  else
    SpinCCW(360, false)
    
  Pause_ms(1000)

  ' Setup counter A for 5 second timeout
  timeout := clkfreq * 5
  ctra[30..26] := %11111
  frqa := 1
  phsa := 0

  ' Search for beacon for 5 seconds
  repeat while phsa < timeout
    if Head.GetAdfIsBeacon == true
      quit

  ' Stop      
  HaltClear


PRI StartNav

  if not m_IsNav
    Head.SetAdfScanRange(45,135)
    Head.AdfScanMode
    m_IsNav := true


PRI StopNav

  Halt
  Head.AdfHalt
  Head.SetAdfPosition(90)
  m_IsNav := false
  

' ------------------------------------------------------------------------------
' Behavior Processing Support Methods
' ------------------------------------------------------------------------------
PRI Inhibit(Priority)

  m_CurrentPriority := Priority

  SetLcdPos(1,8)
  Lcd.str(string("In"))
  Lcd.decx(m_CurrentPriority,2)
  

PRI Release(Priority)

  if m_CurrentPriority == Priority
    m_CurrentPriority := 99
   
  SetLcdPos(1,8)
  Lcd.str(string("Re"))
  Lcd.decx(m_CurrentPriority,2)


' ------------------------------------------------------------------------------
' Sensor Scan (Runs in its own cog)
' ------------------------------------------------------------------------------
PRI SensorScan | distTop,distBot,av,line

  repeat
    ' Forward sonar sensors
    m_DistTop := GetDistance(Sonar_Top)
    m_DistBottom := GetDistance(Sonar_Bottom)

    if m_DistTop < m_DistBottom
      m_DistClosest := m_DistTop
    else
      m_DistClosest := m_DistBottom

    ' IR avoid sensors
    av := 0
    if(ina[Pin_IrLT] == 1 or ina[Pin_IrLB] == 1)
      av += Avoid_Left

    if(ina[Pin_IrRT] == 1 or ina[Pin_IrRB] == 1)
      av += Avoid_Right
      
    m_Avoid := av


' ------------------------------------------------------------------------------
' Line Following Sensors (QTI)
' ------------------------------------------------------------------------------
PRI GetLine : line

    line := 0
    if QTI.readSensorDigital(QTI_Right, LineThreshold) == false
      line := 1
    
    if QTI.readSensorDigital(QTI_Center, LineThreshold) == false
      line += 2
    
    if QTI.readSensorDigital(QTI_Left, LineThreshold) == false
      line += 4

    if QTI.readSensorDigital(QTI_EOL, LineThresholdEOL) == false
      line += 8

                         
' ------------------------------------------------------------------------------
' Sonar
' ------------------------------------------------------------------------------

PRI GetDistance(sonarID) : dist

    sonar.initranging(sonarID)
    Pause_ms(70)
    dist := sonar.getrange(sonarID)

  
' ------------------------------------------------------------------------------
' Process Buttons
' ------------------------------------------------------------------------------
PRI ProcessButtons | btn

  btn := TestButton
  if btn == Pin_BtnSelect
    Halt
    if m_PowerOn == true
      PowerOff
              
  elseif btn == Pin_BtnGo
    if m_PowerOn == false
      PowerOn
    Forward(1000, false)
      
      
PRI TestButton : btn

  if ina[Pin_BtnSelect] == 0
    Pause_ms(30)
    if ina[Pin_BtnSelect] == 0
      repeat while ina[Pin_BtnSelect] == 0
      return Pin_BtnSelect
      
  if ina[Pin_BtnGo] == 0
    Pause_ms(30)
    if ina[Pin_BtnGo] == 0
      repeat while ina[Pin_BtnGo] == 0
      return Pin_BtnGo

  return -1
  

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
      