package loader;

import flash.Boot;
import flash.display.Sprite;
import mt.flash.VarSecure;

public class Api {
	public var score:VarSecure;
	public var loader:Loader;

	public function new(l:Loader = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		loader = l;
		score = new VarSecure(0);
	}

	public function val(c:VarSecure):int {
		return c.get();
	}

	public function setScore(s:VarSecure):void {
		if (loader.isGameOver()) {
			return;
		}
		score.set(s);
		loader.updateScore(score.get());
	}

	public function saveScore(params: *):void {
		loader.gameOver(score, params, true);
	}

	public function registerButton(mc:Sprite):void {
		loader.registerButton(mc);
	}

	public function isLocal():Boolean {
		return true;
	}

	public function getScore():VarSecure {
		var c:VarSecure = new VarSecure();
		c.set(score);
		return c;
	}

	public function getPeriod():int {
		return int(loader.init._periodId);
	}

	public function gameOver(params: *):void {
		loader.gameOver(score, params);
	}

	public function flagCheater():void {
		loader.run.cheatFlag = true;
	}

	public function __const(v:int):VarSecure {
		return new VarSecure(v);
	}

	public function cmult(a:VarSecure, b:VarSecure):VarSecure {
		var a2:VarSecure = a.copy();
		a2.mult(b);
		return a2;
	}

	public function cadd(a:VarSecure, b:VarSecure):VarSecure {
		var a2:VarSecure = a.copy();
		a2.add(b);
		return a2;
	}

	public function available():Boolean {
		return true;
	}

	public function addScore(s:VarSecure):VarSecure {
		if (loader.isGameOver()) {
			return score;
		}
		score.add(s);
		loader.updateScore(score.get());
		return score;
	}

	public function aconst(a:Array):Array {
		var i:int = 0;
		var a2:Array = [];
		for (var _g1:int = 0,
		var _g:int = int(a.length);
		_g1 < _g;
	)
		{
			i = _g1++;
			a2.push(__const(int(a[i])));
		}
		return a2;
	}
}
