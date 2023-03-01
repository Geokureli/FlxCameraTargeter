package flixel.camera.mode;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import openfl.display.Graphics;

class CameraMode implements IFlxDestroyable implements flixel.camera.debug.ICameraDebugDrawable
{
	public var scroll = FlxPoint.get();
	public var applyFocuses = true;
	
	/** Center of the camera */
	public var focusX(get, set):Float;
	/** Center of the camera */
	public var focusY(get, set):Float;
	
	inline function get_focusX():Float return scroll.x + camera.width / 2;
	inline function get_focusY():Float return scroll.y + camera.height / 2;
	
	inline function set_focusX(value:Float):Float return scroll.x = value - camera.width / 2;
	inline function set_focusY(value:Float):Float return scroll.y = value - camera.height / 2;
	
	/** The Managing camera follower instance */
	var follower:CameraFollower;
	
	/** The camera manager */
	var manager(get, never):CameraManager;
	inline function get_manager() return follower.manager;
	
	var target(get, never):FlxObject;
	inline function get_target() return follower.target;

	var camera(get, never):FlxCamera;
	inline function get_camera() return manager.camera;
	
	public function new() {}
	
	public function destroy()
	{
		follower = null;
		scroll = null;
	}
	
	public function snapToTarget()
	{
		focusX = target.x + target.width / 2;
		focusY = target.y + target.height / 2;
	}
	
	public function activate(follower:CameraFollower)
	{
		this.follower = follower;
	}
	
	public function deactivate()
	{
		follower = null;
	}
	
	public function update(elapsed:Float) {}
	
	/**
	 * @param graphics  The graphics of the camera drawing this.
	 * @param offsetX   The offset to apply to counteract all other camera offsets.
	 * @param offsetY   The offset to apply to counteract all other camera offsets.
	 */
	public function debugDraw(graphics:Graphics, offsetX:Float, offsetY:Float) {}
	
	// --- HELPERS
	
	function getTargetWorldBounds()
	{
		return FlxRect.get(target.x, target.y, target.width, target.height);
	}
	
	function getTargetScreenBounds()
	{
		return FlxRect.get(target.x - scroll.x, target.y - scroll.y, target.width, target.height);
	}
}
