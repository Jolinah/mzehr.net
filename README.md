# mzehr.net
Network module for BlitzMax based on ENet (https://github.com/lsalzman/enet)

Quote from http://enet.bespin.org/:

> ENet's purpose is to provide a relatively thin, simple and robust network communication layer on top of UDP (User Datagram Protocol). The primary feature it provides is optional reliable, in-order delivery of packets.

> ENet omits certain higher level networking features such as authentication, lobbying, server discovery, encryption, or other similar tasks that are particularly application specific so that the library remains flexible, portable, and easily embeddable.

## Installation:

1. Copy the folder mzehr.net to <BlitzMax installation directory>/mod.
2. Go to the <BlitzMax installation directory>/bin folder.
3. Execute the bmk executable to build the module for your platform: "bmk makemods -a mzehr.net"

## Building and running the example server and client:

1. Open the files ExampleServer.bmx and ExampleClient.bmx in the BlitzMax IDE or in your preferred IDE.
2. Compile both of them separately.
3. Run the ExampleServer executable first.
4. Run two instances of the ExampleClient executable.
5. Now you should see two players in both of the clients.
6. You can control them with the arrow keys and they should move on both clients in the exact same way.
