/* -----
PHASER CONFIGURATION

Need :
1- {IDGAME}/gameParameters.js -> Global vars for the game {IDGAME}
2- gameGlobal.js -> Global var and customized classes/functions used in all games
3- gameStart.js -> Contain sceneStart : Carousel of pictures running and contract creation
4- {IDGAME}/game.js -> Contain sceneGame : the specific game core
5- gameEnd.js -> Contain sceneEnd : Display score and final information
----- */

var config = {
    type: Phaser.CANVAS,
    width: CANVAS_WIDTH,
    height: CANVAS_HEIGHT,
    canvas: document.getElementById('gameCanvas'),
    scene: [sceneStart, sceneGame, sceneEnd]
};
var game = new Phaser.Game(config);