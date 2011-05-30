package aerys.nao
{
	import aerys.nao.event.ALEvent;
	import aerys.nao.event.ALMethodEvent;
	
	import com.ak33m.rpc.xmlrpc.XMLRPCSerializer;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.xml.XMLDocument;
	
	[Event(name="call", type="aerys.nao.event.ALMethodEvent")]
	[Event(name="result", type="aerys.nao.event.ALMethodEvent")]
	
	public class ALMethod extends EventDispatcher
	{
		use namespace nao;
		
		private static const NS	: Namespace	= new Namespace("jabber:iq:rpc");
		
		private var _name		: String	= null;
		private var _broker		: ALBroker	= null;
		private var _module		: ALModule	= null;
		
		private var _uuids		: Array		= new Array();
		
		public function ALMethod(name	: String,
								 broker : ALBroker,
								 module	: ALModule)
		{
			super();
			
			_name = name;
			_broker = broker;
			_module = module;
		}
		
		public function call(...arguments) : void
		{
			var uuid		: Uuid 		= new Uuid();
			
			var command_s 	: String	= XMLRPCSerializer.serialize(_module.name + "." + _name, arguments[0][0]);
			var prev		: String	= "<iq xmlns=\"jabber:client\" to=\"" + _broker.currentDevice + "\"" 
										  + " id=\"" + uuid + "\""
										  + " type=\"set\"><query xmlns=\"jabber:iq:rpc\">";
			var post		: String 	= "</query></iq>";
			var resComm		: String 	= prev + command_s + post;
			
			_broker.addIqHandler(uuid.toString(), responseHandler);
			_broker.send(resComm);
			
			dispatchEvent(new ALMethodEvent(ALMethodEvent.CALL, _module.name, _name, arguments));
		}
		
		private function responseHandler(response : XML) : void
		{
			var data : Object = null;

			if (response)
			{
				var nsRegEx		: RegExp 		= new RegExp(" xmlns(?:.*?)?=\".*?\"", "gim");
				var xmlString	: String		= response.toString();
				var xmlDocument : XMLDocument 	= new XMLDocument(xmlString.replace(nsRegEx, ""));
				
				data = XMLRPCSerializer.deserialize(xmlDocument);
			}

			dispatchEvent(new ALMethodEvent(ALMethodEvent.RESULT, _module.name, _name, data));
		}
	}
}