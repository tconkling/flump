/**
 * @Author: Karl Harmer, Plumbee Ltd
 */
package flump.display
{
  	public const NativeApplicationState : _NativeApplicationState = new _NativeApplicationState();
}

import flash.desktop.NativeApplication;
import flash.events.Event;

internal class _NativeApplicationState
{
	private var _isActive : Boolean;

	public function _NativeApplicationState()
	{
		_isActive = true;

		NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onAppActivation);
		NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onAppDeactivation);
	}

	private function onAppDeactivation(event : Event) : void
	{
		_isActive = false;
	}

	private function onAppActivation(event : Event) : void
	{
		_isActive = true;
	}

	public function get isActive() : Boolean
	{
		return _isActive;
	}
}