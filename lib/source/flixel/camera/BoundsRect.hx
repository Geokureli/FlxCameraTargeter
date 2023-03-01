package flixel.camera;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

/**
 * A way to define bounds (mainly for the camera) and helpers to generally enforce these bounds.
 */
@:structInit
class BoundsRect
{
	/** Left bound, if null this direction is unbound. */
	public var minX:Null<Float> = null;

	/** Right bound, if null this direction is unbound. */
	public var maxX:Null<Float> = null;

	/** Top bound, if null this direction is unbound. */
	public var minY:Null<Float> = null;

	/** Bottom bound, if null this direction is unbound. */
	public var maxY:Null<Float> = null;

	inline public function new(?minX:Float, ?maxX:Float, ?minY:Float, ?maxY:Float)
	{
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
	}

	/**
	 * Sets all four bounds of this rect.
	 *
	 * @param   minX   The left bound.
	 * @param   maxX   The right bound.
	 * @param   minY   The top bound.
	 * @param   maxY   The bottom bound.
	 */
	inline public function set(?minX:Float, ?maxX:Float, ?minY:Float, ?maxY:Float)
	{
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		return this;
	}

	/**
	 * Sets all four bounds of this rect.
	 *
	 * @param   rect  The bounds.
	 */
	inline public function setRect(rect:FlxRect)
	{
		set(rect.left, rect.right, rect.top, rect.bottom);
		rect.putWeak();
		return this;
	}

	/**
	 * Extends the bound values to include the supplied bounds.
	 *
	 * @param   minX   The left bound.
	 * @param   maxX   The right bound.
	 * @param   minY   The top bound.
	 * @param   maxY   The bottom bound.
	 */
	inline public function extend(?minX:Float, ?maxX:Float, ?minY:Float, ?maxY:Float)
	{
		if (minX != null && (this.minX == null || this.minX > minX))
			this.minX = minX;
		if (maxX != null && (this.maxX == null || this.maxX < maxX))
			this.maxX = maxX;
		if (minY != null && (this.minY == null || this.minY > minY))
			this.minY = minY;
		if (maxY != null && (this.maxY == null || this.maxY < maxY))
			this.maxY = maxY;

		return this;
	}

	/**
	 * Sets all four bounds of this rect.
	 * @param   rect   The bounds.
	 */
	inline public function extendRect(rect:FlxRect)
	{
		if (this.minX > rect.left)
			this.minX = rect.left;
		if (this.maxX < rect.right)
			this.maxX = rect.right;
		if (this.minY > rect.top)
			this.minY = rect.top;
		if (this.maxY < rect.bottom)
			this.maxY = rect.bottom;

		return this;
	}

	/**
	 * Changes `scroll` so that it is within the `scrollBounds` according to `camera's` view rect.
	 * 
	 * @param   scroll  The point to bind.
	 * @param   camera  The camera, to determine the view rect.
	 */
	public function bindScroll(scroll:FlxPoint, camera:FlxCamera)
	{
		return bindScrollTo(scroll, camera, minX, maxX, minY, maxY);
	}

	/**
	 * Creates a new point bound by `scrollBounds` according to `camera's` view rect.
	 * 
	 * @param   scroll  The unbound point.
	 * @param   result  The resulting bound scroll, if null, one is created.
	 * @param   camera  The camera, to determine the view rect.
	 */
	inline function getBoundScroll(scroll:FlxPoint, camera:FlxCamera, ?result:FlxPoint)
	{
		return bindScroll(scroll.copyTo(result), camera);
	}

	public function toString()
	{
		inline function round(num:Float)
		{
			return Math.round(num * 1000) / 1000;
		}
		
		return '( minX:${Math.round(minX)} | maxX:${Math.round(maxX)} | minY:${Math.round(minY)} | maxY:${Math.round(maxY)} )';
	}

	/**
	 * Creates a `BoundsRect` from a `FlxRect`.
	 * @param   rect   The bounds.
	 */
	inline static public function fromRect(rect:FlxRect)
	{
		var out = new BoundsRect(rect.left, rect.right, rect.top, rect.bottom);
		rect.putWeak();
		return out;
	}

	/**
	 * Changes `scroll` so that it is within the given bounds according to `camera's` view rect.
	 * 
	 * @param   scroll      The point to bind.
	 * @param   camera      The camera, to determine the view rect.
	 * @param   minScrollX  The left scroll bound.
	 * @param   maxScrollX  The right scroll bound.
	 * @param   minScrollY  The top scroll bound.
	 * @param   maxScrollY  The bottom scroll bound.
	 */
	public static function bindScrollTo(scroll:FlxPoint, camera:FlxCamera, ?minScrollX:Float, ?maxScrollX:Float, ?minScrollY:Float, ?maxScrollY:Float)
	{
		final viewX = (camera.zoom - 1) * camera.width / (2 * camera.zoom);
		final viewY = (camera.zoom - 1) * camera.height / (2 * camera.zoom);
		final minX = minScrollX == null ? null : minScrollX - viewX;
		final maxX = maxScrollX == null ? null : maxScrollX + viewX - camera.width;
		final minY = minScrollY == null ? null : minScrollY - viewY;
		final maxY = maxScrollY == null ? null : maxScrollY + viewY - camera.height;

		return bindPointTo(scroll, minX, maxX, minY, maxY);
	}

	/**
	 * Changes `scroll` so that it is within the given bounds according to `camera's` view rect.
	 * 
	 * @param   scroll  The point to bind.
	 * @param   camera  The camera, to determine the view rect.
	 * @param   minX   The left bound.
	 * @param   maxX   The right bound.
	 * @param   minY   The top bound.
	 * @param   maxY   The bottom bound.
	 */
	inline public static function bindPointTo(p:FlxPoint, ?minX:Float, ?maxX:Float, ?minY:Float, ?maxY:Float)
	{
		p.x = FlxMath.bound(p.x, minX, maxX);
		p.y = FlxMath.bound(p.y, minY, maxY);

		return p;
	}

	/**
	 * Changes `scroll` so that it is within the given bounds according to `camera's` view rect.
	 * 
	 * @param   scroll  The point to bind.
	 * @param   camera  The camera, to determine the view rect.
	 */
	inline public static function bindScrollToRect(scroll:FlxPoint, camera:FlxCamera, x:Float, y:Float, width:Float, height:Float)
	{
		return bindScrollTo(scroll, camera, x, x + width, y, y + height);
	}

	/**
	 * Changes `scroll` so that it's fully inside the given object, according to `camera's` view rect.
	 * 
	 * @param   scroll  The point to bind.
	 * @param   camera  The camera, to determine the view rect.
	 */
	inline public static function bindScrollToObj(scroll:FlxPoint, camera:FlxCamera, obj:FlxObject)
	{
		return bindScrollToRect(scroll, camera, obj.x, obj.y, obj.width, obj.height);
	}
}
