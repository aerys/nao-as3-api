package aerys.nao
{
	import aerys.nao.ns.nao;
	import aerys.nao.utils.MD5;

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
			var md5Hash : String = MD5.hash(event);
			
			_broker.addSubscribeIqHandler(md5Hash, callback);
			_broker.ALMemory.post_subscribeToMicroEvent(event, "ALTelepathe", _broker.username + "/ALSubscriber.post." + md5Hash, "_rpcCallback");
		}
		public function unsubscribe(event : String) : void
		{
			_broker.removeSubscribeIqHandler(MD5.hash(event));
			_broker.ALMemory.post_unsubscribeToMicroEvent(event, "ALTelepathe");
		}
	}
}