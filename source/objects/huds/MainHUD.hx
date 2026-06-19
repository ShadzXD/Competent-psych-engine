package objects.huds;

import flixel.group.FlxGroup;
import objects.HealthIcon;
import objects.Bar;

@:access(states.PlayState)
/**
 * Main class used for general functions.
 * Also used for retrieving PlayState Variables.
 */
class MainHUD extends FlxGroup
{
	// Things you can edit by overriding in the subclass.
	public var hudFont:String = 'vcr.ttf'; // font used in HUD
	public var healthBar:Bar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var scoreText:FlxText;
	public var songSeconds:Float;
	public var songLength:Float;
	public var timeTxt:FlxText;
	public var healthValue:Float = 1;

	public var timeBar:Bar;

	// disables health, if not needed
	public var useHealth:Bool = true;
	// used to group the icons, to be able to add multiple icons easily
	public var iconGroup:FlxTypedGroup<HealthIcon>;

	public static var instance:MainHUD;

	var ratingFC:String;
	var useHealthBarColors = true;

	public function new()
	{
		instance = this;

		super();
	}

	public var curDecBeat:Float = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public var curBeat:Int = 0;
	public var curStep:Int = 0;

	public function stepHit(curStep:Int)
	{
	}

	public function beatHit(curBeat:Int)
	{
	}

	public function sectionHit(curSection:Int)
	{
	}

	public function updateScore(miss:Bool = false, ?score:Int, ?misses:Int, ?percent:Float)
	{
	}

	public function botplayStuff()
	{
	}

	public function reloadHealthBarColors()
	{
		if (healthBar == null || !useHealthBarColors)
			return;
		healthBar.setColors(FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1],
			PlayState.instance.dad.healthColorArray[2]),
			FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1],
				PlayState.instance.boyfriend.healthColorArray[2]));
	}

	public function doScoreBop():Void
	{
	}

	public function healthStuff(h:Float)
	{
		healthValue = h;
	}

	public function startSong():Void
	{
	}

	public function createPost():Void
	{
	}

	public function updateTime(t:Float)
	{
		songSeconds = t;
	}

	public function recalculateRating(p:Float)
	{
	}

	public function ratingFcString(_r:String)
	{
		ratingFC = _r;
	}
}
