/* -----
Scène d'affichage du score quand la partie est terminée
----- */

var sceneEnd = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 

    function sceneEnd() {
        Phaser.Scene.call(this, { key: 'sceneEnd' });
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