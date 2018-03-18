SuperStrict

Framework brl.blitz
Import brl.basic
Import brl.glmax2d

'Import the module
Import mzehr.net

AppTitle = "Server"
SeedRnd(MilliSecs())

'Some constants for the different types of network messages
Const MSG_LOGIN:Int = 1
Const MSG_NEWPLAYER:Int = 2
Const MSG_REMOVEPLAYER:Int = 3
Const MSG_KEYSTATE:Int = 4
Const MSG_PLAYERSTATE:Int = 5

'Class containing player information
Type TPlayer
	Field Name:String
	
	'Key states
	Field Keys:Byte[]
	
	'Position
	Field X:Float
	Field Y:Float
	
	Method New()
		Keys = New Byte[256]
	End Method

	'Sets the key state of a specific key
	Method SetKey(code:Int, pressed:Int)
		If code >= 0 And code < Keys.Length Then
			Keys[code] = pressed
		End If
	End Method
	
	'Gets the key state of a specific key
	Method GetKey:Int(code:Int)
		If code >= 0 And code < Keys.Length Then Return Keys[code]
		Return False
	End Method
End Type

'Create a server on port 50000 with a maximum of 10 clients/players
Global server:TNetServer = TNetServer.Create(Null, 50000, 10)
If server = Null Then
	Notify("The server could not be initialized. Maybe the port is already in use?")
	End
End If

Graphics 200, 200, 0

'Variables for position updates to players
Local lastPosUpdate:Int = 0
Local numPosUpdates:Int = 10

'Frame measurement for frame independent movement
Local deltaTime:Float = 0
Local lastFrame:Int = MilliSecs()

Repeat
deltaTime = (MilliSecs() - lastFrame) / 1000.0
lastFrame = MilliSecs()
Cls
	'Update the server (receive/send)
	Local event:TNetServerEvent = server.Update()
	While event <> Null
	
		Select event.event
			'A new client connected to the server
			Case TNetServerEvent.CONNECT
				'Create a player object
				Local player:TPlayer = New TPlayer
				player.X = Rand(20, 780)
				player.Y = Rand(20, 580)
				
				'Assign it to the peer object
				event.Peer.SetData(player)
				
				'Other players will be informed about the new player only after a successful login
				
			'A client disconnected from the server
			Case TNetServerEvent.DISCONNECT
				'Tell all other clients that this player has left
				SendPlayerDisconnected(event)
			
				'Remove the player from the peer object
				event.Peer.SetData(Null)
				
			
			'Received data from a client
			Case TNetServerEvent.DATA
				'Fetch the previously created player object (on CONNECT) from the peer object
				Local player:TPlayer = TPlayer(event.Peer.GetData())

				If player.Name = Null Then
					'If the player does not have a name yet, only messages of type MSG_LOGIN will be accepted.
					ProcessData_NotLoggedIn(event)
				Else
					'After the player has successfully logged in, we will accept different messages.
					ProcessData_LoggedIn(event)
				End If
		End Select
		
		event = server.Update()
	Wend
	
	'Update all players
	For Local peer:TNetPeer = EachIn server.GetClients()
		Local player:TPlayer = TPlayer(peer.GetData())

		'Move them 200 pixels/second based on their key states
		player.X:+player.GetKey(KEY_LEFT) * -200 * deltaTime + player.GetKey(KEY_RIGHT) * 200 * deltaTime;
		player.Y:+player.GetKey(KEY_UP) * -200 * deltaTime + player.GetKey(KEY_DOWN) * 200 * deltaTime;
		
		'Limit the position on the x axis
		If player.X < 0
			player.X = 0
		ElseIf player.X > 800
			player.X = 800
		EndIf
		
		'Limit the position on the y axis
		If player.Y < 0
			player.Y = 0
		ElseIf player.Y > 600
			player.Y = 600
		End If
	Next
	
	'Send numPosUpdates position updates per second to all clients
	If MilliSecs() - lastPosUpdate > 1000 / numPosUpdates
	
		'Create a packet containing all player information
		Local paket:TNetPacket = TNetPacket.Create()
		paket.WriteByte(MSG_PLAYERSTATE)
		paket.WriteInt(server.GetClients().Count())
		
		For Local peer:TNetPeer = EachIn server.GetClients()
			Local player:TPlayer = TPlayer(peer.GetData())
			paket.WriteString(player.Name)
			paket.WriteFloat(player.X)
			paket.WriteFloat(player.Y)
		Next
		
		'Send the packet to all clients (unreliable, on channel 0)
		server.Broadcast(paket)
	
		lastPosUpdate = MilliSecs()
	EndIf

Flip -1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

EndGraphics

'Stop the server
server.Shutdown()
End

Function ProcessData_NotLoggedIn(event:TNetServerEvent)
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	Local msgId:Byte = event.Packet.ReadByte()

	Select msgId
		Case MSG_LOGIN
			Local name:String = event.Packet.ReadString()
			
			If name = Null Or name.Length < 3 Then
				'Player name is too short, reply with a negative response
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(MSG_LOGIN)
				paket.WriteByte(0)
				paket.WriteString("The name is too short.")
				
				'Send packet (reliable, on channel 1)
				server.Send(event.Peer, paket, True, 1)
				
			ElseIf FindPlayer(name) <> Null
				'The name is already in use by another player, reply with a negative response
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(MSG_LOGIN)
				paket.WriteByte(0)
				paket.WriteString("The name is already in use by another player.")
				
				'Send packet (reliable, on channel 1)
				server.Send(event.Peer, paket, True, 1)
			
			Else
				'Login ok
				player.name = name
				
				'Create a packet with a positive response
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(MSG_LOGIN)
				paket.WriteByte(1)
				
				'Append information of all other players
				paket.WriteInt(server.GetClients().Count() - 1)
				For Local peer:TNetPeer = EachIn server.GetClients()
					If peer = event.peer Then Continue
					
					Local p:TPlayer = TPlayer(peer.GetData())
					paket.WriteString(p.name)
					paket.WriteFloat(p.X)
					paket.WriteFloat(p.Y)
				Next
				
				'Send packet (reliable, on channel 1)
				server.Send(event.Peer, paket, True, 1)

				'Inform existing players about the new player
				SendPlayerConnected(event)
			EndIf
	End Select
End Function

Function ProcessData_LoggedIn(event:TNetServerEvent)
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	Local msgId:Byte = event.Packet.ReadByte()

	Select msgId
		Case MSG_KEYSTATE
			'Read key state
			Local code:Byte = event.Packet.ReadByte()
			Local pressed:Byte = event.Packet.ReadByte()
			
			'Update the key state on the player object
			player.SetKey(code, pressed)
				
	End Select
End Function

Function FindPlayer:TPlayer(name:String)
	name = name.ToLower()

	For Local peer:TNetPeer = EachIn server.GetClients()
		Local player:TPlayer = TPlayer(peer.GetData())
		
		If player <> Null And player.name.ToLower() = name Then Return player
	Next

	Return Null
End Function

Function SendPlayerConnected(event:TNetServerEvent)
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	'Create a packet containing the information of the local player
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(MSG_NEWPLAYER)
	paket.WriteString(player.Name)
	paket.WriteFloat(player.X)
	paket.WriteFloat(player.Y)
	
	'Send packet to all other clients (reliable, on channel 1)
	For Local client:TNetPeer = EachIn server.GetClients()
		If client = event.Peer Then Continue
		
		server.Send(client, paket, True, 1)
	Next
End Function

Function SendPlayerDisconnected(event:TNetServerEvent)
	Local player:TPlayer = TPlayer(event.Peer.GetData())
	
	'Create a packet containing the name of the local player
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(MSG_REMOVEPLAYER)
	paket.WriteString(player.Name)
	
	'Send packet to all other clients (reliable, on channel 1)
	For Local client:TNetPeer = EachIn server.GetClients()
		If client = event.Peer Then Continue
		
		server.Send(client, paket, True, 1)
	Next
End Function
