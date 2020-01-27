////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

package mx.graphics.codec
{

import flash.display.BitmapData;
import flash.utils.ByteArray;

/**
 *  The IImageEncoder interface defines the interface
 *  that image encoders implement to take BitmapData objects,
 *  or ByteArrays containing raw ARGB pixels, as input
 *  and convert them to popular image formats such as PNG or JPEG.
 *
 *  @see PNGEncoder
 *  @see JPEGEncoder
 *
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public interface IImageEncoder
{
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  contentType
    //----------------------------------

    /**
     *  The MIME type for the image format that this encoder produces.
     *
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    function get contentType():String;

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  Encodes a BitmapData object as a ByteArray.
     *
     *  @param bitmapData The input BitmapData object.
     *
     *  @return Returns a ByteArray object containing encoded image data.
     *
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    function encode(bitmapData:BitmapData):ByteArray;

    /**
     *  Encodes a ByteArray object containing raw pixels
     *  in 32-bit ARGB (Alpha, Red, Green, Blue) format
     *  as a new ByteArray object containing encoded image data.
     *  The original ByteArray is left unchanged.
     *
     *  @param byteArray The input ByteArray object containing raw pixels.
     *  This ByteArray should contain
     *  <code>4 * width * height</code> bytes.
     *  Each pixel is represented by 4 bytes, in the order ARGB.
     *  The first four bytes represent the top-left pixel of the image.
     *  The next four bytes represent the pixel to its right, etc.
     *  Each row follows the previous one without any padding.
     *
     *  @param width The width of the input image, in pixels.
     *
     *  @param height The height of the input image, in pixels.
     *
     *  @param transparent If <code>false</code>,
     *  alpha channel information is ignored.
     *
     *  @return Returns a ByteArray object containing encoded image data.
     *
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    function encodeByteArray(byteArray:ByteArray, width:int, height:int,
                             transparent:Boolean = true):ByteArray;
}

}