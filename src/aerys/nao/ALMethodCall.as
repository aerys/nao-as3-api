package aerys.nao
{
	import aerys.nao.event.ALEvent;
	import aerys.nao.event.ALMethodEvent;

	public class ALMethodCall
	{
		private var _method		: ALMethod	= null;
		private var _handlers	: Array		= new Array();
		
		public function ALMethodCall(method	: ALMethod)
		{
			_method = method;
			_method.addEventListener(ALMethodEvent.RESULT,
									 methodResultHandler);
		}
		
		public function onComplete(handler : Function) : void
		{
			_handlers.push(handler);
		}
		
		private function methodResultHandler(event : ALMethodEvent) : void
		{
			_method.removeEventListener(ALMethodEvent.RESULT,
										methodResultHandler);
			
			for each (var handler : Function in _handlers)
				handler.call(null, event.data);
		}
	}
}