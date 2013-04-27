{{ ADF2.spin }}

' ==============================================================================
'
'   File...... ADF2.spin
'   Purpose... Automatic Direction Finder an using IR beacon
'   Author.... (C) 2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 03/15/2007
'   Updated... 03/26/2010
'
' ==============================================================================

' Note: Switch editor to Documentation mode to read all the text.

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{


  Author: Steve Norris
  Email : steve@norrislabs.com
   
  This object is a reusable Automatic Direction Finder that determines the
  bearing (1-180) of an IR beacon.
  
  This object requires two Cogs.

  The Start, Stop and IsActive methods are used for Cog maintenance. The IR
  detector is mounted on a servo and they are connected to the pins specified in
  the call to the Start method. You can also specify an optional indicator LED.
  This LED will flash to indicate the detection of the IR beacon. 

  To use this object simply include it in the OBJ section of your application code.
  Be sure to call the Start method first before you call any of the other methods.

}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  0717a - This is the first version
  1012a - Updated version using PWM object
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  ScanLeft        = 0
  ScanRight       = 1

  ' Servo parameters (degrees)
  FullLeftPos     = 1
  CenterPos       = 90
  FullRightPos    = 180

  ' Servo parameters (servo units: 500 to 2500)
  CenterWidth     = 1480
  FullLeftWidth   = 580
  FullRightWidth  = 2380


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  ' Cog maintenance variables
  byte m_Cog
  long m_Stack[50]

  ' Object initialized flag
  byte m_Init

  ' Pins
  byte m_PinIR
  byte m_PinServo
  byte m_PinLed

  ' Scanning variables
  long m_StartPos
  long m_EndPos
  long m_CurrentPos

  long m_SetLeftPos
  long m_SetRightPos

  long m_MaxLeftPos
  long m_MaxRightPos

  long m_LockWidth
  
  byte m_ScanDir

  long m_IrStartLeft
  long m_IrStartRight

  long m_BeaconPos

  long m_ScanEnabled
  long m_Scanning
  long m_Locked
  long m_BeaconInScan

  long m_ServoUnitsPerDeg
  

OBJ

  Servo         : "Pwm_32_V2"


PUB Start(PinIR, PinServo, IndicatorLed) : Success
{{
  Starts the ADF in a seperate cog. Pass the pin numbers that are connected to
  the IR sensor,the servo and an optional indicator LED (pass -1 for no LED).
  Returns a true if the startup was successful.
}}
  
  m_PinIR := PinIR
  m_PinServo := PinServo
  m_PinLed := IndicatorLed
  
  m_ServoUnitsPerDeg := round(float(FullRightWidth - FullLeftWidth) / 180.0)
  
  Stop
  Success := (m_Cog := cognew(Main,@m_Stack) + 1) 
  m_Init := Success


PUB Stop
{{
  Stops the execution of the ADF.
}}

  if m_Cog
    Servo.Stop 
    cogstop(m_Cog~ - 1)



PUB IsActive :YesNo
{{
  Determines if the ADF is running in a cog.
}}

  YesNo := m_Cog > 0


PUB SetScanRange(LeftPos, RightPos)
{{
  Set the maximum left/right scan range.
}}

  m_MaxLeftPos := m_SetLeftPos := LeftPos
  m_MaxRightPos := m_SetRightPos := RightPos



PUB SetScanLockWidth(width)
{{
  Set the maximum left/right scan range.
}}

  m_LockWidth := width / 2


PUB SetPosition(Pos)
{{
  Sets the servo position of the IR detector.

  Pos - 1 to 180 degrees
}}

  Servo.Servo(m_PinServo, Deg2Width(Pos))
  

PUB Scan
{{
  Start scanning.
}}
  if not m_ScanEnabled
    m_MaxLeftPos := m_SetLeftPos
    m_MaxRightPos := m_SetRightPos
    
    m_IrStartLeft := 0
    m_IrStartRight := 0

    m_BeaconPos := 0

    FullLeft
    m_ScanEnabled := true


PUB Halt
{{
  Stop scanning.
}}

  if m_ScanEnabled
    m_ScanEnabled := false
    repeat while m_Scanning
      

PUB GetBearing : bearing
{{
  Returns the bearing of the IR beacon.

  0       - Beacon not found
  1..180  - Beacon at this bearing
 -1..-180 - Beacon at this bearing (low accuracy, single scan detect only)
}}

  if m_Init and m_ScanEnabled
    return m_BeaconPos
  else
    return 0


PUB IsBeacon : yesno
{{
  Determines if detecting the IR of a beacon.
}}

  yesno := IrDetected

  
PUB IsBeaconInScan : yesno
{{
  Determines if detected the IR signature of a beacon in last scan.
}}

  yesno := m_BeaconInScan

  
PUB IsScanning : yesno
{{
  Determines if currently scanning.
}}

  yesno := m_ScanEnabled
    

PUB IsLocked : yesno
{{
  Determines if locked onto an beacon.
}}

  yesno := m_Locked

  
PRI Main
' ------------------------------------------------------------------------------
' Main for the ADF
' ------------------------------------------------------------------------------

  ' Initialize servo
  Servo.Start
  SetPosition(90)

  m_Scanning := false
  m_ScanEnabled := false
  m_Locked := false
  
  m_MaxLeftPos := m_SetLeftPos := FullLeftPos
  m_MaxRightPos := m_SetRightPos := FullRightPos
  m_LockWidth := 15
  
  ' Setup indicator LED
  if m_PinLed => 0      
    dira[m_PinLed]~~
    outa[m_PinLed]~~
    Pause_ms(500)
    outa[m_PinLed]~

  repeat
    if m_ScanEnabled
      m_BeaconInScan := ScanOneDir
      if m_BeaconPos > 0
        ' Set scan parameters based on current beacon position
        m_MaxLeftPos := m_BeaconPos - m_LockWidth
        if m_MaxLeftPos < m_SetLeftPos
          m_MaxLeftPos := m_SetLeftPos
        m_MaxRightPos := m_BeaconPos + m_LockWidth
        if m_MaxRightPos > m_SetRightPos
          m_MaxRightPos := m_SetRightPos
        m_Locked := true
      else
        ' No beacon found
        m_MaxLeftPos := m_SetLeftPos
        m_MaxRightPos := m_SetRightPos
        m_Locked := false
    else
      if m_PinLed => 0      
        outa[m_PinLed]~
      m_Locked := false
         

PRI ScanOneDir : IrDetect | counter

  ' Setup the end position for this scan
  if m_ScanDir == ScanLeft
    m_EndPos := m_MaxLeftPos
  else
    m_EndPos := m_MaxRightPos

  ' Initialize IR first detect position
  counter := 0
  if m_ScanDir == ScanLeft
    m_IrStartLeft := 0
  else
    m_IrStartRight := 0

  IrDetect := false
  
  ' Scan in the current direction
  m_Scanning := true
  repeat m_CurrentPos from m_StartPos to m_EndPos
    if not m_ScanEnabled
      m_Scanning := false
      return
      
    if IrDetected
      counter++
      if counter == 1
        ' First time we detected IR in this scan direction
        IrDetect := true
        if m_ScanDir == ScanLeft
          m_IrStartLeft := m_CurrentPos
        else
          m_IrStartRight := m_CurrentPos
            
    SetPosition(m_CurrentPos)
    Pause_ms(8)

  m_Scanning := false

  ' If we detected IR in both directions, calculate the position of the beacon
  if m_IrStartLeft > 0 and m_IrStartRight > 0
    if m_IrStartLeft => m_IrStartRight
      ' Overlap
      m_BeaconPos := m_IrStartRight + ((m_IrStartLeft - m_IrStartRight) / 2)
    else
      ' Gap
      m_BeaconPos := m_IrStartLeft + ((m_IrStartRight - m_IrStartLeft) / 2)
  elseif m_IrStartLeft > 0
    m_BeaconPos := -m_IrStartLeft
  elseif m_IrStartRight > 0
    m_BeaconPos := -m_IrStartRight
  else
    m_BeaconPos := 0

  ' Setup for next scan
  m_StartPos := (m_CurrentPos <# FullRightPos) #> FullLeftPos
  if m_ScanDir == ScanLeft
    m_ScanDir := ScanRight
  else
    m_ScanDir := ScanLeft

  
PRI Deg2Width(deg) : width | u

  width := ((deg - 1) * m_ServoUnitsPerDeg) + FullLeftWidth
    

PRI IRDetected : yesno

  yesno := false

  if ina[m_PinIR] == 0
    yesno := true
  else
    Pause_ms(1)
    if ina[m_PinIR] == 0
      yesno := true
      
  if m_PinLed => 0
    if yesno      
      outa[m_PinLed]~~
    else
      outa[m_PinLed]~

      
PRI FullLeft
  m_ScanDir := ScanRight
  m_StartPos := m_MaxLeftPos
  SetPosition(m_StartPos)
  Pause_ms(500)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))


PRI Pause_us(usDelay)
  waitcnt(cnt + ((clkfreq / 1000000) * usDelay))
  