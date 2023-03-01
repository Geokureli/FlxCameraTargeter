package flixel.camera;

import flixel.camera.mode.CameraMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import openfl.display.Graphics;

/**
 * TODO: doc
 */
class CameraFollower implements IFlxDestroyable
{
	/** The follow target. */
	public var target(default, null):FlxObject;
	
	/**
	 * The amount of focus to give the target. This number is weighed against the sum of all targets' focus values.
	 */
	public var focus:Float = 1.0;
	
	/** Follow mode. */
	public var mode(default, null):CameraMode = null;
	
	/**
	 * The target scroll of this follower.
	 */
	public var scroll(default, null) = FlxPoint.get();
	
	var camera(get, never):FlxCamera;
	
	inline function get_camera()
	{
		return manager.camera;
	}
	
	/**
	 * The previous scroll value after FocalPoint lerping. Used for camera walls
	 */
	var lastScroll = FlxPoint.get();
	
	/**
	 * Hitbox used to collide the camera with walls.
	 */
	var viewHitbox:FlxObject;
	
	/** Avoids pooling. */
	var _point = FlxPoint.get();
	
	/** The Camera manager */
	@:allow(flixel.camera.mode.CameraMode)
	var manager(default, null):CameraManager;
	
	public function new(manager:CameraManager, target:FlxObject, mode:CameraMode, focus:Float)
	{
		this.manager = manager;
		this.target = target;
		this.focus = focus;
		setMode(mode);
		mode.snapToTarget();
		lastScroll.copyFrom(mode.scroll);
		
		viewHitbox = new FlxObject();
		var viewRect = camera.getViewRect();
		viewHitbox.width = viewRect.width;
		viewHitbox.height = viewRect.height;
	}
	
	public function setMode(value:CameraMode)
	{
		// preserve target scroll when switching modes
		var prevScroll:FlxPoint = null;
		if (mode != null)
		{
			prevScroll = mode.scroll;
			mode.deactivate();
		}
		
		mode = value;
		
		if (mode != null)
		{
			mode.activate(this);
			if (prevScroll != null)
				mode.scroll.copyFrom(prevScroll);
		}
		
		return mode;
	}
	
	public function destroy()
	{
		manager = null;
		target = null;
		scroll = FlxDestroyUtil.put(scroll);
		lastScroll = FlxDestroyUtil.put(lastScroll);
		_point = FlxDestroyUtil.put(_point);
		mode = FlxDestroyUtil.destroy(mode);
		viewHitbox = FlxDestroyUtil.destroy(viewHitbox);
	}
	
	public function update(elapsed:Float)
	{
		if (mode != null)
		{
			if (isTargetTeleporting(elapsed))
			{
				// var pos = target.getPosition();
				// trace('target teleporting: ${getTargetName()}, pos:$pos, last:${target.last}');
				// pos.put();
				
				mode.snapToTarget();
			}
			else
				mode.update(elapsed);
			
			scroll.copyFrom(mode.scroll);
			
			if (mode.applyFocuses)
				lerpToFocalPoints(scroll);
			
			// Pass through camera walls
			if (!isTargetTeleporting(elapsed))
				bindToWalls(lastScroll, scroll);
			
			bindToRooms(scroll);
			
			lastScroll.copyFrom(scroll);
		}
	}
	
	/**
	 * Looks in the current level for all `CameraRooms` and keeps the camera inside them.
	 */
	function bindToRooms(scroll:FlxPoint)
	{
		for (room in manager.rooms)
		{
			if (room.exists && room.overlaps(target))
			{
				room.bindScroll(scroll, camera);
			}
		}
	}
	
	/**
	 * Looks in the current level for all `CameraWalls` and prevents the camera from entering.
	 */
	function bindToWalls(lastScroll:FlxPoint, scroll:FlxPoint)
	{
		viewHitbox.last.x = lastScroll.x;
		viewHitbox.last.y = lastScroll.y;
		viewHitbox.x = scroll.x;
		viewHitbox.y = scroll.y;
		
		var hit = false;
		for (wall in manager.walls)
		{
			if (wall.exists && viewHitbox.overlaps(wall))
			{
				hit = true;
				FlxObject.separate(viewHitbox, wall);
			}
		}
		
		// trace('hit:$hit last:${lastScroll.x} scroll:${scroll.x} obj:${viewHitbox.x}');
		scroll.x = viewHitbox.x;
		scroll.y = viewHitbox.y;
	}
	
	/**
	 * Looks in the current level for all `FocalPoints` and applies lerping based on their
	 * distance the target.
	 */
	function lerpToFocalPoints(scroll:FlxPoint)
	{
		final pos = FlxPoint.get(target.x + target.width / 2, target.y + target.height / 2);
		
		for (focus in manager.focuses)
		{
			if (focus.exists && focus.isInRange(pos.x, pos.y))
			{
				final amount:Float = focus.focusAmount(pos.x, pos.y);
				final scrollToX = focus.centerX - camera.width / 2;
				final scrollToY = focus.centerY - camera.height / 2;
				final offsetX = (scrollToX - scroll.x) * amount;
				final offsetY = (scrollToY - scroll.y) * amount;
				scroll.x += offsetX;
				scroll.y += offsetY;
			}
		}
	}
	
	public function isTargetTeleporting(elapsed:Float)
	{
		if (target.last == null)
			return false;
		
		// check if it's moving twice as fast as it's maxVelocity would allow
		final dx = (target.x - target.last.x) / elapsed;
		final dy = (target.y - target.last.y) / elapsed;
		final maxVSquared = Math.max(100, target.maxVelocity.lengthSquared);
		
		// if actual frame velocity is more than double its actual velocity
		return dx * dx + dy * dy > maxVSquared * 4;
	}
	
	inline function getTargetName()
	{
		return Type.getClassName(Type.getClass(target));
	}
	
	/**
	 * @param graphics  The graphics of the camera drawing this.
	 * @param offsetX   The offset to apply to counteract all other camera offsets.
	 * @param offsetY   The offset to apply to counteract all other camera offsets.
	 */
	public function debugDraw(graphics:Graphics, offsetX:Float, offsetY:Float)
	{
		mode.debugDraw(graphics, offsetX + mode.scroll.x, offsetY + mode.scroll.y);
	}
}
