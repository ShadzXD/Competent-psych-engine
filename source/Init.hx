package;

import flixel.input.keyboard.FlxKey;
import backend.WeekData;
import states.StoryMenuState;

/**
 * Class Used for loading save data and, things which are unable to be loaded in Main.
 * This is done so we dont have to rely on TitleState.
 */
class Init
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static function loadSettings()
	{
		ClientPrefs.loadPrefs();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			// trace('LOADED FULLSCREEN SETTING!!');
		}
		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		if (ClientPrefs.data.windowDarkMode)
			backend.Native.setWindowDarkMode(true, true); // Dark Mode is here and not in Main.hx because it sometimes doesnt load there.
	}
}
