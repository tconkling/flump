//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.display.DisplayObject;
import flash.events.MouseEvent;

import mx.managers.PopUpManager;

import com.threerings.util.F;

public class ErrorWindowMgr
{
    public static function showErrorPopup (headline :String, details :String,
        parent :DisplayObject) :void {

        var popup :ErrorWindow = new ErrorWindow();
        popup.x = (parent.width - popup.width) * 0.5;
        popup.y = (parent.height - popup.height) * 0.5;
        PopUpManager.addPopUp(popup, parent, true);

        popup.closeButton.visible = false;
        popup.headline.text = headline;
        popup.details.text = details;
        popup.ok.addEventListener(MouseEvent.CLICK, F.callback(PopUpManager.removePopUp, popup));
    }
}
}
