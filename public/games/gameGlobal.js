/* -----
Declare const vars for all games
----- */

const CANVAS_WIDTH = 300;
const CANVAS_HEIGHT = 320;
const DIR_PATH_BASE = 'games/';


/* -----
Declare global vars used for all games
----- */

var _this; // Means "this" when called from functions or classes/objects

var carousel = [];
var carouselTimer;
var carouselActive = 0; // Image ID showed in the carousel
var textLaunch;
var textLaunchTimer;
var contract; // Contains the Contract object
var score; // Contains the Score object
var gameOver = false; // true when game over
var gameOverCalled = false; // true when game over, used to call ThisGame.Over only once

/* -----
Customized classes that can be used for all games
----- */

class Animate { // Functions regarding the tweens and animations of sprites
    static TweenTranslation(item, moveX, moveY, itemRepeat, itemDuration, itemDelay) {
		_this.tweens.add({
			targets: item,
			ease: 'Linear',
			duration: itemDuration,
			repeat: itemRepeat,
			delay: itemDelay,
			yoyo: true,
			x: moveX,
			y: moveY
		});
	}
	
	static TweenAlpha(item, targetAlpha, itemRepeat, itemDuration, itemDelay) {
		_this.tweens.add({
			targets: item,
			ease: 'Linear',
			duration: itemDuration,
			repeat: itemRepeat,
			delay: itemDelay,
			yoyo: true,
			alpha: targetAlpha
		});
	}
	
	static Blink(item, visibleDelay, invisibleDelay) { // Blinking the item object. Blinking timer = (visible + invisible). Not visible during the invisibleDelay.
        if (item.alpha == 1) {
            item.alpha = 0;
            item.delay = invisibleDelay;
        } else {
            item.alpha = 1;
            item.delay = visibleDelay;
        }
    }

    static PlaySpriteThenDestroy(thisSprite, animKey) { // Play the animation "animKey" on the sprite "thisSprite", then delete the sprite when animation is finished
        thisSprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE, function () {
            thisSprite.destroy();
        }, _this);
        thisSprite.play(animKey);
    }
}

class Carousel {
    static Next(firstDelay, secondDelay) { // Switch to next image. arr contains the objects, firstDelay the timer for first image and secondDelay the timer for all the other images
        let whiteScreen = this.add.graphics(); // Drawing var for white screen
        whiteScreen.setDepth(2);
        let whiteRectangle;
        var blurredImage = [];
        
        if (carouselActive == 0) { // After first image, transition to white screen
            carouselTimer.delay = secondDelay; // Longer delay for the first image
            whiteScreen.fillStyle(0xffffff);
            whiteRectangle = whiteScreen.fillRect(0, 0, 300, 300);
            whiteRectangle.alpha = 0;
            this.tweens.add({ // Displaying the white screen progressively
                targets: whiteRectangle,
                ease: 'Linear',
                duration: 200,
                repeat: 0,
                delay: 0,
                alpha: 1,
                yoyo: true,
                onYoyo: function() { // When the screen is totally white, switch image
                    carouselActive = (carouselActive+1) % carousel.length; // Set next image
                    Carousel.AlphaManager(); // Display new image
                },
                onComplete: function() { // Delete white screen when complete
                    this.targets[0].destroy();
                }
            });
        } else {
            if (carouselActive == carousel.length-1) {
                carouselTimer.delay = firstDelay; // Longer delay for the first image
            }
            for (let i = 0; i <= 6; i++) { // Dynamic blur as transition
                if (i == 0) {
                    blurredImage.push(this.add.image(0, 0, carousel[carouselActive].texture.key).setOrigin(0, 0));
                    blurredImage[i].alpha = 1;
                } else {
                    let facteur = Math.ceil(i/2);
                    if (i%2 == 1) {
                        blurredImage.push(this.add.image(facteur*4, 0, carousel[carouselActive].texture.key).setOrigin(0, 0));
                        blurredImage[i].alpha = 0.5/facteur;
                    } else {
                        blurredImage.push(this.add.image(facteur*4*-1, 0, carousel[carouselActive].texture.key).setOrigin(0, 0));
                        blurredImage[i].alpha = 0.5/facteur;
                    }
                }
            }
            carouselActive = (carouselActive+1) % carousel.length; // Set next image
            Carousel.AlphaManager(); // Display the new image
            this.tweens.add({ // Blur the previous image
                targets: blurredImage,
                ease: 'Linear',
                duration: 100,
                repeat: 0,
                delay: 0,
                yoyo: false,
                x: -320,
                alpha: 0,
                onComplete: function() { // When complete, delete the blurred effect
                    for (var item of this.targets) {
                        item.destroy();
                    }
                }
            });
        }
    }

    static AlphaManager() { // Called to manage the visibility of the images
        for (let i = 0; i < carousel.length; i++) {
            if (i == carouselActive) {
                carousel[i].alpha = 1;
            } else {
                carousel[i].alpha = 0;
            }
        }
    }
}

class ThisGame { // All the functions regarding the main game scene and can be used in all games
    static LoadImages(gameScene) { // Load images used in all games
        gameScene.load.image('bottomBar.png', DIR_PATH_BASE + 'imagesShared/bottomBar.png');
		gameScene.load.image('bottomBarGame.png', DIR_PATH_BASE + 'imagesShared/bottomBarGame.png');
		gameScene.load.image('bottomBarContract.png', DIR_PATH_BASE + 'imagesShared/bottomBarContract.png');
		gameScene.load.image('contractBarGreen.png', DIR_PATH_BASE + 'imagesShared/contractBarGreen.png');
		gameScene.load.image('contractBarRed.png', DIR_PATH_BASE + 'imagesShared/contractBarRed.png');
    }

    static Start(gameScene) { // Starting this game, creating contract and score bottom bar
        gameScene.add.image(0, 296, 'bottomBarGame.png').setOrigin(0, 0).setDepth(999999);
        contract.ContractBar();
        score = new Score(0);
    }
	
	static Over() { // When game over, display a white screen and switch the scene
		if (!gameOverCalled) {
            gameOverCalled = true;
            let whiteScreen = _this.add.graphics().setDepth(9999); // Drawing var for the white screen
            let whiteRectangle;
            whiteScreen.fillStyle(0xffffff);
            whiteRectangle = whiteScreen.fillRect(0, 0, 300, 300);
            whiteRectangle.alpha = 0;
            _this.tweens.add({ // Transition to white screen
                targets: whiteRectangle,
                ease: 'Linear',
                duration: 1500,
                repeat: 0,
                delay: 0,
                alpha: 1,
                onComplete: function() { // Delete white screen when complete
                    _this.scene.stop();
                    _this.scene.start('sceneEnd');
                }
            });
        }
	}
}

class Contract {
	constructor() {
		this.contractBarFill = null;
		this.ratioCompleted = 0; // Between 0 and 1, when 1 is the contract fulfilled
		
		// Kadopoints to win (calculation based on distributed probability)
		let arrProbaPointsToWin = [0, 0.5, 0.75, 0.88, 0.94, 0.97, 0.99, 1];
		let arrPointsToWin = [1, 10, 25, 50, 100, 500, 1000, 10000];
		this.pointsToWin = Random.WithProba(arrProbaPointsToWin, arrPointsToWin);
		
		/* The score to reach calculation depends on the Kadopoints to win :
		- If only 1 Kadopoint, better probability to have a low score to reach => See arrProbaScoreToReachMin
		- If a lot of Kadopoints, bad probability to have a low score to reach => See arrProbaScoreToReachMax
		- In intermediate situations, generate an arrProbaScoreToReach with a factor between arrProbaScoreToReachMin and arrProbaScoreToReachMax
		This factor is saved in arrFactorPointsToWin, and is equal to 1 when min contract and to 0 when max contract. Calculated according to pointsToWin and arrPointsToWin
		*/
		
		let arrProbaScoreToReachMin = [0, 0.5, 0.8, 0.9, 0.97, 0.99, 1];
		let arrProbaScoreToReachMax = [0, 0.01, 0.03, 0.25, 0.75, 0.97, 1];
		let arrFactorPointsToWin = [1, 0.99, 0.97, 0.75, 0.25, 0.03, 0.01, 0];
		
		let factor = 0;
		for (let i = 0; i < arrPointsToWin.length; i++) { // Factor calculation according to pointsToWin and position in arrPointsToWin
			if (this.pointsToWin >= arrPointsToWin[i]) {
				factor = arrFactorPointsToWin[i];
			}
			else {
				break;
			}
		}
		let arrProbaScoreToReach = [];
		for (let i = 0; i < arrProbaScoreToReachMin.length; i++) { // Distributed probability for the score to reach according to the generated factor
			arrProbaScoreToReach.push(arrProbaScoreToReachMax[i] + (arrProbaScoreToReachMin[i] - arrProbaScoreToReachMax[i]) * factor);
		}
		
        // arrScoreToReach must be defined in gameParameters.js for each game
		this.scoreToReach = Random.WithProba(arrProbaScoreToReach, arrScoreToReach);
	}
	
	ContractDisplay() { // Display the contract information when clic on the carousel
        let contractScreen = _this.add.graphics();
        contractScreen.setDepth(2);
        contractScreen.fillStyle(0xD3EBEE, 0.5);
        contractScreen.fillRect(0, 0, 300, 300);
        let contractImage = _this.add.image(150, 150, 'contractBackground.png');
        contractImage.setDepth(3);
		let contractScore = _this.add.text(51, 155, this.scoreToReach, {color: '#159BB6', fontFamily: 'Junegull-Regular, Arial, sans-serif', fixedWidth: '110', fontSize: '16px', align: 'center'});
		contractScore.setDepth(3);
		let contractPointsWin = _this.add.text(194, 155, this.pointsToWin, {color: '#159BB6', fontFamily: 'Junegull-Regular, Arial, sans-serif', fixedWidth: '34', fontSize: '16px', align: 'center'});
		contractPointsWin.setDepth(3);

        _this.input.once('pointerdown', function (pointer) { // Starting the game (scene switch) when clic on the contract information
            if (pointer.leftButtonDown()) {
                _this.scene.stop();
				_this.scene.start('sceneGame');
            }
        }, _this);
    }
	
	ContractBar() { // Display the contract and the progression bar in the game scene bottom bar
		let contractBarBackground = _this.add.image(3, 302, 'bottomBarContract.png').setOrigin(0, 0).setDepth(999999);
		let contractText = _this.add.text(3, 304, this.pointsToWin, {color: '#095C6F', fontFamily: 'Jost-Medium, Arial, sans-serif', fixedWidth: '34', fontSize: '10px', align: 'center'}).setDepth(999999);
		this.contractBarFill = _this.add.image(59, 308, 'contractBarGreen.png').setOrigin(0, 0).setDepth(999999);
		this.contractBarFill.setCrop(0, 0, 0, 7);
	}
	
	ContractBarUpdate() {
		if (this.ratioCompleted < 1) {
			this.ratioCompleted = score.points / this.scoreToReach;
			if (this.ratioCompleted < 1) {
				this.contractBarFill.setCrop(0, 0, this.ratioCompleted * this.contractBarFill.width, 7);
			} else {
				this.contractBarFill = _this.add.image(59, 308, 'contractBarRed.png').setOrigin(0, 0).setDepth(999999);
			}
		}
	}	
}

class Score {
	constructor(points) {
		this.points = points;
		this.textBox = _this.add.text(0, 293, this.points, {color: '#FFF', fontFamily: 'Jost-Medium, Arial, sans-serif', fontSize: '24px', align: 'right', fixedWidth: 295, lineSpacing: 44});
		this.textBox.setShadow(0, 0, '#FFF', 4, true, true);
		this.textBox.setStroke('#559EAC', 4);
		const gradient = this.textBox.context.createLinearGradient(0, 0, 0, this.textBox.height);
		gradient.addColorStop(0, '#FFF');
		gradient.addColorStop(.57, '#e8fcff');
		gradient.addColorStop(.62, '#7cddef');
		gradient.addColorStop(.85, '#FFF');
		this.textBox.setFill(gradient);
        this.textBox.setDepth(999999);
	}
	
	Update(points) {
		if (!gameOver) {
			this.points += points;
			this.textBox.setText(this.points);
		}
	}
}

class Timer {
    constructor(wantedFPS) {
        this.wantedFPS = wantedFPS;
        this.maxDeltaTime = 0.5; // In seconds
        this.oldTime = Date.now();
        this.tmodFactor = 0.95;
        this.calcTmod = 1;
        this.tmod = 1;
        this.deltaT = 1;
        this.frameCount = 0;
        this.paused = false;
    }

    Update() {
        if (!this.paused) {
			this.frameCount++;
			
			let newTime = Date.now();
			
			this.deltaT = Number(((newTime - this.oldTime) / 1000).toFixed(4)); // In seconds
            
			this.oldTime = newTime;

			if (this.deltaT < this.maxDeltaTime) {
				this.calcTmod = this.calcTmod * this.tmodFactor + (1 - this.tmodFactor) * this.deltaT * this.wantedFPS;
            } else {
				this.deltaT = 1 / this.wantedFPS; // In seconds
            }

			this.tmod = this.calcTmod;
		}
    }

    Fps() {
		return this.wantedFPS/this.tmod ;
	}

    Pause() {
        this.paused = true;
    }

    Resume() {
        this.paused = false;
        this.oldTime = Date.now();
    }
}

class Random {
	static IntMinMax(min, max) { // Random int between min and max values (included)
		min = Math.ceil(min);
		max = Math.floor(max);
		return Math.floor(Math.random() * (max - min + 1) + min);
    }
	
	static WithProba(probaList, valueList) { // Random number between 0 and 1, according to a distributed probability array "probaList", linked with a values array "valueList"
		let randomNumber = Math.random().toFixed(8); // The idea is to locate the generated number between 0 and 1 in the array probaList to see which value in valueList is corresponding
		let randomValueMin = 0;
		let randomValueMax = 0;
		for (let i = 1; i < probaList.length; i++) {
			if (randomNumber > probaList[i-1]) {
				randomValueMin = valueList[i-1];
				randomValueMax = valueList[i];
			} else {
				break;
			}
		}
		return Random.IntMinMax(randomValueMin, randomValueMax);	
	}

    static FromQuantities(quantities) { // Choose a random number from an array with quantities and returns the index of the array
        let cumulatedQuantities = [];
        let accumulator = 0;
        for (let i = 0; i < quantities.length; i++) {
            accumulator += quantities[i];
            cumulatedQuantities.push(accumulator);
        }
        let randomNumber = Random.IntMinMax(1, accumulator);
        for (let i = 0;  i < cumulatedQuantities.length; i++) {
            if (randomNumber <= cumulatedQuantities[i]) {
                return i;
            }
        }
    }
}




// /!\
// THIS GRID OBJECT WILL BE IMPROVED WHEN CREATING OTHER GAMES WITH GRIDS (Kaskade, Aqua Splash,...)
// WHEN MODIFIED, THE GAME N°5 Xian-Xiang HAS TO BE IMPROVED TOO
// IDEA = Create new grid object in game scene. In this object, uses this.pieces as the array containing the Pieces objects.

class Grid {
    constructor(nrows, ncols, grid_height, grid_width, grid_hborder, grid_wborder) {
        this.nrows = nrows;
        this.ncols = ncols;
        this.pieces = [];
    }

    static RowToY(val) { // Centered row in pixels to Y value
		return grid_hborder + val*grid_height + grid_height/2;
	}
	
	static ColToX(val) { // Centered column in pixels to X value
		return grid_wborder + val*grid_width + grid_width/2;
	}
	
	static YToRow(val) { // Y value to centered row in pixels
		return Math.floor((val - grid_hborder) / grid_height);
	}
	
	static XToCol(val) { // X value to centered column in pixels
		return Math.floor((val - grid_wborder) / grid_width);
	}
	
	static ColRowToId(c, r) { // [col, row] to unique ID ([0,0] to ID 0 ; [5,6] to ID 41)
		return r * ncol + c;
	}
}