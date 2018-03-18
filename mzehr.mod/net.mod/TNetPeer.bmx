
Rem
bbdoc: Represents a peer/client/player on the server.
End Rem
Type TNetPeer
	Field _peer:Byte Ptr
	Field _data:Object
	
	Rem
	bbdoc: Creates a new peer from an ENet peer struct.
	about:
	This method is used internally by the server and should not be called manually.
	End Rem
	Function Create:TNetPeer(peer:Byte Ptr)
		Local p:TNetPeer = New TNetPeer
		p._peer = peer
		Return p
	End Function
	
	Rem
	bbdoc: Returns the ENet peer struct.
	about:
	This methos is used internally by the server and should not be called manually.
	End Rem
	Method GetPeer:Byte Ptr()
		Return _peer
	End Method
	
	Rem
	bbdoc: Gets the data assigned to this peer (see SetData).
	End Rem
	Method GetData:Object()
		Return _data
	End Method
	
	Rem
	bbdoc: Assigns a custom data object to this peer.
	about:
	This can be used to assign a player object or other data to the peer.
	On the server, you can retrieve a list of connected peers with TNetServer.GetClients() and those
	peers (TNetPeer) contain the assigned data object which can be fetched by calling TNetPeer.GetData().
	End Rem
	Method SetData(value:Object)
		_data = value
	End Method
End Type