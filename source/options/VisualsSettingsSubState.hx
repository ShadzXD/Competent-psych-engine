package options;

import objects.Alphabet;
import options.Option;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals Settings';
		rpcTitle = 'Visuals Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Note Splash Opacity', 'How transparent the note splashes should be.', 'noteSplashAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', BOOL);
		addOption(option);

		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING,
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Grow on Hit', "If unchecked, disables the Score text growing\neverytime you hit a note.", 'scoreZoom', BOOL);
		addOption(option);

		var option:Option = new Option('Background Strumline Opacity', 'How much transparent the background behind the notes should be.', 'underlayOpacity', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Health Bar Opacity', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', BOOL);
		addOption(option);
		//this doesnt even work on win 11 im pretty sure
		#if windows
		var option:Option = new Option('Window Dark Mode', "If unchecked, Game Window will be light mode (Requires game restart)", 'windowDarkMode', BOOL);
		addOption(option);
		#end

		super();
	}
}
