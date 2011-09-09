package aerys.nao.event
{
	import flash.events.Event;
	
	public class ALEvent extends Event
	{
		public static const CONNECTED			: String	= "connected";
		public static const AUTH_SUCCEED		: String	= "authSucceed";
		public static const AUTH_FAILED			: String	= "authSucceed";
		public static const DEVICE_AVAILABLE	: String	= "deviceAvailable";
		public static const MESSAGE_RECEIVED	: String	= "messageReceived";
		
		private var _data						: *			= null;

		public function get data()				: *			{ return _data; }
		public function set data(value : *)		: void 		{ _data = value; }

		
		public function ALEvent(type : String)
		{
			super(type);
		}
		
		override public function clone() : Event
		{
			var newEvent : ALEvent = new ALEvent(type);
			newEvent._data = _data;
			return newEvent;
		}
	}
}