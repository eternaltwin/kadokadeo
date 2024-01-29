/* -----
Variables for this game
----- */

const DIR_PATH = 'games/11/';
const imagesCarousel = [ // Images for the game launcher
    DIR_PATH + 'images/splashScreen1.png',
    DIR_PATH + 'images/splashScreen2.png',
    DIR_PATH + 'images/splashScreen3.png'
];
const starsFloors = [0, 12150, 24300, 30375, 59000]; // Points to reach to obtain red, orange, red or purple star
const arrScoreToReach = [10000, 18000, 25000, 32000, 40000, 45000, 50000]; // Useful to generale small points for small contracts, or high points for high contracts

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

// Keyboard watching : true if the key is down
var keySpace = false;
var keyUp = false;
var keyRight = false;
var keyDown = false;
var keyLeft = false;

var timer;

var idEntity = 0; // 
var arrEntities = new Array(); // Listing hero, bonuses and ennemies
var arrBonuses = new Array(); // Listing bonuses
// CI-DESSUS, JE VOUDRAIS METTRE new CArray(); pour pouvoir utiliser DeleteObject();

/*var testarray = new CArray(1);
console.log(testarray);*/
// J'ESSAIE DE CREER UNE CLASSE PERSO D'ARRAY POUR Y AJOUTER MES FONCTIONS MAIS 
// CA NE FONCTIONNE PAS

class PowerArray extends Array {
    isEmpty() {
      return this.length === 0;
    }
  }
  
  let arr = new PowerArray(1, 2, 5, 10, 50);
  arr.push(3);
  console.log(arr); // false

  // JE DOIS CREER UN FICHIER CUSTOMCLASSES ?? Car dans game.php, gameGlobal vient après gameParameters