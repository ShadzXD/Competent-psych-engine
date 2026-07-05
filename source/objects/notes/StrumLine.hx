package objects.notes;

/**
 * Code for the strumlines,
 */
class StrumLine extends FlxTypedGroup<StrumNote>
{
	public var downScroll:Bool;

	// if the strum is a player strum, whether it should be controlled by the cpu.

	/**
	 * If the strum is a player strum, this variable allows the strum to hit notes on its own.
	 * Please note that this still has health gain and score gain
	 */
	public var cpuControlled:Bool = false;

	public var forceDownscroll:Bool;
	// keeping this here just in case i end up adding multi key (prob not)
	public final noteAmount:Int = 4;

	/**
	 * Whether the strumline should be hidden if the player is using middlescroll
	 */
	public var canBeHidden:Bool = false;

	public var allowStrumlineUnderlay:Bool = false;

	public var doIntroAnimation:Bool = true;

	public function new(x:Float, y:Float, player:Int)
	{
		super();

		for (i in 0...noteAmount)
		{
			var babyArrow:StrumNote = new StrumNote(x, y, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			var targetAlpha:Float = 1;

			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			// babyArrow.y -= 10;
			// babyArrow.alpha = targetAlpha;
			add(babyArrow);
			babyArrow.playerPosition();
		}
	}
	/*
		public function doIntroTransition(arrow:StrumNote)
		{
		}
	 */
}
