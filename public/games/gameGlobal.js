/* -----
Déclaration des constantes
----- */

const CANVAS_WIDTH = 300;
const CANVAS_HEIGHT = 320;
const DIR_PATH_BASE = 'games/';


/* -----
// Déclaration des variables utilisées de façon globale
----- */

var _this; // Remplace "this" dans les fonctions et classes personnalisées

var carousel = [];
var carouselTimer;
var carouselActive = 0; // Contient l'image affichée actuellement dans le splash d'entrée
var textLaunch;
var textLaunchTimer;
var contract; // Contient l'objet Contract avec les informations concernant le contrat à remplir (score à atteindre, points à gagner,...)
var score; // Contient l'objet Score permettant d'afficher et de compter les points
var gameOver = false; // Devient true quand game over

/* -----
Classe contenant des fonctions personnalisées
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
	
	static Blink(item, visibleDelay, invisibleDelay) { // Fonction faisant clignoter l'objet item. Un clignotement dure le temps défini par le délai (visible + invisible). La partie invisible dure pendant le invisibleDelay.
        if (item.alpha == 1) {
            item.alpha = 0;
            item.delay = invisibleDelay;
        } else {
            item.alpha = 1;
            item.delay = visibleDelay;
        }
    }

    static Carousel(arr, firstDelay, secondDelay) { // Fonction faisant remplacer des images successivements. Arr contient les objets, firstDelay la durée de la première image et secondDelay la durée des images suivantes
        let whiteScreen = this.add.graphics(); // Variable de dessin d'un rectangle blanc de transition
        whiteScreen.setDepth(2);
        let whiteRectangle;
        var blurredImage = [];
        
        if (carouselActive == 0) { // Transition vers un écran blanc après la 1ère image
            carouselTimer.delay = secondDelay; // Délai du 1er écran est plus long
            whiteScreen.fillStyle(0xffffff);
            whiteRectangle = whiteScreen.fillRect(0, 0, 300, 300);
            whiteRectangle.alpha = 0;
            this.tweens.add({ // Affichage d'un écran blanc transitoire
                targets: whiteRectangle,
                ease: 'Linear',
                duration: 200,
                repeat: 0,
                delay: 0,
                alpha: 1,
                yoyo: true,
                onYoyo: function() { // Quand l'écran est blanc, j'incrémente l'image et affiche la nouvelle image
                    carouselActive = (carouselActive+1) % carousel.length; // Incrémentation de l'image du carrousel
                    CF.CarouselAlpha(); // Affichage de la nouvelle image
                },
                onComplete: function() { // Suppression du rectangle blanc lorsqu'il a disparu
                    this.targets[0].destroy();
                }
            });
        } else {
            if (carouselActive == carousel.length-1) {
                carouselTimer.delay = firstDelay; // Délai du 1er écran est plus long
            }
            for (let i = 0; i <= 6; i++) { // Création d'un effet de flou dynamique
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
            carouselActive = (carouselActive+1) % carousel.length; // Incrémentation de l'image du carrousel
            CF.CarouselAlpha(); // Affichage de la nouvelle image
            this.tweens.add({ // Défilement de l'image précédente (floutée)
                targets: blurredImage,
                ease: 'Linear',
                duration: 100,
                repeat: 0,
                delay: 0,
                yoyo: false,
                x: -320,
                alpha: 0,
                onComplete: function() { // Suppression des images dupliquées lorsqu'elles ont disparu
                    for (var item of this.targets) {
                        item.destroy();
                    }
                }
            });
        }
    }

    static CarouselAlpha() { // Fonction appelée par la fonction Carousel pour afficher / masquer les images du carrousel.
        for (let i = 0; i < carousel.length; i++) {
            if (i == carouselActive) {
                carousel[i].alpha = 1;
            } else {
                carousel[i].alpha = 0;
            }
        }
    }

    static GameLoadImages(gameScene) { // Fonction permettant de charger les images communes à chaque jeu.
        gameScene.load.image('bottomBar.png', DIR_PATH_BASE + 'imagesShared/bottomBar.png');
		gameScene.load.image('bottomBarGame.png', DIR_PATH_BASE + 'imagesShared/bottomBarGame.png');
		gameScene.load.image('bottomBarContract.png', DIR_PATH_BASE + 'imagesShared/bottomBarContract.png');
		gameScene.load.image('contractBarGreen.png', DIR_PATH_BASE + 'imagesShared/contractBarGreen.png');
		gameScene.load.image('contractBarRed.png', DIR_PATH_BASE + 'imagesShared/contractBarRed.png');
    }

    static GameCreate(gameScene) { // Fonction permettant de démarrer la partie (affichage du contrat, création du score,...)
        gameScene.add.image(0, 296, 'bottomBarGame.png').setOrigin(0, 0).setDepth(999999);
        contract.ContractBar();
        score = new Score(0);
    }
	
	static EndGame() { // Fonction appelée à la fin de la partie (écran blanc et changement de scène)
		let whiteScreen = _this.add.graphics(); // Variable de dessin d'un rectangle blanc de transition
        let whiteRectangle;
		whiteScreen.fillStyle(0xffffff);
		whiteRectangle = whiteScreen.fillRect(0, 0, 300, 300);
		whiteRectangle.alpha = 0;
		_this.tweens.add({ // Affichage d'un écran blanc transitoire
			targets: whiteRectangle,
			ease: 'Linear',
			duration: 300,
			repeat: 0,
			delay: 0,
			alpha: 1,
			onComplete: function() { // Suppression du rectangle blanc lorsqu'il a disparu
				_this.scene.stop();
				_this.scene.start('sceneEnd');
			}
		});
	}

    static PlaySpriteThenDestroy(thisSprite, animKey) { // Fonction qui joue une animation sur un sprite et supprime ce sprite après l'animation
        thisSprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE, function () {
            thisSprite.destroy();
        }, _this);
        thisSprite.play(animKey);
    }

    static DeleteObjectInArray(obj) { 
        arrEntities = arrEntities.filter((obj) => !Object.is(obj, this));
    }
}

class CArray extends Array { // Fonctions personnalisées sur les array (C for Customized)
    /*DeleteObject(objectToDelete) { // Fonction qui supprime l'objet "objectToDelete" de l'array
        return this.filter((obj) => !Object.is(obj, objectToDelete));
    }*/
}

class Contract {
	constructor() {
		this.contractBarFill = null;
		this.ratioCompleted = 0; // Contient le ratio entre 0 et 1 du contrat déjà accompli
		
		// Calcul du nombre de points Kado à gagner (selon une distribution de probabilité)
		let arrProbaPointsToWin = [0, 0.5, 0.75, 0.88, 0.94, 0.97, 0.99, 1];
		let arrPointsToWin = [1, 10, 25, 50, 100, 500, 1000, 10000];
		this.pointsToWin = Randoms.withProba(arrProbaPointsToWin, arrPointsToWin);
		
		/* Le calcul du score à atteindre dépend de nombre de points Kado à gagner :
		- Si on a un contrat à 1 point Kado, on a beaucoup de chance d'avoir un petit score à atteindre => Voir arrProbaScoreToReachMin
		- Si on a un gros contrat, on a peu de chance d'avoir un petit score à atteindre => Voir arrProbaScoreToReachMax
		- Dans les situations intermédiaires, je génère arrProbaScoreToReach avec un facteur qui permet de se trouver entre arrProbaScoreToReachMin et arrProbaScoreToReachMax
		Ce facteur est retrouvé dans arrFactorPointsToWin, et est égal à 1 quand on est au contrat Min et à 0 quand on est au contrat Max. On le sélectionne en fonction de pointsToWin et arrPointsToWin
		*/
		
		let arrProbaScoreToReachMin = [0, 0.5, 0.8, 0.9, 0.97, 0.99, 1];
		let arrProbaScoreToReachMax = [0, 0.01, 0.03, 0.25, 0.75, 0.97, 1];
		let arrFactorPointsToWin = [1, 0.99, 0.97, 0.75, 0.25, 0.03, 0.01, 0];
		
		let factor = 0;
		for (let i = 0; i < arrPointsToWin.length; i++) { // Sélection du facteur en fonction de pointsToWin généré et de l'importance du contrat (ordre dans l'array arrPointsToWin)
			if (this.pointsToWin >= arrPointsToWin[i]) {
				factor = arrFactorPointsToWin[i];
			}
			else {
				break;
			}
		}
		let arrProbaScoreToReach = [];
		for (let i = 0; i < arrProbaScoreToReachMin.length; i++) { // Je génère les probabilités du score à atteindre en fonction du facteur généré
			arrProbaScoreToReach.push(arrProbaScoreToReachMax[i] + (arrProbaScoreToReachMin[i] - arrProbaScoreToReachMax[i]) * factor);
		}
		
        // arrScoreToReach défini dans gameParameters.js
		this.scoreToReach = Randoms.withProba(arrProbaScoreToReach, arrScoreToReach);
	}
	
	ContractDisplay() { // Fonction appelée lors du clic sur l'écran de démarrage pour afficher le contrat
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

        _this.input.once('pointerdown', function (pointer) { // Lancement de la scène du jeu lors du clic gauche
            if (pointer.leftButtonDown()) {
                _this.scene.stop();
				_this.scene.start('sceneGame');
            }
        }, _this);
    }
	
	ContractBar() { // Fonction affichant le contrat et la jauge dans le bas de l'écran de jeu
		let contractBarBackground = _this.add.image(3, 302, 'bottomBarContract.png').setOrigin(0, 0).setDepth(999999);
		let contractText = _this.add.text(3, 304, this.pointsToWin, {color: '#095C6F', fontFamily: 'Jost-Medium, Arial, sans-serif', fixedWidth: '34', fontSize: '10px', align: 'center'}).setDepth(999999);
		this.contractBarFill = _this.add.image(59, 308, 'contractBarGreen.png').setOrigin(0, 0).setDepth(999999);
		this.contractBarFill.setCrop(0, 0, 0, 7);
	}
	
	ContractBarUpdate() { // Fonction affichant le contrat et la jauge dans le bas de l'écran de jeu
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
			
			this.deltaT = ((newTime - this.oldTime) / 1000).toFixed(4); // In seconds
            
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
	static IntMinMax(min, max) { // Fonction qui retourne un nombre aléatoire entre la valeur min (incluse) et max (incluse)
		min = Math.ceil(min);
		max = Math.floor(max);
		return Math.floor(Math.random() * (max - min + 1) + min);
    }
	
	static WithProba(probaList, valueList) { // Fonction qui retourne un nombre aléatoire en tenant compte d'une distribution de probabilités définie par un array "probaList" entre 0 et 1, liée à une liste de valeurs "valueList"
		let randomNumber = Math.random().toFixed(8); // L'idée est de générer un nombre random entre 0 et 1, et de le situer dans l'array probaList pour voir quelle valeur valueList correspond
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

// TRAVAILLER SUR CET OBJET ET METTRE A JOUR : VERIFICATIONS SELON LES LIMITES NCOL, NROWS,..., ETC

class Grid {
    constructor(nrows, ncols, grid_height, grid_width, grid_hborder, grid_wborder) {
        this.nrows = nrows;
        this.ncols = ncols;
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