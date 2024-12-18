/*
Bugs à corriger :
- Logo Kado sur la tête qui subit le flipX
- Echarpe ne bouge pas quand on s'abaisse
*/

/* -----
Game scene
----- */

var sceneGame = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: 
	
    function sceneGame() {
        Phaser.Scene.call(this, { key: 'sceneGame' });
    },

    preload: function() {
        // Shared for all games
        ThisGame.LoadImages(this);

        // This game
        this.load.image('gameBackground.png', DIR_PATH + 'images/gameBackground.png');
        this.load.atlas('sprites', DIR_PATH + 'images/spritesSet.png', DIR_PATH + 'images/spritesSet.json');
    },

    create: function() {
        // Shared for all games
        _this = this;
        ThisGame.Start(this);
        nbBonuses = 0;
        level = 0;

        // This game
        this.add.image(0, 0, 'gameBackground.png').setOrigin(0, 0).setDepth(0);
        AnimatedSprites.LoadAnimations();

        hero = new Hero();
        arrEntities.push(hero);
        timer = new Timer(WANTED_FPS);

        // Keyboard manager
        this.input.keyboard.on('keydown-SPACE', event => { keySpace = true; });
        this.input.keyboard.on('keyup-SPACE', event => { keySpace = false; });
        this.input.keyboard.on('keydown-UP', event => { keyUp = true; });
        this.input.keyboard.on('keyup-UP', event => { keyUp = false; });
        this.input.keyboard.on('keydown-RIGHT', event => { keyRight = true; });
        this.input.keyboard.on('keyup-RIGHT', event => { keyRight = false; });
        this.input.keyboard.on('keydown-DOWN', event => { keyDown = true; });
        this.input.keyboard.on('keyup-DOWN', event => { keyDown = false; });
        this.input.keyboard.on('keydown-LEFT', event => { keyLeft = true; });
        this.input.keyboard.on('keyup-LEFT', event => { keyLeft = false; });

        if (Random.IntMinMax(0, 1000) == 0) { // One game in 1000 have better chance to have red bonuses
            BONUS_PROBAS_ARR[2] = 3;
        }
    },

    update: function() {
        timer.Update();
        hero.Update();
        Bonus.Update();
        Ennemy.Update();
    }
});


/* -----
Game classes
----- */

class Hero {
    constructor() {
		this.x = 150;
        this.y = MAX_Y;
        this.state = S_WAIT;
        this.way = 1;
        this.jumpUp = false;
		this.jumpDx = 0;
		this.jumpPow = 0;
        this.speed = HERO_SPEED;
        this.jspeed = HERO_JSPEED;
        this.maxPow = HERO_MAXPOW;
		this.frame = 0;
        this.spriteHero = _this.add.sprite(this.x, this.y, 'sprites', 'hero/breathing/1.png').setDepth(DEPTH_HERO);
        this.spriteHero.play('breathing');
        this.arrow = _this.add.sprite(this.x, 0, 'sprites', 'arrow/1.png').setDepth(DEPTH_ENNEMIES);
        this.arrow.play('arrow');
        this.arrow.visible = false;
        this.spriteHeroDead = _this.add.image(this.x, this.y, 'sprites', 'heroDead/1.png').setDepth(DEPTH_HERO);
        this.spriteHeroDead.visible = false;
        this.deathY = -5;
    }

    Update() {
        if (gameOver) {
            this.spriteHeroDead.x += this.jumpDx * timer.tmod;
            this.spriteHeroDead.y += this.deathY * timer.tmod;
            this.deathY += timer.tmod;
            if (this.spriteHeroDead.y > 330) {
                ThisGame.Over();
            }
        } else {
            this.jumpDx *= 0.9 ** timer.tmod;
            
            switch (this.state) {
                case S_WAIT:
                case S_MOVE:
                    if (keyLeft) {
                        this.Running();
                        this.way = -1;
                        this.x -= timer.tmod * this.speed;
                    } else if (keyRight) {
                        this.Running();
                        this.way = 1;
                        this.x += timer.tmod * this.speed;
                    } else {
                        this.Braking();
                        this.state = S_WAIT;
                    }
        
                    if (keyUp || keySpace) {
                        this.jumpUp = true;
                        this.jumpPow = 4;
                        if (this.state == S_MOVE) {
                            this.jumpDx = this.way * this.speed;
                        } else {
                            this.jumpDx = 0;
                        }
                        this.state = S_JUMP;
                        this.spriteHero.play('startJumping').chain('jumping');
                        this.AddJumpSmoke();
                    }

                    if (keyDown) {
                        if (this.state == S_WAIT) {
                            if (this.frame >= 46 || this.frame <= 28) {
                                this.spriteHero.setFrame('hero/jumping/59.png');
                            }
                        }
                    }
                break;

                case S_JUMP:
                    if (keyLeft) {
                        this.way = -1;
                        this.jumpDx -= timer.tmod;
                    } else if (keyRight) {
                        this.way = 1;
                        this.jumpDx += timer.tmod;
                    }

                    if (keyUp || keySpace) {
                        if (this.jumpUp && this.jumpPow < this.maxPow) {
                            this.jumpPow *= 1.4 ** timer.tmod;
                            if (this.jumpPow >= this.maxPow) {
                                this.jumpPow = this.maxPow;
                                this.jumpUp = false;
                            }
                        }
                    } else {
                        this.jumpUp = false;
                    }

                    this.x += this.jumpDx * timer.tmod / 1.5;
                    if (!this.jumpUp) {
                        this.jumpPow -= 1.2 * timer.tmod;
                    }

                    if (this.jumpPow <= 0 && this.frame < 73) {
                        this.spriteHero.play('endJumping').chain('falling');
                    }
                break;
            }

            this.y -= timer.tmod * this.jspeed * this.jumpPow;

            if (this.y > MAX_Y) {
                this.jumpPow = 0;
                this.state = S_WAIT;
                this.spriteHero.play('landing').chain('breathing');
                this.y = MAX_Y;
            }
            if (this.x < MIN_X) {
                this.x = MIN_X;
                this.jumpDx *= -2;
            }
            if (this.x > MAX_X) {
                this.x = MAX_X;
                this.jumpDx *= -2;
            }
            
            this.spriteHero.x = this.x;
            this.spriteHero.y = this.y;
            if (this.way == 1) {
                this.spriteHero.setFlipX(false);
            } else {
                this.spriteHero.setFlipX(true);
            }

            this.arrow.x = this.x;
            this.arrow.visible = (this.y < 0) ? true : false;
            
            this.frame = this.spriteHero.frame.name.split('/');
            this.frame = this.frame[this.frame.length-1].replace('.png','');
        }
    }

    Running() {
        if (this.state == S_WAIT) {
            this.spriteHero.play('startRunning').chain('running');
        }
        this.state = S_MOVE;
    }

    Braking() {
        if (this.state == S_MOVE) {
            this.spriteHero.play('braking').chain('breathing');
        }
        this.state = S_MOVE;
    }

    AddJumpSmoke() {
        let spriteJumpSmoke = _this.add.sprite(this.x, this.y, 'sprites', 'jumpSmoke/1.png').setDepth(DEPTH_HERO);
        Animate.PlaySpriteThenDestroy(spriteJumpSmoke, 'jumpSmoke');
    }

    Kill() {
        if (!gameOver) {
            gameOver = true;
            this.spriteHero.destroy();

            let spriteDeathSmoke = _this.add.sprite(this.x, this.y-15, 'sprites', 'deathSmoke/1.png').setDepth(DEPTH_HERO);
            Animate.PlaySpriteThenDestroy(spriteDeathSmoke, 'deathSmoke');
            
            this.spriteHeroDead.x = this.x;
            this.spriteHeroDead.y = this.y;
            this.spriteHeroDead.visible = true;
            _this.tweens.add({
                targets: this.spriteHeroDead,
                ease: 'Linear',
                angle: 360,
                duration: 1000 * (24/WANTED_FPS),
                repeat: -1
            });

            this.jumpDx = (this.x < 150) ? 1 : -1;
        }
    }
}

class Bonus {
    constructor() {
        let positionArray = generatePosition(5 + Math.trunc(Math.sqrt(BONUS_R2)));
        this.x = positionArray.x;
        this.y = positionArray.y;

        this.randomArrayIndex = Random.FromQuantities(BONUS_PROBAS_ARR);
        this.points = BONUS_POINTS[this.randomArrayIndex];
        this.frameIndex = this.randomArrayIndex + 1;
        this.picked = false;

        this.sprites = _this.add.container(this.x, this.y).setDepth(DEPTH_BONUS).setScale(0);
        this.sprites.add(_this.add.image(0, 0, 'sprites', 'bonus/background/' + this.frameIndex + '.png'));
        this.sprites.add(_this.add.image(0, 0, 'sprites', 'bonus/reflect/1.png'));
        _this.tweens.add({
            targets: this.sprites.first,
            ease: 'Linear',
            angle: -360,
            duration: 1250,
            repeat: -1
        });
        _this.tweens.add({
            targets: this.sprites,
            ease: 'Linear',
            scale: 1,
            duration: 312,
            repeat: 0
        });
    }

    static Update() {
        if (arrBonuses.length < 3 && Random.IntMinMax(0, BONUS_PROBAS * arrBonuses.length / timer.tmod) == 0) {
            arrBonuses.push(new Bonus());
            arrEntities.push(arrBonuses[arrBonuses.length-1]);
        }

        for (let i = 0; i < arrBonuses.length; i++) {
            let dx =  hero.x - arrBonuses[i].x;
            let dy =  (hero.y - 20) - arrBonuses[i].y;
            if (dx**2 + dy**2 < BONUS_R2) {
                arrBonuses[i].GetBonus();
            }
        }
    }

    GetBonus() {
        if (!this.picked) {
            nbBonuses++;
            if (nbBonuses % LEVEL_DELTA == 0) {
                level++;
            }

            this.picked = true;
            let spriteBonusPicked = _this.add.sprite(this.x, this.y, 'sprites', 'bonusPicked/1.png').setDepth(DEPTH_HERO);
            Animate.PlaySpriteThenDestroy(spriteBonusPicked, 'bonusPicked');
            
            score.Update(this.points);
		    contract.ContractBarUpdate();
            
            this.sprites.destroy();
            
            arrBonuses = arrBonuses.DeleteObject(this);
            arrEntities = arrEntities.DeleteObject(this);
        }
    }
}

class Ennemy {
    constructor() {
        this.startY = (Random.IntMinMax(0,1) == 0) ? 320 : -20;
        this.way = Math.sign(this.startY) * -1;
        
        let positionArray = generatePosition(40, this.startY);
        this.x = positionArray.x;
        this.y = positionArray.y;
        this.hitFromTop = false;

        this.type = Random.FromQuantities(ENNEMY_PROBAS_ARR.slice(0, level+1));

        switch(this.type) {
            case BIRD:
                this.x += -20 * this.way;
                this.speed = 1 + 0.3 * level;

                this.hitboxDx = 10;
                this.hitboxDy = 0;
                this.hitboxWidth = 78;
                this.hitboxHeight = 12;

                this.spriteEnnemy = _this.add.sprite(0, 0, 'sprites', 'bird/1.png');
                this.hitbox = _this.add.rectangle(this.hitboxDx, this.hitboxDy, this.hitboxWidth, this.hitboxHeight, 0xffffff);
                this.containerEnnemy = _this.add.container(this.x, this.y).setDepth(DEPTH_ENNEMIES);
                this.containerEnnemy.add(this.spriteEnnemy);
                this.containerEnnemy.add(this.hitbox);
                this.spriteEnnemy.play('bird');
                this.hitbox.visible = false;
            break;
        }
        if (this.way == -1) {
            /*
            BUG ICI parfois (je ne sais pas qu'est-ce qui génère le undefined)
            Uncaught TypeError: Cannot set properties of undefined (setting 'scaleX')
    at new Ennemy (game.js:318:41)
    at Ennemy.Update (game.js:325:30)
    at sceneGame.update (game.js:65:16)
    at initialize.step (phaser.min.js:1:948791)
    at initialize.update (phaser.min.js:1:935877)
    at initialize.step (phaser.min.js:1:75942)
    at initialize.step (phaser.min.js:1:80126)
    at e (phaser.min.js:1:140700)

    CAUSE : this.containerEnnemy est défini uniquement dans case BIRD. Mais pas dans case BEE ou BOARLET
            */
            this.containerEnnemy.scaleX = -1;
        }
    }

    static Update() {
        let indexEnnemyProba = (level >= ENNEMY_PROBAS.length) ? ENNEMY_PROBAS.length-1 : level;
        if (arrEnnemies.length < 10 && Random.IntMinMax(0, ENNEMY_PROBAS[indexEnnemyProba] * arrEnnemies.length / timer.tmod) == 0) {
            arrEnnemies.push(new Ennemy());
            arrEntities.push(arrEnnemies[arrEnnemies.length-1]);
        }

        for (let i = 0; i < arrEnnemies.length; i++) {
            let enn = arrEnnemies[i];
            switch (enn.type) {
                case BIRD:
                    enn.x += enn.speed * timer.tmod * enn.way;
                break;
            }

            enn.containerEnnemy.x = enn.x;
            enn.containerEnnemy.y = enn.y;

            switch (enn.type) {
                case BIRD:
                    if (enn.Hit(10)) {
                        if (enn.hitFromTop) {
                            let newJumpPow = Math.max(Math.abs(hero.jumpPow) * 0.7, 0.5);
                            hero.jumpPow = newJumpPow;
                            hero.jumpUp = true;
                            hero.spriteHero.play('startJumping').chain('jumping');
                            hero.AddJumpSmoke();
                            enn.KillBird();
                        } else {
                            hero.Kill();
                        }
                    }
                    if (enn.x > 340 || enn.x < -40) {
                        enn.Remove();
                    }
                break;

                case BEE:
                    if (enn.x > 320 || enn.x < -20) {
                        enn.Remove();
                    }
                break;

                case BOARLET:
                    if (enn.x > 340 || enn.x < -40) {
                        enn.Remove();
                    }
                break;
            }
        }
    }

    Remove() {
        this.containerEnnemy.destroy();
            
        arrEnnemies = arrEnnemies.DeleteObject(this);
        arrEntities = arrEntities.DeleteObject(this);
    }

    Hit(hray) {
        const p = this.containerEnnemy.localTransform.transformPoint(this.hitbox.x, this.hitbox.y);
        let xMinEnnemy = Math.round(p.x - this.hitboxWidth/2 - hero.x);
        let xMaxEnnemy = Math.round(p.x + this.hitboxWidth/2 - hero.x);
        let yMinEnnemy = Math.round(p.y - this.hitboxHeight/2 - hero.y);
        let yMaxEnnemy = Math.round(p.y + this.hitboxHeight/2 - hero.y);

        yMinEnnemy += 20;
        yMaxEnnemy += 20;

        if (xMinEnnemy * xMaxEnnemy > 0) {
			if (xMinEnnemy < 0) {
				if (xMaxEnnemy < hray) {
					return false;
                }
			} else if (xMinEnnemy > hray) {
				return false;
            }
		}

		if (yMinEnnemy * yMaxEnnemy > 0) {
			if (yMinEnnemy < 0) {
				if (yMaxEnnemy < hray) {
					return false;
                }
			} else if (yMinEnnemy > hray) {
				return false;
            }
		}

        this.hitFromTop = ((yMinEnnemy + yMaxEnnemy) / 2 > 5);

        return true;
    }

    KillBird() {
        this.Remove();

        /* FEATHERS GENERATION
        - xFrame and yFrame based on the .fla file (movement interpolation)
        - Animation with 41 frames, one frame is randomly selected for starting
        */
        const xFrame = [-30.25,-30.15,-29.85,-29.3,-28.3,-26.6,-23.85,-19.5,-13.6,-6.6,1,8.6,14.75,19.5,22.55,23.9,24.3,24.3,24.05,23.75,23.75,23.75,23.85,24.05,24.1,23.8,22.75,20.05,15.2,8.4,0.6,-6.7,-13.25,-18.85,-23.55,-26.6,-28.55,-29.55,-29.95,-30.25,-30.25];
        const yFrame = [-16.15,-16.55,-17.65,-19.55,-22.2,-25.7,-29.85,-34.15,-38,-40.95,-43,-41.4,-38.5,-34.8,-30.45,-26.2,-22.5,-19.65,-17.6,-16.45,-16.05,-16.45,-17.65,-19.5,-22.25,-25.75,-30.1,-34.95,-39.3,-42.3,-42.9,-41.6,-38.9,-34.8,-30.2,-26,-22.5,-19.75,-17.65,-16.55,-16.15];
        for (let i = 0; i < 10; i++) {
            let randomFrame = Random.IntMinMax(1,41);
            let xStart = this.x + xFrame[randomFrame-1];
            let yStart = this.y + yFrame[randomFrame-1];
            let featherSprite = _this.add.sprite(xStart, yStart, 'sprites', 'feather/animated/' + randomFrame + '.png').setDepth(DEPTH_ENNEMIES);
            featherSprite.setScale(Random.IntMinMax(50,150)/100);
            featherSprite.play({ key: 'feather', startFrame: randomFrame-1}, true);
            featherSprite.on('animationupdate', function (anim, frame, sprite, frameKey) {
                sprite.y += 0.5 + Math.abs((frame.index*2-41)/41);
            }, _this);
            _this.tweens.add({
                targets: featherSprite,
                ease: 'Linear',
                alpha: 0,
                delay: Random.IntMinMax(0, 40) * 1000 / WANTED_FPS,
                duration: 10 * 1000 / WANTED_FPS,
                repeat: 0,
                onComplete: function() { // Sprite deletion when animation finished
                    this.targets[0].destroy();
                }
            });
        }
    }
}

class AnimatedSprites {
    static LoadAnimations() {
        _this.anims.create({ 
            key: 'breathing', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/breathing/', 
                suffix: '.png', 
                start: 1, 
                end: 28
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'startRunning', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/startRunning/', 
                suffix: '.png', 
                start: 29, 
                end: 32
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'running', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/running/', 
                suffix: '.png', 
                start: 33, 
                end: 35
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'endRunning', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/running/', 
                suffix: '.png', 
                start: 36, 
                end: 39
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'braking', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/braking/', 
                suffix: '.png', 
                start: 40, 
                end: 57
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'startJumping', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/jumping/', 
                suffix: '.png', 
                start: 58, 
                end: 69
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'jumping', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/jumping/', 
                suffix: '.png', 
                start: 70, 
                end: 72
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'endJumping', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/endJumping/', 
                suffix: '.png', 
                start: 73, 
                end: 79
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'falling', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/endJumping/', 
                suffix: '.png', 
                start: 80, 
                end: 93
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'landing', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'hero/landing/', 
                suffix: '.png', 
                start: 94, 
                end: 105
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'arrow', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'arrow/', 
                suffix: '.png', 
                start: 1, 
                end: 25
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'jumpSmoke', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'jumpSmoke/', 
                suffix: '.png', 
                start: 1, 
                end: 9
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'deathSmoke', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'deathSmoke/', 
                suffix: '.png', 
                start: 1, 
                end: 15
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'bonusPicked', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'bonusPicked/', 
                suffix: '.png', 
                start: 1, 
                end: 23
            }), 
            repeat: 0,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'bird', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'bird/', 
                suffix: '.png', 
                start: 1, 
                end: 18
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });

        _this.anims.create({ 
            key: 'feather', 
            frames: _this.anims.generateFrameNames('sprites', { 
                prefix: 'feather/animated/', 
                suffix: '.png', 
                start: 1, 
                end: 41
            }), 
            repeat: -1,
            frameRate: WANTED_FPS
        });
    }
}

function generatePosition(searchRay, startX = null) {
    let searchPosition = true;
    let genX = startX;
    let genY = 0;
    while (searchPosition) { // Calculate random X and Y position avoiding existing entities
        if (startX == null) {
            genX = Random.IntMinMax(0, 300 - searchRay * 2) + searchRay;
        }
        genY = Random.IntMinMax(0, MAX_Y - searchRay * 2) + searchRay;
        searchPosition = false;
        for (let i = 0; i < arrEntities.length; i++) {
            let dx = arrEntities[i].x - genX;
            let dy = arrEntities[i].y - genY;
            if (dx**2 + dy**2 < searchRay**2) {
                searchPosition = true;
                break;
            }
        }
    }

    return {x: genX, y: genY};
}