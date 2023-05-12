<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

final class Game {
	public static function view(): void {
		include("../src/Views/Game.php");
	}
}
