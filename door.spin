'
' NOTICE: Change the value for SetMAC, SetGetway, SetSubnet, and SetIP to match your network!!!
'
' Show how to get data from a form using the "GET" method
' Your inputs must be named "0" thru "9" for example
'   Name: <INPUT NAME="0"><BR>
'   City: <INPUT NAME="1"><BR>
'
'  VarExists[0] will be 1 if input "0" was sent otherwise it will be zero (same for "1" thru "9")
'  VarStr[0] will be a pointer to the string entered for the input (same for "1" thru "9")
'  Unchecked checkboxes do NOT return the input, checked checkboxes return the string "on"
'
' The variable VarFilename is a pointer to the filename specified in the URL (without the "/" prefix)
'
' If you have more than 10 inputs, you should probably be using the POST method
'
CON
  _clkmode = xtal1 + pll16x     'Use the PLL to multiple the external clock by 16
  _xinfreq = 5_000_000          'An external clock of 5MHz. is used (80MHz. operation)

  ServoCh1 = 24                                        'Pin that the servo is on

CON
  CR            = 13
  LF            = 10
  QUOTE         = 34
  _bytebuffersize = 2048


VAR

  'Configuration variables for the W5100
  byte  MAC[6]                  '6 element array contianing MAC or source hardware address ex. "02:00:00:01:23:45"
  byte  Gateway[4]              '4 element array containing gateway address ex. "192.168.0.1"
  byte  Subnet[4]               '4 element array contianing subnet mask ex. "255.255.255.0"
  byte  IP[4]                   '4 element array containing IP address ex. "192.168.0.13"
  long  localSocket             '1 element for the socket number

  'Variables to info for where to return the data to
  byte  destIP[4]               '4 element array containing IP address ex. "192.168.0.16"
  long  destSocket              '1 element for the socket number

  'Misc variables
  byte  data[_bytebuffersize]


  ' Get variables 0 thru 9
  long VarFilename ' pointer to string
  byte VarExists[10]
  long VarStr[10]   ' pointer to string 

  ' Status of the door
  byte status
OBJ
  ETHERNET      : "Brilldea_W5100_Indirect_Driver_Ver006.spin"
  SERVO         : "Servo32v7.spin"

PUB main 

  'Set up the servo, set it to neutral
   SERVO.Start
   SERVO.Ramp
   SERVO.SetRamp(ServoCh1,1500,200)

  'Start the W5100 driver on Parallax Web Server module
  ETHERNET.StartINDIRECT(0, 8, 9, 12, 11, 10, 14, 15)

  SetMAC($00, $08, $DC, $16, $EF, $B9) ' !!! CHANGE TO MATCH YOUR NETWORK !!!
  SetGateway(192, 168, 1, 1)           ' !!! CHANGE TO MATCH YOUR NETWORK !!!
  SetSubnet(255, 255, 255, 0)          ' !!! CHANGE TO MATCH YOUR NETWORK !!!
  SetIP(192, 168, 1, 252)              ' !!! CHANGE TO MATCH YOUR NETWORK !!!

  localSocket := 80 
  destSocket := 80  

  'Infinite loop of the server
  repeat
    ETHERNET.SocketOpen(0, ETHERNET#_TCPPROTO, localSocket, destSocket, @destIP[0])
    ETHERNET.SocketTCPlisten(0)
    repeat while !ETHERNET.SocketTCPestablished(0)
    bytefill(@data, 0, _bytebuffersize)
    WaitCnt(clkfreq / 100 + cnt) ' 10mSec    
    ETHERNET.rxTCP(0, @data)

    if data[0] == "G" ' Assume a GET request
      ParseURL

      'Send the web page - hardcoded here
      'status line
      StringSend(0, string("HTTP/1.1 200 OK", CR, LF))
       
      'optional header
      StringSend(0, string("Server: Parallax Spinneret Web Server", CR))
      StringSend(0, string("Connection: close", CR))
      StringSend(0, string("Content-Type: text/html", CR, LF))

      StringSend(0, string(CR, LF))

      if (byte[VarStr[1]] <> 0)
        if (byte[VarStr[1]] == "o")
          SERVO.SetRamp(ServoCh1,500,200)
          status := "1"
        if (byte[VarStr[1]] == "c")
          SERVO.SetRamp(ServoCh1,2300,200)
          status := "0"

      if (status == "0")
        StringSend(0, string("closed", CR))
      if (status == "1")
        StringSend(0, string("opened", CR))
      StringSend(0, string(CR, LF))

    ETHERNET.SocketTCPdisconnect(0)
    ETHERNET.SocketClose(0)

  return 'end of main
  

PRI SetMAC(p0, p1, p2, p3, p4, p5)
  MAC[0] := p0
  MAC[1] := p1
  MAC[2] := p2
  MAC[3] := p3
  MAC[4] := p4
  MAC[5] := p5
  ETHERNET.WriteMACaddress(true, @MAC[0])
   return 'end of SetMAC


PRI SetGateway(p0, p1, p2, p3)
  Gateway[0] := p0
  Gateway[1] := p1
  Gateway[2] := p2
  Gateway[3] := p3
  ETHERNET.WriteGatewayAddress(true, @Gateway[0])
  return 'end of SetGateway


PRI SetSubnet(p0, p1, p2, p3)
  Subnet[0] := p0
  Subnet[1] := p1
  Subnet[2] := p2
  Subnet[3] := p3
  ETHERNET.WriteSubnetMask(true, @SubNet[0])
  return 'end of SetSubnet


PRI SetIP(p0, p1, p2, p3)
  IP[0] := p0
  IP[1] := p1
  IP[2] := p2
  IP[3] := p3
  ETHERNET.WriteIPAddress(true, @IP[0])
  return 'end of SetIP


PRI StringSend(_socket, _dataPtr)
  if byte[_dataPtr] <> 0
    ETHERNET.txTCP(_socket, _dataPtr, strsize(_dataPtr))
  return 'end of StringSend


PRI ParseURL | char, inPlace, outPlace  ' !!! NOTICE - THIS MODIFIES data[] !!! 
  inPlace := 4 ' skip "GET "
  VarFileName := @data[5] ' Skip "GET /"
  
  repeat char from 0 to 9
    VarExists[char] := 0
    VarStr[char] := @EmptyStr

  repeat until (char == "?") or (char == " ")
    char := data[inPlace++]

  data[inPlace-1] := 0 ' String terminator for filename string
  outPlace := inPlace

  if char == "?"
    repeat until char == " "
      char := data[inPlace]
      if (char =< "9") and (char => "0")
        char := char - 48
        VarExists[char] := 1
        inPlace+=2 ' skip "x="
        VarStr[char] := @data[outPlace]   
        char := data[inPlace]
        if (char <> "&") and (char <> " ")
          data[outPlace++] := char
      repeat until (char == "&") or (char == " ")
        inPlace++
        char := data[inPlace]
        if (char <> "&") and (char <> " ")
          if char == "%"
            inPlace++
            char := data[inPlace++] - 48
            if char > 9
              char-=7
            char := char << 4
            data[outPlace]:=char
            char := data[inPlace] - 48
            if char > 9
              char-=7
            data[outPlace++]+=char
            char := "x" 
          else
            if char == "+"
              data[outPlace++] := " "
            else
              data[outPlace++] := char  
      data[outPlace++] := 0 ' String terminator
      inPlace++  
  return
  
DAT
  EmptyStr BYTE 0
    
