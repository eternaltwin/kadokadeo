/* -----
Global vars specific to this game
----- */

const DIR_PATH = 'games/11/';
const imagesCarousel = [ // Images for the game launcher
    DIR_PATH + 'images/splashScreen1.png',
    DIR_PATH + 'images/splashScreen2.png',
    DIR_PATH + 'images/splashScreen3.png'
];
const starsFloors = [0, 12150, 24300, 30375, 59000]; // Score to reach for green, orange, red or violet star
const arrScoreToReach = [10000, 18000, 25000, 32000, 40000, 45000, 50000]; // Useful to generate low scores for low contracts, and high scores for big contracts

// Game const
const WANTED_FPS = 32;

const DEPTH_BONUS = 1;
const DEPTH_HERO = 2;
const DEPTH_ENNEMIES = 3;

const MAX_Y = 280;
const MIN_X = 15;
const MAX_X = 285;

const S_WAIT = 0;
const S_MOVE = 1;
const S_JUMP = 2;
const HERO_SPEED = 5;
const HERO_JSPEED = 0.7;
const HERO_MAXPOW = 25;

const BONUS_PROBAS = 100;
const BONUS_PROBAS_ARR = [50, 10, 1];
const BONUS_POINTS = [200, 500, 3000];
const BONUS_R2 = 600;

const BIRD = 0;
const BEE = 1;
const BOARLET = 2;
const ENNEMY_PROBAS = [50, 35, 20, 10, 5, 4, 4, 3, 3, 2, 1];
const ENNEMY_PROBAS_ARR = [100, 40, 10];

const LEVEL_DELTA = 15;

// Keyboard watching : true if the key is down
var keySpace = false;
var keyUp = false;
var keyRight = false;
var keyDown = false;
var keyLeft = false;

var timer;
var level; // Level (speed of the game) calculated from nbBonuses with LEVEL_DELTA
var nbBonuses; // Number of bonuses taken

var arrEntities = new CArray(); // Listing hero, bonuses and ennemies
var arrBonuses = new CArray(); // Listing bonuses
var arrEnnemies = new CArray(); // Listing ennemies