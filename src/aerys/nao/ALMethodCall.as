package aerys.nao
{
	import aerys.nao.event.ALMethodEvent;
	import aerys.nao.rpc.XMLRPCDeserializer;
	import aerys.nao.rpc.XMLRPCType;
	
	import com.ak33m.rpc.xmlrpc.XMLRPCSerializer;
	
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	import flash.xml.XMLDocument;
	import aerys.nao.ns.nao;
	import aerys.nao.utils.Uuid;

	public class ALMethodCall extends EventDispatcher
	{
		use namespace nao;
		
		private static const NS	: Namespace	= new Namespace("jabber:iq:rpc");
		
		private var _method		: ALMethod	= null;
		private var _handlers	: Array		= new Array();
		
		public function ALMethodCall(method	: ALMethod, arguments : Array)
		{
			super();
			
			initialize(method, arguments);
		}
		
		public function onResult(callback : Function) : ALMethodCall
		{
			addEventListener(ALMethodEvent.RESULT,
							 function(event : ALMethodEvent) : void
							 {
								 callback.call(null, event.data);
							 });
			
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
				var nsRegEx		: RegExp 	= / xmlns(?:.*?)?=\".*?\"/gim;
				var xmlString	: String	= response.toString();
				
				data = XMLRPCDeserializer.deserialize(new XML(xmlString.replace(nsRegEx, "")));
			}
			
			var event : ALMethodEvent = new ALMethodEvent(ALMethodEvent.RESULT,
				_method.module.name,
				_method.name,
				data);
			
			dispatchEvent(event);
		}
	}
}