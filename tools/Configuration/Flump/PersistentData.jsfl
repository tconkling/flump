function colorTheme () {
	return fl.getThemeColor(fl.getThemeColorParameters()[0])+","+fl.getThemeColor(fl.getThemeColorParameters()[5]);
}

function clear () {
	//fl.trace ("clear");
	var doc = fl.getDocumentDOM(); 
	if (doc) { 
		var elem = fl.getDocumentDOM().selection[0]; 
		if (elem!=null) {
			var lList = elem.getPersistentDataNames();
			for (var i=0;i<lList.length;i++) elem.removePersistentData(lList[i]);
		}
	}
}

function load () {
	//fl.trace ("load");
	var doc = fl.getDocumentDOM(); 
	if (doc) { 
		var elem = fl.getDocumentDOM().selection[0]; 
		if (elem!=null) {
			var lList = elem.getPersistentDataNames();
			var lArg = "";
			for (var i=0;i<lList.length;i++) lArg+=lList[i]+"="+elem.getPersistentData(lList[i])+"&";
			return lArg.substring(0,lArg.length-1);
		}
	}
	
	return "";
}

function save (pArg) {
	//fl.trace ("save:"+pArg);
	var doc = fl.getDocumentDOM(); 
	if (doc) { 
		var elem = fl.getDocumentDOM().selection[0]; 		
		if (elem!=null) {
			clear();			
			if (pArg=="") return;
			var lList=pArg.split("&");		
			for (i =0;i<lList.length;i++) {
				var lItem=lList[i].split("=");
				var lKey=lItem[0];
				var lValue=lItem[1];
			
				if (lValue.split(",").length>1) {
					var lArray=lValue.split(",");
					var lType="integerArray";
					for (var j=0;j<lArray.length;j++) {						
						if (isNaN(parseInt(lArray[j]))) {
							lType="string";
							break;
						} else if (parseInt(lArray[j]).toString()==lArray[j]) lArray[j]=parseInt(lArray[j]);
						else {
							lType="doubleArray";
							lArray[j]=parseFloat(lArray[j]);
						}
					}
					if (lType=="string") elem.setPersistentData( lKey, "string", lValue);
					else elem.setPersistentData( lKey,lType, lArray );
				} else if (parseInt(lValue).toString()==lValue) elem.setPersistentData( lKey, "integer", parseInt(lValue) ); 
				else if (parseFloat(lValue).toString()==lValue) elem.setPersistentData( lKey, "double", parseFloat(lValue) ); 
				else elem.setPersistentData( lKey, "string", lValue);
			
			}
		} 
	}
	
}