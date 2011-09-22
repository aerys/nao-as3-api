package aerys.nao
{
	import aerys.nao.ns.nao;
	import aerys.nao.utils.Uuid;

	public class ALSubscribe
	{
		use namespace nao;
		
		private var _broker : ALBroker;
		
		public function ALSubscribe(broker : ALBroker)
		{
			_broker = broker;
		}
		
		public function subscribe(event : String, callback : Function) : void
		{
			var uuid 		: Uuid 		= new Uuid();
			var uuidString 	: String 	= uuid.toString();
			
			_broker.addSubscribeIqHandler(uuidString, callback);
			_broker.ALMemory.post_subscribeToMicroEvent(event, "ALTelepathe", _broker.username + "/ALSubscriber.post." + uuidString, "_rpcCallback");
		}
		
		public function unsubscribe(event : String) : void
		{
			_broker.ALMemory.post_unsubscribeToMicroEvent(event, "ALTelepathe");
		}
	}
}