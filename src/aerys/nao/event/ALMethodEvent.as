package aerys.nao.event
{
	import flash.events.Event;
	
	public class ALMethodEvent extends Event
	{
		public static const RESULT				: String	= "result";
		public static const CALL				: String	= "call";
		public static const MESSAGE_RECEIVED	: String	= "messageReceived";
		
		private var _module	: String	= null;
		private var _method	: String	= null;
		private var _data	: *			= null;
		
		public function get module()	: String	{ return _module; }
		public function get method()	: String	{ return _method; }
		public function get data()		: *			{ return _data; }
		
		public function ALMethodEvent(type		: String,
									  module	: String,
									  method	: String,
									  data		: *)
		{
			super(type, true);
			
			_module = module;
			_method = method;
			_data = data;
		}
		
		override public function clone() : Event
		{
			return new ALMethodEvent(type, _module, _method, _data);
		}
	}
}