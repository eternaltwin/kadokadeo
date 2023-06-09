<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

final class Game {
    // Ajouter une function list pour lister toutes les parties
    // et renvoyer vers la view dédiée

	public static function view(): void {
		include("../src/Views/Game.php");
	}
}
