package states;

import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.FlxState;
import flash.media.Sound;
import backend.Song;
import backend.StageData;
import objects.Character;
import objects.notes.Note;
import objects.notes.NoteSplash;
import objects.notes.SustainSplash;
#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end
#if MULTITHREADED_LOADING
import sys.thread.Mutex;
import sys.thread.FixedThreadPool;
#end

#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];

	static inline var LOAD_STALL_TIMEOUT:Float = 30.0; // seconds of zero progress before the watchdog forces completion
	static inline var MAX_LOAD_THREADS:Int = 6; // extra workers past this just thrash disk/RAM during loading
	#if MULTITHREADED_LOADING
	static var mutex:Mutex; // guards asset maps; nulled in _loaded
	static var progressMutex:Mutex = new Mutex(); // guards loaded/threadsCompleted counters
	static var threadPool:FixedThreadPool = null;
	#end

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;

		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var barGroup:FlxSpriteGroup;
	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var stateChangeDelay:Float = 0;

	var funkay:FlxSprite;

	#if HSCRIPT_ALLOWED
	var hscript:HScript;
	#end

	override function create()
	{
		persistentUpdate = true;
		#if html5
		// skip the loading screen on html5 since its useless lmaooo
		onLoad();
		#end

		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		#if HSCRIPT_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/data/LoadingScreen.hx'; // mods/My-Mod/data/LoadingScreen.hx
			#if sys
			if (FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new HScript(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);

					if (hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('initialized hscript interp successfully: $scriptPath');
						return super.create();
					}
					else
					{
						trace('"$scriptPath" contains no \"onCreate" function, stopping script.');
					}
				}
				catch (e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
					var hscript:HScript = cast(Iris.instances.get(scriptPath), HScript);
				}
				if (hscript != null)
					hscript.destroy();
				hscript = null;
			}
			#end
		}
		#end

		var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		addBehindBar(bg);

		funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/loading/funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		addBehindBar(funkay);

		super.create();

		if (stateChangeDelay <= 0 && checkLoaded())
		{
			dontUpdate = true;
			onLoad();
		}
	}

	function addBehindBar(obj:flixel.FlxBasic)
	{
		insert(members.indexOf(barGroup), obj);
	}

	var transitioning:Bool = false;

	var watchLoaded:Int = -1;
	var watchInit:Bool = false;
	var stallTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate)
			return;

		if (!transitioning)
		{
			if (!finishedLoading && checkLoaded())
			{
				if (stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else
					stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = (loadMax > 0) ? loaded / loadMax : 0;

			/* watchdog: force completion if loading stalls (zero progress) instead of freezing */
			if (!finishedLoading)
			{
				if (loaded != watchLoaded || initialThreadCompleted != watchInit)
				{
					watchLoaded = loaded;
					watchInit = initialThreadCompleted;
					stallTime = 0;
				}
				else if ((stallTime += elapsed) >= LOAD_STALL_TIMEOUT)
				{
					logLoadTimeout();
					checkLoaded(); // cache whatever already decoded before bailing
					transitioning = true;
					onLoad();
					return;
				}
			}
		}

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001)
				curPercent = intendedPercent;
			else
				curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}

		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			if (hscript.exists('onUpdate'))
				hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	override function destroy()
	{
		if (hscript != null)
		{
			if (hscript.exists('onDestroy'))
				hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		super.destroy();
	}
	#end

	var finishedLoading:Bool = false;

	function onLoad()
	{
		_loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function _loaded()
	{
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;

		FlxTransitionableState.skipNextTransIn = true;
		#if MULTITHREADED_LOADING
		if (threadPool != null)
			threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;
		#end
	}

	static function logLoadTimeout()
		trace('LoadingState watchdog: no progress for ${LOAD_STALL_TIMEOUT}s at $loaded/$loadMax (prepDone=$initialThreadCompleted); forcing completion -- remaining assets will load on demand.');

	public static function checkLoaded():Bool
	{
		/* swap out pending bitmaps under mutex, then cache on the main thread outside the lock */
		var pending:Map<String, BitmapData> = null;
		var pendingKeys:Map<String, String> = null;
		#if MULTITHREADED_LOADING
		if (mutex != null)
			mutex.acquire();
		if (requestedBitmaps.keys().hasNext())
		{
			pending = requestedBitmaps;
			pendingKeys = originalBitmapKeys;
			requestedBitmaps = new Map<String, BitmapData>();
			originalBitmapKeys = new Map<String, String>();
		}
		if (mutex != null)
			mutex.release();
		#end
		if (pending != null)
		{
			for (key => bitmap in pending)
			{
				if (bitmap != null && Paths.cacheBitmap(pendingKeys.get(key), bitmap) != null)
				{
				}
				else
					trace('failed to cache image $key');
			}
		}
		return (loaded >= loadMax && initialThreadCompleted);
	}

	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		#if !SHOW_LOADING_SCREEN
		intrusive = false;
		#end

		_startPool();
		loadNextDirectory();

		if (intrusive)
			return new LoadingState(target, stopMusic);

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var watchLoaded:Int = -1;
		var watchInit:Bool = false;
		#if sys
		var stallStart:Float = Sys.time();
		while (true)
		{
			if (checkLoaded())
			{
				_loaded();
				break;
			}

			/* watchdog: same stall guard as the intrusive path so a stuck load can't hard-freeze */
			if (loaded != watchLoaded || initialThreadCompleted != watchInit)
			{
				watchLoaded = loaded;
				watchInit = initialThreadCompleted;
				stallStart = Sys.time();
			}
			else if (Sys.time() - stallStart >= LOAD_STALL_TIMEOUT)
			{
				logLoadTimeout();
				_loaded();
				break;
			}
			Sys.sleep(0.001);
		}
		#end
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null)
			imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null)
			soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null)
			musicToPrepare = musicToPrepare.concat(music);
	}

	static var initialThreadCompleted:Bool = true;
	static var dontPreloadDefaultVoices:Bool = false;

	static function _startPool()
	{
		#if MULTITHREADED_LOADING
		if (threadPool != null) // idempotent: one live pool per load
			return;

		if (mutex == null)
			mutex = new Mutex();
		#end
		#if (MULTITHREADED_LOADING && cpp)
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		if (threadCount > MAX_LOAD_THREADS)
			threadCount = MAX_LOAD_THREADS;
		#else
		var threadCount:Int = 1;
		#end
		#if MULTITHREADED_LOADING
		threadPool = new FixedThreadPool(threadCount);
		#end
	}

	/* route a preload object's fields (images/sounds/music/...) into the given lists by prefix */
	static function collectPreloadAssets(json:Dynamic, imgs:Array<String>, snds:Array<String>, mscs:Array<String>)
	{
		for (asset in Reflect.fields(json))
		{
			var filters:Int = Reflect.field(json, asset);
			var asset:String = asset.trim();
			if (filters < 0 || StageData.validateVisibility(filters))
			{
				if (asset.startsWith('images/'))
					imgs.push(asset.substr('images/'.length));
				else if (asset.startsWith('sounds/'))
					snds.push(asset.substr('sounds/'.length));
				else if (asset.startsWith('music/'))
					mscs.push(asset.substr('music/'.length));
			}
		}
	}

	public static function prepareToSong()
	{
		if (PlayState.SONG == null)
		{
			imagesToPrepare = [];
			soundsToPrepare = [];
			musicToPrepare = [];
			songsToPrepare = [];
			loaded = 0;
			loadMax = 0;
			initialThreadCompleted = true;
			return;
		}

		_startPool();
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];
		initialThreadCompleted = false;

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName);
		#if MULTITHREADED_LOADING
		/* one sequential prep task off the main thread: build the asset lists, then kick off the
			per-asset loaders. startThreads() always runs (even on failure) so prep can't softlock */
		threadPool.run(() ->
		{
			try
			{
				var noteSkin:String = Note.defaultNoteSkin;
				if (song.arrowSkin != null && song.arrowSkin.length > 1)
					noteSkin = song.arrowSkin;
				var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
				if (Paths.fileExists('images/$customSkin.png', IMAGE))
					noteSkin = customSkin;
				imagesToPrepare.push(noteSkin);

				var noteSplash:String = NoteSplash.defaultNoteSplash;
				if (song.splashSkin != null && song.splashSkin.length > 0)
					noteSplash = song.splashSkin;
				else
					noteSplash += NoteSplash.getSplashSkinPostfix();

				imagesToPrepare.push(noteSplash);

				var holdSplash:String = 'noteSplashes/holdSplash';

				if (PlayState.SONG.holdSplashSkin != null
					&& PlayState.SONG.holdSplashSkin.length > 0
					&& Paths.getSparrowAtlas('noteSplashes/' + PlayState.SONG.holdSplashSkin) != null)
					holdSplash = 'noteSplashes/' + PlayState.SONG.holdSplashSkin;

				imagesToPrepare.push(holdSplash);
				try
				{
					var path:String = Paths.json('$folder/preload');
					var json:Dynamic = null;
					#if MODS_ALLOWED
					var moddyFile:String = Paths.modsJson('$folder/preload');
					if (FileSystem.exists(moddyFile))
						json = Json.parse(File.getContent(moddyFile));
					else
						json = Json.parse(File.getContent(path));
					#else
					json = Json.parse(Assets.getText(path));
					#end

					if (json != null)
					{
						var imgs:Array<String> = [];
						var snds:Array<String> = [];
						var mscs:Array<String> = [];
						collectPreloadAssets(json, imgs, snds, mscs);
						prepare(imgs, snds, mscs);
					}
				}
				catch (e:Dynamic)
				{
				}

				if (song.stage == null || song.stage.length < 1)
					song.stage = StageData.vanillaSongStage(folder);

				var stageData:StageFile = StageData.getStageFile(song.stage);
				if (stageData != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					if (stageData.preload != null)
						collectPreloadAssets(stageData.preload, imgs, snds, mscs);

					if (stageData.objects != null)
					{
						for (sprite in stageData.objects)
						{
							if (sprite.type == 'sprite' || sprite.type == 'animatedSprite')
								if ((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
									imgs.push(sprite.image);
						}
					}
					prepare(imgs, snds, mscs);
				}

				songsToPrepare.push('$folder/Inst');

				var player1:String = song.player1;
				var player2:String = song.player2;
				var gfVersion:String = song.gfVersion;
				var prefixVocals:String = song.needsVoices ? '$folder/Voices' : null;
				if (gfVersion == null)
					gfVersion = 'gf';

				dontPreloadDefaultVoices = false;
				preloadCharacter(player1, prefixVocals);
				if (!dontPreloadDefaultVoices && prefixVocals != null)
				{
					if (Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs')
						&& Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
					{
						songsToPrepare.push('$prefixVocals-Player');
						songsToPrepare.push('$prefixVocals-Opponent');
					}
					else if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
						songsToPrepare.push(prefixVocals);
				}

				/* chars parsed sequentially -> no concurrent pushes into the prepare lists */
				if (player2 != player1)
					preloadCharacter(player2, prefixVocals);
				if (stageData != null && !stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
					preloadCharacter(gfVersion);
			}
			catch (e:Dynamic)
			{
				trace('ERROR! while preparing song: $e');
			}

			clearInvalids();
			startThreads();
			initialThreadCompleted = true;
		});
		#end
	}

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentFolder:String = null)
	{
		#if MULTITHREADED_LOADING
		for (folder in arr.copy())
		{
			var nam:String = folder.trim();
			if (nam.endsWith('/'))
			{
				#if MODS_ALLOWED
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
				{
					for (file in FileSystem.readDirectory(subfolder))
					{
						if (file.endsWith(ext))
						{
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if (!arr.contains(toAdd))
								arr.push(toAdd);
						}
					}
				}
				#end
				// trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			if (parentFolder == 'songs')
				myKey = '$member$ext';

			// trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true)))
			{
				arr.remove(member);
				if (doTrace)
					trace('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
		#end
	}

	public static function startThreads()
	{
		#if MULTITHREADED_LOADING
		if (mutex == null) // owned by _startPool; don't replace (workers may hold it)
			mutex = new Mutex();
		#end
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		// then start threads
		_threadFunc();
	}

	static function _threadFunc()
	{
		for (sound in soundsToPrepare)
			initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare)
			initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare)
			initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare)
			initThread(() -> preloadGraphic(image), 'image $image');
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		#if MULTITHREADED_LOADING
		threadPool.run(() ->
		{
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try
			{
				if (func() != null)
				{
					#if debug
					var diff = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				}
				else
					trace('ERROR! fail on preloading $traceData ');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading $traceData: $e');
			}
			progressMutex.acquire();
			loaded++;
			progressMutex.release();
		});
		#end
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			// Skip silently when the JSON isn't on disk -- File.getContent
			// throws a noisy stack trace and we'd just swallow it below.
			// Characters referenced by charts/events that don't exist on
			// the current mod are common and not actionable here.
			if (!FileSystem.exists(path) && !Assets.exists(path))
				return;
			var character:Dynamic = Json.parse(FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path));
			#else
			if (!Assets.exists(path))
				return;
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flixel_animate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if (!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
			}
			#if flixel_animate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if (i == 0)
						st = '';

					if (Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						// trace('found Sprite PNG');
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				if (char == PlayState.SONG.player1)
					dontPreloadDefaultVoices = true;
			}
		}
		catch (e:haxe.Exception)
		{
			trace(e.details());
		}
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound>
	{
		var file:String = Paths.getPath(key + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);
		#if MULTITHREADED_LOADING
		// trace('precaching sound: $file');
		if (!Paths.currentTrackedSounds.exists(file))
		{
			if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
			{
				var sound:Sound = #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
				mutex.acquire();
				Paths.currentTrackedSounds.set(file, sound);
				mutex.release();
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		mutex.acquire();
		Paths.localTrackedAssets.push(file);
		mutex.release();
		#end
		return Paths.currentTrackedSounds.get(file);
	}

	// thread safe sound loader
	static function preloadGraphic(key:String):Null<BitmapData>
	{
		try
		{
			var requestKey:String = 'images/$key';
			if (requestKey.lastIndexOf('.') < 0)
				requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey))
			{
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
				{
					#if sys
					var bitmap:BitmapData = BitmapData.fromFile(file);
					#else
					var bitmap:BitmapData = OpenFlAssets.getBitmapData(file, false);
					#end
					#if MULTITHREADED_LOADING
					mutex.acquire();
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					mutex.release();
					#end
					return bitmap;
				}
				else
					trace('no such image $key exists');
			}

			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		}
		catch (e:haxe.Exception)
		{
			trace('ERROR! fail on preloading image $key');
		}

		return null;
	}

	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
    	')
	@:noCompletion
	public static function getCPUThreadsCount():Int
	{
		return -1;
	}
	#end
}
