/* -----
Scène du jeu proprement dit
----- */

var sceneGame = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 
	
    function sceneGame() {
        Phaser.Scene.call(this, { key: 'sceneGame' });
    },

    preload: function() {
        // Chargement des images nécessaires pour le jeu
        // Shared for all games
        CF.GameLoadImages(this);

        // This game
        this.load.image('gameBackground.png', DIR_PATH + 'images/gameBackground.png');
    },

    create: function() {
        // Shared for all games
        _this = this;
        CF.GameCreate(this);

        // This game
        this.add.image(0, 0, 'gameBackground.png').setOrigin(0, 0);
    }
});