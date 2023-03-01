package flixel.camera;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.camera.debug.CameraMover;
import flixel.camera.mode.*;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;

@:bitmap("flixel/images/cameraMover.png")
private class CameraMoverGraphic extends openfl.display.BitmapData {}

/**
 * 
 */
class CameraManager
{
	/**
	 * The default tween time used when shifting focus from one to another. I figured we would
	 * change this based on what generally works best, but didn't want a changing global var.
	 */
	static inline var FOCUS_TWEEN_TIME = 1.0;
	
	/**
	 * The default ease used when shifting focus from one to another. I figured we would
	 * change this based on what generally works best, but didn't want a changing global var.
	 */
	static final FOCUS_EASE = FlxEase.cubeInOut;
	
	public final camera:FlxCamera;
	
	/** The bounds of the camera's `scroll`. */
	public final scrollBounds:BoundsRect = {};
	
	/** Delegate for `scrollBounds.minX` */
	public var minScrollX(get, set):Null<Float>;
	
	/** Delegate for `scrollBounds.maxX` */
	public var maxScrollX(get, set):Null<Float>;
	
	/** Delegate for `scrollBounds.minY` */
	public var minScrollY(get, set):Null<Float>;
	
	/** Delegate for `scrollBounds.maxY` */
	public var maxScrollY(get, set):Null<Float>;
	
	var _tempPointer = new FlxObject(0, 0, 1, 1);
	
	/**
	 * Smoothes out the camera movement by interpolating its position between the old position and
	 * the new. 1.0 means no interpolation. 1.0 > lerp > 0.0 will cause lerp. For example, 0.5 lerp
	 * will place the camera halfway between it's previous position and the new desired position.
	 */
	public var lerp:Float = 0.1;
	
	public var walls = new FlxTypedGroup<CameraWall>();
	public var rooms = new FlxTypedGroup<CameraRoom>();
	public var focuses = new FlxTypedGroup<CameraFocus>();
	
	#if debug
	public var drawDebug:Bool = #if cam_debug_draw true #else false #end;
	#end
	
	var followers = new Map<FlxObject, CameraFollower>();
	
	var tempFollower:CameraFollower = null;
	
	@:allow(flixel.camera.debug.CameraMover)
	var debugOffset = FlxPoint.get();
	
	/**
	 * The previous scroll value, verbatim
	 */
	var lastScroll = FlxPoint.get(Math.NaN, Math.NaN);
	
	/**
	 * Avoids pooling.
	 */
	var _point = FlxPoint.get();
	
	// var target_offset:FlxPoint = new FlxPoint();
	
	public function new(camera:FlxCamera)
	{
		this.camera = camera;
	}
	
	#if debug
	public function enableDebugFeatures()
	{
		FlxG.game.debugger.interaction.addTool(new CameraMover(this));
		// FlxG.watch.add(this, "prevModeScroll", "prevModeScroll");
		// FlxG.watch.add(this, "debugOffset", "debugOffset");
		// FlxG.watch.add(this, "scrollBounds", "scrollBounds");
		
		// FlxG.console.registerObject("cam", this);
		
		final button = FlxG.debugger.addButton(RIGHT, new CameraMoverGraphic(0, 0), () -> drawDebug = !drawDebug, true);
		button.toggled = !drawDebug;
	}
	#end

	public function update(elapsed:Float)
	{
		if (camera == null)
			return;

		var totalFocus = 0.0;
		for (follower in followers)
		{
			follower.update(elapsed);
			totalFocus += follower.focus;
		}

		_point.set(0, 0);
		for (follower in followers)
		{
			var focus = calcFollowerFocus(follower.focus, totalFocus);
			_point.x += follower.scroll.x * focus;
			_point.y += follower.scroll.y * focus;
		}
		
		if (tempFollower != null)
		{
			tempFollower.update(elapsed);
			_point.x += tempFollower.scroll.x * tempFollower.focus;
			_point.y += tempFollower.scroll.y * tempFollower.focus;
		}
		
		bindScroll(_point);
		
		// apply lerp
		if (lerp >= 1.0 || lerp <= 0.0 || !lastScroll.isValid())
			camera.scroll.copyFrom(_point);
		else
		{
			camera.scroll.x = (_point.x - lastScroll.x) * lerp + lastScroll.x;
			camera.scroll.y = (_point.y - lastScroll.y) * lerp + lastScroll.y;
		}
		
		lastScroll.copyFrom(camera.scroll);
		
		camera.scroll.x = Math.round(camera.scroll.x);
		camera.scroll.y = Math.round(camera.scroll.y);
		
		camera.scroll += debugOffset;
	}
	
	function calcFollowerFocus(followerFocus:Float, totalFocus:Float)
	{
		// tempFollower.focus of 1.0 overrides all other followers
		final tempFocus = tempFollower == null ? 0.0 : tempFollower.focus;
		return (1.0 - tempFocus) * (followerFocus / totalFocus);
	}
	
	/**
	 * Changes `scroll` so that it is within the `scrollBounds` according to `camera's` view rect.
	 * 
	 * @param   scroll   The point to bind.
	 */
	function bindScroll(scroll:FlxPoint)
	{
		if (scrollBounds == null)
			return scroll;
		
		// copied from FlxCamera
		return scrollBounds.bindScroll(scroll, camera);
	}
	
	/**
	 * Used primarily for debug drawing
	 */
	public function debugDraw()
	{
		#if debug
		if (drawDebug && camera != null)
		{
			final gfx = camera.debugLayer.graphics;
			
			var offsetX = debugOffset.x - camera.scroll.x;
			var offsetY = debugOffset.y - camera.scroll.y;
			
			for (focus in focuses)
			{
				if (focus.visible && focus.ignoreDrawDebug == false)
					focus.debugDraw(gfx, offsetX, offsetY);
			}
			
			for (room in rooms)
			{
				if (room.visible && room.ignoreDrawDebug == false)
					room.debugDraw(gfx, offsetX, offsetY);
			}
			
			for (wall in walls)
			{
				if (wall.visible && wall.ignoreDrawDebug == false)
					wall.debugDraw(gfx, offsetX, offsetY);
			}
			
			for (follower in followers)
				follower.debugDraw(gfx, offsetX, offsetY);
		}
		#end
	}

	@:allow(flixel.camera.debug.CameraMover)
	function setDebugOffset(x:Float, y:Float)
	{
		camera.scroll.subtract(x - debugOffset.x, y - debugOffset.y);
		debugOffset.set(x, y);
	}

	/**
	 * Reduces the focus of every other follow target to 0.0 and sets the focus of the specified
	 * follwer to 1.0.
	 * 
	 *  Note: This happens instantly, for a smooth transition use `tweenFullFocusTo`
	 * 
	 * @param target    The target to focus
	 */
	public function setFullFocusTo(target:FlxObject)
	{
		if (followers.exists(target) == false)
			throw 'no existing CameraFollower for target: $target';

		for (follower in followers)
			follower.focus = (follower.target == target ? 1.0 : 0.0);
	}

	/**
	 * Tweens the focus of the specified follower to the desired amount, in the specified time.
	 * 
	 * @param target    The target to tween
	 * @param time      The tween time
	 * @param focus     The new focus amount of the follower
	 * @param ease      The tween ease, if null cubeInAndOut is used, if null cubeInAndOut is used
	 * @param callback  Called when the tween in done
	 */
	public function tweenTargetFocusTo(target:FlxObject, time = FOCUS_TWEEN_TIME, focus:Float, ?ease, ?callback)
	{
		if (followers.exists(target) == false)
			throw 'no existing CameraFollower for target: $target';

		final follower = followers[target];
		final startingFocus = follower.focus;

		FlxTween.num(0.0, 1.0, time, tweenOptionsHelper(ease, callback), (t) ->
		{
			final targetFocus = (follower.target == target ? 1.0 : 0.0);
			follower.focus = startingFocus + (focus - startingFocus) * t;
		});
	}

	inline public function isFollowing(target:FlxObject)
	{
		return followers.exists(target);
	}

	/**
	 * Adds a follow target.
	 * @param target  The target to follow
	 * @param mode    The mode used to follow the target
	 * @param focus   The focus amount. If null, 1.0 is used if there are no other follow targets,
	 *                otherwise, the focus is 0.0.
	 */
	public function addFollowTarget(target:FlxObject, ?mode:CameraMode, ?focus:Float)
	{
		if (followers.exists(target))
		{
			if (mode != null)
				setFollowMode(target, mode);
			else if (!(followers[target].mode is LockOnMode))
				setFollowMode(target, new LockOnMode());

			if (focus != null)
				followers[target].focus = focus;

			return;
		}

		if (mode == null)
			mode = new LockOnMode();

		if (focus == null)
		{
			// If this is the first follower set focus to 1.0, otherwise 0.0.
			focus = 1.0;
			for (_ in followers)
				focus = 0.0;
		}

		followers[target] = new CameraFollower(this, target, mode, focus);
	}

	public function removeFollowTarget(target:FlxObject)
	{
		followers.remove(target);
	}

	/**
	 * A quick way to fully focus the camera on a target without messing with the current multi-target
	 * focus balance.
	 * 
	 * @param target    The target to focus, temporarily
	 * @param time      The tween time
	 * @param ease      The tween ease, if null cubeInAndOut is used, if null cubeInAndOut is used
	 * @param callback  Called when the tween in done
	 */
	public function tweenToTempTarget(target:FlxObject, time = FOCUS_TWEEN_TIME, ?mode:CameraMode, ?ease, ?callback)
	{
		if (tempFollower != null)
			throw 'Can only have 1 temp target at a time (for now)';

		if (mode == null)
			mode = new LockOnMode();

		tempFollower = new CameraFollower(this, target, mode, 0);

		FlxTween.num(0.0, 1.0, time, tweenOptionsHelper(ease, callback), (focus) ->
		{
			tempFollower.focus = focus;
		});
	}

	/**
	 * Unfocuses the current temporary focus target or position.
	 * @param time      The tween time
	 * @param ease      The tween ease, if null cubeInAndOut is used, if null cubeInAndOut is used
	 * @param callback  Called when the tween in done
	 */
	public function tweenFromTempTarget(time = FOCUS_TWEEN_TIME, ?ease, ?callback)
	{
		if (tempFollower == null)
			throw 'No current temp target';

		function onComplete()
		{
			tempFollower.destroy();
			tempFollower = null;
			if (callback != null)
				callback();
		}

		FlxTween.num(tempFollower.focus, 0.0, time, tweenOptionsHelper(ease, onComplete), (focus) ->
		{
			tempFollower.focus = focus;
		});
	}

	/**
	 * A quick way to fully focus the camera on a target without messing with the current multi-target
	 * focus balance.
	 * 
	 * @param x         The world x to focus on, temporarily
	 * @param y         The world y to focus on, temporarily
	 * @param time      The tween time
	 * @param ease      The tween ease, if null cubeInAndOut is used, if null cubeInAndOut is used
	 * @param callback  Called when the tween in done
	 */
	public function tweenToTempXY(x:Float, y:Float, time = FOCUS_TWEEN_TIME, ?ease, ?callback)
	{
		if (tempFollower != null)
			throw 'Can only have 1 temp target at a time (for now)';

		_tempPointer.x = x;
		_tempPointer.y = y;
		tweenToTempTarget(_tempPointer, time, ease, callback);
	}

	/**
	 * Removes all follow targets and adds the specified one. If a target is given it will add
	 * it as the lone follow target. Useful if the player enters a new area.
	 */
	public function resetFollowers(?target:FlxObject, ?mode:CameraMode, focus = 1.0)
	{
		followers.clear();
		lastScroll.set(Math.NaN, Math.NaN);

		if (target != null)
			addFollowTarget(target, mode, focus);
	}

	/**
	 * Tweens the focal strength on the target to 0.
	 * 
	 * @param target    The followed target
	 * @param time      The tween time
	 * @param ease      The tween ease, if null cubeInAndOut is used
	 * @param callback  Called on complete
	 */
	inline public function unfocusTarget(target:FlxObject, time = FOCUS_TWEEN_TIME, ?ease, ?callback)
	{
		tweenTargetFocusTo(target, time, 0, ease, callback);
	}

	/**
	 * Tweens the focal strength on the target to 0 and then removes the target from the follow list.
	 * 
	 * @param target    The followed target
	 * @param time      The tween time
	 * @param ease      The tween ease, if null cubeInAndOut is used, if null cubeInAndOut is used
	 * @param callback  Called on complete, affter the target is removed
	 */
	inline public function unfocusTargetAndRemove(target:FlxObject, time = FOCUS_TWEEN_TIME, ?ease, ?callback)
	{
		unfocusTarget(target, time, ease, () ->
		{
			followers.remove(target);
			if (callback != null)
				callback();
		});
	}

	inline function tweenOptionsHelper(?ease:EaseFunction, ?callback:() -> Void)
	{
		final tweenOptions:TweenOptions = {
			ease: (ease == null ? FOCUS_EASE : ease)
		}

		if (callback != null)
			tweenOptions.onComplete = (_) -> callback();

		return tweenOptions;
	}

	public function setFollowMode(target:FlxObject, mode:CameraMode)
	{
		if (followers.exists(target) == false)
			throw 'no existing CameraFollower for target: $target';

		followers[target].setMode(mode);
	}

	static var screenRect = FlxRect.get();

	public function isOnScreen(obj:FlxObject)
	{
		screenRect = getWorldViewRect(screenRect);
		// @formatter:off

		return screenRect.left   < obj.x + obj.width
			&& screenRect.right  > obj.x
			&& screenRect.top    < obj.y + obj.height
			&& screenRect.bottom > obj.y; 
		// @formatter:on
	}

	inline function get_minScrollX()
		return scrollBounds.minX;

	inline function set_minScrollX(value:Float)
		return scrollBounds.minX = value;

	inline function get_maxScrollX()
		return scrollBounds.maxX;

	inline function set_maxScrollX(value:Float)
		return scrollBounds.maxX = value;

	inline function get_minScrollY()
		return scrollBounds.minY;

	inline function set_minScrollY(value:Float)
		return scrollBounds.minY = value;

	inline function get_maxScrollY()
		return scrollBounds.maxY;

	inline function set_maxScrollY(value:Float)
		return scrollBounds.maxY = value;

	public function getWorldViewRect(?rect:FlxRect)
	{
		rect = camera.getViewRect(rect);
		rect.x += camera.scroll.x - debugOffset.x;
		rect.y += camera.scroll.y - debugOffset.y;
		return rect;
	}
}
