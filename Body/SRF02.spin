'' ******************************************************************************
'' * SRF02 Object                                                               *
'' *   Modified to handle multiple Sonars                                       *
'' * based on SRF08 Object                                                      *
'' * James Burrows May 2006                                                     *
'' * Version 1.1                                                                *
'' ******************************************************************************
''
'' NOTE: DeviceAddress should be passed as 0..4 for five sonars
''
'' this object provides the PUBLIC functions:
''  -> Init  - sets up the address and inits sub-objects such
''  -> Start - try a re-start.
''  -> geti2cError - return the i2cobject error
''  -> isStarted - return the start status
''  -> getSwVersion  - read register 0 - the device revision
''  -> setSRFRangingMode - set the ranging mode
''  -> getRangingMode  - return the ranging mode
''  -> getSRFRange - get the max range returnable (sets the pulse timeout)
''  -> getLight - read the light.  Must be done after a "initranging"
''  -> initRanging - initiate a pulse.
''  -> DataReady - is the distance/light data ready.
''
'' this object provides the PRIVATE functions:
''  -> None
''
'' this object uses the following sub OBJECTS:
''  -> i2cObject
''
'' Revision History:
''  -> V1   - Release
''  -> V1.1 - Updated to allow i2cSCL line driving pass-true to i2cObject
''
'' SRF08 from Devantech Ltd - http://www.robotelectronics.co.uk 
''
'' Default address is %1110_0010


CON
  _SRF_CmdReg    = 0
  _SRF_SwReg     = 0  
  _SRF_InchRange = 80
  _SRF_CM_Range  = 81
  _SRF_Light     = 1
  _SRF_Distance  = 2
  ' approx SRF ranging values
  _SRF_Range1M   = 24     ' 24
  _SRF_Range3M   = 24 * 3 ' 72 
  _SRF_Range6M   = 24 * 6 ' 144
  _SRF_Range11M  = 255    ' maximum range

VAR
  'long  SRF08Address
  long  started
  long  SRF_rangingMode
  long  SRF_range
  long  SRF_LastRange
  long  SRF_LastLight
  

OBJ
  i2cObject   : "i2cObject"

PUB Init(_i2cSDA,_i2cSCL): okay | x
  ' update object parameters
  SRF_rangingMode := _SRF_InchRange
  SRF_range := _SRF_Range3M
  i2cObject.init(_i2cSDA,_i2cSCL,0)

  repeat x from 0 to 4
    InitRanging(x)  

  ' start
  started := true
  okay := started
    
  return okay  


PUB devicePresent(son) : okay
  okay:=false
  ' check if device is present before allowing initialization
  if started == true
    okay := i2cObject.devicePresent(SONAR_ADDRESSES[son])
  return okay


PUB stop
  ' stop the object
  if started == true
    started := false


PUB isStarted : result
  return started


PUB geti2cError : errorCode
  return i2cObject.getError

  
PUB getSwVersion(son) : version
  ' read the SRF's version register
  if started == true
    version := i2cObject.readLocation(SONAR_ADDRESSES[son], _SRF_SwReg,8,8)
    return version

 
PUB getRange(son) : result

  if started == true
    i2cObject.i2cStart
    i2cObject.i2cWrite(SONAR_ADDRESSES[son] | 0,8)
    i2cObject.i2cWrite(2,8)
    i2cObject.i2cStart
    i2cObject.i2cWrite(SONAR_ADDRESSES[son] | 1,8)
    SRF_LastRange := 0
    SRF_LastRange := i2cObject.i2cRead(i2cObject#_i2cACK)
    SRF_LastRange <<= 8
    SRF_LastRange := SRF_LastRange + i2cObject.i2cRead(i2cObject#_i2cNAK)
    i2cObject.i2cStop
      
    return (SRF_LastRange)


PUB initRanging(son) : result | ackbit

  if started == true
    i2cObject.i2cStart
    i2cObject.i2cwrite(SONAR_ADDRESSES[son],8)
    i2cObject.i2cwrite(_SRF_CmdReg,8)
    i2cObject.i2cwrite(SRF_rangingMode,8)
    i2cObject.i2cStop
     
    ' data will be available in 65ms
    return result  


PUB SetAddress(sonFrom, sonTo)

  if started == true
    i2cObject.writeLocation(SONAR_ADDRESSES[sonFrom], 0, $A0, 8, 8)
    i2cObject.writeLocation(SONAR_ADDRESSES[sonFrom], 0, $AA, 8, 8)
    i2cObject.writeLocation(SONAR_ADDRESSES[sonFrom], 0, $A5, 8, 8)
    i2cObject.writeLocation(SONAR_ADDRESSES[sonFrom], 0, SONAR_ADDRESSES[sonTo], 8, 8)
     

PUB dataReady(son) : result | dev_ready
  ' if the SRF08 is busy it will not drive the SDA
  ' line - so you get a 255 back.
  ' when it goes to < 255 then the result is ready
  if started == true
    if getSwVersion(son) == 255
      dev_ready := false
    else
      dev_ready := true
    return dev_ready


DAT

SONAR_ADDRESSES         byte    $E0, $E2, $E4, $E6, $E8                ' 5 sonars