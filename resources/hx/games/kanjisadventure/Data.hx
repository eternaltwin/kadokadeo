package kanjisadventure;

// Tables extracted from the original gfx.swf by the asset pipeline (1x units unless said otherwise)
class Data {
	// tile variants (frames of tileFull / tileCell / tileTop): does the brush go above its cell
	public static var TILE_OVER:Array<Bool> = [false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, true];
	public static var TILE_GROUND = 0;
	public static var TILE_GROUND_SHADE = 1;
	public static var TILE_STAIR_UP = 47;
	public static var TILE_STAIR_DOWN = 48;
	// wall variants for each set of open sides (frame 1 + right 1 + down 2 + left 4 + up 8)
	public static var TILE_WALLS:Array<Array<Int>> = [[2], [3, 4, 5, 6, 7], [8, 9, 10, 11, 12, 13, 14, 15, 16, 17], [18], [19, 20, 21, 22, 23], [24, 25, 26, 27, 28], [29], [30], [31, 32, 33, 34, 35], [36], [37, 38, 39, 40, 41], [42], [43], [44], [45], [46]];

	// text holders animated by their timeline: [x, y, scaleX, scaleY, alpha] for each frame
	public static var LOSS:Array<Array<Float>> = [[0.05, -3.9, 0.9979, 1.0031, 1], [0.05, -4.15, 0.9979, 1.0031, 1], [0.05, -4.45, 0.9979, 1.0031, 1], [0.05, -4.8, 0.9979, 1.0031, 1], [0.05, -5.25, 0.9979, 1.0031, 1], [0.05, -5.75, 0.9979, 1.0031, 1], [0.05, -6.3, 0.9979, 1.0031, 1], [0.05, -6.9, 0.9979, 1.0031, 1], [0.05, -6.35, 0.9979, 1.0031, 1], [0.05, -5.4, 0.9979, 1.0031, 1], [0.05, -5.4, 0.7691, 0.7731, 1], [0.05, -5.35, 0.5402, 0.543, 1], [0.05, -5.4, 0.3113, 0.313, 1], [0.05, -5.4, 0.0825, 0.0829, 1]];
	public static var SCORE:Array<Array<Float>> = [[0.05, 0, 0.1945, 0.1945, 1], [0.05, 0, 0.5479, 0.5477, 1], [0.05, 0, 0.8004, 0.8001, 1], [0.05, 0, 0.9518, 0.9515, 1], [0.05, 0, 1.0023, 1.002, 1]];

	// text fields: [x, y, width, font size]
	public static var TEXT_LIFE:Array<Float> = [14.3, 18.5, 35.4, 10];
	public static var TEXT_FOOD:Array<Float> = [68.2, 18.5, 22.25, 10];
	public static var TEXT_GOLD:Array<Float> = [107.5, 18.5, 28.9, 10];
	public static var TEXT_SHURIKEN:Array<Float> = [107.7, 4.8, 14.2, 10];
	public static var TEXT_SHOPNAME:Array<Float> = [29.55, -2.1, 85.7, 10];
	public static var TEXT_SHOPGOLD:Array<Float> = [42.15, 12.3, 28.9, 10];
	public static var TEXT_PANEL:Array<Float> = [3.8, 79.75, 227.2, 10];
	public static var TEXT_LOSS:Array<Float> = [-16.5, -6, 33.6, 10];
	public static var TEXT_SCORE:Array<Float> = [-27.8, -10.95, 56.2, 20];
	public static var TEXT_LOG:Array<Float> = [4.4, 2, 310.65, 10];

	public static var BAR_LIFE:Array<Float> = [6.7, 11];
	public static var PANEL_SIZE:Array<Float> = [240, 103.85];
}
