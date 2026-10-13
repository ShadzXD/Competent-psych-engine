package util;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

/**
 * General Utilities. Will most likely be deprecated in the future.
 */
class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		// trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if (FileSystem.exists(path))
			daList = File.getContent(path);
		#else
		if (Assets.exists(path))
			daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key => count in countByColor)
		{
			if (count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false)
	{
		#if sys
		if (!absolute)
			folder = Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/'))
			folder.substr(0, folder.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end
		Sys.command(command, [folder]);
		trace('$command $folder');
		#else
		FlxG.log.warn("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	inline static public function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + cameraLerp(ratio) * (target - base);
	}

	inline static public function cameraLerp(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / 0.016666666666666666);
	}

	/**
	 * Remaps a value from a range to a new range
	 *
	 * Akin to `FlxMath.remapToRange`
	 * @param x Input value
	 * @param l1 Low bound of range 1
	 * @param h1 High bound of range 1
	 * @param l2 Low bound of range 2
	 * @param h2 High bound of range 2
	 * @return Input value remapped to range 2
	 */
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	/**
	 * Returns a `FlxEase` from a string
	 *
	 * Faster than using getProperty
	 */
	public static function getEaseFromString(ease:String = 'linear')
	{
		return switch (ease.toLowerCase().trim())
		{
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepInOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}

	/**
	 * Creates or uses a provided point and rotates it around a given `x` and `y` by radians
	 *
	 * Akin to `new FlxPoint(x,y).radians += angle`
	 * @param x
	 * @param y
	 * @param angle
	 * @param point
	 * @return A rotated FlxPoint
	 */
	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}

	/**
	 * Clamps/Bounds a value between a range that it cannot go below or over
	 *
	 * Akin to `FlxMath.bound`
	 * @param n Input value
	 * @param l Low boundary
	 * @param h High Boundary
	 * @return Clamped value
	 */
	inline public static function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h)
			n = h;
		if (n < l)
			n = l;
		return n;
	}

	inline public static function quantizeAlpha(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}
}
