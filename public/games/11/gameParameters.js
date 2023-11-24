/* -----
Variables liées au jeu proprement dit
----- */

const DIR_PATH = 'games/11/';
const imagesCarousel = [ //Images du carrousel (écran de démarrage)
    DIR_PATH + 'images/splashScreen1.png',
    DIR_PATH + 'images/splashScreen2.png'
];
const starsFloors = [0, 12150, 24300, 30375, 59000]; // Score à atteindre pour les différents paliers étoile verte, orange, rouge, violette
const arrScoreToReach = [10000, 18000, 25000, 32000, 40000, 45000, 50000]; // Permet de générer des petits scores pour des petits contrats, et des gros scores pour des gros contrats