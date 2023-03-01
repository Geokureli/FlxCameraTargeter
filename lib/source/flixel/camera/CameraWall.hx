package flixel.camera;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxRect;
import flixel.util.FlxDirectionFlags;
import openfl.display.Graphics;

class CameraWall extends FlxObject implements flixel.camera.debug.ICameraDebugDrawable
{
	public var blockingDirections(get, set):FlxDirectionFlags;

	public function get_blockingDirections():FlxDirectionFlags
	{
		return allowCollisions;
	}

	public function set_blockingDirections(value:FlxDirectionFlags):FlxDirectionFlags
	{
		return allowCollisions = value;
	}

	// @formatter:off
	public var left(get, never):Float;
	function get_left() return x;
	public var top(get, never):Float;
	function get_top() return y;
	public var right(get, never):Float;
	function get_right() return x + width;
	public var bottom(get, never):Float;
	function get_bottom() return y + height;
	// @formatter:on
	/**
	 * @param blockingDirections  The directions to block. I.E.: left will prevent the camera from
	 *                            passing through when moving left.
	 */
	public function new(x = 0.0, y = 0.0, width = 0.0, height = 0.0, blockingDirections = ANY)
	{
		super(x, y, width, height);
		this.blockingDirections = blockingDirections;
		immovable = true;
	}

	inline static var DEBUG_COLOR = 0xFFff0000;

	public function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float)
	{
		final screenX = x + offsetX;
		final screenY = y + offsetY;

		gfx.lineStyle(1, DEBUG_COLOR);
		gfx.drawRect(screenX, screenY, width, height);
	}
}
