package flixel.camera;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import openfl.display.Graphics;

/**
 * TODO: doc
 */
class CameraFocus extends FlxObject implements flixel.camera.debug.ICameraDebugDrawable
{
	public var centerX:Float;
	public var centerY:Float;
	public var shape:FocusShape;
	public var ease:EaseFunction;
	public var strength:Float = 1.0;

	#if debug
	var lastAmount:Float = 0;
	#end

	public function new(centerX:Float, centerY:Float, shape:FocusShape, ?ease:EaseFunction)
	{
		this.centerX = centerX;
		this.centerY = centerY;
		this.shape = shape;
		this.ease = ease == null ? FlxEase.cubeIn : ease;

		var x:Float;
		var y:Float;
		var width:Float;
		var height:Float;

		switch (shape)
		{
			case CIRCLE(_, outerRadius):
				x = centerX - outerRadius;
				y = centerY - outerRadius;
				width = height = outerRadius * 2;
			case RECT(halfWidth, halfHeight, lerpBuffer):
				x = centerX - halfWidth - lerpBuffer;
				y = centerY - halfHeight - lerpBuffer;
				width = (halfWidth + lerpBuffer) * 2;
				height = (halfHeight + lerpBuffer) * 2;
		}
		super(x, y, width, height);
	}

	public function isInRange(posX:Float, posY:Float):Bool
	{
		#if debug
		lastAmount = -1;
		#end

		final dx = centerX - posX;
		final dy = centerY - posY;

		switch (shape)
		{
			case CIRCLE(innerRadius, outerRadius):
				return dx * dx + dy * dy < outerRadius * outerRadius;
			case RECT(halfWidth, halfHeight, lerpBuffer):
				return abs(dx) < halfWidth + lerpBuffer && abs(dy) < halfHeight + lerpBuffer;
		}
	}

	inline function abs(n:Float)
		return n < 0 ? -n : n;

	public function focusAmount(posX:Float, posY:Float):Float
	{
		final dx = centerX - posX;
		final dy = centerY - posY;

		var amount = switch (shape)
		{
			case CIRCLE(innerRadius, outerRadius):
				inline calcCircleAmount(dx, dy, innerRadius, outerRadius);
			case RECT(halfWidth, halfHeight, lerpBuffer):
				inline calcRectAmount(dx, dy, halfWidth, halfHeight, lerpBuffer);
		}

		#if debug
		lastAmount = amount;
		#end

		return ease(amount * strength);
	}

	function calcCircleAmount(dx:Float, dy:Float, innerRadius:Float, outerRadius:Float):Float
	{
		final dis = Math.sqrt(dx * dx + dy * dy);

		// if (dis >= outerRadius)
		// 	return 0;

		if (dis <= innerRadius)
			return 1;

		return 1 - ((dis - innerRadius) / (outerRadius - innerRadius));
	}

	function calcRectAmount(dx:Float, dy:Float, halfWidth:Float, halfHeight:Float, lerpBuffer:Float):Float
	{
		dx = abs(dx);
		dy = abs(dy);

		if (dx > halfWidth + lerpBuffer && dy < halfHeight + lerpBuffer)
			return 0;

		if (dx <= halfWidth && dy <= halfHeight)
			return 1;

		dx -= halfWidth;
		dy -= halfHeight;

		final closer = dx > dy ? dx : dy;
		return 1 - (closer / lerpBuffer);
	}

	#if debug
	public function debugDraw(gfx:Graphics, offsetX:Float, offsetY:Float)
	{
		switch (shape)
		{
			case CIRCLE(innerRadius, outerRadius):
				inline debugDrawCircle(gfx, innerRadius, outerRadius, offsetX, offsetY);
			case RECT(halfWidth, halfHeight, lerpBuffer):
				inline debugDrawRect(gfx, halfWidth, halfHeight, lerpBuffer, offsetX, offsetY);
		}
	}

	inline static var DEBUG_COLOR = 0xFF0000ff;

	public function debugDrawCircle(gfx:Graphics, innerRadius:Float, outerRadius:Float, offsetX:Float, offsetY:Float)
	{
		final screenX = centerX + offsetX;
		final screenY = centerY + offsetY;

		final amount = 1.0 - lastAmount;

		gfx.lineStyle(amount >= 0 ? 3 : 1, DEBUG_COLOR);
		gfx.drawCircle(screenX, screenY, outerRadius);
		gfx.lineStyle(amount == 1 ? 3 : 1, DEBUG_COLOR);
		gfx.drawCircle(screenX, screenY, innerRadius);

		if (amount >= 0 && amount < 1)
		{
			gfx.lineStyle(1, DEBUG_COLOR);
			gfx.drawCircle(screenX, screenY, innerRadius + amount * (outerRadius - innerRadius));
		}
	}

	function debugDrawRect(gfx:Graphics, halfWidth:Float, halfHeight:Float, lerpBuffer:Float, offsetX:Float, offsetY:Float)
	{
		final screenX = centerX + offsetX;
		final screenY = centerY + offsetY;

		inline function rect(halfWidth:Float, halfHeight:Float, thickness = 1, color = DEBUG_COLOR)
		{
			gfx.lineStyle(thickness, color);
			gfx.drawRect(screenX - halfWidth, screenY - halfHeight, halfWidth * 2, halfHeight * 2);
		}

		rect(halfWidth, halfHeight, lastAmount == 0 ? 3 : 1);
		rect(halfWidth + lerpBuffer, halfHeight + lerpBuffer, lastAmount > 0 && lastAmount < 1 ? 3 : 1);

		if (lastAmount >= 0 && lastAmount < 1)
		{
			final dis = lerpBuffer * (1 - lastAmount);
			rect(halfWidth + dis, halfHeight + dis);
		}
	}
	#end
}

enum FocusShape
{
	/**
	 * @param innerRadius  The distance where the lerping ends.
	 * @param outerRadius  The distance where the lerping begins.
	 */
	CIRCLE(inner:Float, outer:Float);

	/**
	 * @param halfWidth   
	 * @param halfHeight  
	 * @param lerpBuffer  
	 */
	RECT(halfWidth:Float, halfHeight:Float, lerpBuffer:Float);
}
