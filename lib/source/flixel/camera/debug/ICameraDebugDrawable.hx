package flixel.camera.debug;

import openfl.display.Graphics;

interface ICameraDebugDrawable
{
	#if debug
	function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float):Void;
	#end
}
