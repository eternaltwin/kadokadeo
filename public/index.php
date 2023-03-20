<?php declare(strict_types=1);
require_once "../vendor/autoload.php";

use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;

$Home = new Home();
$Game = new Game();

$Home->render();
