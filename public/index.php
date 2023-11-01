<?php declare(strict_types=1);

require_once '../vendor/autoload.php';

use \Kadokadeo\Controllers\SessionManager;
use \Kadokadeo\Controllers\ErrorManager;
use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;

session_start();

// Redirect an error to an exception
set_error_handler('\Kadokadeo\Controllers\ErrorManager::catchError');

// Set time zone
date_default_timezone_set('Europe/Brussels');

try {
    if (!SessionManager::isConnected()) {
        $dispatcher = FastRoute\simpleDispatcher(function(FastRoute\RouteCollector $r) {
            $r->get('/', '\Kadokadeo\Controllers\Home::view');
            $r->get('/signin', '\Kadokadeo\Controllers\SessionManager::signin');
            $r->get('/oauth/callback', '\Kadokadeo\Controllers\SessionManager::signinCallback');
        });
    } else {
        $dispatcher = FastRoute\simpleDispatcher(function(FastRoute\RouteCollector $r) {
            $r->get('/', '\Kadokadeo\Controllers\UserSettings::view');
            $r->get('/user/settings', '\Kadokadeo\Controllers\UserSettings::view');
            $r->post('/user/settings/edit', '\Kadokadeo\Controllers\UserSettings::edit');
            $r->get('/game', '\Kadokadeo\Controllers\Game::view');
            $r->get('/signout', '\Kadokadeo\Controllers\SessionManager::signout');
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
} catch(Exception $e) {
    ErrorManager::displayException($e);
}