/* -----
Configuration de Phaser
Nécessite :
1- {IDGAME}/gameParameters.js -> Variables globales propre au jeu {IDGAME}
2- gameGlobal.js -> Variables globales et classes/fonctions personnalisées utiles pour tous les jeux
3- gameStart.js -> Contient sceneStart : Splash d'entrée commun à tous les jeux, génération du contrat
4- {IDGAME}/game.js -> Contient sceneGame : Selon le jeu joué, contient la scène du jeu
5- gameEnd.js -> Contient sceneEnd : Ecran de fin de partie, affichage du score et des succès
----- */

var config = {
    type: Phaser.CANVAS,
    width: CANVAS_WIDTH,
    height: CANVAS_HEIGHT,
    canvas: document.getElementById('gameCanvas'),
    scene: [sceneStart, sceneGame, sceneEnd]
};
var game = new Phaser.Game(config);