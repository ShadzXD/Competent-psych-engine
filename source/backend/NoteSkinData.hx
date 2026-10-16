package backend;

import flixel.FlxBasic;
import haxe.Json;

typedef NoteSkin =
{
	var strum_skin:String;

	var note_skin:String;
	var note_splash_skin:String;
	var sustain_splash_skin:String;

	@:optional var allow_note_splash:Bool;
	@:optional var allow_sustain_splash:Bool;
}

class NoteSkinData extends FlxBasic
{
	public var hudType:String;

	public var strumSkin:String;
	public var noteSkin:String;
	public var noteSplashSkin:String;
	public var sustainSplashSkin:String;
	public var useNoteSplash:Bool = true;
	public var useSustainSplash:Bool = true;

	public function new(hud:String)
	{
		super();
		hudType = hud;

		var path:String = Paths.getPath('data/noteskins/' + hud + '.json', TEXT, null, true);
		try
		{
			loadJsonFile(Json.parse(Paths.getContent(path)));
		}
		catch (e:Dynamic)
		{
			trace('Error loading popop file of "$hud": $e');
			path = Paths.getPath('data/popups/funkin.json', TEXT, null, true);
			loadJsonFile(Json.parse(Paths.getContent(path)));
		}
	}

	public function loadJsonFile(json:Dynamic)
	{
		strumSkin = json.strum_skin;
		noteSkin = json.note_skin;
		noteSplashSkin = json.note_splash_skin;
		sustainSplashSkin = json.sustain_splash_skin;
		useNoteSplash = json.allow_note_splash == null ? true : json.allow_note_splash;
		useSustainSplash = json.allow_sustain_splash == null ? true : json.allow_sustain_splash;
	}
}
