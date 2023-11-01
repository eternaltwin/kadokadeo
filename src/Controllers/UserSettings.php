<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

use \Kadokadeo\Models\User;

final class UserSettings {
    public User $user;
    static public string $email = ""; 
    
    // Vérifier si on garde en statique ou pas

	public static function view(): void {
        // Vérifier si email déjà existant dans la BDD et si oui le récupérer pour pré-remplir le champ
        $email = self::$email;
        include("../src/Views/UserSettings.php");
	}

    public static function edit(): void {
        if (isset($_POST['email'])) {
            if (!empty($_POST['email']) &&
                preg_match("/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/", $_POST['email'])) {
                self::$email = $_POST['email'];
            }
        }
        $user = new User($_SESSION['uuid'], 0, $_SESSION['username']);
        self::view();
	}
}
