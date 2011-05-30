package aerys.nao.event
{
	import flash.events.Event;
	
	public class ALEvent extends Event
	{
		public static const CONNECTED			: String	= "al_connected";
		public static const DEVICE_AVAILABLE	: String	= "al_device_available";
		
		public function ALEvent(type : String)
		{
			super(type);
		}
	}
}