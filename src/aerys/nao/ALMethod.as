package aerys.nao
{
	import aerys.nao.event.ALMethodEvent;
	import aerys.nao.ns.nao;
	
	import flash.events.EventDispatcher;
	
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
			if(_name.substr(0, 5) == "post_")
				_name = "post." + _name.substr(5);
			_broker = broker;
			_module = module;
		}
		
		public function call(...arguments) : ALMethodCall
		{
			var call : ALMethodCall	= new ALMethodCall(this, arguments[0][0]);
			
			call.addEventListener(ALMethodEvent.RESULT, callResultHandler);
			
			dispatchEvent(new ALMethodEvent(ALMethodEvent.CALL,
											_module.name,
											_name,
											arguments));
			
			return call;
		}
		
		private function callResultHandler(event : ALMethodEvent) : void
		{
			if (event.bubbles)
			{
				dispatchEvent(new ALMethodEvent(ALMethodEvent.RESULT,
												event.module,
												event.method,
												event.data));
			}
		}
	}
}