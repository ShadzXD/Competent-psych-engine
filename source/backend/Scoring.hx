package backend;

/**
 * Class used to handle PlayState Scoring.
 * Based on the V-Slice scoring system.
 */
class Scoring
{
	/**
	 * Max Amount of Score, player can get.
	 */
	static final PBOT1_MAX_NOTE_HIT_SCORE:Int = 500;

	/**
	 * Score For notes that have passed by on the screen.
	 */
	public static final PBOT1_MISS_NOTE_SCORE:Int = 100;

	public static final PBOT1_GHOST_TAP_NOTE_MISS_SCORE:Int = 10;

	public static final PBOT1_HOLD_NOTE_SCORE:Int = 10;

	/**
	 * Returns Score Based on Accuracy on Note Hit
	 * @param msTiming
	 * @return Int
	 */
	public static function scoreNoteAccuracy(msTiming:Float):Int
	{
		var absTiming:Float = Math.abs(msTiming);
		var slope:Float = 0.080;
		var offset:Float = 54.99;

		if (absTiming < 5.0)
		{
			return PBOT1_MAX_NOTE_HIT_SCORE;
		}

		var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-slope * (absTiming - offset))));
		var score:Int = Std.int(PBOT1_MAX_NOTE_HIT_SCORE * factor + 10);
		return score;
	}

	/**
	 * Returns score for holds held.
	 * Todo: rework this for other scoring types.
	 *
	 * @return Int
	 */
	public static function holdNoteScore():Int
	{
		return PBOT1_HOLD_NOTE_SCORE;
	}

	/**
	 * Returns score for missing a note by letting it go off screen.
	 * Todo: rework this for other scoring types.
	 *
	 * @return Int
	 */
	public static function missNoteScore():Int
	{
		return PBOT1_MISS_NOTE_SCORE;
	}

	/**
	 * Returns score for missing a note by pressing a key with ghost tapping off.
	 * Todo: rework this for other scoring types.
	 *
	 * @return Int
	 */
	public static function missGhostTapScore():Int
	{
		return PBOT1_GHOST_TAP_NOTE_MISS_SCORE;
	}
}
