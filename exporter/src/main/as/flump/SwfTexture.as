//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.ColorMatrixFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flump.xfl.XflMovie;

import flump.executor.load.LoadedSwf;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class SwfTexture
{
    public function get symbol():String {   return _symbol;     }
    public function get origin():Point  {   return new Point(_origin.x*_scale, _origin.y*_scale);     }
    public function get w():int {   return Math.ceil(_w*_scale);  }
    public function get h():int {   return Math.ceil(_h*_scale);  }
    public function get a():int {   return w*h;  }

    public static function fromFlipbook (lib :XflLibrary, movie :MovieMold, frame :int,
        quality :String = StageQuality.BEST, scale :Number = 1) :SwfTexture {

        const klass :Class = Class(lib.swf.getSymbol(movie.id));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        const name :String = movie.id + "_flipbook_" + frame;
        return new SwfTexture(name, clip, scale, quality);
    }

    public static function fromTexture (swf :LoadedSwf, tex :XflTexture,
        quality :String = StageQuality.BEST, scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(tex.symbol));
        const instance :Object = new klass();
        const disp :DisplayObject = (instance is BitmapData) ?
            new Bitmap(BitmapData(instance)) : DisplayObject(instance);
        return new SwfTexture(tex.symbol, disp, scale, quality);
    }

    public function SwfTexture (symbol :String, disp :DisplayObject, scale :Number, quality :String) {
        this._symbol = symbol;
        this._quality = quality;

        // wrap object twice for convenience
        var wrapper:Sprite = new Sprite();
        wrapper.addChild(disp);
        this._disp = new Sprite();
        this._disp.addChild(wrapper);

        // set the scale and size info
        this._treatAsFiltered = this.hasPotentiallySizeAlteringFilters(disp);
        this.setScale(scale);
    }
    
    // scale can be changed after creation, if desired
    public function setScale(value:Number):void
    {
        // To compensate for the fact that filters don't "scale", do the following
        // if filtered:
        //    render at scale 1
        //    then scale bitmapData to target size
        // if not filtered:
        //    set the scale in the wrapper
        //    render directly at target size with vector renderer
        if (this._treatAsFiltered) {
            // cache the scale to use later
            this._scale = value;
            // only need to calculate size once, since this._disp is not changing
            if (this._visualBounds == null) {
                recalculateSizeInfo();
            }
        } else {
            // embed the scale in this._disp
            var wrapper:DisplayObject = this._disp.getChildAt(0);
            wrapper.scaleX = wrapper.scaleY = value;
            this._scale = 1;
            // recalculate size since this._disp has changed
            recalculateSizeInfo();
        }
    }

    public function toBitmapData (borderPadding :int = 0) :BitmapData {
        // render with vector renderer
        var bmd :BitmapData = new BitmapData(Math.ceil(this._w), Math.ceil(this._h), true, 0x00);
        var m :Matrix = new Matrix();
        m.translate(this._origin.x, this._origin.y);
        bmd.drawWithQuality(this._disp, m, null, null, null, true, this._quality);

        // scale bitmap to target size if necessary (only used if _disp contains filters)
        if (this._scale != 1.0) {
            bmd = Util.renderToBitmapData(bmd, this.w, this.h, this._quality, this._scale);
        }

        // add padding if necessary
        return (borderPadding > 0 ? Util.padBitmapBorder(bmd, borderPadding) : bmd);
    }

    public function toString () :String { return "a " + this.a + " w " + this.w + " h " + this.h; }

    private function recalculateSizeInfo() :void {
        // get normal bounds
        this._strictBounds = this._disp.getChildAt(0).getBounds(this._disp);
        this._visualBounds = this._strictBounds;
        
        // possibly increase the visual bounds (due to filter action)
        if (this._treatAsFiltered) {
            // render to bmd
            var topLeft:Point = new Point(_filteredBmd.width / 2 - this._strictBounds.width / 2 - this._strictBounds.x, _filteredBmd.height / 2 - this._strictBounds.height / 2 - this._strictBounds.y);
            var m :Matrix = new Matrix(1,0,0,1, topLeft.x, topLeft.y);
            _filteredBmd.drawWithQuality(this._disp, m, null, null, null, true, this._quality);
            
            // calculate visual bounds
            this._visualBounds = _filteredBmd.getColorBoundsRect(0xff000000, 0x00000000, false);
            _filteredBmd.fillRect(this._visualBounds, 0x0);

            // adjust registration point
            this._visualBounds.x = -(topLeft.x - this._visualBounds.x);
            this._visualBounds.y = -(topLeft.y - this._visualBounds.y);
        }
        
        // calculate derivative info
        this._origin = new Point(-this._visualBounds.x, -this._visualBounds.y);
        this._w = this._visualBounds.width;
        this._h = this._visualBounds.height;
    }
    
    private function hasPotentiallySizeAlteringFilters(dObj:DisplayObject) :Boolean {
        // check dObj's filter list
        var filters:Array = dObj.filters;
        for (var ff:int = 0, nf:int = filters.length; ff < nf; ++ff) {
            // all standard filters except ColorMatrixFilter can change the visual bounds
            if (!(filters[ff] is ColorMatrixFilter)) {
                return true;
            }
        }
        // recursively check children
        var dObjContainer:flash.display.DisplayObjectContainer = dObj as flash.display.DisplayObjectContainer;
        if (dObjContainer) {
            for (var cc:int = 0, nc:int = dObjContainer.numChildren; cc < nc; ++cc) {
                var child:DisplayObject = dObjContainer.getChildAt(cc);
                if (hasPotentiallySizeAlteringFilters(child)) {
                    return true;
                }
            }
        }
        // all clear
        return false;        
    }
    
    private var _symbol :String;
    private var _disp :DisplayObjectContainer;
    private var _w :int, _h :int;
    private var _origin :Point;
    private var _strictBounds :Rectangle;
    private var _visualBounds :Rectangle;
    private var _scale :Number;
    private var _quality :String;
    private var _treatAsFiltered:Boolean;
    
    static private var _filteredBmd:BitmapData = new BitmapData(2048, 2048, true, 0x0);
    { _filteredBmd.lock(); }
}
}
