
Rem
bbdoc: An event raised by the client.
End Rem
Type TNetClientEvent
	Rem
	bbdoc: Server: A new client has established a connection with the server. | Client: The connection with the server has been established.
	End Rem
	Const CONNECT:Int = 1

	Rem
	bbdoc: The connection was closed (client: connection with the server | server: connection with a specific client).
	End Rem
	Const DISCONNECT:Int = 2
	
	Rem
	bbdoc: Data received (client: from the server | server: from a specific client).
	End Rem
	Const DATA:Int = 3
	
	Rem
	bbdoc: Event that was raised (equals to TNetClientEvent.CONNECT or DATA).
	End Rem
	Field Event:Int
	
	Rem
	bbdoc: The packet that was received (only available in a DATA event).
	End Rem
	Field Packet:TNetPacket
	
	Rem
	bbdoc: The channel on which the packet was received.
	End Rem
	Field Channel:Int
	
	Function ClientEvent:TNetClientEvent(event:Int, packet:TNetPacket, channel:Int)
		Local ev:TNetClientEvent = New TNetClientEvent
		ev.event = event
		ev.packet = packet
		ev.channel = channel
		Return ev
	End Function
End Type

Rem
bbdoc: An event raised by the server.
End Rem
Type TNetServerEvent Extends TNetClientEvent
	Rem
	bbdoc: The client that received data/connected/disconnected.
	End Rem
	Field Peer:TNetPeer
	
	Function ServerEvent:TNetServerEvent(event:Int, packet:TNetPacket, peer:TNetPeer, channel:Int)
		Local ev:TNetServerEvent = New TNetServerEvent
		ev.event = event
		ev.packet = packet
		ev.peer = peer
		ev.channel = channel
		Return ev
	End Function
End Type