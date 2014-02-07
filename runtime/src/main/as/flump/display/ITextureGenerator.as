/**
 * @Author: Karl Harmer, Plumbee Ltd
 */
package flump.display
{
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.textures.Texture;

public interface ITextureGenerator
{
	function fromEmbeddedAsset(onTextureCallback : Function, assetClass : Class, mipMapping : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void;

	function fromBitmap(onTextureCallback : Function, bitmap : Bitmap, generateMipMaps : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void;

	function fromBitmapData(onTextureCallback : Function, data : BitmapData, generateMipMaps : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void;

	function fromAtfData(onTextureCallback : Function, data : ByteArray, scale : Number = 1, useMipMaps : Boolean = true, async : Function = null) : void;

	function fromColor(onTextureCallback : Function, width : Number, height : Number, color : uint = 0xffffffff, optimizeForRenderToTexture : Boolean = false, scale : Number = -1, format : String = "bgra") : void;

	function empty(onTextureCallback : Function, width : Number, height : Number, premultipliedAlpha : Boolean = true, mipMapping : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = -1, format : String = "bgra") : void;

	function fromTexture(onTextureCallback : Function, texture : Texture, region : Rectangle = null, frame : Rectangle = null, rotated : Boolean = false) : void;
}
}
