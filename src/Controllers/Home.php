<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

/* Créer une classe SessionManager pour vérifier si les variables de session existent et savoir si l'utilisateur est connecté ou pas.
En fonction de la réponse, Home peut rediriger vers la page des jeux */

final class Home {
	public static function view(): void {
        include("../src/Views/Home.php");
	}
}
