/* -----
Scène du splash d'entrée (carrousel de l'écran de démarrage et contrat)
----- */

var sceneStart = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 

    function sceneStart() {
        Phaser.Scene.call(this, { key: 'sceneStart' });
    },

    preload: function() {
        // Chargement des images du carrousel (écran de démarrage)
        for (var img of imagesCarousel) {
            this.load.image(img, img);
        }
        this.load.image('contractBackground.png', DIR_PATH + 'images/contractBackground.png');
    },

    create: function() {
        _this = this;
        // Affichage de l'écran de démarrage
        for (let i = 0; i < imagesCarousel.length; i++) {
            carousel.push(this.add.image(0, 0, imagesCarousel[i]).setOrigin(0, 0));
            carousel[i].alpha = 0;
        }
        carousel[0].alpha = 1;

        textLaunch = this.add.text(0, 302, 'Cliquer pour commencer', {color: '#FF6600', fontFamily: 'Junegull-Regular, Arial, sans-serif', fontSize: '16px', fixedWidth: CANVAS_WIDTH, align: 'center'});
        textLaunch.setDepth(2);
        textLaunchTimer = this.time.addEvent({ delay: 300, callback: CF.Blink, args: [textLaunch, 300, 150], callbackScope: this, loop: true });
        carouselTimer = this.time.addEvent({ delay: 3000, callback: CF.Carousel, args: [carousel, 3000, 1100], callbackScope: this, loop: true });

        // Affichage du contrat lors du clic gauche
		
		this.input.once('pointerdown', function (pointer) {
			if (pointer.leftButtonDown()) {
				// Immobilisation du fond
				textLaunchTimer.remove();
				carouselTimer.remove();
				this.tweens.killAll();
				textLaunch.alpha = 1;
				
				// Création et affichage du contrat
				contract = new Contract();
				contract.ContractDisplay();
            }
        }, this);
    }
});