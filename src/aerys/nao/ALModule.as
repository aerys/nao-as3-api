package aerys.nao
{
	import aerys.nao.event.ALMethodEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	[Event(name="call", type="aerys.nao.event.ALMethodEvent")]
	[Event(name="result", type="aerys.nao.event.ALMethodEvent")]

	public dynamic class ALModule extends ProxyEventDispatcher
	{
		private var _name		: String		= null;
		private var _broker		: ALBroker		= null;
		
		private var _methods	: Object		= new Object();
		
		public function get name() : String	{ return _name; }
		
		public function ALModule(name 	: String,
								 broker	: ALBroker)
		{
			super();
			
			_name = name;
			_broker = broker;
		}
		
		override protected function getProperty(name : *) : *
		{
			var methodName 	: String 	= name;
			var method		: ALMethod	= _methods[methodName];
			
			if (!method)
			{
				method = new ALMethod(methodName, _broker, this);
				//method.addEventListener(ALMethodEvent.CALL, methodHandler);
				//method.addEventListener(ALMethodEvent.RESULT, methodHandler);
				
				_methods[methodName] = method;
			}
			
			return method;
		}
		
		override protected function callProperty(name : *, ...rest) : *
		{
			var method : ALMethod = getProperty(name);
			
			method.call(rest);
			
			return new ALMethodCall(method);
		}
		
		private function methodHandler(event : ALMethodEvent) : void
		{
			if (event.bubbles)
				dispatchEvent(event);
		}
	}
}