package flixel.camera.debug;

import flash.display.BitmapData;
import flash.ui.Keyboard;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect; 
import flixel.system.debug.interaction.Interaction;

@:bitmap("flixel/images/cameraMover.png")
private class ToolGraphic extends BitmapData {}

/**
 * TODO: doc
 */
class CameraMover extends flixel.system.debug.interaction.tools.Tool
{
	var dragging:Bool = false;
	var cam:CameraManager;
	var start = FlxPoint.get();
	var oldOffset = FlxPoint.get();

	public function new(cam:CameraManager)
	{
		this.cam = cam;
		super();
	}

	override function init(brain:Interaction)
	{
		super.init(brain);

		_name = "CameraMover";
		setButton(ToolGraphic);
		setCursor(new ToolGraphic(0, 0));

		// var m = FlxPoint.get();
		// FlxG.watch.add(this, "start", "start");
		// FlxG.watch.addFunction("mouse", () -> m.set(mouseX, mouseY));
		// FlxG.watch.add(this, "oldOffset", "oldOffset");
		// FlxG.watch.add(cam, "debugOffset", "debugOffset");
		var view = FlxRect.get();
		FlxG.watch.addFunction("view", () -> cam.getWorldViewRect(view));

		return this;
	}

	override public function update():Void
	{
		if (FlxG.mouse.justPressedRight)
		{
			cam.debugOffset.set(0, 0);
			oldOffset.set(0, 0);
			start.set(0, 0);
		}

		if (_brain.pointerPressed && !dragging)
			startDragging();
		else if (_brain.pointerPressed && dragging)
			doDragging();
		else if (_brain.pointerJustReleased && dragging)
			stopDragging();
	}

	function stopDragging():Void
	{
		dragging = false;
		doDragging();
	}

	function startDragging():Void
	{
		if (dragging)
			return;

		dragging = true;
		oldOffset.copyFrom(cam.debugOffset);
		start.x = mouseX;
		start.y = mouseY;
	}

	function doDragging():Void
	{
		cam.setDebugOffset(oldOffset.x + start.x - mouseX, oldOffset.y + start.y - mouseY);
	}

	override function get_mouseX()
	{
		return FlxG.mouse.screenX;
	}

	override function get_mouseY()
	{
		return FlxG.mouse.screenY;
	}
}
