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
Classes utiles au jeu
----- */

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
        this.selectEffect.pause(); // STOP <> PAUSE
        this.sprites.last.setAlpha(0);
    }

    Select() {
		this.selectEffect.restart();
		this.selected = true;
		pieceSelected = CF.ColRowToId(this.column, this.row);
    }
	
	Deselect() {
		this.selectEffect.pause();
		this.sprites.last.setAlpha(0);
		this.selected = false;
		pieceSelected = -1;
	}
	
	Remove(similarity) { // Fonction de suppression d'une pièce du plateau, avec animation et affichage du nombre de similitudes entre 2 pièces (0, 1, 2 ou 3)
		this.removed = true;
		this.sprites.visible = false;
		let keyAnimation = 'explode'+CF.ColRowToId(this.column, this.row).toString();
		let animPieceExplosion = _this.anims.create({ // Animation "explosion" de la pièce
            key: keyAnimation,
            frames: _this.anims.generateFrameNumbers('pieceExplosion.png'),
            frameRate: 30
        });
		let spritePieceExplosion = _this.add.sprite(this.x+2, this.y-43, 'pieceExplosion.png');
		spritePieceExplosion.play(keyAnimation);
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