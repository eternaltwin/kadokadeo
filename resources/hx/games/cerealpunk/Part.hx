package cerealpunk;

// Animator.pList: {>MovieClip, vx, vy, vr, weight, frict, timer, scale, ft, fvr}, the fields the code sets on a
// particle clip (null when not set: Animator.main tests them)
class Part extends MC {
	public var vx:Float = 0;
	public var vy:Float = 0;
	public var vr:Null<Float> = null;
	public var weight:Null<Float> = null;
	public var frict:Null<Float> = null;
	// (also set to 0 by the last frame script of partCircle)
	public var timer:Null<Float> = null;
	public var scale:Null<Float> = null;
	public var ft:Null<Int> = null;
	public var fvr:Null<Float> = null;
}
