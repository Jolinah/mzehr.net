SuperStrict

Framework brl.blitz
Import brl.basic
Import brl.glmax2d

'Modul importieren
Import mzehr.net

AppTitle = "Server"
SeedRnd(MilliSecs())


'Kleine Klasse um Spieler-Infos zu speichern
Type TPlayer
	'Name des Spielers
	Field Name:String
	
	'Tasten-Stati des Spielers
	Field Keys:Byte[]
	
	'Position des Spielers
	Field X:Float
	Field Y:Float
	
	Method New()
		Keys = New Byte[256]
	End Method

	'Legt den Status einer Taste des Spielers fest (gedrückt/nicht gedrückt)
	Method SetKey(code:Int, pressed:Int)
		If code >= 0 And code < Keys.Length Then
			Keys[code] = pressed
		End If
	End Method
	
	'Fragt den Status einer Taste ab (gedrückt/nicht gedrückt)
	Method GetKey:Int(code:Int)
		If code >= 0 And code < Keys.Length Then Return Keys[code]
		Return False
	End Method
End Type



'Einen Server auf Port 50000 mit maximal 10 Clients/Spielern erstellen
Global server:TNetServer = TNetServer.Create(Null, 50000, 10)

'Fehlermeldung anzeigen wenn der Server nicht initialisiert werden konnte
If server = Null Then
	Notify("Der Server konnte nicht initialisiert werden.")
	End
End If

'Grafik initialisieren (bei einem Server eigentlich nicht notwendig)
Graphics 200, 200, 0

'Variablen für Positions-Updates an alle Spieler
Local lastPosUpdate:Int = 0
Local numPosUpdates:Int = 10

'Variablen für die Zeitmessung eines Frames (Frame-Unabhängige Programmierung)
Local deltaTime:Float = 0
Local lastFrame:Int = MilliSecs()

'Hauptschleife des Server-Programms
Repeat
deltaTime = (MilliSecs() - lastFrame) / 1000.0
lastFrame = MilliSecs()
Cls

	'Server aktualisieren (Nachrichten senden/empfangen)
	Local event:TNetServerEvent = server.Update()

	'Solange Events vorhanden sind, diese abarbeiten und Update erneut ausführen
	'bis kein Event mehr zurückgegeben wird	
	While event <> Null
	
		Select event.event
			'Ein Client/Spieler hat sich mit dem Server verbunden
			Case TNetServerEvent.CONNECT
				'Spieler-Objekt erstellen
				Local player:TPlayer = New TPlayer
				player.X = Rand(20, 780)
				player.Y = Rand(20, 580)
				
				'Objekt dem Client zuweisen
				event.Peer.SetData(player)
				
				'Bereits verbundene Spieler müssen noch über den neuen Spieler informiert werden
				'Dies wird allerdings erst gemacht wenn der Name des Spielers bekannt ist
				'(siehe DatenVerarbeitung_NichtAngemeldet)
				
				
			'Ein Client/Spieler hat den Server verlassen
			Case TNetServerEvent.DISCONNECT
				'Allen verbundenen Clients/Spielern mitteilen dass dieser Spieler
				'nicht mehr verbunden ist
				SendeTrennungsNachricht(event)
			
				'Zuvor erstelltes Spieler-Objekt entfernen
				event.Peer.SetData(Null)
				
			
			'Ein Client/Spieler hat Daten gesendet
			Case TNetServerEvent.DATA
				'Mit dieser Zeile wird das Spieler-Objekt geholt, das zuvor zugewiesen wurde (bei CONNECT)
				Local player:TPlayer = TPlayer(event.Peer.GetData())

				'Daten zwecks Übersichtlichkeit in einer separaten Funktion verarbeiten			
				If player.Name = Null Then
					'Wenn der Spieler noch keinen Namen hat, dannt wird nur die Nachricht mit der Nr. 1 akzeptiert
					DatenVerarbeitung_NichtAngemeldet(event)
				Else
					'Wenn der Spieler anschliessend einen Namen gesendet hat (mit der Nachricht Nr. 1),
					'werden vom Server auch Nachrichten mit anderen Nummern verarbeitet
					DatenVerarbeitung_Angemeldet(event)
				End If
			
		End Select
		
		'Update erneut ausführen
		event = server.Update()
	Wend
	
	
	'Welt/Spieler aktualisieren
	For Local peer:TNetPeer = EachIn server.GetClients()
		Local player:TPlayer = TPlayer(peer.GetData())

		'Spieler aufgrund seiner Tastendrücke 200 Pixel/Sekunde bewegen lassen
		player.X:+player.GetKey(KEY_LEFT) * -200 * deltaTime + player.GetKey(KEY_RIGHT) * 200 * deltaTime;
		player.Y:+player.GetKey(KEY_UP) * -200 * deltaTime + player.GetKey(KEY_DOWN) * 200 * deltaTime;
		
		'Position auf der X-Achse limitieren		
		If player.X < 0
			player.X = 0
		ElseIf player.X > 800
			player.X = 800
		EndIf
		
		'Position auf der Y-Achse limitieren
		If player.Y < 0
			player.Y = 0
		ElseIf player.Y > 600
			player.Y = 600
		End If
	Next
	
	
	'15 mal pro Sekunde die Position jedes Spielers an jeden Client senden
	If MilliSecs() - lastPosUpdate > 1000 / numPosUpdates
	
		'Paket erstellen mit Infos zu jedem Spieler
		Local paket:TNetPacket = TNetPacket.Create()
		paket.WriteByte(5)  'Nachricht-Nr. 5
		paket.WriteInt(server.GetClients().Count())  'Anzahl Spieler
		
		'Spieler-Infos in das Paket schreiben
		For Local peer:TNetPeer = EachIn server.GetClients()
			Local player:TPlayer = TPlayer(peer.GetData())
			paket.WriteString(player.Name)
			paket.WriteFloat(player.X)
			paket.WriteFloat(player.Y)
		Next
		
		'Paket an alle Spieler senden
		'Diesmal als unwichtiges Paket auf Kanal 0, da die Positionen sehr häufig gesendet werden
		'macht es in der Regel nichts wenn mal 1 Paket verloren geht
		server.Broadcast(paket)
	
		'Letztes Update = gerade eben
		lastPosUpdate = MilliSecs()
	EndIf
	

Flip -1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

'Grafik-Modus beenden
EndGraphics

'Server herunterfahren
server.Shutdown()

'Programm-Ende
End


'Verarbeitet von Clients empfangene Daten (wenn diese noch nicht Angemeldet sind)
'event:TNetServerEvent		Event-Objekt mit dem Absender des Pakets und dem Paket selber
Function DatenVerarbeitung_NichtAngemeldet(event:TNetServerEvent)
	
	'Mit dieser Zeile wird das zuvor zugewiesene Spieler-Objekt vom Client geholt
	'Über dieses Objekt kann z.B. auf den Namen des Spielers zugegriffen werden
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	'Ein Byte vom Paket lesen
	'In diesem Beispiel fängt jede Nachricht mit diesem Byte an
	'Anhand dieses Bytes wird unterschieden welche Daten vom Paket gelesen werden
	Local msgId:Byte = event.Packet.ReadByte()

	'Je nach dem Wert des Bytes unterschiedliche Daten lesen/senden etc.
	Select msgId

		'1 = Name (Der Spieler sendet seinen gewünschten Namen)
		Case 1
			'Name vom Paket lesen
			Local name:String = event.Packet.ReadString()
			
			'Name überprüfen
			If name = Null Or name.Length < 3 Then
				'Spieler-Name ist zu KURZ -> Nachricht zurück senden
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(1)	'Nachricht-Nr. 1
				paket.WriteByte(0)  'Anmeldung fehlgeschlagen
				paket.WriteString("Dieser Name ist zu kurz.")  'Fehlermeldung
				
				'Das Antwort-Paket zurücksenden, als wichtige Nachricht und auf dem Kanal 1 (nicht komprimiert)
				server.Send(event.Peer, paket, True, 1)
				
			ElseIf FindPlayer(name) <> Null
				'Es existiert bereits ein Spieler mit diesem Namen
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(1)  'Nachricht-Nr. 1
				paket.WriteByte(0)  'Anmeldung fehlgeschlagen
				paket.WriteString("Dieser Name wird bereits verwendet.")  'Fehlermeldung
				
				'Das Antwort-Paket zurücksenden, als wichtige Nachricht und auf dem Kanal 1 (nicht komprimiert)
				server.Send(event.Peer, paket, True, 1)
			
			Else
				'Spieler-Name ist OK -> Name setzen
				'(Dadurch gilt der Spieler als angemeldet und darf nun auch andere Nachrichten senden)
				player.name = name
				
				'Antwort senden
				Local paket:TNetPacket = TNetPacket.Create()
				paket.WriteByte(1)  'Nachricht-Nr. 1
				paket.WriteByte(1)  'Anmeldung erfolgreich (keine Fehlermeldung notwendig)
				
				'Infos über alle anderen Spieler in das Paket schreiben
				paket.WriteInt(server.GetClients().Count() - 1)
				For Local peer:TNetPeer = EachIn server.GetClients()
					'Eigenen Spieler ignorieren
					If peer = event.peer Then Continue
					
					Local p:TPlayer = TPlayer(peer.GetData())
					paket.WriteString(p.name)
					paket.WriteFloat(p.X)
					paket.WriteFloat(p.Y)
				Next
				
				'Das Antwort-Paket zurücksenden, als wichtige Nachricht und auf dem Kanal 1 (nicht komprimiert)
				server.Send(event.Peer, paket, True, 1)

				'Bereits verbundene Spieler erst jetzt über den neuen Spieler informieren (da nun erst der Name bekannt ist)
				SendeVerbindungsNachricht(event)
			EndIf
		
	End Select
	
End Function


'Sucht nach einem TPlayer mit dem angegebenen Namen
'name:String		Name des Spielers
'Gibt Null oder den Spieler zurück, wenn er gefunden wurde
Function FindPlayer:TPlayer(name:String)
	
	'Gross-/Kleinschreibung des Namens spielt keine Rolle
	name = name.ToLower()

	For Local peer:TNetPeer = EachIn server.GetClients()
		'TPlayer-Objekt vom Client holen
		Local player:TPlayer = TPlayer(peer.GetData())
		
		'Prüfen ob der Name übereinstimmt und falls ja, den Spieler zurückgeben
		If player <> Null And player.name.ToLower() = name Then Return player
	Next

	'Kein Spieler gefunden
	Return Null
End Function


'Verarbeitet von Clients empfangene Daten (wenn diese Angemeldet sind)
'event:TNetServerEvent		Event-Objekt mit dem Absender des Pakets und dem Paket selber
Function DatenVerarbeitung_Angemeldet(event:TNetServerEvent)
	
	'Mit dieser Zeile wird das zuvor zugewiesene Spieler-Objekt vom Client geholt
	'Über dieses Objekt kann z.B. auf den Namen des Spielers zugegriffen werden
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	'Ein Byte vom Paket lesen
	'In diesem Beispiel fängt jede Nachricht mit diesem Byte an
	'Anhand dieses Bytes wird unterschieden welche Daten vom Paket gelesen werden
	Local msgId:Byte = event.Packet.ReadByte()

	'Je nach dem Wert des Bytes unterschiedliche Daten lesen/senden etc.
	Select msgId

		'4 = Tasten-Status des Clients
		Case 4
			'Tasten-Code lesen
			Local code:Byte = event.Packet.ReadByte()
			
			'Status lesen (gedrückt/nicht gedrückt)
			Local pressed:Byte = event.Packet.ReadByte()
			
			'Taste beim Spieler-Objekt aktualisieren
			player.SetKey(code, pressed)
				
	End Select
	
End Function


'Sendet eine Verbindungsnachricht an alle anderen Spieler
'event:TNetServerEvent		Event-Objekt mit dem Client der sich verbunden hat
Function SendeVerbindungsNachricht(event:TNetServerEvent)
	
	'Diese Zeile holt das Spieler-Objekt
	Local player:TPlayer = TPlayer(event.Peer.GetData())

	'Paket erstellen, dass an alle anderen Spieler gesendet wird
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(2)  'Nachricht-Nr. 2
	paket.WriteString(player.Name)  'Name des Spielers
	paket.WriteFloat(player.X)	'X-Position des Spielers
	paket.WriteFloat(player.Y)  'Y-Position des Spielers
	
	For Local client:TNetPeer = EachIn server.GetClients()
		'Nicht an den Client senden der sich verbunden hat
		If client = event.Peer Then Continue
		
		'Aber an alle anderen Senden
		server.Send(client, paket, True, 1)
	Next

End Function

'Sendet eine Trennungsnachricht an alle anderen Spieler
'event:TNetServerEvent		Event-Objekt mit dem Client der die Verbindung getrennt hat
Function SendeTrennungsNachricht(event:TNetServerEvent)
	
	'Diese Zeile holt das Spieler-Objekt
	Local player:TPlayer = TPlayer(event.Peer.GetData())
	
	'Paket erstellen, dass an alle anderen Spieler gesendet wird
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(3)  'Nachricht-Nr. 3
	paket.WriteString(player.Name)  'Name des Spielers
	
	For Local client:TNetPeer = EachIn server.GetClients()
		'Nicht an den Client senden der die Verbindung getrennt hat
		If client = event.Peer Then Continue
		
		'Aber an alle anderen Senden
		server.Send(client, paket, True, 1)
	Next

End Function
