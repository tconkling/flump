//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;

import flash.display.DisplayObject;
import flash.events.MouseEvent;

import mx.managers.PopUpManager;

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
        popup.ok.addEventListener(MouseEvent.CLICK, F.bind(PopUpManager.removePopUp, popup));
    }
}
}
