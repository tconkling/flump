package flump.xfl 
{

    public class XflCustomData 
    {
        use namespace xflns;
        
        
        public static function getCustomData(xmlList:XMLList) :Object
        {
            var data:Object={};
            var tempValue:*;
            var j:int;
            
            for (var i:String in xmlList.PD) {
                if (xmlList.PD[i].@t=="i") tempValue=parseInt(xmlList.PD[i].@v);
                else if (xmlList.PD[i].@t=="I") {
                    tempValue=xmlList.PD[i].@v.split(",");
                    for (j=0;j<tempValue.length;j++) tempValue[j]=parseInt(tempValue[j]);
                }
                else if (xmlList.PD[i].@t=="d") tempValue=parseFloat(xmlList.PD[i].@v);
                else if (xmlList.PD[i].@t=="D") {
                    tempValue=xmlList.PD[i].@v.split(",");
                    for (j=0;j<tempValue.length;j++) tempValue[j]=parseFloat(tempValue[j]);
                }
                else tempValue=xmlList.PD[i].@v.toString();
                
                data[xmlList.PD[i].@n]=tempValue;
            }
            
            for (var z:String in data) return data;
            
            return null;
        }
        
    }

}