/* -----
Scene with the carousel of images running
----- */

var sceneStart = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 

    function sceneStart() {
        Phaser.Scene.call(this, { key: 'sceneStart' });
    },

    preload: function() {
        // Loading carousel images
        for (var img of imagesCarousel) {
            this.load.image(img, img);
        }
        this.load.image('contractBackground.png', DIR_PATH_BASE + 'imagesShared/contractBackground.png');
    },

    create: function() {
        _this = this;
        // Display starting screen (first image)
        for (let i = 0; i < imagesCarousel.length; i++) {
            carousel.push(this.add.image(0, 0, imagesCarousel[i]).setOrigin(0, 0));
            carousel[i].alpha = 0;
        }
        carousel[0].alpha = 1;

        textLaunch = this.add.text(0, 302, 'Cliquer pour commencer', {color: '#FF6600', fontFamily: 'Junegull-Regular, Arial, sans-serif', fontSize: '16px', fixedWidth: CANVAS_WIDTH, align: 'center'});
        textLaunch.setDepth(2);
        textLaunchTimer = this.time.addEvent({ delay: 300, callback: Animate.Blink, args: [textLaunch, 300, 150], callbackScope: this, loop: true });
        carouselTimer = this.time.addEvent({ delay: 3000, callback: Carousel.Next, args: [3000, 1100], callbackScope: this, loop: true });

        // Display the contract informations when clicking
		this.input.once('pointerdown', function (pointer) {
			if (pointer.leftButtonDown()) {
				// Freeze background
				textLaunchTimer.remove();
				carouselTimer.remove();
				this.tweens.killAll();
				textLaunch.alpha = 1;
				
				// Create and display the contract information
				contract = new Contract();
				contract.ContractDisplay();
            }
        }, this);
    }
});