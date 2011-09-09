package aerys.nao.rpc
{
	import mx.utils.Base64Decoder;

	public final class XMLRPCDeserializer
	{
		public static function deserialize (xmlresult : XML) : Object
		{
			var resultparamxml	: XMLList	= xmlresult.params.param;
			var faultxml		: XMLList 	= xmlresult.fault.value;
				
			var result			: Array	= [];
			
			if (resultparamxml.toString() != "")
			{
				var i : int = 0;
				for each(var resultparam : XML in resultparamxml)
				{
					if (resultparam.value.toString() != "")
						result.push(deserializeObject(resultparam.value));
				}
				
				return result;
			}
			else if (faultxml)
			{
				/*var faultobj	: * 		= decodeObject(faultxml);
				var tfault		: Fault 	= new Fault(faultobj.faultCode,faultobj.faultString);*/
				
				//				return tfault;
			}
			else
			{
				//				throw new Error(RPCMessageCodes.INVALID_XMLRPCFORMAT);
			}
			
			return null;
		}
		
		public static function deserializeObject(robject : Object) : Object
		{
			var typeName : String = robject.children()[0].name();
			
			//trace(typeName);
			if (typeName == XMLRPCType.STRING)
				return String(robject.string);
			else if (typeName == XMLRPCType.INT)
				return new int(robject.int);
			else if (typeName == XMLRPCType.I4)
				return new int(robject.i4);
			else if (typeName == XMLRPCType.DOUBLE)
				return new Number(robject.double);
			else if (typeName == XMLRPCType.FLOAT)
				return new Number(robject.float);
			else if (typeName == XMLRPCType.BOOLEAN)
			{
				if (isNaN(robject.bool))
				{
					if (String(robject.bool).toLowerCase() == "true")
						return true;
					else if (String(robject.bool).toLowerCase() == "false")
						return false;
					else
						return null;
				}
				else
				{
					return Boolean(Number(robject.bool));
				}
			}
			else if (typeName == XMLRPCType.DATE)
			{
				var tdatestring	: String 	= robject.children();
				var datepattern	: RegExp 	= /^(-?\d\d\d\d)-?(\d\d)-?(\d\d)T(\d\d):(\d\d):(\d\d)/;
				var d			: Array 	= tdatestring.match(datepattern);
				var tdate		: Date 		=  new Date(d[1],d[2]-1,d[3],d[4],d[5],d[6]);
				
				return tdate;
			}
			else if (typeName == XMLRPCType.BASE64)
			{
				var base64decoder : Base64Decoder = new Base64Decoder();
				
				base64decoder.decode(robject.base64);
				
				return base64decoder.flush();
				
			}
			else if (typeName == XMLRPCType.ARRAY)
			{
				var tarray : Array = new Array();
				
				for each (var value : * in robject.array.data.value)
				tarray.push(deserializeObject(value));
				
				return tarray;
			}
			else if (typeName == XMLRPCType.STRUCT)
			{
				var tvalue	: Object = new Object();
				
				for each (var member : * in robject.struct.member)
				tvalue[member.name] = deserializeObject(member.value);
				
				return tvalue;
			}
			else if (typeName == XMLRPCType.DOUBLE)
				return Number(robject.double);
			else 
				return String(robject);
		}
	}
}