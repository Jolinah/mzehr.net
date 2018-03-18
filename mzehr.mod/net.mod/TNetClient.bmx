
Rem
bbdoc: Class used to establish a connection with a server.
End Rem
Type TNetClient
	Field _host:Byte Ptr
	Field _peer:Byte Ptr
	
	Rem
	bbdoc: Creates a new and unconnected client.
	End Rem
	Function Create:TNetClient()
		Local client:TNetClient = New TNetClient
		Return client
	End Function

	Rem
	bbdoc: Establishes a connection with a server.
	returns: True if the connection has been established, False if not.
	about:
	<pre>
	host:String			IP address or hostname on which to listen for incoming connections.
	port:Int			Port on which to listen for incoming connections.
	connectTimeout:Int		(Optional) Maximum time in ms to wait for the connection.
	channelCount:Int		(Optional) Number of communication channels. Will be limited to 1-255. (Default: 2)
	</pre>
	End Rem
	Method Connect:Int(host:String, port:Int, connectTimeout:Int = 5000, channelCount:Int = 2)
		'In case we are connected -> disconnect
		Disconnect()
		
		'Create address struct
		Local addr:Byte Ptr = enet_address_create(0, port)
		If addr = Null Then Return False
		enet_address_set_host(addr, host)

		If channelCount < ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT
			channelCount = ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT
		ElseIf channelCount > ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT
			channelCount = ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT
		End If
				
		'Create host
		_host = enet_host_create(Null, 1, channelCount, 0, 0)
		If _host = Null Then Return False

		'Connect to the remote host
		_peer = enet_host_connect(_host, addr, channelCount)
		enet_address_destroy(addr)

		'No peer available for connection?
		If _peer = Null Then
			enet_host_destroy(_host)
			_host = Null
			Return False
		EndIf
		
		Local ev:ENetEvent = New ENetEvent
		
		'Wait for connection response
		If enet_host_service(_host, ev, connectTimeout) > 0 And ev.event = TNetClientEvent.CONNECT
			'Connection successful
			Return True
		Else
			'Timeout reached
			enet_peer_reset(_peer)
			enet_host_destroy(_host)
			_host = Null
			_peer = Null
			Return False
		End If
	End Method

	Rem
	bbdoc: Closes the connection to the server.
	about:
	<pre>
	disconnectTime:Int		(Optional) Maximum time in ms to wait for remaining messages to be sent before the connection will be closed.
	</pre>
	End Rem
	Method Disconnect(disconnectTime:Int = 2000)
		'Already disconnected?
		If _host = Null And _peer = Null Then Return

		If _peer = Null Then
			enet_host_destroy(_host)
			_host = Null
			Return
		End If
		
		If _host = Null Then
			enet_peer_reset(_peer)
			_peer = Null
			Return
		End If
	
		'Immediate disconnect (no server notification)
		If disconnectTime <= 0 Then
			enet_peer_reset(_peer)
			enet_host_destroy(_host)
			_host = Null
			_peer = Null
			Return
		End If
		
		'Gentle disconnect (wait for server acknowledgement)
		Local ev:ENetEvent = New ENetEvent
		Local begin:Int = MilliSecs()

		enet_peer_disconnect(_peer)
		
		While enet_host_service(_host, ev, disconnectTime) > 0
			Select ev.event
				Case TNetClientEvent.DATA
					'Drop any received packets
					enet_packet_destroy(ev.packet)

				Case TNetClientEvent.DISCONNECT
					'Disconnection successful
					Exit
			End Select
			
			'Disconnect time reached?
			If MilliSecs() - begin >= disconnectTime Then Exit
		Wend
		
		'Reset the peer and destroy the host
		enet_peer_reset(_peer)
		enet_host_destroy(_host)
		_host = Null
		_peer = Null
	End Method

	Rem
	bbdoc: Updates the client (receives and sends messages).
	returns: An object of type TNetClientEvent that represents the last event or Null if there was no event.
	about:
	<pre>
	waitTime:Int		(Optional) Time in ms to wait for incoming messages. (Default = 0, this means the function will return immediatley if there are no messages to receive).
	</pre>
	End Rem
	Method Update:TNetClientEvent(waitTime:Int = 0)
		If _host = Null Then Return Null
		
		Local ev:ENetEvent = New ENetEvent
		If enet_host_service(_host, ev, waitTime) > 0
			Select ev.event
				Case TNetClientEvent.DATA
					Return TNetClientEvent.ClientEvent(ev.event, TNetPacket.FromEnet(ev.packet), ev.channelID)
					
				Case TNetClientEvent.DISCONNECT
					Return TNetClientEvent.ClientEvent(ev.event, Null, 0)
			End Select
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Sends a packet / a message to the server.
	about:
	<pre>
	packet:TNetPacket		The packet that will be sent
	reliable:Int			(Optional) Whether the packet should be sent reliable or not (Default: False, this is suitable for unimportant anf fast data like player positions)
	channel:Int			(Optional) The channel used for transmitting the packet (Default: 0, reliable/important messages should be sent on a different channel than unimportant messages, for example channel 1)
	compressed:Int			(Optional) Whether the data will be compressed or not (Default: False, should only be used with large data, i.e. when sending 100x100 tiles etc.)
	</pre>
	End Rem
	Method Send(packet:TNetPacket, reliable:Int = False, channel:Int = 0, compressed:Int = False)
		If packet = Null Then Return
		If _host = Null Or _peer = Null Then Return
		
		Local flags:Int = 0
		If reliable Then flags = ENET_PACKET_FLAG_RELIABLE
		
		Local p:Byte Ptr = packet.EnetPacket(flags, compressed)
		If p = Null Then Return
		
		enet_peer_send(_peer, channel, p)
	End Method

	Rem
	bbdoc: Sends all buffered messages as soon as possible or immediately.
	about:
	It's better to use Update, because Update does almost the same and also receives incoming messages.
	End Rem
	Method Flush()
		If _host = Null Then Return
		enet_host_flush(_host)
	End Method
End Type