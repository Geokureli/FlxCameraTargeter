package flixel.camera.mode;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.display.Graphics;

/**
 * The most common camera mode of renaine, used for basic platforming.
 */
class PlatformerMode extends CameraMode
{
	/** The highest screen position the target can be before the camera will scroll to compensate **/
	public var top:Float = FlxG.height * .25;

	/** The lowest screen position the target can be before the camera will scroll to compensate **/
	public var bottom:Float = FlxG.height * .75;

	/**
	 * How far ahead to show, in the player's forward x direction. 0 will put the target in the
	 * camera's center.
	**/
	public var leading:Float;

	/**
	 * The horizontal dead-zone width. How far the target can move backwards before flipping the 
	 * leading direction
	**/
	public var deadWidth:Float;

	/** How fast to snap the cam to the new y after the target lands on the ground **/
	public var yPanSpeed:Float;

	public var coyoteTime:Float = 0.1;

	var coyoteTimer:Float = 0;

	var currentLeading:Float;

	public function new(deadWidth:Float, leading:Float, yPanSpeed:Float)
	{
		this.deadWidth = deadWidth;
		this.leading = currentLeading = leading;
		this.yPanSpeed = yPanSpeed;

		super();
	}

	override function snapToTarget()
	{
		final hardLeft = FlxG.width / 2 - leading - deadWidth;
		final normalizedLeading = -currentLeading / leading / 2 + 0.5;
		final fullWidth = leading + leading + deadWidth; // softRight - hardLeft
		final left = hardLeft + fullWidth * normalizedLeading;

		scroll.x = left + (deadWidth - target.width) / 2;
		scroll.y = target.y + target.height - bottom;
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		final bounds = getTargetScreenBounds();
		updateX(elapsed, bounds);
		updateY(elapsed, bounds);
		bounds.put();
	}

	function updateX(elapsed:Float, bounds:FlxRect)
	{
		final hardLeft = FlxG.width / 2 - leading - deadWidth;
		final softLeft = FlxG.width / 2 - leading;
		final hardRight = FlxG.width / 2 + leading + deadWidth;
		final softRight = FlxG.width / 2 + leading;
		final fullWidth = leading + leading + deadWidth; // softRight - hardLeft

		// normalize from range(-leading, leading) to range(0, 1)
		final normalizedLeading = -currentLeading / leading / 2 + 0.5;
		final left = hardLeft + fullWidth * normalizedLeading;
		final right = left + deadWidth;

		var oldLeading = currentLeading;
		if (bounds.right > right)
		{
			final dif = bounds.right - right;
			scroll.x += dif;
			// move the deadzone to its left-most position
			if (currentLeading + dif < leading)
				currentLeading += dif;
			else if (currentLeading < leading)
				currentLeading = leading;
		}
		else if (bounds.left < left)
		{
			final dif = bounds.left - left;
			scroll.x += dif;
			// move the deadzone to its right-most position
			if (currentLeading + dif > -leading)
				currentLeading += dif;
			else if (currentLeading > -leading)
				currentLeading = -leading;
		}

		// scroll more to account for the changing `leading`
		if (currentLeading != oldLeading)
		{
			final newNormalizedLeading = -currentLeading / leading / 2 + 0.5;
			final newLeft = hardLeft + fullWidth * newNormalizedLeading;

			scroll.x -= newLeft - left;
		}
	}

	function updateY(elapsed:Float, bounds:FlxRect)
	{
		// linearly move so the target is at the bottom
		if (target.touching.has(FLOOR))
		{
			final speed = yPanSpeed * elapsed;
			if (bounds.bottom + speed < bottom)
				scroll.y -= speed;
			else if (bounds.bottom - speed > bottom)
				scroll.y += speed;
			else
				scroll.y += bounds.bottom - bottom;

			coyoteTimer = coyoteTime;
		}
		else if (coyoteTimer <= 0)
		{
			if (bounds.bottom > bottom)
				scroll.y += bounds.bottom - bottom;
			else if (bounds.top < top)
				scroll.y += bounds.top - top;
		}
		else
			coyoteTimer -= elapsed;
	}

	override function debugDraw(graphics:Graphics, offsetX:Float, offsetY:Float)
	{
		final midX = FlxG.width / 2 + offsetX;
		final hardLeft = midX - leading - deadWidth;
		final softLeft = midX - leading;
		final hardRight = midX + leading + deadWidth;
		final softRight = midX + leading;
		final top = top + offsetY;
		final bottom = bottom + offsetY;

		// normalize from range(-leading, leading) to range(0, 1)
		final normalizedLeading = -currentLeading / leading / 2 + 0.5;
		final left = hardLeft + (softRight - hardLeft) * normalizedLeading;

		inline function rect(x:Float, y:Float, w:Float, h:Float, thickness = 1.0, color = 0xFFffffff)
		{
			graphics.lineStyle(thickness, color);
			graphics.drawRect(x, y, w, h);
		}

		graphics.lineStyle(1, 0xFFffffff);
		graphics.moveTo(softLeft, top);
		graphics.lineTo(softLeft, bottom);
		graphics.moveTo(softRight, top);
		graphics.lineTo(softRight, bottom);

		if (target.wasTouching.has(FLOOR))
		{
			graphics.lineStyle(3, 0xFFffffff);
			graphics.moveTo(left, bottom - target.height);
			graphics.lineTo(left, bottom);
			graphics.lineTo(left + deadWidth, bottom);
			graphics.lineTo(left + deadWidth, bottom - target.height);
		}
		else
			rect(left, top, deadWidth, bottom - top, 3);
	}
}
