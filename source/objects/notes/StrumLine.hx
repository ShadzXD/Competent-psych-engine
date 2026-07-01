package objects.notes;

class StrumLine extends FlxTypedGroup<StrumNote>
{
	public var downScroll:Bool;
	// note used for redirecting
	public var note:String;
	public var cpuControlled:Bool = false;
	public var forceDownscroll:Bool;

	public function new(x:Float, y:Float, player:Int, ?noteAmount:Int = 4)
	{
		super();

		for (i in 0...noteAmount)
		{
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.data.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(x, y, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;

			// babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.alpha = targetAlpha;
			add(babyArrow);
			babyArrow.playerPosition();
		}
	}
}
