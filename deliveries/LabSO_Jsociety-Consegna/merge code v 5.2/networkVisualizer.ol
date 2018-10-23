/*

Il Network Visualiser `e un tool amministrativo da terminale per il monitoraggio del sistema.
--> Implementazione
Il Network Visualizer invia richieste a tutta la rete per conoscere
lo stato delle blockchain di tutti i nodi, la loro versione, le transazioni che contengono,
generando le seguenti informazioni:

• La data e l’ora del server timestamp al momento della richiesta.

• Per ogni utente/nodo: la sua chiave pubblica; le transazioni
che ha effettuato divise per entrate/uscite;
la versione della blockchain che utilizza e la quantita` totale di Jollar che possiede.

• Per ogni transazione al punto precedente, ordinate in ordine cronologico,
 si indica la data, l’ora, e gli utenti (con le loro chiavi pubbliche) coinvolti.

• La blockchain piu` lunga presente nella rete (chiamata la versione ufficiale),
con tutta la struttura dati che contiene.

*/

include "time.iol"
include "semaphore_utils.iol"
include "interface.iol"
include "message_digest.iol"
include "console.iol"
include "math.iol"

include "json_utils.iol"
//interfaccia per il servizio di crittografia
include "MyUtilInterface.iol"

outputPort MyKeyUtil {
	Interfaces: MyUtilInterface
}

embedded {
	Java: "myUtil.MyKeyUtil" in MyKeyUtil
}
//porta di output che interroga server timestamp
outputPort ToCore {
	Location: "socket://localhost:9000/"
	Protocol: http
	Interfaces: JollarInterface
}

outputPort portaBroadcast {
	Interfaces: JollarInterface
}

inputPort InPort {
	Location: "socket://localhost:9009/"
	Protocol: http
	Interfaces: JollarInterface
}

init{
	println@Console( "Connessione stabilita con: \"socket://localhost:9000\" " )();
	generaChiavi@MyKeyUtil()(chiavi);
	publicKey = chiavi.publicKey;
	privateKey = chiavi.privateKey;
	// walletAmount = 0;
	with (info) {
		.publicKey = publicKey;
		.location = "socket://localhost:9009";
		.protocol = "http"
	};
	// Inizialmente assegno valore zero, così la prima blockchain più lunga è quella ufficiale
	global.officialBlockchain = 0;
	global.puntBlockchain = 0
}

main{
	aggiungiPeer@ToCore(info)(sidNV);
	println@Console("NV aggiunto con successo:\nLoc: " + info.location +
		"\nProt: " + info.protocol + "\nPubK: " + info.publicKey)();
	sidMsg.sid = sidNV.sid;
	println@Console( "SID:\t" + sidMsg.sid)();
	println@Console( "Richiesta monitoraggio risorse ai peer connessi.." )();
	inAttesaDelleTransazioni();
	println@Console( "Resuming.. Contatto il server." )();
	//networkVisualizer@ToCore(sidMsg)(infoNet);

	invioPeer@ToCore(sidMsg)(listaPeer);
	getCurrentTimeMillis@Time()( time );
	getDateTime@Time(time)(date);

	println@Console("Richiesta informazioni blockchain effettuata: " + date)();
	for (i = 2, i < #listaPeer.nodo, i++) {
		//binding dinamico:
		//ad ogni iterazione cambio location e protocol della portaBroadcast
		pB -> portaBroadcast;
		nodoi -> listaPeer.nodo[i];
		with( pB ){
			.location = nodoi.location;
			.protocol = nodoi.protocol
		};
		println@Console("[Network Visualizer]: Ricezione blockchain da: " + i + " nodo -> " + pB.location + " - " + pB.protocol)();
		// Salvo tutte le blockchain dei vari blocchi, quella più lunga è la ufficiale
		riceviBlockchain@portaBroadcast()(blockchainTemp);
		global.blockchain[i] << blockchainTemp;
		if(#blockchainTemp.block > #global.officialBlockchain.block){
			global.puntBlockchain = i;
			global.officialBlockchain << blockchain[i]
		};
		println@Console("Lunghezza blockchain ricevuta: " + #global.blockchain[i].block)()
		// Stampare transazioni nella blockchain e wallet (TODO)
	}
}