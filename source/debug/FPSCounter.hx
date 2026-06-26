package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import util.MemoryUtil;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	public var memoryPeak:Float;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 14, color);
		autoSize = LEFT;
		multiline = true;

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		if(!visible)
			return;
		// prevents the overlay from updating every frame, why would you need to anyways
		if (deltaTimeout > 1000)
		{
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void
	{
		// so people can override it in hscript
		if (memoryMegas >= memoryPeak)
			memoryPeak = memoryMegas;

		text = 'FPS: ${currentFPS} / '
			+ ClientPrefs.data.framerate
		#if sys
			+ '\nMemory: ${MemoryUtil.formatMemory(memoryMegas)} / ${MemoryUtil.formatMemory(memoryPeak)}'#end;
		textColor = 0xFFFFFFFF;

		if (currentFPS < FlxG.drawFramerate * 0.5)
		{
			textColor = 0xFFFF0000;
		}
	}

	inline function get_memoryMegas():Float
	{
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
	}
}
