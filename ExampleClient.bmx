SuperStrict

'Modul importieren
Import mzehr.net

AppTitle = "Client"
SeedRnd(MilliSecs())

'Kleine Klasse für den eigenen und die anderen Spieler
Type TPlayer
	'Liste mit allen Spielern
	Global List:TList = New TList

	'Name des Spielers
	Field Name:String
	
	'Position des Spielers
	Field X:Float
	Field Y:Float
	
	Field ZielX:Float
	Field ZielY:Float

	Field Initialisiert:Int
	
	Method New()
		'Neue Spieler in die Liste einfügen
		List.AddLast(Self)
	End Method
	
	Method Update(deltaTime:Float)
		X = Interpoliere(X, ZielX, 2.0 * deltaTime)
		Y = Interpoliere(Y, ZielY, 2.0 * deltaTime)
	End Method
	
	'Zeichnet den Spieler
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


'Einen neuen Client erstellen
Global client:TNetClient = TNetClient.Create()

'Den lokalen Spieler erstellen
Local myPlayer:TPlayer = New TPlayer
myPlayer.Name = "Guest" + Rand(1000, 9999)

'Verbindung herstellen
If client.Connect("localhost", 50000)
	'Login-Paket erstellen
	Local paket:TNetPacket = TNetPacket.Create()
	paket.WriteByte(1)  'Nachricht-Nr. 1
	paket.WriteString(myPlayer.Name)  'Name des eigenen Spielers
	
	'Paket an den Server senden (wichtige Nachricht auf Kanal 1)
	client.Send(paket, True, 1)
	
	'Maximal 2 Sekunden auf die Antwort des Servers warten
	Local event:TNetClientEvent = client.Update(2000)
	If event <> Null And event.event = TNetClientEvent.DATA
		'Daten empfangen
		
		Local msgId:Byte = event.Packet.ReadByte()
		If msgId = 1
			'Antwort auslesen
			Local loggedIn:Int = event.Packet.ReadByte()
			If loggedIn
				'Bestehende Spieler einlesen
				Local numPlayers:Int = event.Packet.ReadInt()
				For Local i:Int = 0 To numPlayers - 1
					'Spielerdaten lesen
					Local name:String = event.Packet.ReadString()
					Local x:Float = event.Packet.ReadFloat()
					Local y:Float = event.Packet.ReadFloat()
					
					'Spieler erstellen
					Local player:TPlayer = New TPlayer
					player.name = name
					player.X = x
					player.Y = y
					player.ZielX = x
					player.ZielY = y
				Next
			Else
				'Login fehlgeschlagen
				Local error:String = event.Packet.ReadString()
				client.Disconnect()
				Notify(error)
				End
			End If
		Else
			'Ungültige Antwort
			client.Disconnect()
			Notify("Der Server hat eine unerwartete Antwort gesendet. Protokoll-Fehler?")
			End
		End If
	Else
		'Keine Antwort
		client.Disconnect()
		Notify("Der Server hat innerhalb von 2 Sekunden keine Antwort gesendet. Verbindung fehlgeschlagen.")
		End
	End If
Else
	'Connect schlug fehl
	Notify "Es konnte keine Verbindung hergestellt werden."
	End
End If


'An dieser Stelle ist die Verbindung hergestellt und der Spieler eingeloggt

'Grafik initialisieren
Graphics 800, 600, 0

'Variable zum Zwischenspeichern von Tasten-Stati 
Local keyState:Byte[] = New Byte[256]

'Variable zum Beenden des Programms aus der Hauptschleife heraus
Local quitApp:String = Null

'Variablen für die Zeitmessung eines Frames (Frame-Unabhängige Programmierung)
Local deltaTime:Float = 0
Local lastFrame:Int = MilliSecs()

Repeat
deltaTime = (MilliSecs() - lastFrame) / 1000.0
lastFrame = MilliSecs()
Cls

	'Status-Änderungen von Tasten an den Server senden
	UpdateKey(KEY_UP, keyState[KEY_UP])
	UpdateKey(KEY_DOWN, keyState[KEY_DOWN])
	UpdateKey(KEY_LEFT, keyState[KEY_LEFT])
	UpdateKey(KEY_RIGHT, keyState[KEY_RIGHT])

	'Client aktualisieren (empfangen/senden)
	Local event:TNetClientEvent = client.Update()
	While event <> Null
		Select event.event
			'Der Server hat die Verbindung getrennt
			Case TNetClientEvent.DISCONNECT
				quitApp = "Der Server hat die Verbindung getrennt."
			
			'Daten vom Server empfangen
			Case TNetClientEvent.DATA
				'Daten verarbeiten
				DatenVerarbeitung(event)
				
		End Select
	
		'Nächstes Ereignis abrufen
		event = client.Update()
	Wend

	
	'Alle Spieler aktualisieren und zeichnen
	For Local player:TPlayer = EachIn TPlayer.List
		player.Update(deltaTime)
		player.Draw()
	Next

Flip -1
Until AppTerminate() Or KeyHit(KEY_ESCAPE) Or quitApp <> Null

EndGraphics

'Client schliessen
client.Disconnect()

'Grund für das Beenden des Programms anzeigen (falls gegeben)
If quitApp <> Null Then Notify(quitApp)

End


'Findet einen Spieler per Name
Function FindPlayer:TPlayer(name:String)
	'Gross-/Kleinschreibung spielt keine Rolle
	name = name.ToLower()

	For Local player:TPlayer = EachIn TPlayer.List
		'Namen überprüfen, falls sie identisch sind den Spieler zurückgeben
		If player.name.ToLower() = name Then Return player
	Next
	
	'Kein Spieler gefunden
	Return Null
End Function


'Sendet Status-Änderungen einer bestimmten Taste (falls notwendig)
Function UpdateKey(code:Int, lastState:Byte Var)
	'Update erforderlich?
	Local update:Int = False

	If KeyDown(code) And Not lastState Then
		lastState = True
		update = True  'Update veranlassen
	Else If lastState And Not KeyDown(code) Then
		lastState = False
		update = True  'Update veranlassen
	End If
	
	'Update falls erforderlich
	If update Then
		'Paket erstellen
		Local paket:TNetPacket = TNetPacket.Create()
		paket.WriteByte(4)  'Nachricht-Nr. 4
		paket.WriteByte(code)  'Taste
		paket.WriteByte(lastState)  'Status
		
		'Paket senden
		client.Send(paket, True, 1)
	End If
End Function


'Verarbeitet die vom Server empfangenen Daten
'event:TNetClientEvent		Event-Objekt welches den Absender der Nachricht und das Paket selbst enthält
Function DatenVerarbeitung(event:TNetClientEvent)

	'Ein Byte vom Paket lesen
	'In diesem Beispiel fängt jede Nachricht mit diesem Byte an
	'Anhand dieses Bytes wird unterschieden welche Daten vom Paket gelesen werden
	Local msgId:Byte = event.Packet.ReadByte()
	
	'Je nach dem Wert des Bytes unterschiedliche Daten lesen/senden etc.
	Select msgId
		'2 = Neuer Mitspieler
		Case 2
			'Daten lesen
			Local name:String = event.Packet.ReadString()
			Local x:Float = event.Packet.ReadFloat()
			Local y:Float = event.Packet.ReadFloat()

			'Spieler erstellen
			Local player:TPlayer = New TPlayer
			player.Name = name
			player.X = x
			player.Y = y
			player.ZielX = x
			player.ZielY = y
			
		'3 = Spieler verlässt das Spiel
		Case 3
			'Daten lesen
			Local name:String = event.Packet.ReadString()
			
			'Spieler entfernen
			Local player:TPlayer = FindPlayer(name)
			If player <> Null Then TPlayer.List.Remove(player)
				
		'5 = Positions-Updates
		Case 5
			'Anzahl Spieler im Update lesen
			Local numPlayers:Int = event.Packet.ReadInt()
			
			For Local i:Int = 0 To numPlayers - 1
				'Daten von einem Spieler lesen
				Local name:String = event.Packet.ReadString()
				Local x:Float = event.Packet.ReadFloat()
				Local y:Float = event.Packet.ReadFloat()
				
				'Spieler suchen und Position aktualisieren
				Local player:TPlayer = FindPlayer(name)
				If player <> Null Then
					If Not player.Initialisiert
						player.X = x
						player.Y = y
						player.Initialisiert = True
					End If
					player.ZielX = x
					player.ZielY = y
				End If
			Next
	End Select
End Function

Function Interpoliere:Float(aktuell:Float, neu:Float, faktor:Float)
	faktor = Clamp01(faktor)
	Return ((1.0 - faktor) * aktuell) + (faktor * neu)
End Function

Function Clamp01:Float(wert:Float)
	If wert < 0.0 Then Return 0.0
	If wert > 1.0 Then Return 1.0
	Return wert
End Function