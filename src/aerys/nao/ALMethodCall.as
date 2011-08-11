package aerys.nao
{
	import aerys.nao.event.ALEvent;
	import aerys.nao.event.ALMethodEvent;
	
	import com.ak33m.rpc.xmlrpc.XMLRPCSerializer;
	
	import flash.events.EventDispatcher;
	import flash.xml.XMLDocument;

	public class ALMethodCall extends EventDispatcher
	{
		private var _method		: ALMethod	= null;
		private var _handlers	: Array		= new Array();
		
		public function ALMethodCall(method	: ALMethod, arguments : Array)
		{
			super();
			
			initialize(method, arguments);
		}
		
		public function onResult(callback : Function) : ALMethodCall
		{
			addEventListener(ALMethodEvent.RESULT, callback);
			
			return this;
		}
		
		private function initialize(method : ALMethod, arguments : Array) : void
		{
			_method = method;
			
			var uuid		: Uuid 		= new Uuid();
			var broker		: ALBroker	= _method.broker;
			var methodName	: String	= _method.module.name + "." + _method.name;
			var command_s 	: String	= XMLRPCSerializer.serialize(methodName, arguments);
			var prev		: String	= "<iq xmlns=\"jabber:client\" to=\""
				  						  + broker.currentDevice + "\"" 
										  + " id=\"" + uuid + "\""
										  + " type=\"set\"><query xmlns=\"jabber:iq:rpc\">";
			var post		: String 	= "</query></iq>";
			
			broker.addIqHandler(uuid.toString(), responseHandler);
			broker.send(prev + command_s + post);
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
			
			dispatchEvent(new ALMethodEvent(ALMethodEvent.RESULT,
											_method.module.name,
											_method.name,
											data));
		}
	}
}