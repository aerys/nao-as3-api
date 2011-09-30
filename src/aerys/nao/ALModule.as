package aerys.nao
{
	import aerys.nao.event.ALMethodEvent;
	import aerys.nao.utils.ProxyEventDispatcher;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.describeType;
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
				method.addEventListener(ALMethodEvent.CALL, methodHandler);
				method.addEventListener(ALMethodEvent.RESULT, methodHandler);
				
				_methods[methodName] = method;
			}
			
			return method;
		}
		
		override protected function callProperty(name : *, ...rest) : *
		{
			return (getProperty(name) as ALMethod).call(rest);;
		}
		
		private function methodHandler(event : ALMethodEvent) : void
		{
			dispatchEvent(event);
		}
		
		public function exit() : void
		{
			
		}
		
		public function version() : String
		{
			return null;
		}
		
		public function ping() : Boolean
		{
			return false;
		}
		
		public function getMethodList() : Array
		{
			var xml			: XML		= describeType(this);
			var methods		: XMLList	= xml..method;
			var methodsList	: Array		= new Array();
			
			for each (var method : XML in methods)
				methodsList.push(method.@name);
				
			return methodsList;
		}
		
		public function getMethodHelp(methodName : String) : Object
		{
			return null;
		}
		
		public function getModuleHelp() : Object
		{
			return null;
		}
		
		public function getBrokerName() : String
		{
			return null;
		}
		
		public function getUsage(methodName : String) : String
		{
			return null;
		}
	}
}