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
    }

    Update() {
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
}

class Bonus {
    constructor() {
        let searchPosition = true;
        let searchRay = 5 + Math.trunc(Math.sqrt(BONUS_R2));
        while (searchPosition) { // Calculate random X and Y position avoiding existing entities
            this.x = Random.IntMinMax(0, 300 - searchRay * 2) + searchRay;
            this.y = Random.IntMinMax(0, MAX_Y - searchRay * 2) + searchRay;
            searchPosition = false;
            for (let i = 0; i < arrEntities.length; i++) {
                let dx = arrEntities[i].x - this.x;
                let dy = arrEntities[i].y - this.y;
                if (dx**2 + dy**2 < searchRay**2) {
                    searchPosition = true;
                    break;
                }
            }
        }

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
    }
}