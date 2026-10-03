package alphabounce;

// written by tools/alpha_assets.py from gfx.swf
class Data {
	// colours of the options (Option.getCol)
	public static var OPT_COL:Array<Int> = [8388479, 3198314, 39766, 2621399, 52675, 34715, 3263999, 1867469, 470939, 9008639, 7612109, 6291611, 14753279, 13435084, 10158205, 16726724, 13444724, 10162469, 16749419, 13467164, 10184960, 16771859, 12832000, 7576320, 12255044, 6999344];
	// text field: glyphs (anim lvlGlyph), advances, field left / width / top (Flash px), scale
	public static var LVL_CHARS = "NIVEAU0123456789";
	public static var LVL_ADV:Array<Float> = [36.8906, 18.4688, 36.8906, 30.75, 36.8906, 36.8906, 36.8906, 30.75, 36.8906, 36.8906, 36.8906, 36.8906, 36.8906, 36.8906, 36.8906, 36.8906];
	public static var LVL_FIELD:Array<Float> = [2.0, 295.5, 4.8, 38.3906, 1.0, 1.0, 12.3281];
	// text field: glyphs (anim scoreGlyph), advances, field left / width / top (Flash px), scale
	public static var SCORE_CHARS = "0123456789";
	public static var SCORE_ADV:Array<Float> = [10.7461, 8.9551, 10.7461, 10.7461, 10.7461, 10.7461, 10.7461, 10.7461, 10.7461, 10.7461];
	public static var SCORE_FIELD:Array<Float> = [-30.803, 62.097, -6.05, 11.1973, 1.0, 1.1643, 4.2];
}
