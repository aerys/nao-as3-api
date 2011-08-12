package aerys.nao.event
{
	import flash.events.Event;
	
	public class ALEvent extends Event
	{
		public static const CONNECTED			: String	= "connected";
		public static const DEVICE_AVAILABLE	: String	= "deviceAvailable";
		
		public function ALEvent(type : String)
		{
			super(type);
		}
		
		override public function clone() : Event
		{
			return new ALEvent(type);
		}
	}
}