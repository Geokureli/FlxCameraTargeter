package flixel.camera;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxDirectionFlags;
import openfl.display.Graphics;

class CameraRoom extends FlxObject implements flixel.camera.debug.ICameraDebugDrawable
{
	public var edges:FlxDirectionFlags;

	var bounds:BoundsRect;

	public function new(x = 0.0, y = 0.0, width = 0.0, height = 0.0, edges:FlxDirectionFlags = ANY)
	{
		this.edges = edges;
		bounds = new BoundsRect();
		super(x, y, width, height);
	}

	public function bindScroll(scroll:FlxPoint, camera:FlxCamera)
	{
		// @formatter:off
		bounds.minX = edges.has(LEFT ) ? x        : null;
		bounds.maxX = edges.has(RIGHT) ? x+width  : null;
		bounds.minY = edges.has(UP   ) ? y        : null;
		bounds.maxY = edges.has(DOWN ) ? y+height : null;
		// @formatter:on
		return bounds.bindScroll(scroll, camera);
	}

	inline static var DEBUG_COLOR = 0xFF0000ff;

	public function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float)
	{
		final screenX = x + offsetX;
		final screenY = y + offsetY;

		gfx.lineStyle(1, DEBUG_COLOR);
		gfx.drawRect(screenX, screenY, width, height);
	}
}
