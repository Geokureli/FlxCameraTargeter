package flixel.camera.mode;

import flixel.math.FlxRect;
import openfl.display.Graphics;

/**
 * Made as a test for the CameraManager, but it works.
 */
class DeadZoneMode extends CameraMode
{
	public var deadzone:FlxRect;

	public function new(deadzone:FlxRect)
	{
		this.deadzone = deadzone;
		super();
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		scroll = camera.scroll;
		final bounds = getTargetScreenBounds();
		final worldZone = FlxRect.get(deadzone.x, deadzone.y, deadzone.width, deadzone.height);

		if (bounds.right > worldZone.right)
			scroll.x += bounds.right - worldZone.right;
		else if (bounds.left < worldZone.left)
			scroll.x += bounds.left - worldZone.left;

		if (bounds.bottom > worldZone.bottom)
			scroll.y += bounds.bottom - worldZone.bottom;
		else if (bounds.top < worldZone.top)
			scroll.y += bounds.top - worldZone.top;

		bounds.put();
		worldZone.put();

		// lerp towards nearby FocalPoints
		lerpToFocalPoints();
	}

	#if debug
	override function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float)
	{
		gfx.lineStyle(1, 0xFFffffff);
		gfx.drawRect(deadzone.x + offsetX, deadzone.y + offsetY, deadzone.width, deadzone.height);
	}
	#end
}
