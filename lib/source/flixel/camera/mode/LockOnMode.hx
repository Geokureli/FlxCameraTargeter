package flixel.camera.mode;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxSpriteUtil;
import openfl.display.Graphics;

/**
 * Made as a test for the CameraManager, but it works.
 */
class LockOnMode extends CameraMode
{
	override function update(elapsed)
	{
		super.update(elapsed);
		snapToTarget();
	}

	#if debug
	override function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float)
	{
		gfx.lineStyle(1, 0xFFffffff);
		var midX = Std.int(camera.width / 2 + offsetX);
		var midY = Std.int(camera.height / 2 + offsetY);
		gfx.moveTo(midX, midY - 5);
		gfx.lineTo(midX, midY + 5);
		gfx.moveTo(midX - 5, midY);
		gfx.lineTo(midX + 5, midY);
	}
	#end
}
