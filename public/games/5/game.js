/* -----
Déclaration des constantes
----- */

const CANVAS_WIDTH = 300;
const CANVAS_HEIGHT = 320;
const DIR_PATH = 'games/5/';


/* -----
// Déclaration des variables utilisées de façon globale
----- */

var _this; // Remplace "this" dans les fonctions et classes personnalisées
const imagesCarousel = [ //Images du carrousel (écran de démarrage)
    DIR_PATH + 'images/splashScreen1.png',
    DIR_PATH + 'images/splashScreen2.png'
];

const starsFloors = [0, 10240, 12288, 13312, 15600]; // Score à atteindre pour les différents paliers étoile verte, orange, rouge, violette

var carousel = [];
var carouselTimer;
var carouselActive = 0; // Contient l'image affichée actuellement dans le splash d'entrée
var textLaunch;
var textLaunchTimer;
var contract; // Contient l'objet Contract avec les informations concernant le contrat à remplir (score à atteindre, points à gagner,...)

const grid_width = 43; // Largeur d'une cellule du plateau de jeu
const grid_height = 34; // Hauteur d'une cellule du plateau de jeu
const grid_wborder = 21; // Largeur du bord du plateau de jeu
const grid_hborder = 24; // Hauteur du bord du plateau de jeu
const nrow = 7; // Nombre de lignes dans le plateau de jeu
const ncol = 6; // Nombre de colonnes dans le plateau de jeu
var pieces = []; // Contient la liste des objets Piece
var pieceSelected = -1; // Contient l'ID de la pièce sélectionnée (-1 si aucune sélection)
var nPiecesLeft = nrow*ncol; // Contient le nombre de pièces restantes dans le jeu. Fin de la partie si nPiecesLeft = 0
var move; // Contient l'objet Move permettant de tracer les chemins et réaliser les coups
var score; // Contient l'objet Score permettant d'afficher et de compter les points
var gameEnded = false;


/* -----
Scène du splash d'entrée (carrousel de l'écran de démarrage et contrat)
----- */

var SceneSplash = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 

    function SceneSplash() {
        Phaser.Scene.call(this, { key: 'sceneSplash' });
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


/* -----
Scène du jeu proprement dit
----- */

var SceneGame = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 
	
    function SceneGame() {
        Phaser.Scene.call(this, { key: 'sceneGame' });
    },

    preload: function() {
        // Chargement des images nécessaires pour le jeu
        this.load.image('gameBackground.png', DIR_PATH + 'images/gameBackground.png');
        this.load.image('bottomBar.png', DIR_PATH + 'images/bottomBar.png');
		this.load.image('bottomBarGame.png', DIR_PATH + 'images/bottomBarGame.png');
		this.load.image('bottomBarContract.png', DIR_PATH + 'images/bottomBarContract.png');
		this.load.image('contractBarGreen.png', DIR_PATH + 'images/contractBarGreen.png');
		this.load.image('contractBarRed.png', DIR_PATH + 'images/contractBarRed.png');
		this.load.image('wayTurnBottom.png', DIR_PATH + 'images/wayTurnBottom.png');
        this.load.image('wayTurnTop.png', DIR_PATH + 'images/wayTurnTop.png');
        this.load.image('wayLineH.png', DIR_PATH + 'images/wayLineH.png');
		this.load.image('wayLineV.png', DIR_PATH + 'images/wayLineV.png');
		this.load.image('wayTurnBottomRed.png', DIR_PATH + 'images/wayTurnBottomRed.png');
		this.load.image('wayTurnTopRed.png', DIR_PATH + 'images/wayTurnTopRed.png');
        this.load.image('wayLineHRed.png', DIR_PATH + 'images/wayLineHRed.png');
		this.load.image('wayLineVRed.png', DIR_PATH + 'images/wayLineVRed.png');
        this.load.image('wayEndH.png', DIR_PATH + 'images/wayEndH.png');
		this.load.image('wayEndVBottom.png', DIR_PATH + 'images/wayEndVBottom.png');
		this.load.image('wayEndVTop.png', DIR_PATH + 'images/wayEndVTop.png');
        for (let i = 0; i < 5; i++) {
            if (i < 4) {
                this.load.image('similarity' + i + '.png', DIR_PATH + 'images/similarity' + i + '.png');
                if (i < 3) {
                    this.load.image('shape' + i + '.png', DIR_PATH + 'images/shape' + i + '.png');
                    this.load.image('shape' + i + 'mask.png', DIR_PATH + 'images/shape' + i + 'mask.png');
                    for (let j = 0; j < 4; j++) {
                        this.load.image('shape' + i + 'color' + j + '.png', DIR_PATH + 'images/shape' + i + 'color' + j + '.png');
                    }
                }
            }
            this.load.image('symbol' + i + '.png', DIR_PATH + 'images/symbol' + i + '.png');
        }
		this.load.spritesheet('pieceExplosion.png', DIR_PATH + 'images/pieceExplosion.png', {frameWidth: 103, frameHeight: 155});
    },

    create: function() {
        _this = this;
        this.add.image(0, 0, 'gameBackground.png').setOrigin(0, 0);
        this.add.image(0, 296, 'bottomBarGame.png').setOrigin(0, 0);
		contract.ContractBar();
        for (let i = 0; i < 42; i++) {
            pieces.push(new Piece(
                Randoms.intMinMax(0, 2),
                Randoms.intMinMax(0, 3),
                Randoms.intMinMax(0, 4),
                Math.floor(i/(nrow-1)),
                i%(ncol)
            ));
        }
		move = new Move(pieces[0], pieces[0]);
		score = new Score(0);
		
		// Gestion des clics
        this.input.on('pointerdown', function (pointerClick) {
            if (pointerClick.leftButtonDown()) {
				let colClick = CF.XToCol(pointerClick.x);
				let rowClick = CF.YToRow(pointerClick.y);
				let idPieceClick = -1; // ID de la pièce cliquée. Si clic hors du plateau, alors vaut -1
				
				if (colClick >= 0 && colClick < ncol && rowClick >=0 && rowClick < nrow) {
					idPieceClick = CF.ColRowToId(colClick, rowClick);
				}
					
				if (pieceSelected == -1) { // Il s'agit du premier clic
					if (idPieceClick >= 0 && !pieces[idPieceClick].removed) {
						pieces[idPieceClick].Select();
						this.input.on('pointermove', function (pointerMove) {
							let colMove = CF.XToCol(pointerMove.x);
							let rowMove = CF.YToRow(pointerMove.y);
							let idPieceMove = -1; // ID de la pièce survolée. Si hors du plateau, alors vaut -1
							if (colMove >= 0 && colMove < ncol && rowMove >=0 && rowMove < nrow) {
								idPieceMove = CF.ColRowToId(colMove, rowMove);
								move.Update(pieces[pieceSelected], pieces[idPieceMove]);
								move.DrawWay();
							} else {
								move.ClearWay();
							}
						});
					}
				} else { // Il s'agit du deuxième clic
					move.ClearWay();
					if (idPieceClick >= 0 && !pieces[idPieceClick].removed && idPieceClick != pieceSelected) {
						move.Update(pieces[pieceSelected], pieces[idPieceClick]);
						move.Validate();
					}
					pieces[pieceSelected].Deselect();
					this.input.off('pointermove');
				}
            }
        }, this);
    }
});


/* -----
Scène d'affichage du score quand la partie est terminée
----- */

var SceneScore = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 

    function SceneScore() {
        Phaser.Scene.call(this, { key: 'sceneScore' });
    },

    preload: function() {
        
		this.load.image('endBackground.png', DIR_PATH + 'images/endBackground.png');
		this.load.image('endPanelScore.png', DIR_PATH + 'images/endPanelScore.png');
		this.load.image('endPanelContract.png', DIR_PATH + 'images/endPanelContract.png');
		this.load.image('iconKadoPoints.png', DIR_PATH + 'images/iconKadoPoints.png');
		this.load.image('endPanelContractOK.png', DIR_PATH + 'images/endPanelContractOK.png');
		this.load.image('endPanelContractFail.png', DIR_PATH + 'images/endPanelContractFail.png');
		this.load.image('endStarBarBackground.png', DIR_PATH + 'images/endStarBarBackground.png');
		this.load.image('endStarBarFill.png', DIR_PATH + 'images/endStarBarFill.png');
		this.load.image('endStarBarWhiteLight.png', DIR_PATH + 'images/endStarBarWhiteLight.png');
		this.load.image('endStarBackground.png', DIR_PATH + 'images/endStarBackground.png');
		this.load.image('endStarGreen.png', DIR_PATH + 'images/endStarGreen.png');
		this.load.image('endStarOrange.png', DIR_PATH + 'images/endStarOrange.png');
		this.load.image('endStarRed.png', DIR_PATH + 'images/endStarRed.png');
		this.load.image('endStarViolet.png', DIR_PATH + 'images/endStarViolet.png');
		this.load.image('endStarWhiteLightSmall.png', DIR_PATH + 'images/endStarWhiteLightSmall.png');
		this.load.image('endStarWhiteLightWide.png', DIR_PATH + 'images/endStarWhiteLightWide.png');
    },

    create: function() {
        _this = this;
		this.add.image(0, 0, 'endBackground.png').setOrigin(0, 0);
		EndGame.ScoreBoard();
	}
});


/* -----
Configuration de Phaser
----- */

var config = {
    type: Phaser.CANVAS,
    width: CANVAS_WIDTH,
    height: CANVAS_HEIGHT,
    canvas: document.getElementById('gameCanvas'),
    scene: [SceneSplash, SceneGame, SceneScore]
};
var game = new Phaser.Game(config);


/* -----
Classe contenant des fonctions personnalisées
----- */

class CF { // CF pour "CustomizedFunctions"
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
	
	static RowToY(val) { // Fonction transformant un numéro de ligne centré (plateau de jeu) en valeur Y
		return grid_hborder + val*grid_height + grid_height/2;
	}
	
	static ColToX(val) { // Fonction transformant un numéro de colonne centré (plateau de jeu) en valeur X
		return grid_wborder + val*grid_width + grid_width/2;
	}
	
	static YToRow(val) { // Fonction transformant une coordonnée Y en un numéro de ligne (plateau de jeu)
		return Math.floor((val - grid_hborder) / grid_height);
	}
	
	static XToCol(val) { // Fonction transformant une coordonnée X en un numéro de colonne (plateau de jeu)
		return Math.floor((val - grid_wborder) / grid_width);
	}
	
	static ColRowToId(c, r) { // Fonction transformant une coordonnée [col, row] vers un identifiant unique (pièce n° 0 en haut à gauche [0,0], 41 en bas à droite [5,6])
		return r * ncol + c;
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
				_this.scene.start('sceneScore');
			}
		});
	}
}

class Randoms {
	static intMinMax(min, max) { // Fonction qui retourne un nombre aléatoire entre la valeur min (incluse) et max (incluse)
		min = Math.ceil(min);
		max = Math.floor(max);
		return Math.floor(Math.random() * (max - min + 1) + min);
    }
	
	static withProba(probaList, valueList) { // Fonction qui retourne un nombre aléatoire en tenant compte d'une distribution de probabilités définie par un array "probaList" entre 0 et 1, liée à une liste de valeurs "valueList"
		let randomNumber = Math.random(); // L'idée est de générer un nombre random entre 0 et 1, et de le situer dans l'array probaList pour voir quelle valeur valueList correspond
		let randomValueMin = 0;
		let randomValueMax = 0;
		for (let i = 1; i < probaList.length; i++) {
			if (randomNumber > probaList[i-1]) {
				randomValueMin = valueList[i-1];
				randomValueMax = valueList[i];
			}
			else {
				break;
			}
		}
		return Randoms.intMinMax(randomValueMin, randomValueMax);	
	}
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
		let arrScoreToReach = [5000, 9000, 11000, 12000, 13000, 14000, 15000];
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
		let contractBarBackground = _this.add.image(3, 302, 'bottomBarContract.png').setOrigin(0, 0);
		let contractText = _this.add.text(3, 304, this.pointsToWin, {color: '#095C6F', fontFamily: 'Jost-Medium, Arial, sans-serif', fixedWidth: '34', fontSize: '10px', align: 'center'});
		this.contractBarFill = _this.add.image(59, 308, 'contractBarGreen.png').setOrigin(0, 0);
		this.contractBarFill.setCrop(0, 0, 0, 7);
	}
	
	ContractBarUpdate() { // Fonction affichant le contrat et la jauge dans le bas de l'écran de jeu
		if (this.ratioCompleted < 1) {
			this.ratioCompleted = score.points / this.scoreToReach;
			if (this.ratioCompleted < 1) {
				this.contractBarFill.setCrop(0, 0, this.ratioCompleted * this.contractBarFill.width, 7);
			} else {
				this.contractBarFill = _this.add.image(59, 308, 'contractBarRed.png').setOrigin(0, 0);
			}
		}
	}	
}

class Piece {
    constructor(shape, color, symbol, row, column) {
		this.shape = shape;
        this.color = color;
        this.symbol = symbol;
        this.row = row;
        this.column = column;
        this.x = CF.ColToX(column);
        this.y = CF.RowToY(row);
        this.selected = false;
        this.removed = false;
        this.sprites = _this.add.container(this.x, this.y);
        this.sprites.setSize(grid_width, grid_height);
        this.sprites.add(_this.add.image(0, 0, 'shape' + this.shape + '.png'));
        this.sprites.add(_this.add.image(0, -4, 'shape' + this.shape + 'color' + this.color + '.png'));
        this.sprites.add(_this.add.image(0, -4, 'symbol' + this.symbol + '.png'));
        this.sprites.add(_this.add.image(0, 0, 'shape' + this.shape + 'mask.png'));
        this.selectEffect = _this.tweens.add({
            targets: this.sprites.last,
            ease: 'Linear',
            duration: 475,
            repeat: -1,
            delay: 0,
            yoyo: true,
            alpha: 0.5
        });
        this.selectEffect.stop();
        this.sprites.last.setAlpha(0);
    }

    Select() {
		this.selectEffect.play();
		this.selected = true;
		pieceSelected = CF.ColRowToId(this.column, this.row);
    }
	
	Deselect() {
		this.selectEffect.stop();
		this.sprites.last.setAlpha(0);
		this.selected = false;
		pieceSelected = -1;
	}
	
	Remove(similarity) { // Fonction de suppression d'une pièce du plateau, avec animation et affichage du nombre de similitudes entre 2 pièces (0, 1, 2 ou 3)
		this.removed = true;
		this.sprites.visible = false;
		
		let animPieceExplosion = _this.anims.create({ // Animation "explosion" de la pièce
            key: 'explode',
            frames: _this.anims.generateFrameNumbers('pieceExplosion.png'),
            frameRate: 30
        });
		let spritePieceExplosion = _this.add.sprite(this.x+2, this.y-43, 'pieceExplosion.png');
		spritePieceExplosion.play('explode');
		spritePieceExplosion.on('animationcomplete', function() {
			spritePieceExplosion.destroy();
		});
		
		let spriteSimilarity = _this.add.sprite(this.x-3, this.y-13, 'similarity' + similarity + '.png');
		spriteSimilarity.alpha = 0;
		spriteSimilarity.scale = 0;
		
		
		_this.tweens.add({ // Animation du chiffre montrant le nombre de similitudes sur la pièce qui disparait
			targets: spriteSimilarity,
			ease: 'Linear',
			duration: 300,
			repeat: 0,
			delay: 0,
			alpha: {value: 1, yoyo: true},
			scale: 1,
			hold: 650,
			onComplete: function() { // Suppression du sprite lorsqu'il a disparu
				this.targets[0].destroy();
			}
		});
	}
}


class Move { // Classe d'un coup joué (sélection de 2 pièces)
	constructor(piece1, piece2) {
		this.Update(piece1, piece2);
		this.similarity = 0;
		this.spritesWay = new Array(); // Contient les sprites dessinant le chemin, sous forme d'array
	}
	
	Update(piece1, piece2) { // Fonction servant de constructeur et de mise à jour : piece1 et piece2 = object pièce de départ et d'arrivée ; way1 et way2 sont les 2 possibilités de raccorder les pièces (1 = vertical puis horizontal ; 2 = horizontal puis vertical)
		this.piece1 = piece1;
		this.piece2 = piece2;
		this.way1 = this.DefineWay(1);
		this.way2 = this.DefineWay(2);
	}
	
	DefineWay(priorDirection) {
		let col1 = this.piece1.column;
		let col2 = this.piece2.column;
		let colSign = Math.sign(col2 - col1);
		let col = col1;
		let row1 = this.piece1.row;
		let row2 = this.piece2.row;
		let rowSign = Math.sign(row2 - row1);
		let row = row1;
		let pieceId1 = CF.ColRowToId(col1, row1);
		let pieceId2 = CF.ColRowToId(col2, row2);
		let pieceId = pieceId1;
		let arrayWay = [pieceId1];
		while (pieceId != pieceId2) {
			if (priorDirection == 1) { // D'abord vertical (row)
				if (row != row2) {
					row += rowSign;
				} else {
					col += colSign;
				}
			} else { // D'abord horizontal (col)
				if (col != col2) {
					col += colSign;
				} else {
					row += rowSign;
				}
			}
			pieceId = CF.ColRowToId(col, row);
			arrayWay.push(pieceId);
		}
		
		return arrayWay;
	}
	
	DrawWay() { // Fonction permettant de dessiner les lignes du chemin en blanc ou rouge lors du mouvement de la souris, lorsqu'une première pièce est sélectionnée
		this.ClearWay();
		let way1Valid = this.CheckWay(this.way1); // Teste la validité du chemin 1
		let way2Valid = this.CheckWay(this.way2); // Teste la validité du chemin 2
		let wayToDraw; // Définit le chemin à dessiner
		if (way1Valid) { 
			wayToDraw = this.way1;
		} else if (way2Valid) {
			wayToDraw = this.way2;
		} else {
			wayToDraw = this.way1;
		}
		if (wayToDraw.length > 1) { // Choix de l'image sur une case
			for (let i = 0 ; i < wayToDraw.length; i++) {
				let imageName = "way";
				let imageFlipX = false;
				let idPrevious = i > 0 ? wayToDraw[i-1] : wayToDraw[i];
				let idNext = i < wayToDraw.length-1 ? wayToDraw[i+1] : wayToDraw[i];
				let idGap = idPrevious-idNext;
				if (i == 0) { // Début du chemin
					if (Math.abs(idGap) == 1) {
						imageName += "EndH";
						imageFlipX = (idGap > 0);
					} else {
						imageName += "EndV";
						imageName += (idGap > 0) ? "Top" : "Bottom";
					}
				} else if (i == wayToDraw.length-1) { // Fin du chemin
					if (Math.abs(idGap) == 1) {
						imageName += "EndH";
						imageFlipX = (idGap < 0);
					} else {
						imageName += "EndV";
						imageName += (idGap < 0) ? "Top" : "Bottom";
					}
				} else { // Milieu du chemin
					if (Math.abs(idGap) == 2) {
						imageName += "LineH";
					} else if (Math.abs(idGap) == ncol*2) {
						imageName += "LineV";
					} else {
						imageName += "Turn";
						if (idPrevious == wayToDraw[i]-ncol || idNext == wayToDraw[i]-ncol) { // On va vers le haut si on a une pièce voisine qui a un ID = ID actuel-6
							imageName += "Top";
							imageFlipX = (Math.abs(idGap) == ncol-1);
						} else {
							imageName += "Bottom";
							imageFlipX = (Math.abs(idGap) == ncol+1);
						}
					}
					if (!pieces[wayToDraw[i]].removed) {
						imageName += "Red";
					}
				}
				let ipiece = pieces[wayToDraw[i]];
				this.spritesWay.push(_this.add.image(ipiece.x, ipiece.y, imageName + ".png").setFlip(imageFlipX, false));
			}
		}
	}
	
	
	CheckWay(way) { // Fonction permettant de vérifier si le chemin est valide ou non (présence de pièces sur le chemin)
		let validWay = true;
		let firstPiece = way[0];
		let lastPiece = way[way.length-1];
		for (let pieceId of way) {
			if (pieceId == firstPiece || pieceId == lastPiece) {
				continue;
			} else {
				if (!pieces[pieceId].removed) {
					validWay = false;
					break;
				}
			}
		}
		
		return validWay;
	}
	
	Validate() {
		if(this.CheckWay(this.way1) || this.CheckWay(this.way2)) {
			this.Compare();
			this.piece1.Remove(this.similarity);
			this.piece2.Remove(this.similarity);
			let scoreList = [1, 50, 300, 1000];
			score.Update(scoreList[this.similarity]);
			contract.ContractBarUpdate();
			
			// Fin de partie si plus aucune pièce
			nPiecesLeft -= 2;
			if (nPiecesLeft == 0) {
				gameEnded = true;
				CF.EndGame();
			}
		}
	}
	
	Compare() { // Fonction qui compte le nombre de similitudes entre 2 pièces et qui renvoie ce nombre (entre 0 et 3)
		this.similarity = 0;
		if (this.piece1.shape == this.piece2.shape) {
			this.similarity += 1;
		}
		if (this.piece1.color == this.piece2.color) {
			this.similarity += 1;
		}
		if (this.piece1.symbol == this.piece2.symbol) {
			this.similarity += 1;
		}
	}
	
	ClearWay() { // Fonction qui supprime les sprites dessinant le chemin
		if (pieceSelected != -1) {
			for (let spriteWay of this.spritesWay) {
				spriteWay.destroy();
			}
			this.spritesWay = [];
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
	}
	
	Update(points) {
		if (!gameEnded) {
			this.points += points;
			this.textBox.setText(this.points);
		}
	}
}

class EndGame {
	static ScoreBoard() {
		let scoreBoardPanel = _this.add.image(0, 0, 'endPanelScore.png');
		let scoreBoardText = _this.add.text(-1*CANVAS_WIDTH/2, -23, score.points, {color: '#FCAF01', fontFamily: 'Junegull-Regular, Arial, sans-serif', fontSize: '46px', fixedWidth: CANVAS_WIDTH, align: 'center'});
		scoreBoardText.setStroke('#C85404', 3);
        let scoreBoard = _this.add.container(CANVAS_WIDTH/2, CANVAS_HEIGHT/2);
        scoreBoard.setSize(300, 74);
        scoreBoard.add(scoreBoardPanel);
		scoreBoard.add(scoreBoardText);
		let scoreBoardTweenPosition = _this.tweens.add({
			targets: scoreBoard,
			ease: 'Linear',
			duration: 750,
			repeat: 0,
			delay: 0,
			y: 25+scoreBoard.height/2,
			onComplete: function() {
				_this.scoreTextTweenTranslation = CF.TweenTranslation(scoreBoardText, scoreBoardText.x, scoreBoardText.y+2, -1, 800, 0);
				EndGame.ContractBoard();
			}
		});
	}
	
	static ContractBoard() {
		let contractBoardPanel = _this.add.image(0, 0, 'endPanelContract.png');
		let contractScoreText = _this.add.text(-1*CANVAS_WIDTH/2-68, 0, contract.scoreToReach, {color: '#159BB6', fontFamily: 'Junegull-Regular, Arial, sans-serif', fontSize: '16px', fixedWidth: CANVAS_WIDTH, align: 'center'});
		let contractPointsText = _this.add.text(30, 0, contract.pointsToWin, {color: '#159BB6', fontFamily: 'Junegull-Regular, Arial, sans-serif', fontSize: '16px'});
        let contractBoard = _this.add.container(CANVAS_WIDTH/2, CANVAS_HEIGHT+92);
		let contractPointsIcon = _this.add.image(40+contractPointsText.width, 8, 'iconKadoPoints.png').setScale(0.5);
        contractBoard.setSize(300, 92);
        contractBoard.add(contractBoardPanel);
		contractBoard.add(contractScoreText);
		contractBoard.add(contractPointsText);
		contractBoard.add(contractPointsIcon);
		let contractBoardTweenPosition = _this.tweens.add({
			targets: contractBoard,
			ease: 'Linear',
			duration: 300,
			repeat: 0,
			delay: 0,
			y: CANVAS_HEIGHT-50,
			completeDelay: 350,
			onComplete: function() {
				EndGame.ContractStatus();
			}
		});
	}
	
	static ContractStatus() {
		let contractStatus;
		if (score.points >= contract.scoreToReach) {
			contractStatus = _this.add.image(0, 0, 'endPanelContractOK.png');
		} else {
			contractStatus = _this.add.image(0, 0, 'endPanelContractFail.png');
		}
		contractStatus.setX(265);
		contractStatus.setY(240);
		contractStatus.setRotation(0.5);
		contractStatus.setScale(5);
		let contractStatusTween = _this.tweens.add({
			targets: contractStatus,
			ease: 'Linear',
			duration: 200,
			repeat: 0,
			delay: 0,
			scale: 1,
			onComplete: function() {
				EndGame.StarBoard();
			}
		});
	}
	
	static StarBoard() {
		let starBarBackground = _this.add.image(25, 158, 'endStarBarBackground.png').setOrigin(0, 0);
		let starBackground = _this.add.image(203, 112, 'endStarBackground.png').setOrigin(0, 0);
		let starBoard = _this.add.container(-1*CANVAS_WIDTH, 0);
        starBoard.add(starBarBackground);
		starBoard.add(starBackground);
		let starBoardTweenPosition = _this.tweens.add({
			targets: starBoard,
			ease: 'Linear',
			duration: 300,
			repeat: 0,
			delay: 350,
			x: 0,
			onComplete: function() {
				EndGame.StarBar();
			}
		});
	}
	
	static StarBar() {
		let starFloor = 0; // 1 = no star ; 2 = green ; 3 = orange ; 4 = red ; 5 = violet
		let barDistance = [0, 49, 99, 149, 196];
		let barProgress = 0;
		let barProgressImage = _this.add.image(26, 159, 'endStarBarFill.png').setOrigin(0, 0);
		for (let starScore of starsFloors) {
			if (score.points >= starScore) {
				starFloor++;
			}
		}
		for (let i = 0 ; i < starFloor ; i++) {
			if (i < starFloor-1) {
				barProgress = barDistance[i+1];
			} else {
				if (i == barDistance.length-1) {
					barProgress = barProgressImage.width;
				} else {
					barProgress += Math.ceil((barDistance[i+1] - barDistance[i]) * (score.points - starsFloors[i]) / (starsFloors[i+1] - starsFloors[i]));
				}
			}
		}
		barProgressImage.setCrop(0, 0, barProgress, barProgressImage.width);
		// INSERER LE TWEEN AVEC L'AVANCEE DE LA BARRE (ET L'EFFET BLANC ?)
		EndGame.BigStar(starFloor);
	}
	
	static BigStar(floor) { //floor => 1 = no star ; 2 = green ; 3 = orange ; 4 = red ; 5 = violet
		let starName;
		switch(floor) {
			case 2: 
				starName = "Green";
			break;
			
			case 3:
				starName = "Orange";
			break;
			
			case 4:
				starName = "Red";
			break;
			
			case 5:
				starName = "Violet";
			break;
			
			default:
				starName = "nostar";
		}
		if (starName != "nostar") {
			let starImage = _this.add.image(247, 154, 'endStar' + starName + '.png'); 
			let starReflectBig = _this.add.image(247, 154, 'endStarWhiteLightWide.png').setAlpha(0);
			let starReflectSmall = _this.add.image(247, 154, 'endStarWhiteLightSmall.png').setAlpha(0);
			starImage.setScale(5);
			let starImageTweenScale = _this.tweens.add({
				targets: starImage,
				ease: 'Linear',
				duration: 500,
				repeat: 0,
				delay: 0,
				scale: 1,
				onComplete: function() {
					CF.TweenAlpha(starReflectBig, 0.5, -1, 500, 300);
					CF.TweenAlpha(starReflectSmall, 0.6, -1, 500, 0);
				}
			});
		}
	}
}