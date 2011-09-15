package aerys.nao
{
	import aerys.nao.event.ALMethodEvent;
	import aerys.nao.ns.nao;
	import aerys.nao.rpc.XMLRPCDeserializer;
	import aerys.nao.rpc.XMLRPCSerializer;
	import aerys.nao.utils.Uuid;
	
	import flash.events.EventDispatcher;

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
								 if (event.data != null && event.data.length > 0)
								 	callback.apply(null, event.data);
								 else
								    callback.call(null, null);
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
			if (method.module.name == "AWPreferences")
				broker.sendToPreferencesProxy(prev + command_s + post);
			else
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
			
			dispatchEvent(new ALMethodEvent(ALMethodEvent.RESULT,
											_method.module.name,
											_method.name,
											data));
		}
	}
}