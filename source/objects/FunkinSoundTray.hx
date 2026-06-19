package objects;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import openfl.display.Sprite;
import flash.media.Sound;
import lime.ui.Window;

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;

	var volumeMaxSound:Sound;

	public function new()
	{
		// calls super, then removes all children to add our own
		// graphics
		super();
		removeChildren();

		var bg:Bitmap = new Bitmap(Assets.getBitmapData(Paths.getPath("images/soundtray/volumebox.png", IMAGE)));
		bg.scaleX = graphicScale;
		bg.scaleY = graphicScale;
		bg.smoothing = true;
		addChild(bg);

		y = -height;
		visible = false;

		// makes an alpha'd version of all the bars (bar_10.png)
		var backingBar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.getPath("images/soundtray/bars_10.png", IMAGE)));
		backingBar.x = 9;
		backingBar.y = 5;
		backingBar.scaleX = graphicScale;
		backingBar.scaleY = graphicScale;
		backingBar.smoothing = true;
		addChild(backingBar);
		backingBar.alpha = 0.4;

		// clear the bars array entirely, it was initialized
		// in the super class
		_bars = [];

		// 1...11 due to how block named the assets,
		// we are trying to get assets bars_1-10
		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.getPath("images/soundtray/bars_" + i + ".png", IMAGE)));
			bar.x = backingBar.x;
			bar.y = 5;
			bar.scaleX = graphicScale;
			bar.scaleY = graphicScale;
			bar.smoothing = true;
			addChild(bar);
			_bars.push(bar);
		}
		volumeUpSound = Paths.sound("soundtray/Volup");
		volumeDownSound = Paths.sound("soundtray/Voldown");
		volumeMaxSound = Paths.sound("soundtray/VolMAX");
	}

	override public function update(ms:Float):Void
	{
		y = CoolUtil.coolLerp(y, lerpYPos, 0.1);
		alpha = CoolUtil.coolLerp(alpha, alphaTarget, 0.25);

		// If it has volume, we want to auto-hide after 1 second (1000ms), we simply decrement a timer
		var hasVolume:Bool = (!FlxG.sound.muted && FlxG.sound.volume > 0);

		if (hasVolume)
		{
			// Animate sound tray thing
			if (_timer > 0)
			{
				_timer -= (ms / 1000);
			}
			else if (y >= -height)
      		{
        		lerpYPos = -height - 10;
        		alphaTarget = 0;
      		}

			
      		if (y <= -height)
      		{
        		visible = false;
       			active = false;
      		}	
		}
		else if (!visible)
			moveTrayMakeVisible();
	}

	override function showIncrement():Void
	{
		moveTrayMakeVisible(true);
		saveVolumePreferences();
	}

	override function showDecrement():Void
	{
		moveTrayMakeVisible(false);
		saveVolumePreferences();
	}

	function moveTrayMakeVisible(up:Bool = false):Void
	{
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		alphaTarget = 1;

		for (i in 0..._bars.length)
			_bars[i].visible = i < getGlobalVolume(up);
	}

	function getGlobalVolume(up:Bool = false):Int
	{
		var globalVolume = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted || FlxG.sound.volume == 0)
			globalVolume = 0;

		if (!silent)
		{
			// This is a String currently, but there is or was a Flixel PR to change this to a FlxSound or a Sound bject
			var sound:Sound = up ? volumeUpSound : volumeDownSound;

			if (globalVolume == 10)
				sound = volumeMaxSound;
			if (sound != null)
				FlxG.sound.load(sound).play().volume = 0.3;
		}

		return globalVolume;
	}

	function saveVolumePreferences():Void
	{
		// Actually save when the volume is changed / modified
		#if FLX_SAVE
		// Save sound preferences
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}
}
