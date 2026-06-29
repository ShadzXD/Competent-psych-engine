package objects.huds;

import flixel.util.FlxStringUtil;
import objects.Bar;
import objects.HealthIcon;

/**
 * Recreation of Psych Engine's hud.
 * You can extend this one if your hud is similiar.
 */
@:access(states.PlayState)
class PsychHUD extends MainHUD
{
	var scoreTxtTween:FlxTween;
	var healthLerp:Float = 1;
	var iconOffset:Int = 26;
	var ratingName:String = '?';
	final IDLE_ICON_VALUE = 0;
	final LOSING_ICON_VALUE = 1;
	final ALLY_ICON_OFFSET = 60;
	final ENEMY_ICON_OFFSET = 40;

	public function new()
	{
		super();
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');

		timeTxt = new FlxText(PlayState.STRUM_X + (FlxG.width / 2) - 248, ClientPrefs.data.downScroll ? FlxG.height - 44 : 17, 400, "", 27);
		timeTxt.setFormat(Paths.font(hudFont), 27, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = showTime;
		if (ClientPrefs.data.timeBarType == 'Song Name')
			timeTxt.text = PlayState.SONG.song;
		timeTxt.borderSize = 1.75;
		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return PlayState.instance.songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		if (ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		final lerpValue:Float = 0.1 / (ClientPrefs.data.framerate / 60);
		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.09), 'healthBar', function()
		{
			healthLerp = FlxMath.lerp(healthLerp, PlayState.instance.get_health(), lerpValue);
			return healthLerp;
		}, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);

		iconGroup = new FlxTypedGroup<HealthIcon>();
		add(iconGroup);

		iconP1 = new HealthIcon(PlayState.instance.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 63;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		iconGroup.add(iconP1);

		iconP2 = new HealthIcon(PlayState.instance.dad.healthIcon, false);
		iconP2.y = healthBar.y - 63;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		iconGroup.add(iconP2);

		scoreText = new FlxText(0, healthBar.y + 42, FlxG.width, "", 21);
		scoreText.setFormat(Paths.font(hudFont), 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
		scoreText.borderSize = 1.75;
		add(scoreText);
		updateScore(false, PlayState.instance.songScore, PlayState.instance.songMisses, PlayState.instance.ratingPercent); // hope this doesnt cause a crash
	}

	override function update(elapsed:Float)
	{
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max),
			healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);
		for (obj in iconGroup)
		{
			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 5));
			obj.scale.set(mult, mult);
			obj.updateHitbox();
			if (obj.isPlayer)
			{
				obj.x = (healthBar.barCenter + (150 * obj.scale.x - 150) / 2 - (obj.isAlly ? iconOffset - ALLY_ICON_OFFSET : iconOffset));

				obj.animation.curAnim.curFrame = (healthBar.percent < 20) ? LOSING_ICON_VALUE : IDLE_ICON_VALUE;
			}
			else
			{
				obj.x = (healthBar.barCenter - (150 * obj.scale.x) / 2 - (obj.isAlly ? iconOffset + ENEMY_ICON_OFFSET : iconOffset) * 2);
				obj.animation.curAnim.curFrame = (healthBar.percent > 80) ? LOSING_ICON_VALUE : IDLE_ICON_VALUE;
			}
		}
		super.update(elapsed);
		if (ClientPrefs.data.timeBarType != 'Song Name')
			timeTxt.text = FlxStringUtil.formatTime(songSeconds, false);
	}

	override public function updateScore(miss:Bool = false, ?score:Int, ?misses:Int, ?percent:Float)
	{
		// Rating Name
		if (PlayState.instance.totalPlayed != 0) // Prevent divide by 0
			recalculateRating(percent);

		var percent:Float = CoolUtil.floorDecimal(percent * 100, 2);
		var str:String = '${percent}%';

		// "tempScore" variable is used to prevent another memory leak, just in case
		// "\n" here prevents the text from being cut off by beat zooms
		var tempScore:String = 'Score: ${FlxStringUtil.formatMoney(score, false, true)}' + (' • Misses: ${misses}') + ' • Accuracy: ${str}';

		scoreText.text = tempScore;
	}

	override public function botplayStuff()
	{
		// took this from doido teehee
		scoreText.text = 'SCORE WONT SAVE';
		scoreText.color = FlxColor.RED;
	}

	override public function doScoreBop():Void
	{
		if (scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreText.scale.x = 1.075;
		scoreText.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreText.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween)
			{
				scoreTxtTween = null;
			}
		});
	}

	override function beatHit(curBeat:Int)
	{
		for (icon in iconGroup)
		{
			icon.scale.set(1.15, 1.15);
			icon.updateHitbox();
		}
	}

	override function startSong()
	{
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	}
}
