package aerys.nao
{
	import aerys.nao.event.ALEvent;
	import aerys.nao.event.ALMethodEvent;
	
	import com.ak33m.rpc.xmlrpc.XMLRPCSerializer;
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.IHash;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSEvent;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.hurlant.util.Hex;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.HeaderEvent;
	
	[Event(name="connected", type="aerys.nao.event.ALEvent")]
	[Event(name="devices", type="aerys.nao.event.ALEvent")]
	[Event(name="call", type="aerys.nao.event.ALMethodEvent")]
	[Event(name="result", type="aerys.nao.event.ALMethodEvent")]
	
	public dynamic class ALBroker extends ProxyEventDispatcher
	{
		use namespace nao;
		
		private static const NS	: Namespace	= new Namespace("jabber:iq:rpc");
		
		private var _username		: String			= null;
		
		private var _xmpp			: XMPP				= null;
		
		private var _dispatcher		: EventDispatcher	= null;
		private var _modules		: Object			= new Object();
		private var _iqHandlers		: Object			= new Object();
		
		private var _devices		: ArrayCollection	= new ArrayCollection();
		private var _currentDevice	: String			= null;
		
		public function get currentDevice() : String	{ return _currentDevice; }
		
		public function set currentDevice(value : String) : void
		{
			_currentDevice = value;
		}
		
		public function get availableDevices() : ArrayCollection	{ return _devices; }
		
		public function ALBroker()
		{
			super();
			
			_dispatcher = new EventDispatcher(this);
		}
		
		public function connect(host 		: String,
								username 	: String,
								password 	: String) : void
		{
			_username = username;
			
			var hash			: IHash 	= Crypto.getHash("sha1");
			var result			: ByteArray = hash.hash(Hex.toArray(Hex.fromString(password)));
			var passwordHash	: String 	= Hex.fromArray(result);
			
			_xmpp = new XMPP();
			_xmpp.setJID(username)
				 .setPassword(passwordHash)
				 .setServer(host);

			_xmpp.addEventListener(XMPPEvent.MESSAGE, messageHandler);
			/*_xmpp.addEventListener(XMPPEvent.MESSAGE_MUC, handleMUCMessage);*/
			_xmpp.addEventListener(XMPPEvent.SESSION, sessionHandler);
			/*_xmpp.addEventListener(XMPPEvent.SECURE, handleSecure);*/
			_xmpp.addEventListener(XMPPEvent.AUTH_SUCCEEDED, authSucceedHandler);
			_xmpp.addEventListener(XMPPEvent.AUTH_FAILED, authFailedHandler);
			_xmpp.addEventListener(XMPPEvent.PRESENCE_AVAILABLE, presenceAvailableHandler);
			/*_xmpp.addEventListener(XMPPEvent.PRESENCE_UNAVAILABLE, handlePresenceUnAvail);
			_xmpp.addEventListener(XMPPEvent.PRESENCE_ERROR, handlePresenceError);
			_xmpp.addEventListener(XMPPEvent.PRESENCE_SUBSCRIBE, handlePresenceSubscribe);*/
//			_xmpp.addEventListener(XMPPEvent.ROSTER_ITEM, rosterItemHandler);
			
			_xmpp.socket.addEventListener(StreamEvent.DISCONNECTED, socketHandler);
			_xmpp.socket.addEventListener(StreamEvent.CONNECT_FAILED, socketHandler);
			_xmpp.socket.addEventListener(StreamEvent.CONNECTED, socketHandler);
			
			_xmpp.setupTLS(TLSEvent, TLSConfig, TLSEngine, TLSSocket, true, true, false);
			_xmpp.connect();
		}
		
		private function socketHandler(event : StreamEvent) : void
		{
		}
		
		private function authSucceedHandler(event : XMPPEvent) : void
		{
		}
		
		private function authFailedHandler(event : XMPPEvent) : void
		{
		}
		
		private function sessionHandler(event : XMPPEvent) : void
		{
			_xmpp.getRoster();
			_xmpp.sendPresence();
			
			dispatchEvent(new ALEvent(ALEvent.CONNECTED));
		}
		
		private function messageHandler(event : XMPPEvent) : void
		{
			if (!event.stanza.body)
				return ;
			
			var xml 	: XML 		= new XML(event.stanza.body);
			
			if (xml..NS::fault.length() != 0)
				throw new Error(xml..NS::value.NS::string,
								xml..NS::value.NS::int);
			
			var iqId 	: String 	= xml.@id;
			var handler : Function 	= _iqHandlers[iqId];
			
			if (handler != null)
			{
				handler(xml..NS::methodResponse[0]);
				
				delete _iqHandlers[iqId];
			}
		}
		
		private function presenceAvailableHandler(event : XMPPEvent) : void
		{
			var from 	: String 	= event.stanza.from;
			var match 	: Array 	= from.match(/^.*\/(nao-[0-9]+)$/);
			
			if (match && match.length == 2 && !_devices.contains(match[1]))
				_devices.addItem(match[1]);
		}

		nao function send(data : String, to : String = null) : void
		{
//			_xmpp.sendMessage(to || _dst, data);
			_xmpp.sendMessage(_username + "/" + _currentDevice, data);
		}
		
		nao function addIqHandler(iq : String, handler : Function) : void
		{
			_iqHandlers[iq] = handler;
		}
		
		override protected function getProperty(name : *) : *
		{
			var moduleName 	: String 	= name;
			var module		: ALModule	= _modules[moduleName];
			
			if (!module)
			{
				module = new ALModule(moduleName, this);
				module.addEventListener(ALMethodEvent.CALL, methodHandler);
				module.addEventListener(ALMethodEvent.RESULT, methodHandler);
				
				_modules[moduleName] = module;
			}
			
			return module;
		}
		
		private function methodHandler(event : ALMethodEvent) : void
		{
			if (event.bubbles)
				dispatchEvent(event);
		}
		
	}
}