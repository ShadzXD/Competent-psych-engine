package objects.huds;

import objects.Bar;
import objects.HealthIcon;

/**
 * Recreation of Kade Engine's hud.
 */
@:access(states.PlayState)
class KadeHUD extends MainHUD
{
	var iconOffset:Int = 26;
	final IDLE_ICON_VALUE = 0;
	final LOSING_ICON_VALUE = 1;
	final ALLY_ICON_OFFSET = 60;
	final ENEMY_ICON_OFFSET = 40;
	var kadeRatingFC:String;
	var kadeEngineWatermark:FlxText;
	var botplayFUCKText:FlxText; // i love coding, dont u ?

	// fuck fuck fuck fuck fuck
	public function new()
	{
		super();
		PlayState.instance.useNewScoring = false;

		hudFont = "original.ttf";
		kadeEngineWatermark = new FlxText(30, FlxG.height * (!ClientPrefs.data.downScroll ? 0.95 : 0.06), 0, "",
			15); // due to how its setup, on base kade, this didnt appear on downscroll for some reason
		kadeEngineWatermark.setFormat(Paths.font(hudFont), 15, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		add(kadeEngineWatermark);

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.9 : 0.08), 'healthBar', function()
		{
			return PlayState.instance.get_health();
		}, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		add(healthBar);

		useHealthBarColors = false;
		scoreText = new FlxText(0, healthBar.y + 50, FlxG.width, "", 16);
		scoreText.setFormat(Paths.font(hudFont), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
		add(scoreText);
		updateScore(false, PlayState.instance.songScore, PlayState.instance.songMisses, PlayState.instance.ratingPercent); // hope this doesnt cause a crash
		scoreText.x = healthBar.x + healthBar.width / 2 - 150;

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

		if (PlayState.SONG.flippedHealth)
		{
			healthBar.leftToRight = true;
			healthBar.setColors(FlxColor.LIME, FlxColor.RED);
			iconP1.flipX = true;
			iconP2.flipX = true;
		}

		botplayFUCKText = new FlxText(0, 500, 0, "BOTPLAY", 40);
		botplayFUCKText.setFormat(Paths.font(hudFont), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayFUCKText.screenCenter(X);
		botplayFUCKText.visible = false;
		add(botplayFUCKText);
	}

	override function createPost()
	{
		kadeEngineWatermark.text = PlayState.instance.curSong + " " + CoolUtil.capitalize(Difficulty.getString()) + " - KE 1.1.2" + " (PE 1.0.4" + ")";
	}

	override function update(elapsed:Float)
	{
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max),
			healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);
		for (obj in iconGroup)
		{
			obj.setGraphicSize(Std.int(FlxMath.lerp(150, obj.width, 0.50)));

			obj.updateHitbox();
			if (obj.isPlayer)
			{
				if (!PlayState.SONG.flippedHealth)
					obj.x = (healthBar.barCenter + (150 * obj.scale.x - 150) / 2 - (obj.isAlly ? iconOffset - ALLY_ICON_OFFSET : iconOffset));
				else
					obj.x = healthBar.barCenter - (150 * obj.scale.x) / 2 - (obj.isAlly ? iconOffset + ENEMY_ICON_OFFSET : iconOffset) * 2;

				obj.animation.curAnim.curFrame = (healthBar.percent < 20) ? LOSING_ICON_VALUE : IDLE_ICON_VALUE;
			}
			else
			{
				if (!PlayState.SONG.flippedHealth)
					obj.x = healthBar.barCenter - (150 * obj.scale.x) / 2 - (obj.isAlly ? iconOffset + ENEMY_ICON_OFFSET : iconOffset) * 2;
				else
					obj.x = (healthBar.barCenter + (150 * obj.scale.x - 150) / 2 - (obj.isAlly ? iconOffset - ALLY_ICON_OFFSET : iconOffset));

				obj.animation.curAnim.curFrame = (healthBar.percent > 80) ? LOSING_ICON_VALUE : IDLE_ICON_VALUE;
			}
		}
		super.update(elapsed);
	}

	var isFC:Bool = true;

	override public function updateScore(miss:Bool = false, ?score:Int, ?misses:Int, ?percent:Float)
	{
		// Rating Name
		if (PlayState.instance.totalPlayed != 0) // Prevent divide by 0
			recalculateRating(percent);
		// thank u manofsomething for pointing the rating system out
		var percent:Float = CoolUtil.floorDecimal(percent * 100, 2);
		if (misses > 0 || percent <= 96)
			isFC = false;
		else
			isFC = true;
		kadeRatingFC = (isFC ? "| FC" : misses == 0 ? "| A" : percent <= 75 ? "| BAD" : ""); // what the fuck is this system bro
		if (PlayState.instance.totalPlayed == 0)
			kadeRatingFC = ""; // i dont care
		var tempScore:String = 'Score:$score' + (' | Misses:${misses}') + ' | Accuracy:${percent}% ' + '$kadeRatingFC';

		scoreText.text = tempScore;
	}

	override function beatHit(curBeat:Int)
	{
		for (icon in iconGroup)
		{
			icon.setGraphicSize(Std.int(icon.width + 30));
			icon.updateHitbox();
		}
	}

	override public function botplayStuff()
		botplayFUCKText.visible = true;
}
