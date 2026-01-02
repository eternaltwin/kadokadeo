package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol27")] public dynamic class Contract extends MovieClip {
	public var tokens_label:TextField;
	public var tokens:TextField;
	public var title:MovieClip;
	public var score_label:TextField;
	public var score:TextField;
	public var jack:MovieClip;

	public function new(l:Loader = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		super();
		score_label.text = Loader.TEXT.SCORE_LABEL;
		tokens_label.text = Loader.TEXT.TOKENS_LABEL;
		tokens.text = Std.string(l.start._tokens);
		score.text = Std.string(l.start._contract);
		jack.visible = Boolean(l.start._jackpot);
		title.gotoAndStop(Loader.TEXT.LANG);
	}
}
