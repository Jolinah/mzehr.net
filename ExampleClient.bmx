SuperStrict

Framework brl.blitz
Import brl.basic
Import brl.glmax2d

'Import the module
Import mzehr.net

AppTitle = "Client"
SeedRnd(MilliSecs())

'Some constants for the different types of network messages
Const MSG_LOGIN:Int = 1
Const MSG_NEWPLAYER:Int = 2
Const MSG_REMOVEPLAYER:Int = 3
Const MSG_KEYSTATE:Int = 4
Const MSG_PLAYERSTATE:Int = 5

'Class containing player information
Type TPlayer
	'List containing all players
	Global List:TList = New TList

	Field Name:String
	
	'Position
	Field X:Float
	Field Y:Float
	
	'Target position
	Field TargetX:Float
	Field TargetY:Float

	Field Initialized:Int
	
	Method New()
		'Add the new player to the list
		List.AddLast(Self)
	End Method
	
	Method Update(deltaTime:Float)
		'Adjust the position smoothly over time (linear interpolation)
		X = Interpolate(X, TargetX, 2.0 * deltaTime)
		Y = Interpolate(Y, TargetY, 2.0 * deltaTime)
	End Method
	
	Method Draw()
		Local px:Int = Int(X)
		Local py:Int = Int(Y)
	
		DrawText(Name, px - TextWidth(Name) / 2, py - 40 - TextHeight(Name))
		DrawOval(px - 10, py - 40, 20, 20)
		DrawLine(px, py - 30, px, py + 10)
		DrawLine(px, py - 10, px - 20, py - 30)
		DrawLine(px, py - 10, px + 20, py - 30)
		DrawLine(px, py + 10, px - 20, py + 30)
		DrawLine(px, py + 10, px + 20, py + 30)
	End Method
End Type

'Create a new client
Global client:TNetClient = TNetClient.Create()

'Create the local player
Local myPlayer:TPlayer = New TPlayer
myPlayer.Name = "Guest" + Rand(1000, 9999)

'Connect to the server
If client.Connect("localhost", 50000)
	'Create the login packet
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(MSG_LOGIN)
	paket.WriteString(myPlayer.name)
	
	'Send the packet to the server (reliable, on channel 1)
	client.Send(paket, True, 1)
	
	'Await the response from the server (wait for a maximum time of 2 seconds)
	Local event:TNetClientEvent = client.Update(2000)
	
	'Data received
	If event <> Null And event.event = TNetClientEvent.DATA
		
		'Read the response from the server
		Local msgId:Byte = event.Packet.ReadByte()
		If msgId = MSG_LOGIN
			Local loggedIn:Int = event.Packet.ReadByte()
			If loggedIn
				Local numPlayers:Int = event.Packet.ReadInt()
				For Local i:Int = 0 To numPlayers - 1
					'Read existing player information
					Local name:String = event.Packet.ReadString()
					Local x:Float = event.Packet.ReadFloat()
					Local y:Float = event.Packet.ReadFloat()
					
					'Create a player object for each existing player
					Local player:TPlayer = New TPlayer
					player.name = name
					player.X = x
					player.Y = y
					player.TargetX = x
					player.TargetY = y
				Next
			Else
				'Login failed
				Local error:String = event.Packet.ReadString()
				client.Disconnect()
				Notify(error)
				End
			End If
		Else
			client.Disconnect()
			Notify("The server responded with an invalid message id. Protocol error?")
			End
		End If
	Else
		client.Disconnect()
		Notify("The server did not respond to the login within 2 seconds. Connection failed.")
		End
	End If
Else
	Notify "Could not connect to the server."
	End
End If

'At this point the connection is established and the local player successfully logged in.

Graphics 800, 600, 0

'Buffer of key states
Local keyState:Byte[] = New Byte[256]

'App will be quit if this variable is set to a quit reason
Local quitApp:String = Null

'Frame measurement for frame independent movement
Local deltaTime:Float = 0
Local lastFrame:Int = MilliSecs()

Repeat
deltaTime = (MilliSecs() - lastFrame) / 1000.0
lastFrame = MilliSecs()
Cls

	'Send messages to the server whenever the key down state changes
	UpdateKey(KEY_UP, keyState[KEY_UP])
	UpdateKey(KEY_DOWN, keyState[KEY_DOWN])
	UpdateKey(KEY_LEFT, keyState[KEY_LEFT])
	UpdateKey(KEY_RIGHT, keyState[KEY_RIGHT])

	'Update the client (receive/send)
	Local event:TNetClientEvent = client.Update()
	While event <> Null
		Select event.event
			Case TNetClientEvent.DISCONNECT
				quitApp = "The server has closed the connection."
			
			'Data received form the server
			Case TNetClientEvent.DATA
				ProcessData(event)
				
		End Select
	
		'Fetch next event (if any)
		event = client.Update()
	Wend

	
	'Update and draw all players
	For Local player:TPlayer = EachIn TPlayer.List
		player.Update(deltaTime)
		player.Draw()
	Next

Flip -1
Until AppTerminate() Or KeyHit(KEY_ESCAPE) Or quitApp <> Null

EndGraphics

client.Disconnect()

'If there is a quit reason, show a message box
If quitApp <> Null Then Notify(quitApp)

End

Function FindPlayer:TPlayer(name:String)
	name = name.ToLower()

	For Local player:TPlayer = EachIn TPlayer.List
		If player.name.ToLower() = name Then Return player
	Next
	
	Return Null
End Function

Function UpdateKey(code:Int, lastState:Byte Var)
	Local update:Int = False

	If KeyDown(code) And Not lastState Then
		lastState = True
		update = True
	Else If lastState And Not KeyDown(code) Then
		lastState = False
		update = True
	End If
	
	If update Then
		'Create a packet containing the key down state of the key
		Local paket:TNetPacket = TNetPacket.Create()
		paket.WriteByte(MSG_KEYSTATE)
		paket.WriteByte(code)
		paket.WriteByte(lastState)
		
		'Send the packet (reliable, on channel 1)
		client.Send(paket, True, 1)
	End If
End Function

Function ProcessData(event:TNetClientEvent)
	Local msgId:Byte = event.Packet.ReadByte()
	
	Select msgId
		Case MSG_NEWPLAYER
			'Read player information
			Local name:String = event.Packet.ReadString()
			Local x:Float = event.Packet.ReadFloat()
			Local y:Float = event.Packet.ReadFloat()

			'Create a player
			Local player:TPlayer = New TPlayer
			player.Name = name
			player.X = x
			player.Y = y
			player.TargetX = x
			player.TargetY = y
			
		Case MSG_REMOVEPLAYER
			Local name:String = event.Packet.ReadString()
			
			'Remove the player with the given name
			Local player:TPlayer = FindPlayer(name)
			If player <> Null Then TPlayer.List.Remove(player)
				
		Case MSG_PLAYERSTATE
			Local numPlayers:Int = event.Packet.ReadInt()
			
			For Local i:Int = 0 To numPlayers - 1
				'Read player information
				Local name:String = event.Packet.ReadString()
				Local x:Float = event.Packet.ReadFloat()
				Local y:Float = event.Packet.ReadFloat()
				
				'Find the player by name and update his target position
				Local player:TPlayer = FindPlayer(name)
				If player <> Null Then
					If Not player.Initialized
						player.X = x
						player.Y = y
						player.Initialized = True
					End If
					player.TargetX = x
					player.TargetY = y
				End If
			Next
	End Select
End Function

'Linear interpolation
Function Interpolate:Float(aktuell:Float, neu:Float, faktor:Float)
	faktor = Clamp01(faktor)
	Return ((1.0 - faktor) * aktuell) + (faktor * neu)
End Function

Function Clamp01:Float(wert:Float)
	If wert < 0.0 Then Return 0.0
	If wert > 1.0 Then Return 1.0
	Return wert
End Function
