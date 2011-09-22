package aerys.nao
{
	import aerys.nao.event.ALEvent;
	import aerys.nao.event.ALMethodEvent;
	import aerys.nao.ns.nao;
	import aerys.nao.rpc.XMLRPCDeserializer;
	import aerys.nao.utils.ProxyEventDispatcher;
	
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
	
	import flash.utils.ByteArray;
	
	[Event(name="connected", type="aerys.nao.event.ALEvent")]
	[Event(name="deviceAvailable", type="aerys.nao.event.ALEvent")]
	[Event(name="call", type="aerys.nao.event.ALMethodEvent")]
	[Event(name="result", type="aerys.nao.event.ALMethodEvent")]
	
	public dynamic class ALBroker extends ProxyEventDispatcher
	{
		use namespace nao;
		
		private static const NS			: Namespace	= new Namespace("jabber:iq:rpc");
		
		private var _username			: String			= null;
		private var _host				: String			= null;
		
		private var _xmpp				: XMPP				= null;
		private var _prefxmpp			: XMPP				= null;
		private var _connected			: Boolean			= false;
		
		private var _modules			: Object			= new Object();
		private var _iqHandlers			: Object			= new Object();
		private var _subcribeIqHandlers	: Object			= new Object();
		
		private var _devices			: Array				= new Array();
		private var _currentDevice		: String			= null;
		
		public function get username()		: String	{ return _username; }
		public function get connected()		: Boolean	{ return _connected; }
		public function get devices() 		: Array		{ return _devices; }
		public function get currentDevice() : String	{ return _currentDevice; }
		
		public function set currentDevice(value : String) : void
		{
			_currentDevice = value;
		}
		
		public function connect(host 		: String,
								username 	: String,
								password 	: String = "") : void
		{
			_username 	= username;
			_host 		= host;
			
			var hash			: IHash 	= Crypto.getHash("sha1");
			var result			: ByteArray = hash.hash(Hex.toArray(Hex.fromString(password)));
			var passwordHash	: String 	= Hex.fromArray(result);
			
			_xmpp = new XMPP();
			
			if (password != "")
				_xmpp.setJID(username)
					 .setPassword(passwordHash)
					 .setServer(host);
			else
				_xmpp.setJID(username)
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
			
			/*_xmpp.socket.addEventListener(StreamEvent.DISCONNECTED, socketHandler);
			_xmpp.socket.addEventListener(StreamEvent.CONNECT_FAILED, socketHandler);
			_xmpp.socket.addEventListener(StreamEvent.CONNECTED, socketHandler);*/
			
			_xmpp.setupTLS(TLSEvent, TLSConfig, TLSEngine, TLSSocket, true, true, false);
			_xmpp.connect();
		}
		
		public function disconnect() : void
		{
			_xmpp.disconnect();
			_connected = false;
		}
		
		/*private function socketHandler(event : StreamEvent) : void
		{
		}*/
		
		private function authSucceedHandler(event : XMPPEvent) : void
		{
			dispatchEvent(new ALEvent(ALEvent.AUTH_SUCCEED));
		}
		
		private function authFailedHandler(event : XMPPEvent) : void
		{
			dispatchEvent(new ALEvent(ALEvent.AUTH_FAILED));
		}
		
		private function sessionHandler(event : XMPPEvent) : void
		{
			_xmpp.getRoster();
			_xmpp.sendPresence();

			_connected = true;
			dispatchEvent(new ALEvent(ALEvent.CONNECTED));
		}
		
		private function messageHandler(event : XMPPEvent) : void
		{
			if (!event.stanza.body)
				return ;
			
			var xml 	: XML 		= new XML(event.stanza.body);
			
			//trace(event.stanza.body);
			
			
			if (xml..NS::fault.length() != 0)
				throw new Error((xml..NS::value.NS::string[0] as XML).toString(),
								xml..NS::value.NS::int.toString());
			
			var iqId 	: String 	= xml.@id;
			var handler : Function 	= _iqHandlers[iqId];
			
			if (handler != null)
			{
				handler(xml..NS::methodResponse[0]);
				
				delete _iqHandlers[iqId];
			}
			else
			{
				if (xml..NS::methodCall[0] != null)
					orphanMessageHandler(xml..NS::methodCall[0]);
			}
		}
		
		private function presenceAvailableHandler(event : XMPPEvent) : void
		{
			var from 	: String 	= event.stanza.from;
			var match 	: Array 	= from.match(/^.*\/(nao-[0-9]+)$/);
			
			if (match && match.length == 2)
			{
				for (var i : int = 0; i < _devices.length && _devices[i] != match[1]; ++i)
					continue ;
			
				if (i >= _devices.length)
					_devices.push(match[1]);
			}
			
			dispatchEvent(new ALEvent(ALEvent.DEVICE_AVAILABLE));
		}
		
		nao function send(data : String, to : String = null) : void
		{
			_xmpp.sendMessage(_username + "/" + _currentDevice, data);
		}
		
		nao function sendToPreferencesProxy(data : String, to : String = null) : void
		{
			_xmpp.sendMessage("_preferences@" + _host +  "/" + _currentDevice, data);
		}
		
		nao function addIqHandler(iq : String, handler : Function) : void
		{
			_iqHandlers[iq] = handler;
		}
		
		nao function addSubscribeIqHandler(iq : String, handler : Function) : void
		{
			_subcribeIqHandlers[iq] = handler;
		}
		
		override protected function getProperty(name : *) : *
		{			
			var moduleName 	: String 	= name;
			
			if(moduleName == "ALSubscribe")
			{
				if (!_modules.hasOwnProperty(moduleName))
					_modules[moduleName] = new ALSubscribe(this);
				return _modules[moduleName];
			}
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
		
		
		private function orphanMessageHandler(response : XML) : void
		{
			var data 	: Object = null;
			var method 	: String = "";
			var module 	: String = "";
			
			if (response)
			{
				var nsRegEx		: RegExp 	= / xmlns(?:.*?)?=\".*?\"/gim;
				var xmlString	: String	= response.toString();
				
				var methodname : Array = (response..NS::methodName.toString()).split(".");
				
				module = methodname[0];
				if(methodname[1] == "post")
					method = methodname[2];
				else
					method = methodname[1];

				data = XMLRPCDeserializer.deserialize(new XML(xmlString.replace(nsRegEx, "")));
				
				if (module == "ALSubscriber")	
				{					
					var handler : Function = _subcribeIqHandlers[method];
					handler(data[1]);
				}
				else
				{
					dispatchEvent(new ALMethodEvent(ALMethodEvent.MESSAGE_RECEIVED, module, method, data));
				}
			}
		}
	}
}