{{ Mission.spin }}

' ==============================================================================
'
'   File...... Mission.spin
'   Purpose... Mission application for N25-ButlerBot (aka Baxter)
'   Author.... (C) 2009-2011 Steven R. Norris
'   E-mail.... steve@norrislabs.com
'   Started... 12/29/2009
'   Updated... 12/21/2011
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{
   Baxter is the transport component of the Beverage Delivery System (BDS).
   Supporting Baxter will be one or more fixed location dispenser robots.
   You can think of a dispenser robot as a kind of vending machine. Like real
   vending machines each dispenser robot will support a certain type of item such
   as a canned beverage or bagged snack.

   Currently Baxter is using 6 Cogs.
}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  1022a - This is the first version
  1025a - Added RF speed commands
  1113a - Updated to new link protocol
  1129a - Added Demo mode for TCA conference in LA!
  1151a - Added new line constrained demo (Demo2)
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' IDs
  NetID         = "R"           ' Robot Network
  DevID         = "5"           ' ButlerBot ID

  RoboFridgeID  = "6"           ' RoboFridge ID
  
  ' Pins
  Pin_DataIn    = 0
  Pin_DataOut   = 1

  Pin_QTILeft   = 2
  Pin_QTICenter = 3
  Pin_QTIRight  = 4
  Pin_QTIEOL    = 5
  
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
  Pin_BtnSelect = 22
  Pin_BtnGo     = 23

  Pin_Docked    = 24

  ' SRF02 Sonar IDs
  Sonar_Top     = 0
  Sonar_Bottom  = 1

  ' Turn rates
  TR_Veer       = 40
  TR_Quick      = 60
  TR_Sharp      = 80

  ' Avoid codes
  Avoid_None    = 0
  Avoid_Left    = 1
  Avoid_Right   = 2
  Avoid_Both    = 3

  ' Route Engine Operators
  Op_Nop          = 0
  Op_FindBeacon   = 1
  Op_GotoBeacon   = 2
  Op_FollowLine   = 3
  Op_FollowLineTA = 3
  Op_FindLine     = 4
  Op_Dock         = 5
  Op_Halt         = 6
  Op_Fwd          = 7
  Op_Fwd2Line     = 8
  Op_Fwd2Rev      = 9
  Op_Rev          = 10
  Op_SpinCW       = 11
  Op_SpinCCW      = 12
  Op_OpenLid      = 13
  Op_CloseLid     = 14
  Op_Pause        = 15
  Op_Repeat       = 16
  Op_End          = 17
  
  ' Route Engine Functions return codes
  Ret_None      = 0
  Ret_Continue  = 1
  Ret_Complete  = 2

  ' QTI channels
  QTI_Left      = 0
  QTI_Center    = 1
  QTI_Right     = 2
  QTI_EOL       = 3

  ' Line Following  
  LineThreshold    = 10
  LineThresholdEOL = 50
  MaxLostLineCt    = 400
  IgnoreEOL        = 250

  ' Behavior Stacks IDs
  BS_Default      = 0
  BS_PaceFree     = 1
  BS_PaceBox      = 2
  BS_NavRoute     = 3
  BS_LiFoDock     = 4
  
  ' RoboFridge  
  ' Operation Codes
  RFOp_Idle       = 0
  RFOp_OpenDoor   = 1
  RFOp_CloseDoor  = 2
  RFOp_Dispense   = 3
  
  ' Door status
  RFDS_Unknown    = 0
  RFDS_Closed     = 1
  RFDS_Opened     = 2

  'Status Codes
  RFST_Unknown    = 0
  RFST_OK         = 1
  RFST_InProgress = 2
  RFST_Error      = 3

  ' Menu operations
  MuOp_Idle       = 0
  MuOp_Default    = 1
  MuOp_NavRoute1  = 2
  MuOp_NavRoute2  = 3
  MuOp_PaceFree   = 4
  MuOp_PaceBox    = 5
  MuOp_LiFoDock   = 6
  MuOp_LiFoPPong  = 7
  

DAT
        Title     byte "ButlerBot-1151a",0

        ' Task Menu (Name string, 0, operation)
        Tasks     byte "Remote Only?  ",0,MuOp_Default
                  byte "Pace Free?    ",0,MuOp_PaceFree
                  byte "Pace in Box?  ",0,MuOp_PaceBox
                  byte "LiFo PingPong?",0,MuOp_LiFoPPong
                  byte "LiFo Dock?    ",0,MuOp_LiFoDock

        TotalTasks long 5

        ' Routes
        GetBeer   long Op_Fwd, 84
                  long Op_SpinCCW, 120
                  long Op_GotoBeacon
                  long Op_Dock
                  long Op_Halt
                  long Op_SpinCW, 95
                  long Op_Fwd, 24
                  long Op_GotoBeacon
                  long Op_Halt
                  long Op_OpenLid, Op_Pause, 5000, Op_CloseLid
                  long Op_SpinCCW, 155
                  long Op_End

        PingPong  long Op_FindLine, Drive#Mov_SpinCW
                  long Op_FollowLine
                  long Op_Repeat
                  
        PaceFree  long Op_Fwd, 60
                  long Op_OpenLid, Op_Pause, 3000, Op_CloseLid
                  long Op_SpinCW, 180
                  long Op_Fwd, 60
                  long Op_OpenLid, Op_Pause, 3000, Op_CloseLid
                  long Op_SpinCCW, 180
                  long Op_Repeat
                  
        PaceBox   long Op_Fwd2Line, 120
                  long Op_OpenLid, Op_Pause, 3000, Op_CloseLid
                  long Op_SpinCW, 180
                  long Op_Fwd2Line, 120
                  long Op_OpenLid, Op_Pause, 3000, Op_CloseLid
                  long Op_SpinCCW, 180
                  long Op_Repeat
                  

VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  ' Current Behavior Stack
  long m_BehStack

  ' Menu system
  long m_MenuItem
  long m_MenuOp

  ' Current behavior (abritration winner)
  long m_CurrentBehavior
  
  ' Current sensor values
  long m_DistTop
  long m_DistBottom
  long m_DistClosest
  long m_Avoid

  ' Line Following
  long m_LastLine
  long m_LostLineCt
  long m_IgnoreEOL
  
  ' Route execution engine
  long m_Route
  long m_Index

  ' Behavior inhibitors
  long m_BNav
  long m_UseAvoidance
  long m_OnPad

  ' RoboFridge Status
  long m_LastOp
  long m_LastOpStatus
  long m_Cans
  long m_DoorStatus
  long m_Temperature

  ' Docking
  long m_DockSeq
  long m_FindLine  
  
  byte m_Buffer[32]
  long m_Stack[60]


OBJ

  Head          : "iHead"
  RfLink        : "FullDuplexSerial128"
  Sonar         : "SRF02"
  Drive         : "MotorArbiter"
  QTI           : "QTIEngine"
  Lcd           : "debug_lcd"

  
PUB Main | nextpriority
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
  
  ' Reset global variables
  MasterReset

  ' Start sensor scan (uses 1 cog)
  cognew(SensorScan, @m_Stack)
  Pause_ms(1000)
  
  ' LED off
  outa[Pin_Led]~

  ' Init menu 
  m_MenuItem := 0
  ShowMenuItem(m_MenuItem)
  
  ' Process Behavior Stacks
  repeat
    ' Default stack
    nextpriority := DefaultStack(0)

    ' Process additional selected behaviors or stacks
    if m_BehStack == BS_PaceFree
      PaceFreeStack(nextpriority)    
    
    if m_BehStack == BS_PaceBox
      PaceBoxStack(nextpriority)    
    
    if m_BehStack == BS_NavRoute
      NavRouteStack(nextpriority)    
    
    if m_BehStack == BS_LiFoDock
      DockStack(nextpriority)    
    
    ' Now arbitrate
    m_CurrentBehavior := Drive.Arbitrate


' ------------------------------------------------------------------------------
' BEHAVIOR STACK: Default
' ------------------------------------------------------------------------------
PRI DefaultStack(StartPriority) : NextPriority

  ProcessButtons(StartPriority++)
  ProcessRF(StartPriority++)
  
  NextPriority := StartPriority


' ------------------------------------------------------------------------------
' BEHAVIOR STACK: Dock
' ------------------------------------------------------------------------------
PRI DockStack(StartPriority) : NextPriority

  m_OnPad := true
  Dock(StartPriority++)
  
  NextPriority := StartPriority


' ------------------------------------------------------------------------------
' BEHAVIOR STACK: Navigate a Route
' ------------------------------------------------------------------------------
PRI NavRouteStack(StartPriority) : NextPriority 

  Blocked(StartPriority++)
  Navigate(StartPriority++)
  
  NextPriority := StartPriority
  

' ------------------------------------------------------------------------------
' BEHAVIOR STACK: Pace Free - pace back and forth while avoiding stuff
' ------------------------------------------------------------------------------
PRI PaceFreeStack(StartPriority) : NextPriority 

  Blocked(StartPriority++)
  Avoid(StartPriority++)
  Navigate(StartPriority++)
  
  NextPriority := StartPriority
  

' ------------------------------------------------------------------------------
' BEHAVIOR STACK: Pace in Box - Pace back and forth within a lined box while avoiding stuff
' ------------------------------------------------------------------------------
PRI PaceBoxStack(StartPriority) : NextPriority 

  Blocked(StartPriority++)
  Navigate(StartPriority++)
  Avoid(StartPriority++)
  
  NextPriority := StartPriority
  

' ------------------------------------------------------------------------------
' BEHAVIOR: User Button Commands/Menu System
'   Inhibitors: None
'   Triggers  : Select/Go Buttons
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI ProcessButtons(Priority) | btn,ptr

  btn := TestButton
  if btn == Pin_BtnGo
    ptr := @Tasks + (m_MenuItem * 16)
    m_MenuOp := byte[ptr][15]
    ExecuteMenuOp
    ShowMenuItem(m_MenuItem)
    if not Drive.IsPower
      Drive.PowerOn(Priority)

  elseif btn == Pin_btnSelect
    if Drive.GetDirection <> Drive#Mov_Halt
      m_BehStack := BS_Default
      Drive.HaltClear(Priority)
      if Drive.IsPower
        Drive.PowerOff(Priority)
      return
  
    ' Select next possible task
    m_MenuItem++
    if m_MenuItem == TotalTasks
      m_MenuItem := 0
    ShowMenuItem(m_MenuItem)
   
      
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
  

PRI ExecuteMenuOp | temp
    
  MasterReset
  
  case m_MenuOp
    MuOp_Default:
      m_BehStack := BS_Default
      
    MuOp_PaceFree:
      m_UseAvoidance := true
      m_Route := @PaceFree
      m_BehStack := BS_PaceFree
      
    MuOp_PaceBox:
      m_UseAvoidance := true
      m_Route := @PaceBox
      m_BehStack := BS_PaceBox
      
    MuOp_LiFoPPong:
      m_UseAvoidance := true
      m_Route := @PingPong
      m_BehStack := BS_NavRoute
    
    MuOp_NavRoute1:
      m_UseAvoidance := true
      m_Route := @GetBeer
      m_BehStack := BS_NavRoute
    
    MuOp_LiFoDock:
      m_BehStack := BS_LiFoDock

  m_MenuOp := MuOp_Idle


PRI ShowMenuItem(item)

  Lcd.clrln(1)
  SetLcdPos(1, 0)

  if(item <> -1)
    Lcd.str(@Tasks + (item * 16))
  else
    DisplayMsg(string("Select?"))


PRI MasterReset | i

  m_DockSeq := 0
  m_FindLine := false

  m_LastOp := 0
  m_LastOpStatus := 0

  m_LastLine := 0
  m_LostLineCt := 0
  m_IgnoreEOL := IgnoreEOL
  
  m_Route := 0
  m_Index := 0
  m_UseAvoidance := false
  m_OnPad := false


' ------------------------------------------------------------------------------
' BEHAVIOR: User RF Commands
'   Inhibitors: None
'   Triggers  : Receive RF command
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI ProcessRF(Priority) | data 

  data := RfLink.rxcheck

  ' Check for new RoboFridge status
  if data == "<" 
    GetFridgeStatus
      
  ' Commands
  if data == ">"
    if GetHeader
      if GetCmd
      ' Power on
        if strcomp(@m_Buffer, string("P1"))
          if not Drive.IsPower
            Drive.PowerOn(Priority)
          
      ' Power off
        if strcomp(@m_Buffer, string("p1"))
          if Drive.IsPower
            Drive.PowerOff(Priority)
       
      ' Execute "Pace Free" Route
        if strcomp(@m_Buffer, string("M1"))
          m_UseAvoidance := true
          m_Route := @PaceFree
          m_BehStack := BS_PaceFree
          if not Drive.IsPower
            Drive.PowerOn(Priority)
       
      ' Execute "Pace in Box" Route
        if strcomp(@m_Buffer, string("M2"))
          m_UseAvoidance := true
          m_Route := @PaceBox
          m_BehStack := BS_PaceBox
          if not Drive.IsPower
            Drive.PowerOn(Priority)
       
      ' Execute "Ping Pong" Route
        if strcomp(@m_Buffer, string("M3"))
          m_UseAvoidance := true
          m_Route := @PingPong
          m_BehStack := BS_NavRoute
          if not Drive.IsPower
            Drive.PowerOn(Priority)

      ' Execute "Get Beer" Route
        if strcomp(@m_Buffer, string("M4"))
          m_Route := @GetBeer
          m_BehStack := BS_NavRoute
          if not Drive.IsPower
            Drive.PowerOn(Priority)

      ' Cancel current active mode  
        if m_Buffer[0] == "m"
          m_BehStack := BS_Default
          Drive.Halt(Priority)
          if Drive.IsPower
            Drive.PowerOff(Priority)
       
      ' Lid Open
        if strcomp(@m_Buffer, string("F1"))
          Head.AdfHalt
          Head.LidOpen
          Pause_ms(4000)
          Head.LidClose
       
        if strcomp(@m_Buffer, string("S1"))
          Drive.SetSpeed(Priority, 10)
          
        if strcomp(@m_Buffer, string("S2"))
          Drive.SetSpeed(Priority, 20)
          
        if strcomp(@m_Buffer, string("S3"))
          Drive.SetSpeed(Priority, 30)
          
      ' Forward
        if strcomp(@m_Buffer, string("FW"))
          if not Drive.IsPower
            Drive.PowerOn(Priority)
          if Drive.GetDirection <> Drive#Mov_Halt and Drive.GetDirection <> Drive#Mov_Fwd
            Drive.Halt(Priority)
          Drive.Forward(Priority, 1000, false)
       
      ' Reverse
        if strcomp(@m_Buffer, string("BK"))
          if not Drive.IsPower
            Drive.PowerOn(Priority)
          if Drive.GetDirection <> Drive#Mov_Halt and Drive.GetDirection <> Drive#Mov_Rev
            Drive.Halt(Priority)
          Drive.Reverse(Priority, 1000, false)
                  
      ' Stop
        if strcomp(@m_Buffer, string("HL"))
          if(Drive.GetDirection == Drive#Mov_SpinCCW or Drive.GetDirection == Drive#Mov_SpinCW)
            Drive.HaltClear(Priority)
          else
            Drive.Halt(Priority)
          RfLink.rxflush
            
      ' Emergency Stop
        if strcomp(@m_Buffer, string("ES"))
          Drive.HaltClear(Priority)
          RfLink.rxflush
            
      ' Left
        if strcomp(@m_Buffer, string("LF"))
          if Drive.GetDirection == Drive#Mov_Fwd
            Drive.TurnLeft(Priority, TR_Veer)
          elseif Drive.GetDirection == Drive#Mov_Rev
            Drive.TurnRight(Priority, TR_Veer)
          elseif Drive.GetDirection == Drive#Mov_Halt
            Drive.SpinCCW(Priority, 360, false)
                         
      ' Left More
        if strcomp(@m_Buffer, string("L2"))
          if Drive.GetDirection == Drive#Mov_Fwd
            Drive.TurnLeft(Priority, TR_Quick)
          elseif Drive.GetDirection == Drive#Mov_Rev
            Drive.TurnRight(Priority, TR_Quick)
          elseif Drive.GetDirection == Drive#Mov_Halt
            Drive.SpinCCW(Priority, 360, false)
                         
      ' Right
        if strcomp(@m_Buffer, string("RT"))
          if Drive.GetDirection == Drive#Mov_Fwd
            Drive.TurnRight(Priority, TR_Veer)
          elseif Drive.GetDirection == Drive#Mov_Rev
            Drive.TurnLeft(Priority, TR_Veer)
          elseif Drive.GetDirection == Drive#Mov_Halt
            Drive.SpinCW(Priority, 360, false)
       
      ' Right
        if strcomp(@m_Buffer, string("R2"))
          if Drive.GetDirection == Drive#Mov_Fwd
            Drive.TurnRight(Priority, TR_Quick)
          elseif Drive.GetDirection == Drive#Mov_Rev
            Drive.TurnLeft(Priority, TR_Quick)
          elseif Drive.GetDirection == Drive#Mov_Halt
            Drive.SpinCW(Priority, 360, false)
       
       
PRI GetHeader : status | data

  status := false
  data := RfLink.rxtime(5000)
  if data == NetID
    data := RfLink.rxtime(5000)
    if data == DevID
      status := true
   
        
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


PRI GetFridgeStatus | data

  data := RfLink.rxtime(5000)
  if data == NetID
    data := RfLink.rxtime(5000)
    if data == RoboFridgeID
      if GetCmd
        m_LastOp := m_Buffer[0]
        m_LastOpStatus := m_Buffer[1]
        m_DoorStatus := m_Buffer[2]
        m_Cans := m_Buffer[3]
        m_Temperature := m_Buffer[4]
   

' ------------------------------------------------------------------------------
' BEHAVIOR: Blocked
'   Inhibitors: UseAvoidance, Current Direction
'   Triggers  : Closest Distance
'   Continuous: Yes
'   Self-Start: No
' ------------------------------------------------------------------------------
PRI Blocked(Priority) | av

  if m_UseAvoidance and Drive.GetDirection == Drive#Mov_Fwd and m_DistClosest < 12
    if m_DistBottom < 6
      Drive.HaltClear(Priority)
    else
      Drive.Halt(Priority)
      
          
' ------------------------------------------------------------------------------
' BEHAVIOR: Blocked2
'   Inhibitors: UseAvoidance, Current Direction
'   Triggers  : Closest Distance
'   Continuous: Yes
'   Self-Start: No
' ------------------------------------------------------------------------------
PRI Blocked2(Priority) | av

  if m_UseAvoidance and Drive.GetDirection == Drive#Mov_Fwd and m_DistClosest < 12
    if m_DistBottom < 6
      Drive.HaltClear(Priority)
    else
      Drive.Halt(Priority)
      
    av := m_Avoid
    ' Turn left or right
    if av == Avoid_Left
      Drive.SpinCW(Priority, 45, true)
    elseif av == Avoid_Right
      Drive.SpinCCW(Priority, 45, true)
    else
      Drive.SpinCCW(Priority, 180, true)
          
' ------------------------------------------------------------------------------
' BEHAVIOR: Avoid
'   Inhibitors: UseAvoidance, Current Direction
'   Triggers  : Left/Right proximity sensors
'   Continuous: Yes
'   Self-Start: No
' ------------------------------------------------------------------------------
PRI Avoid(Priority) | av

  if m_UseAvoidance and Drive.GetDirection == Drive#Mov_Fwd
    av := m_Avoid
    ' Turn left or right
    if av == Avoid_Left
      Drive.TurnRight(Priority, 10)
    elseif av == Avoid_Right
      Drive.TurnLeft(Priority, 10)
                        
          
' ------------------------------------------------------------------------------
' BEHAVIOR: Cruise
'   Inhibitors: Power, Current Direction
'   Triggers  : none
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI Cruise(Priority)

  if Drive.IsPower and Drive.GetDirection == Drive#Mov_Halt
    Drive.Forward(Priority, 1000, false)

  
' ------------------------------------------------------------------------------
' BEHAVIOR: Dock with RoboFridge Sequence
'   Inhibitors: Power, Current Direction
'   Triggers  : RoboFridge status, Dock sensor, Line Following sensors 
'   Continuous: No, done after all steps complete
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI Dock(Priority)

  case m_DockSeq
    ' Start docking sequence at Approach Pad
    0:
      if Drive.IsPower and Drive.GetDirection == Drive#Mov_Halt
        ' RoboFridge Open Door command
        RfLink.str(string(">R6F1",13))
        m_DockSeq++
        result := Ret_Continue

    ' Docking
    1:
      if IsDocked and Drive.GetDirection == Drive#Mov_Fwd
        Drive.Halt(Priority)
        m_DockSeq++

      elseif m_LastOp == RFOp_OpenDoor and m_LastOpStatus == RFST_OK
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.SetSpeed(Priority, 10)
          Drive.Forward(Priority, 1000, false)
          Head.LidOpen
        FollowLine(Priority)
        result := Ret_Continue

    ' Docked
    2:  
      ' RoboFridge Dispense Can command
      RfLink.str(string(">R6F3",13))
      m_DockSeq++
      result := Ret_Continue

    ' Undock
    3:  
      if m_LastOp == RFOp_Dispense and m_LastOpStatus == RFST_OK
        Drive.Reverse(Priority, 6, true)
        Drive.Pause(Priority, 500)
        m_DockSeq++
        result := Ret_Continue

    ' Close Lid
    4:
      Head. LidClose
      m_DockSeq++

    ' Reacquire the line
    5:
      Drive.SetSpeed(Priority, 15)
      if FindLine(Priority, Drive#Mov_SpinCCW) == Ret_Complete
        m_DockSeq++
       
    ' Drive away (follow line back to Approach Pad)
    6:
      if Drive.GetDirection == Drive#Mov_Fwd and IsEndOfLine
'        Drive.Halt(Priority)
        Head. LidClose
        m_DockSeq++
      else
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.Forward(Priority, 1000, false)
        FollowLine(Priority)
      result := Ret_Continue
            
    ' End docking sequence
    7:
      ' RoboFridge Close Door command
      RfLink.str(string(">R6F2",13))
      Drive.SetSpeed(Priority, Drive#DefaultSpeed)
      m_DockSeq++
      result := Ret_Complete

    other:
      result := Ret_Complete


' ------------------------------------------------------------------------------
' BEHAVIOR: Find Line by spinning in place
'   Inhibitors: Current Direction
'   Triggers  : Line sensors
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI FindLine(Priority, SpinDir)

  result := Ret_Continue
  if Drive.GetDirection == Drive#Mov_Halt
    if m_FindLine
      if SpinDir == Drive#Mov_SpinCW
        Drive.SpinCW(Priority, 20, true)
      else
        Drive.SpinCCW(Priority, 20, true)
        
      if GetLine > 0
        m_FindLine := false
        result := Ret_Complete
    else
      if SpinDir == Drive#Mov_SpinCW
        Drive.SpinCW(Priority, 20, true)
        Drive.SpinCW(Priority, 40, true)
        Drive.SpinCW(Priority, 60, true)
      else
        Drive.SpinCCW(Priority, 20, true)
        Drive.SpinCCW(Priority, 40, true)
        Drive.SpinCCW(Priority, 60, true)
      m_FindLine := true

      
' ------------------------------------------------------------------------------
' BEHAVIOR: Follow Line and Stop at EOL
'   Inhibitors: Current Direction
'   Triggers  : EOL/line sensors
'   Continuous: Yes
'   Self-Start: No
' ------------------------------------------------------------------------------
PRI StopAtEOL(Priority)

  result := Ret_Continue
  if Drive.GetDirection == Drive#Mov_Fwd
    if m_IgnoreEOL > 0
      m_IgnoreEOL--
    else
      if IsEndOfLine
        Drive.StopTurn(Priority)
        Drive.Pause(Priority, 500)
        Drive.Halt(Priority)

        m_LastLine := 0
        m_LostLineCt := 0
        m_IgnoreEOL := IgnoreEOL
        result := Ret_Complete


' ------------------------------------------------------------------------------
' BEHAVIOR: Follow Line
'   Inhibitors: Current Direction
'   Triggers  : Line following (QTI) sensors
'   Continuous: No, done after line is lost
'   Self-Start: No
' ------------------------------------------------------------------------------
PRI FollowLine(Priority) | line

  if Drive.GetDirection == Drive#Mov_Fwd 
    line := GetLine
  
    if line == 0
      m_LostLineCt++
    else
      m_LostLineCt := 0

    if m_LostLineCt > MaxLostLineCt
      ' Line has been lost for too long
      Drive.Halt(Priority)
      m_LastLine := 0
      return Ret_Complete
  
    case line
      0:  ' No line, get agressive
        if m_LastLine == 1
          Drive.TurnRight(Priority, 80)
          
        if m_LastLine == 3
          Drive.TurnRight(Priority, 80)

        elseif m_LastLine == 4
          Drive.TurnLeft(Priority, 80)

        elseif m_LastLine == 6
          Drive.TurnLeft(Priority, 80)
     
      1:  ' Far Right
        Drive.TurnRight(Priority, 20)

      2:  ' Center
        Drive.StopTurn(Priority)
        
      3:  ' Near Right
        Drive.TurnRight(Priority, 10)
        
      4:  ' Far Left
        Drive.TurnLeft(Priority, 20)
     
      6:  ' Near Left
        Drive.TurnLeft(Priority, 10)      
     
    m_LastLine := line

  return Ret_Continue


' ------------------------------------------------------------------------------
' BEHAVIOR: Goto Beacon
'   Inhibitors: None
'   Triggers  : Beacon bearing (from head)
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI GotoBeacon(Priority) | bearing,error,corr 

  ' Start beacon navigation if not running
  StartBNav
  
  ' Steer towards the beacon
  bearing := Head.GetAdfBearing
  if bearing > 0
  ' Start up if we are stopped
    if Drive.GetDirection == Drive#Mov_Halt
      Drive.Forward(Priority, 1000, false)

    ' Calculate drive (proportional) correction
    error := ((bearing - 90) / 3)
    corr := ||error
    corr <#= 30
      
    ' Correct for any error              
    if corr > 0
      if error > 0
        ' Right turn
        Drive.TurnRight(Priority, corr)
      else
        ' Left turn 
        Drive.TurnLeft(Priority, corr)
  else
    Drive.Halt(Priority)


PRI StartBNav

  if not m_BNav
    Head.SetAdfScanRange(45,135)
    Head.AdfScanMode
    m_UseAvoidance := true
    m_BNav := true


PRI StopBNav(Priority)

  Drive.Halt(Priority)
  Head.AdfHalt
  Head.SetAdfPosition(90)
  m_UseAvoidance := false
  m_BNav := false
  
           
' ------------------------------------------------------------------------------
' BEHAVIOR: Find Beacon
'   Inhibitors: None
'   Triggers  : Beacon sensor (from head)
'   Continuous: No, done after beacon found or timeout
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI FindBeacon(Priority, Turn) : status | dir,timeout

  ' Move away from the current beacon
  if Drive.GetDirection == Drive#Mov_Halt
    if Turn == Drive#Mov_SpinCW
      Drive.SpinCW(Priority, 360, false)
    else
      Drive.SpinCCW(Priority, 360, false)
    Drive.Pause(Priority, 1000)
    return Ret_Continue
    
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
  Drive.HaltClear(Priority)
  return Ret_Complete
  

' ------------------------------------------------------------------------------
' BEHAVIOR: Navigate (Route Execution Engine)
'   Inhibitors: Route
'   Triggers  : Depends on operator
'   Continuous: Yes
'   Self-Start: Yes
' ------------------------------------------------------------------------------
PRI Navigate(Priority) | opcode,status

  if m_Route > 0
    opcode := LONG[m_Route][m_Index]
    case opcode
      Op_GotoBeacon:
        GotoBeacon(Priority)
        if GetLine > 0
          m_OnPad := true
          StopBNav(Priority)
          m_Index++
        
      Op_FindBeacon:
        status := FindBeacon(Priority, LONG[m_Route][m_Index + 1])
        if status == Ret_Complete
          m_Index += 2

      Op_FollowLine:
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.Forward(Priority, 1000, false)
        status := FollowLine(Priority)
        if status == Ret_Complete
          m_Index++
        else
          status := StopAtEOL(Priority)
          if status == Ret_Complete
            m_Index++
            
      Op_FindLine:
        status := FindLine(Priority, LONG[m_Route][m_Index + 1])
        if status == Ret_Complete
          m_Index += 2
            
      Op_Dock:
        m_OnPad := true
        status := Dock(Priority)
        if status == Ret_Complete
          m_OnPad := false
          m_Index++
        
      Op_Halt:
        StopBNav(Priority)
        m_Index++

      Op_Fwd:
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.Forward(Priority, LONG[m_Route][m_Index + 1], false)
        elseif Drive.HasArrived
          m_Index += 2
          
      Op_Fwd2Line:
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.Forward(Priority, LONG[m_Route][m_Index + 1], false)
        elseif GetLine > 0
          Drive.Halt(Priority)
          m_Index += 2
        elseif Drive.HasArrived
          m_Index += 2
          
      Op_Rev:
        if Drive.GetDirection == Drive#Mov_Halt
          Drive.Reverse(Priority, LONG[m_Route][m_Index + 1], false)
        elseif Drive.HasArrived
          m_Index += 2
          
      Op_SpinCW:
        m_Index++
        Drive.SpinCW(Priority, LONG[m_Route][m_Index], true)
        m_Index++

      Op_SpinCCW:
        m_Index++
        Drive.SpinCCW(Priority, LONG[m_Route][m_Index], true)
        m_Index++

      Op_OpenLid:
        Head.AdfHalt
        Head.LidOpen
        m_Index++

      Op_CloseLid:
        Head.LidClose
        m_Index++

      Op_Pause:
        Head.AdfHalt
        m_Index++
        Pause_ms(LONG[m_Route][m_Index])
        m_Index++

      Op_Repeat:
        m_Index := 0

      Op_End:
        m_BehStack := 0
        MasterReset
        if Drive.IsPower
          Drive.PowerOff(Priority)
        
          
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
' Sonar Sensors
' ------------------------------------------------------------------------------

PRI GetDistance(sonarID) : dist

    sonar.initranging(sonarID)
    Pause_ms(70)
    dist := sonar.getrange(sonarID)

  
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


PRI IsEndOfLine : yesno

  yesno := false
  if QTI.readSensorDigital(QTI_EOL, LineThresholdEOL) == false
    if GetLine > 0
      yesno := true

    
' ------------------------------------------------------------------------------
' Docked Sensor
' ------------------------------------------------------------------------------
PRI IsDocked : yesno

  if ina[Pin_Docked] == 0
    yesno := true
  else
    yesno := false
                         
' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SendRfMsg(msg)

  RfLink.str(string("<R5"))
  RfLink.str(msg)
  RfLink.tx(13)

  
PRI DisplayMsg(msg)

  Lcd.clrln(1)
  SetLcdPos(1, 0)
  Lcd.str(msg)
    

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


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