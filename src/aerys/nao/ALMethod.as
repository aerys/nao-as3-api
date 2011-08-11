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
		
		public function get name()		: String	{ return _name; }
		public function get broker()	: ALBroker	{ return _broker; }
		public function get module() 	: ALModule	{ return _module; }
		
		public function ALMethod(name	: String,
								 broker : ALBroker,
								 module	: ALModule)
		{
			super();
			
			_name = name;
			_broker = broker;
			_module = module;
		}
		
		public function call(...arguments) : ALMethodCall
		{
			var call : ALMethodCall	= new ALMethodCall(this, arguments[0][0]);
			
			call.addEventListener(ALMethodEvent.RESULT, callResultHandler);
			
			return call;
		}
		
		private function callResultHandler(event : ALMethodEvent) : void
		{
			dispatchEvent(event);
		}
	}
}