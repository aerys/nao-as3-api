package aerys.nao.rpc
{
	import avmplus.getQualifiedClassName;
	
	import flash.utils.ByteArray;
	
	import mx.formatters.DateFormatter;
	import mx.utils.Base64Encoder;

	public final class XMLRPCSerializer
	{
		public static function serialize(methodName : String, arguments : Array) : String
		{
			var xmlrpc	: XML = <methodCall>
									<methodName>{methodName}</methodName>
								</methodCall>;
			
			if (arguments.length > 0)
			{
				var tparams	: XML = <params></params>;
				
				for each (var param : Object in arguments)
				tparams.appendChild(<param>
										<value>{serializeObject(param)}</value>
									</param>);
				
				xmlrpc.insertChildAfter(xmlrpc.methodName,tparams);
			}
			
			return xmlrpc;
		}
		
		public static function serializeObject(value : Object) : XMLList
		{
			if (value is String)
				return serializeString(value as String)
			else if (value is Number && Math.floor(value as Number) == value)
				return serializeInteger(value as int);
			else if (value is Boolean)
				return serializeBoolean(value as Boolean);
			else if (value is Number)
				return serializeDouble(value as Number);
			else if (value is Date)
				return serializeDate(value as Date);
			else if (value is Array)
				return serializeArray(value as Array);
			else if (value is Object)
				return serializeStruct(value as Object);
			
			throw new Error("Unhandled type '" + getQualifiedClassName(value) + "'");
		}
		
		private static function serializeString(rstring : String) : XMLList
		{
			return new XMLList("<" + XMLRPCType.STRING + ">"
							   + rstring
							   + "</" + XMLRPCType.STRING + ">");
		}
		
		private static function serializeBoolean(rboolean : Boolean) : XMLList
		{
			return new XMLList("<" + XMLRPCType.BOOLEAN + ">"
							   + (rboolean ? "1" : "0")
							   + "</" + XMLRPCType.BOOLEAN + ">");
		}
		
		private static function serializeInteger(rinteger : int) : XMLList
		{
			return new XMLList("<" + XMLRPCType.INT + ">"
							   + rinteger
							   + "</" + XMLRPCType.INT + ">");
		}
		
		private static function serializeDouble(rdouble : Number) : XMLList
		{
			return new XMLList("<" + XMLRPCType.DOUBLE + ">"
							   + rdouble
							   + "</" + XMLRPCType.DOUBLE + ">");
		}
		
		private static function serializeDate (rdate:Date):XMLList
		{
			var tdateformatter	: DateFormatter	= new DateFormatter();
			
			tdateformatter.formatString = "YYYYMMDDTJJ:NN:SS";
			
			return new XMLList("<" + XMLRPCType.DATE + ">"
							   + tdateformatter.format(rdate)
							   + "</" + XMLRPCType.DATE + ">");
		}
		
		private static function serializeArray(rarray : Array) : XMLList
		{
			var tarrayxml		: XML = <array></array>
			var tarraydataxml	: XML = <data></data>
			
			for (var i : int; i < rarray.length; i++)
				tarraydataxml.appendChild(<value>{serializeObject(rarray[i])}</value>);
			
			tarrayxml.appendChild(tarraydataxml);
			
			return new XMLList(tarrayxml);
		}
		
		private static function serializeBase64(rbase64 : ByteArray) : XMLList
		{
			var enc	: Base64Encoder = new Base64Encoder();
			
			enc.encodeBytes(rbase64);
			
			return new XMLList("<" + XMLRPCType.BASE64 + ">"
							   + enc.flush()
							   + "</" + XMLRPCType.BASE64 + ">");
		}
		
		private static function serializeStruct(rprops : Object) : XMLList
		{
			var tstructxml 	: XML = <struct></struct>;
			var i 			: int = 0;
			
			for (var j : * in rprops)
			{
				tstructxml.appendChild(<member>
										<name>{j}</name>
										<value>{serializeObject(rprops[j])}</value>
									   </member>);
			}
			
			return new XMLList(tstructxml);
		}
	}
}