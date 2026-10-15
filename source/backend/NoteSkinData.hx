package backend;

import flixel.FlxBasic;
import haxe.Json;

typedef NoteSkin =
{
	var strum_skin:String;

	var note_skin:String;
	var note_splash_skin:String;
	var sustain_splash_skin:String;
	var antialiasing:Bool;
	var rgb:Bool;
	@:optional var pixel_shader:Int;
}

class NoteSkinData extends FlxBasic
{
	public var strumSkin:String;
	public var noteSkin:String;
	public var noteSplashSkin:String;
	public var sustainSplashSkin:String;
	public var hudType:String;
	public var antialiasing:Bool;
	public var useRGB:Bool = true;
	public var pixelShaderValue:Int;

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
		antialiasing = json.antialiasing;
		useRGB = json.rgb;
		pixelShaderValue = json.pixel_shader;
	}
}
