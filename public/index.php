<?php declare(strict_types=1);

/* A FAIRE :
- PDO singleton
- Supprimer loginFunction et callbackLoginFunction pour tout mettre dans des classes dédiées
- Ajouter le pseudo dans la BDD, avec le timestamp inscription / 1ère connexion et éventuellement d'autres valeurs
- Lien de déconnexion
- Quand connecté, accéder à la page listant tous les jeux
- Quand clic sur un jeu, accéder au jeu ---> ACTIVER PHASER
- Réaliser le classement par jeu
*/

require_once '../vendor/autoload.php';

use \Kadokadeo\Controllers\Auth;
use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;

session_start();

if(isset($_SESSION['userName'])) {
  var_dump($_SESSION['userName']);
}

function loginFunction() {
  $oauth = new Auth();
  $oauth->handleLogin();
}

function callbackLoginFunction() {
  $oauth = new Auth();
  $oauth->handleCallback();
}

$dispatcher = FastRoute\simpleDispatcher(function(FastRoute\RouteCollector $r) {
  $r->get('/', '\Kadokadeo\Controllers\Home::view');
  $r->get('/game', '\Kadokadeo\Controllers\Game::view');
  $r->post('/login', 'loginFunction');
  $r->get('/oauth/callback', 'callbackLoginFunction');
});

// Fetch method and URI from somewhere
$httpMethod = $_SERVER['REQUEST_METHOD'];
$uri = $_SERVER['REQUEST_URI'];
if (false !== $pos = strpos($uri, '?')) {
  $uri = substr($uri, 0, $pos);
}
$uri = rawurldecode($uri);

$routeInfo = $dispatcher->dispatch($httpMethod, $uri);

switch ($routeInfo[0]) {
  case FastRoute\Dispatcher::NOT_FOUND:
    // ... 404 Not Found
  break;
  case FastRoute\Dispatcher::METHOD_NOT_ALLOWED:
    $allowedMethods = $routeInfo[1];
    // ... 405 Method Not Allowed
  break;
  case FastRoute\Dispatcher::FOUND:
    $handler = $routeInfo[1];
    $vars = $routeInfo[2];
    $handler($vars);
  break;
}