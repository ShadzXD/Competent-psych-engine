package objects.notes;

class SustainSplash extends FlxSprite
{
	public static var startCrochet:Float;
	public static var frameRate:Int;

	public var strumNote:StrumNote;
	public var skin:String = 'holdSplash';

	public function new():Void
	{
		super();
		if (PlayState.SONG != null
			&& PlayState.SONG.holdSplashSkin != null
			&& PlayState.SONG.holdSplashSkin.length > 0
			&& Paths.getSparrowAtlas('noteSplashes/' + PlayState.SONG.holdSplashSkin) != null)
			skin = PlayState.SONG.holdSplashSkin;
		frames = Paths.getSparrowAtlas('noteSplashes/$skin');
		animation.addByPrefix('start', 'start', 16, false);
		animation.addByPrefix('hold', 'hold', 18, true);
		animation.addByPrefix('end', 'end', 24, false);
	}

	override function update(elapsed)
	{
		super.update(elapsed);
		if (strumNote != null)
		{
			repositionSplash();

			if (!animation.curAnim.name.startsWith("end") && strumNote.animation.curAnim.name == "static")
			{
				visible = false;
			}
		}
	}

	function repositionSplash()
	{
		setPosition(strumNote.x, strumNote.y);
		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
	}

	public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void
	{
		final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
		if (strum.visible == false) // kill splash if size of hold is too small
		{
			kill();
			return;
		}
		final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
		final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

		var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

		clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

		if (daNote.shader != null)
		{
			shader = new objects.notes.NoteSplash.PixelSplashShaderRef().shader;
			shader.data.r.value = daNote.shader.data.r.value;
			shader.data.g.value = daNote.shader.data.g.value;
			shader.data.b.value = daNote.shader.data.b.value;
			shader.data.mult.value = daNote.shader.data.mult.value;
		}
		visible = true;
		strumNote = strum;
		repositionSplash();
		alpha = strum.alpha;
		animation.play('start');
		animation.curAnim.looped = false;

		animation.finishCallback = (animationName:String) ->
		{
			if (animationName == "start")
			{
				animation.play('hold', true, false, 0);
				animation.curAnim.looped = true;
			}
		}

		new FlxTimer().start(timeThingy, (idk:FlxTimer) ->
		{
			if (tailEnd.mustPress && !(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled))
			{
				animation.play('end', true, false, 0);
				animation.curAnim.looped = false;
				animation.curAnim.frameRate = 24;
				clipRect = null;
				animation.finishCallback = (idkEither:Dynamic) ->
				{
					kill();
				}
				return;
			}
			kill();
		});
	}
}
