package backend;

import openfl.utils.Assets;
import haxe.Json;
import backend.Song;
import psychlua.ModchartSprite;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	@:optional var isPixelStage:Null<Bool>;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;

	@:optional var preload:Dynamic;

	@:optional var hudSkin:String;
	@:optional var popUpSkin:String;
}

class StageData
{
	public static function dummy():StageFile
	{
		return {
			directory: "",
			defaultZoom: 0.9,

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1,

			hudSkin: "funkin",
			popUpSkin: "funkin"
		};
	}

	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = '';
		if (SONG.stage != null)
			stage = SONG.stage;
		else
			stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = (stageFile != null) ? stageFile.directory : ''; // preventing crashes
	}

	public static function getStageFile(stage:String):StageFile
	{
		try
		{
			var path:String = Paths.getPath('stages/' + stage + '.json', TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
				return cast haxe.Json.parse(File.getContent(path));
			#else
			if (Assets.exists(path))
				return cast haxe.Json.parse(Assets.getText(path));
			#end
		}
		return dummy();
	}
}
