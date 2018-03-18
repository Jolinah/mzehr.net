
Rem
bbdoc: A data packet/message. Data can be written into or read from the packet.
End Rem
Type TNetPacket
	Field _packet:Byte Ptr
	Field _bank:TBank
	Field _stream:TBankStream

	Rem
	bbdoc: Creates a new packet (for sending).
	End Rem
	Function Create:TNetPacket()
		Local packet:TNetPacket = New TNetPacket
		packet._bank = TBank.Create(0)
		packet._stream = TBankStream.Create(packet._bank)
		packet.WriteByte(0)
		Return packet
	End Function
	
	Rem
	bbdoc: Reads a packet from an ENet packet struct.
	about:
	This function is used internally and should not be called manually.
	End Rem
	Function FromEnet:TNetPacket(p:Byte Ptr)
		Local packet:TNetPacket = New TNetPacket
		packet._packet = p
		packet._bank = TBank.CreateStatic(enet_packet_data(p), enet_packet_size(p))
		packet._stream = TBankStream.Create(packet._bank)

		'Decompression
		Local cmp:Byte = packet.ReadByte()
		If cmp Then
			Local buf:Byte Ptr = MemAlloc(packet._bank.Size() - 1)
			Local l:Int = 0
			uncompress(buf, l, Varptr packet._bank.buf()[1], packet._bank.Size() - 1)
			
			packet._stream.Close()
			packet._bank = TBank.Create(l)
			packet._stream = TBankStream.Create(packet._bank)
			
			MemCopy(packet._bank.buf(), buf, l)
			MemFree(buf)
		End If
		
		Return packet
	End Function

	Method Delete()
		Destroy()
	End Method
	
	Rem
	bbdoc: Releases the memory used by the packet.
	about:
	Will be called automatically on deconstruction of the object (garbage collector), but can also be called manually.
	End Rem
	Method Destroy()
		If _stream <> Null Then
			_stream.Close()
			_stream = Null
		End If
		
		If _bank <> Null Then
			_bank = Null
		End If
	
		If _packet <> Null Then
			enet_packet_destroy(_packet)
			_packet = Null
		End If
	End Method

	Rem
	bbdoc: Reads multiple Bytes from the packet and writes them to the specified memory location.
	returns: Number of successfully read bytes.
	about:
	<pre>
	buf:Byte Ptr		Memory location where the bytes will be written to.
	count:Int		Number of bytes that should be read.
	</pre>
	End Rem
	Method Read:Int(buf:Byte Ptr, count:Int)
		Return _stream.Read(buf, count)
	End Method
	
	Rem
	bbdoc: Reads a byte from the packet.
	End Rem
	Method ReadByte:Byte()
		Return _stream.ReadByte()
	End Method
	
	Rem
	bbdoc: Reads multiple Bytes from the packet and writes them to the specified memory location.
	returns: Number of successfully read bytes.
	about:
	<pre>
	buf:Byte Ptr		Memory location where the bytes will be written to.
	count:Int		Number of bytes that should be read.
	</pre>
	End Rem
	Method ReadBytes:Int(buf:Byte Ptr, count:Int)
		Return _stream.ReadBytes(buf, count)
	End Method

	Rem
	bbdoc: Reads a short from the packet.
	End Rem
	Method ReadShort:Short()
		Return _stream.ReadShort()
	End Method
	
	Rem
	bbdoc: Reads an int from the packet.
	End Rem
	Method ReadInt:Int()
		Return _stream.ReadInt()
	End Method

	Rem
	bbdoc: Reads a long from the packet.
	End Rem
	Method ReadLong:Long()
		Return _stream.ReadLong()
	End Method
	
	Rem
	bbdoc: Reads a float from the packet.
	End Rem
	Method ReadFloat:Float()
		Return _stream.ReadFloat()
	End Method
	
	Rem
	bbdoc: Reads a double from the packet.
	End Rem
	Method ReadDouble:Double()
		Return _stream.ReadDouble()
	End Method
	
	Rem
	bbdoc: Reads a string from the packet.
	about:
	Reads an int that specifies the length of the string and then the string itself.
	End Rem
	Method ReadString:String()
		Local l:Int = _stream.ReadInt()
		If l = -1 Then Return Null
		Return _stream.ReadString(l)
	End Method
	
	Rem
	bbdoc: Reads a line of text from the packet.
	End Rem
	Method ReadLine:String()
		Return _stream.ReadLine()
	End Method
	
	Rem
	bbdoc: Reads an object from the packet (untested).
	End Rem
	Method ReadObject:Object()
		Return _stream.ReadObject()
	End Method

	Rem
	bbdoc: Writes multiple bytes into the packet.
	about:
	<pre>
	buf:Byte Ptr		Memory location from where the data is read and then written to the packet.
	count:Int		Number of bytes that should be read/written.
	</pre>
	End Rem
	Method Write(buf:Byte Ptr, count:Int)
		_stream.Write(buf, count)
	End Method
	
	Rem
	bbdoc: Writes a byte into the packet.
	End Rem
	Method WriteByte(value:Byte)
		_stream.WriteByte(value)
	End Method
	
	Rem
	bbdoc: Writes multiple bytes into the packet.
	about:
	<pre>
	buf:Byte Ptr		Memory location from where the data is read and then written to the packet.
	count:Int		Number of bytes that should be read/written.
	</pre>
	End Rem
	Method WriteBytes(buf:Byte Ptr, count:Int)
		_stream.WriteBytes(buf, count)
	End Method

	Rem
	bbdoc: Writes a short into the packet.
	End Rem
	Method WriteShort(value:Short)
		_stream.WriteShort(value)
	End Method
	
	Rem
	bbdoc: Writes an int into the packet.
	End Rem
	Method WriteInt(value:Int)
		_stream.WriteInt(value)
	End Method
	
	Rem
	bbdoc: Writes a long into the packet.
	End Rem
	Method WriteLong(value:Long)
		_stream.WriteLong(value)
	End Method
	
	Rem
	bbdoc: Writes a float into the packet.
	End Rem
	Method WriteFloat(value:Float)
		_stream.WriteFloat(value)
	End Method
	
	Rem
	bbdoc: Writes a double into the packet.
	End Rem
	Method WriteDouble(value:Double)
		_stream.WriteDouble(value)
	End Method
	
	Rem
	bbdoc: Writes a string into the packet.
	about:
	Writes an int containing the length of the string followed by the string itself.
	End Rem
	Method WriteString(value:String)
		If value = 0
			_stream.WriteInt(-1)
			Return
		Else
			_stream.WriteInt(value.Length)
			_stream.WriteString(value)
		End If
	End Method
	
	Rem
	bbdoc: Writes a line of text into the packet.
	End Rem
	Method WriteLine(value:String)
		_stream.WriteLine(value)
	End Method
	
	Rem
	bbdoc: Writes an object to the packet (untested).
	End Rem
	Method WriteObject(value:Object)
		_stream.WriteObject(value)
	End Method
	
	Rem
	bbdoc: Converts the packet to an ENet packet struct.
	about:
	This method is used internally and should not be called manually.
	End Rem
	Method EnetPacket:Byte Ptr(enet_flags:Int = 0, compressed:Int = False)
		If _packet <> Null Then Return _packet
		If _bank = Null Then Return Null
		
		If compressed Then
			'Compression
			Local cmp:Byte Ptr = MemAlloc(_bank.Size() - 1)
			Local cmpLen:Int = 0
			compress(cmp, cmpLen, Varptr _bank.buf()[1], _bank.Size() - 1)
			
			Local buf:Byte Ptr = MemAlloc(cmpLen + 1)
			MemCopy(Varptr buf[1], cmp, cmpLen)
			buf[0] = 1

			Local p:Byte Ptr = enet_packet_create(buf, cmpLen + 1, enet_flags)
			
			MemFree(cmp)
			MemFree(buf)
			
			Return p
		Else
			'No compression
			Return enet_packet_create(_bank.buf(), _bank.Size(), enet_flags)
		End If
	End Method

End Type