Rem
bbdoc: Class used to run a server.
End Rem
Type TNetServer
	Field _host:Byte Ptr
	Field _peers:TList
	
	Method New()
		_peers = New TList
	End Method

	Rem	
	bbdoc: Creates a new server that listens for incoming connections on the specified ip address and port.
	returns: An object of Type TNetServer or Null in case the server could not be started.
	about:
	<pre>
	ip:String			IP address on which to listen for incoming connections (use Null, "127.0.0.1" or "localhost" to listen on all local addresses).
	port:Int			Port number (should be greater than 1000 and as high as possible, i.e. 50000 or another number that is not used by other protocols or services).
	maxConnections:Int		Maximum number of allowed connections / players.
	maxChannels:Int			(Optional) Maximum number of communication channels. Will be limited to 1-255. (Default: 2)
	</pre>
	End Rem
	Function Create:TNetServer(ip:String, port:Int, maxConnections:Int, maxChannels:Int = 2)
		Local addr:Byte Ptr = enet_address_create(ENET_HOST_ANY, port)
		If addr = Null Then Return Null
		
		If ip <> Null And ip <> "" And ip <> "localhost" And ip <> "127.0.0.1"
			enet_address_set_host(addr, ip)
		End If
		
		If maxChannels < ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT
			maxChannels = ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT
		ElseIf maxChannels > ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT
			maxChannels = ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT
		End If
		
		Local host:Byte Ptr = enet_host_create(addr, maxConnections, maxChannels, 0, 0)
		enet_address_destroy(addr)
		If host = Null Then Return Null
		
		Local sv:TNetServer = New TNetServer
		sv._host = host
		Return sv
	End Function

	Rem
	bbdoc: Shuts down the server.
	about:
	<pre>
	shutdownTime:Int		(Optional) Maximum time in ms to wait for the remaining messages to be sent before shutting down. (Default: 5000)
	</pre>
	End Rem
	Method Shutdown(shutdownTime:Int = 5000)
		If _host = Null Then Return
	
		Local p:TNetPeer = Null
		
		For p = EachIn _peers
			enet_peer_disconnect(p.GetPeer())
		Next
		
		Local ev:ENetEvent = New ENetEvent
		
		Local begin:Int = MilliSecs()
		
		If shutdownTime > 0 Then
			While enet_host_service(_host, ev, shutdownTime) > 0
				Select ev.event
					Case TNetServerEvent.CONNECT
						enet_peer_reset(ev.peer)
					
					Case TNetServerEvent.DATA
						enet_packet_destroy(ev.packet)
						
					Case TNetServerEvent.DISCONNECT
						p = FindPeer(ev.peer)
						If p <> Null Then _peers.Remove(p)
						
				End Select
				
				If _peers.IsEmpty() Then Exit
				If MilliSecs() - begin >= shutdownTime Then Exit
			Wend
		EndIf

		If Not _peers.IsEmpty() Then
			For p = EachIn _peers
				enet_peer_reset(p)
			Next
			_peers.Clear()
		EndIf
		
		enet_host_destroy(_host)
		_host = Null
	End Method
	
	Rem
	bbdoc: Updates the server (receives and sends messages).
	returns: An object of Type TNetServerEvent tha represents the last event or null if there was no event.
	about:
	<pre>
	waitTime:Int			(Optional) Time in ms to wait for incoming messages. (Default = 0, this means the function will return immediatley if there are no messages to receive).
	</pre>
	End Rem
	Method Update:TNetServerEvent(waitTime:Int = 0)
		If _host = Null Then Return Null
		
		Local p:TNetPeer = Null
		Local ev:ENetEvent = New ENetEvent
		
		If enet_host_service(_host, ev, waitTime) > 0
			Select ev.event
				'New client
				Case TNetServerEvent.CONNECT
					p = TNetPeer.Create(ev.peer)
					_peers.AddLast(p)
					
					Return TNetServerEvent.ServerEvent(ev.event, Null, p, ev.channelID)

					
				'Data from existing client				
				Case TNetServerEvent.DATA
					p = FindPeer(ev.peer)
					If p = Null Then Return Null
					
					Return TNetServerEvent.ServerEvent(ev.event, TNetPacket.FromEnet(ev.packet), p, ev.channelID)

									
				'Client disconnected	
				Case TNetServerEvent.DISCONNECT
					p = FindPeer(ev.peer)
					If p = Null Then Return Null
					_peers.Remove(p)
					
					Return TNetServerEvent.ServerEvent(ev.event, Null, p, ev.channelID)
			End Select
		Else
			Return Null
		End If
	End Method

	
	'Finds a client/peer by ENet peer struct
	Method FindPeer:TNetPeer(peer:Byte Ptr)
		For Local p:TNetPeer = EachIn _peers
			If p.GetPeer() = peer Then Return p
		Next
		Return Null
	End Method

		
	Rem
	bbdoc: Sends a packet to the specified peer / player.
	about:
	<pre>
	peer:TNetPeer		The peer / player that will receive the packet.
	packet:TNetPacket	The packet that will be sent.
	reliable:Int		(Optional) Whether the packet should be sent reliable or not (Default: False, this is suitable for unimportant anf fast data like player positions)
	channel:Int		(Optional) The channel used for transmitting the packet (Default: 0, reliable/important messages should be sent on a different channel than unimportant messages, for example channel 1).
	compressed:Int		(Optional) Whether the data will be compressed or not (Default: False, should only be used with large data, i.e. when sending 100x100 tiles etc.)
	</pre>
	End Rem
	Method Send(peer:TNetPeer, packet:TNetPacket, reliable:Int = False, channel:Int = 0, compressed:Int = False)
		If _host = Null Or peer = Null Or packet = Null Then Return
		If peer.GetPeer() = Null Then Return
		
		Local flags:Int = 0
		If reliable Then flags = ENET_PACKET_FLAG_RELIABLE
		
		Local p:Byte Ptr = packet.EnetPacket(flags, compressed)
		If p = Null Then Return
		
		enet_peer_send(peer.GetPeer(), channel, p)
	End Method

	
	Rem	
	bbdoc: Sends a packet to all connected peers / players.
	about:
	<pre>
	packet:TNetPacket	The packet that will be sent.
	reliable:Int		(Optional) Whether the packet should be sent reliable or not (Default: False, this is suitable for unimportant anf fast data like player positions)
	channel:Int		(Optional) The channel used for transmitting the packet (Default: 0, reliable/important messages should be sent on a different channel than unimportant messages, for example channel 1).
	compressed:Int		(Optional) Whether the data will be compressed or not (Default: False, should only be used with large data, i.e. when sending 100x100 tiles etc.)
	</pre>
	End Rem
	Method Broadcast(packet:TNetPacket, reliable:Int = False, channel:Int = 0, compressed:Int = False)
		If _host = Null Or packet = Null Then Return
		
		Local flags:Int = 0
		If reliable Then flags = ENET_PACKET_FLAG_RELIABLE
		
		Local p:Byte Ptr = packet.EnetPacket(flags, compressed)
		If p = Null Then Return
		
		enet_host_broadcast(_host, channel, p)
	End Method

	Rem
	bbdoc: Gets a list containing all the connected peers / players.
	about:
	You should not modify the list in any way! Use the DisconnectClient or DropClient functions instead.
	End Rem
	Method GetClients:TList()
		Return _peers
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
	
	Rem
	bbdoc: Sends a disconnect message to the peer / player and closes the connection after the message has been acknowledged.
	End Rem
	Method DisconnectClient(peer:TNetPeer)
		If peer = Null Or peer.GetPeer() = Null Then Return
		enet_peer_disconnect(peer.GetPeer())
	End Method
	
	Rem
	bbdoc: Closes the connection to a peer immediately. The peer won't be notified and will only notice the disconnection after the ping timeout.
	End Rem
	Method DropClient(peer:TNetPeer)
		If peer = Null Or peer.GetPeer() = Null Then Return
		enet_peer_reset(peer.GetPeer())
		_peers.Remove(peer)
	End Method
End Type