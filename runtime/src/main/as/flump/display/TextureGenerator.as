/**
 * @Author: Karl Harmer, Plumbee Ltd
 */
package flump.display
{
import flash.desktop.NativeApplication;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.textures.Texture;

public class TextureGenerator implements ITextureGenerator, IDisposable
{
	private var _textureConfig : TextureConfig;

	public function TextureGenerator()
	{
		NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onAppActivation);
	}

	public function onAppActivation(event : Event) : void
	{
		if(_textureConfig != null)
		{
			proceedTextureUpload();
		}
	}

	public function fromEmbeddedAsset(onTextureCallback : Function, assetClass : Class, mipMapping : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void
	{
		_textureConfig = new TextureConfig(TextureConfig.EMBEDDED, onTextureCallback, assetClass);
		_textureConfig.generateMipMaps = mipMapping;
		_textureConfig.optimizeForRenderToTexture = optimizeForRenderToTexture;
		_textureConfig.scale = scale;
		_textureConfig.format = format;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function fromBitmap(onTextureCallback : Function, bitmap : Bitmap, generateMipMaps : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void
	{
		_textureConfig = new TextureConfig(TextureConfig.BITMAP, onTextureCallback, bitmap);
		_textureConfig.generateMipMaps = generateMipMaps;
		_textureConfig.optimizeForRenderToTexture = optimizeForRenderToTexture;
		_textureConfig.scale = scale;
		_textureConfig.format = format;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function fromBitmapData(onTextureCallback : Function, data : BitmapData, generateMipMaps : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = 1, format : String = "bgra") : void
	{
		_textureConfig = new TextureConfig(TextureConfig.BITMAP_DATA, onTextureCallback, data);
		_textureConfig.generateMipMaps = generateMipMaps;
		_textureConfig.optimizeForRenderToTexture = optimizeForRenderToTexture;
		_textureConfig.scale = scale;
		_textureConfig.format = format;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function fromAtfData(onTextureCallback : Function, data : ByteArray, scale : Number = 1, useMipMaps : Boolean = true, async : Function = null) : void
	{
		_textureConfig = new TextureConfig(TextureConfig.ATF, onTextureCallback, data);
		_textureConfig.generateMipMaps = useMipMaps;
		_textureConfig.scale = scale;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function fromColor(onTextureCallback : Function, width : Number, height : Number, color : uint = 0xffffffff, optimizeForRenderToTexture : Boolean = false, scale : Number = -1, format : String = "bgra") : void
	{
		_textureConfig = new TextureConfig(TextureConfig.COLOR, onTextureCallback);
		_textureConfig.width = width;
		_textureConfig.height = height;
		_textureConfig.color = color;
		_textureConfig.optimizeForRenderToTexture = optimizeForRenderToTexture;
		_textureConfig.scale = scale;
		_textureConfig.format = format;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function empty(onTextureCallback : Function, width : Number, height : Number, premultipliedAlpha : Boolean = true, mipMapping : Boolean = true, optimizeForRenderToTexture : Boolean = false, scale : Number = -1, format : String = "bgra") : void
	{
		_textureConfig = new TextureConfig(TextureConfig.EMPTY, onTextureCallback);
		_textureConfig.width = width;
		_textureConfig.height = height;
		_textureConfig.premultipliedAlpha = premultipliedAlpha;
		_textureConfig.optimizeForRenderToTexture = optimizeForRenderToTexture;
		_textureConfig.scale = scale;
		_textureConfig.format = format;

		if(NativeApplicationState.isActive)
		{
			proceedTextureUpload();
		}
	}

	public function fromTexture(onTextureCallback : Function, texture : Texture, region : Rectangle = null, frame : Rectangle = null, rotated : Boolean = false) : void
	{
		onTextureCallback(Texture.fromTexture(texture, region, frame));
	}

	private function proceedTextureUpload() : void
	{
		switch(_textureConfig.type)
		{
			case TextureConfig.EMBEDDED :
				_textureConfig.callback(Texture.fromEmbeddedAsset(_textureConfig.data, _textureConfig.generateMipMaps, _textureConfig.optimizeForRenderToTexture, _textureConfig.scale, _textureConfig.format));
				break;
			case TextureConfig.BITMAP :
				_textureConfig.callback(Texture.fromBitmap(_textureConfig.data, _textureConfig.generateMipMaps, _textureConfig.optimizeForRenderToTexture, _textureConfig.scale, _textureConfig.format));
				break;
			case TextureConfig.BITMAP_DATA :
				_textureConfig.callback(Texture.fromBitmapData(_textureConfig.data, _textureConfig.generateMipMaps, _textureConfig.optimizeForRenderToTexture, _textureConfig.scale, _textureConfig.format));
				break;
			case TextureConfig.ATF :
				_textureConfig.callback(Texture.fromAtfData(_textureConfig.data, _textureConfig.scale, _textureConfig.generateMipMaps));
				break;
			case TextureConfig.COLOR :
				_textureConfig.callback(Texture.fromColor(_textureConfig.width, _textureConfig.height, _textureConfig.color, _textureConfig.optimizeForRenderToTexture, _textureConfig.scale, _textureConfig.format));
				break;
			case TextureConfig.EMPTY :
				_textureConfig.callback(Texture.empty(_textureConfig.width, _textureConfig.height, _textureConfig.premultipliedAlpha, _textureConfig.generateMipMaps, _textureConfig.optimizeForRenderToTexture, _textureConfig.scale, _textureConfig.format));
				break;
		}

		_textureConfig = null;
	}

	public function dispose() : void
	{
		NativeApplication.nativeApplication.removeEventListener(Event.ACTIVATE, onAppActivation);
	}
}
}

internal class TextureConfig
{
	public static const EMBEDDED : uint = 0;
	public static const BITMAP : uint = 1;
	public static const BITMAP_DATA : uint = 2;
	public static const ATF : uint = 3;
	public static const COLOR : uint = 4;
	public static const EMPTY : uint = 5;

	private var _type : uint;
	private var _data : *;
	private var _callback : Function;

	public var width : Number;
	public var height : Number;
	public var color : uint;
	public var scale : Number;
	public var optimizeForRenderToTexture : Boolean;
	public var generateMipMaps : Boolean;
	public var format : String;
	public var premultipliedAlpha : Boolean;

	public function TextureConfig(type : uint, callback : Function, data : * = null) : void
	{
	  	_type = type;
		_data = data;
		_callback = callback;
	}

	public function get type() : uint
	{
		return _type;
	}

	public function get data() : *
	{
		return _data;
	}

	public function get callback() : Function
	{
		return _callback;
	}
}
