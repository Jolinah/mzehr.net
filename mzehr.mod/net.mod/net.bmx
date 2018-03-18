SuperStrict

Rem
bbdoc: Network module based on ENet (http://enet.bespin.org)
End Rem
Module mzehr.net

ModuleInfo "Version 2.0"
ModuleInfo "Author: Michael Zehr (Jolinah)"
ModuleInfo "License: MIT X11 License (License.txt)"
ModuleInfo "Credit: Lee Salzman (http://enet.bespin.org)"

ModuleInfo "History: 1.0 First release"
ModuleInfo "History: 1.1 Instead of importing pub.enet, the newest source code of ENet has been compiled into the module (version 1.3.13 as of now). However, the protocol of ENet version 1.3 and above is not compatible with ENet versions 1.2 and below. You will need to redistribute the client to all existing players after updating the server or they won't be able to play on the new server."

Import brl.linkedlist
Import brl.bank
Import brl.bankstream

'Import pub.stdc
Import pub.zlib

Import "enet/enet/*.h"
Import "enet/callbacks.c"
Import "enet/compress.c"
Import "enet/host.c"
Import "enet/list.c"
Import "enet/packet.c"
Import "enet/peer.c"
Import "enet/protocol.c"

?Win32
Import "enet/win32.c"
Import "-lws2_32"
Import "-lwinmm"
?MacOs
Import "enet/unix.c"
?Linux
Import "enet/unix.c"
?

Include "TNetServer.bmx"
Include "TNetPeer.bmx"
Include "TNetClient.bmx"
Include "TNetEvent.bmx"
Include "TNetPacket.bmx"

Type ENetEvent
	Field event:Int
	Field peer:Byte Ptr
	Field channelID:Byte
	Field data:Int
	Field packet:Byte Ptr
End Type

Extern "C"
	Const ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT:Int = 1
	Const ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT:Int = 255
	
	Const ENET_HOST_ANY:Int = 0
	
	Const ENET_PACKET_FLAG_RELIABLE:Int = 0
	Const ENET_PACKET_FLAG_UNSEQUENCED:Int = 1

	'Address functions
	Function enet_address_get_host:Int(address:Byte Ptr, HostName$z, nameLength:Int)
	Function enet_address_get_host_ip:Int(address:Byte Ptr, HostName$z, nameLength:Int)
	Function enet_address_set_host:Int(address:Byte Ptr, HostName$z)
	
	'Global functions
	Function enet_deinitialize()
	Function enet_initialize:Int()
	Function enet_initialize_with_callbacks:Int(version:Int, inits:Byte Ptr)
	Function enet_linked_version:Int()
	
	'Host functions
	Function enet_host_bandwith_limit(host:Byte Ptr, incomingBandwith:Int, outgoingBandwith:Int)
	Function enet_host_broadcast(host:Byte Ptr, channelID:Byte, packet:Byte Ptr)
	Function enet_host_channel_limit(host:Byte Ptr, channelLimit:Int)
	Function enet_host_check_events:Int(host:Byte Ptr, event:Byte Ptr)
	Function enet_host_compress(host:Byte Ptr, compressor:Byte Ptr)
	Function enet_host_compress_with_range_coder:Int(host:Byte Ptr)
	Function enet_host_connect:Byte Ptr(host:Byte Ptr, address:Byte Ptr, channelCount:Int, data:Int = 0)
	Function enet_host_create:Byte Ptr(address:Byte Ptr, peerCount:Int, channelLimit:Int, incomingBandwith:Int, outgoingBandwith:Int)
	Function enet_host_destroy(host:Byte Ptr)
	Function enet_host_flush(host:Byte Ptr)
	Function enet_host_service:Int(host:Byte Ptr, event:Byte Ptr, timeout:Int)
	
	'Packet functions
	Function enet_packet_create:Byte Ptr(data:Byte Ptr, dataLength:Int, flags:Int)
	Function enet_packet_destroy(packet:Byte Ptr)
	Function enet_packet_resize:Int(packet:Byte Ptr, dataLength:Int)
	
	'Peer functions
	Function enet_peer_disconnect(peer:Byte Ptr, data:Int = 0)
	Function enet_peer_disconnect_later(peer:Byte Ptr, data:Int = 0)
	Function enet_peer_disconnect_now(peer:Byte Ptr, data:Int = 0)
	Function enet_peer_ping(peer:Byte Ptr)
	Function enet_peer_ping_interval(peer:Byte Ptr, pingInterval:Int)
	Function enet_peer_receive:Byte Ptr(peer:Byte Ptr, channelID:Byte Ptr)
	Function enet_peer_reset(peer:Byte Ptr)
	Function enet_peer_send:Int(peer:Byte Ptr, channelID:Byte, packet:Byte Ptr)
	Function enet_peer_throttle_configure(peer:Byte Ptr, interval:Int, acceleration:Int, deceleration:Int)
	Function enet_peer_timeout(peer:Byte Ptr, timeoutLimit:Int, timeoutMinimum:Int, timeoutMaximum:Int)
	
	'Undocumented / internal functions
	'Function enet_host_bandwith_throttle(host:Byte Ptr)
	'Function enet_crc32:Int(buffers:Byte Ptr, bufferCount:Int)
	'Function enet_peer_dispatch_incoming_reliable_commands(peer:Byte Ptr, channel:Byte Ptr)
	'Function enet_peer_dispatch_incoming_unreliable_commands(peer:Byte Ptr, channel:Byte Ptr)
	'Function enet_peer_on_connect(peer:Byte Ptr)
	'Function enet_peer_on_disconnect(peer:Byte Ptr)
	'Function enet_peer_queue_acknowledgement:Byte Ptr(peer:Byte Ptr, command:Byte Ptr, sentTime:Short)
	'Function enet_peer_queue_incoming_command:Byte Ptr(peer:Byte Ptr, command:Byte Ptr, data:Byte Ptr, dataLength:Int, flags:Int, fragmentCount:Int)
	'Function enet_peer_queue_outgoing_command:Byte Ptr(peer:Byte Ptr, command:Byte Ptr, packet:Byte Ptr, offset:Int, length:Short)
	'Function enet_peer_reset_queues(peer:Byte Ptr)
	'Function enet_peer_setup_outgoing_command(peer:Byte Ptr, outgoingCommand:Byte Ptr)
	'Function enet_peer_throttle:Int(peer:Byte Ptr, rtt:Int)
	'Function enet_socket_accept:Int(socket:Int, address:Byte Ptr)
	'Function enet_socket_bind:Int(socket:Int, address:Byte Ptr)
	'Function enet_socket_create:Int(socketType:Int)
	'Function enet_socket_destroy(socket:Int)
	'Function enet_socket_get_address:Int(socket:Int, address:Byte Ptr)
	'Function enet_socket_get_option:Int(socket:Int, socketOption:Int, option:Int Ptr)
	'Function enet_socket_listen:Int(socket:Int, port:Int)
	'Function enet_socket_receive:Int(socket:Int, address:Byte Ptr, buffer:Byte Ptr, length:Int)
	'Function enet_socket_send:Int(socket:Int, address:Byte Ptr, buffer:Byte Ptr, length:Int)
	'Function enet_socket_set_option:Int(socket:Int, socketOption:Int, option:Int)
	'Function enet_socket_shutdown:Int(socket:Int, socketShutdown:Int)
	'Function enet_socket_wait:Int(socket:Int, param1:Int Ptr, param2:Int)
	'Function enet_socketset_select:Int(socket:Int, socketset:Byte Ptr, socketset2:Byte Ptr, param3:Int)
End Extern

Function enet_peer_address(peer:Byte Ptr, host_ip:Int Var, host_port:Int Var)
	Local ip:Int = (Int Ptr peer)[3]
	Local port:Int = (Short Ptr peer)[8]
?LittleEndian
	ip = (ip Shr 24) | (ip Shr 8 & $ff00) | (ip Shl 8 & $ff0000) | (ip Shl 24)
?
	host_ip = ip
	host_port = port
End Function

Function enet_packet_data:Byte Ptr(packet:Byte Ptr)
	Return Byte Ptr((Int Ptr packet)[2])
End Function

Function enet_packet_size:Int(packet:Byte Ptr)
	Return (Int Ptr packet)[3]
End Function

Function enet_address_create:Byte Ptr(host_ip:Int, host_port:Int)
	Local t:Byte Ptr = MemAlloc(6)
?BigEndian
		(Int Ptr t)[0] = host_ip
?LittleEndian
		(Int Ptr t)[0] = (host_ip Shr 24) | (host_ip Shr 8 & $ff00) | (host_ip Shl 8 & $ff0000) | (host_ip Shl 24)
?
	(Short Ptr t)[2] = host_port
	Return t
End Function

Function enet_address_destroy(address:Byte Ptr)
	MemFree address
End Function

enet_initialize()
atexit_(enet_deinitialize)