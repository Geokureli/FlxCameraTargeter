package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.camera.CameraManager;

class PlayState extends FlxState
{
	var cam:CameraManager;
	
	override public function create()
	{
		super.create();
		
		cam = new CameraManager(FlxG.camera);
		#if debug
		cam.enableDebugFeatures();
		#end
	}

	override public function update(elapsed:Float)
	{
		// update cam just before super, before target touching flags are reset.
		cam.update(elapsed);
		super.update(elapsed);
	}
	
	override function draw()
	{
		super.draw();
		cam.debugDraw();
	}
}
