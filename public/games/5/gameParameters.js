/* -----
Variables liées au jeu proprement dit
----- */

const DIR_PATH = 'games/5/';
const imagesCarousel = [ //Images du carrousel (écran de démarrage)
    DIR_PATH + 'images/splashScreen1.png',
    DIR_PATH + 'images/splashScreen2.png'
];
const starsFloors = [0, 10240, 12288, 13312, 15600]; // Score à atteindre pour les différents paliers étoile verte, orange, rouge, violette
const arrScoreToReach = [5000, 9000, 11000, 12000, 13000, 14000, 15000]; // Permet de générer des petits scores pour des petits contrats, et des gros scores pour des gros contrats

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