<?php declare(strict_types=1);

/* A FAIRE :
- Ajouter le pseudo dans la BDD, avec le timestamp inscription / 1ère connexion et éventuellement d'autres valeurs
- Quand connecté, accéder à la page listant tous les jeux
- Quand clic sur un jeu, accéder au jeu ---> ACTIVER PHASER
- Réaliser le classement par jeu
*/

require_once '../vendor/autoload.php';

use \Kadokadeo\Scripts\SessionManager;
use \Kadokadeo\Controllers\Auth;
use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;

session_start();

if (!SessionManager::isConnected()) {
    $dispatcher = FastRoute\simpleDispatcher(function(FastRoute\RouteCollector $r) {
        $r->get('/', '\Kadokadeo\Controllers\Home::view');
        $r->get('/login', '\Kadokadeo\Controllers\Auth::login');
        $r->get('/oauth/callback', '\Kadokadeo\Controllers\Auth::loginCallback');
    });
} else {
    $dispatcher = FastRoute\simpleDispatcher(function(FastRoute\RouteCollector $r) {
        $r->get('/', '\Kadokadeo\Controllers\Game::view');
        $r->get('/game', '\Kadokadeo\Controllers\Game::view');
        $r->get('/signout', '\Kadokadeo\Controllers\Auth::signOut');
    });
}

// Fetch method and URI from somewhere. If user is disconnected, redirect to home page
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
        header("Location: /", true, 302);
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