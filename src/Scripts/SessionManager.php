<?php declare(strict_types=1);
namespace Kadokadeo\Scripts;

/* This class create and manage a unique SessionManager entity */
final class SessionManager {
    // Define the $_SESSION variables. Changing this array needs also to adapt the calls to those $_SESSION variables in the website
    private static $sessionVars = array(
        "userUuid",
        "username"
    );

    // Not allowing to construct or clone
    private function __construct() { }
    private function __clone() { }

    // Check if user is connected (return true or false)
    public static function isConnected(): bool {
        $result = true;
        $nvars = count(self::$sessionVars);
        for ($i = 0; $i < $nvars; $i++) {
            if (!isset($_SESSION[self::$sessionVars[$i]])) {
                $result = false;
                break;
            }
        }

        return $result;
    }

    // Create the $_SESSION variables. It is called from Auth controller.
    public static function setSession(array $sessionDatas): void {
        if (!self::isConnected()) {
            try {
                $nvars = count(self::$sessionVars);
                if (count($sessionDatas) != $nvars) {
                    throw new Error("Problème lors de la connexion. Conctactez l'administrateur.");
                }
                for ($i = 0; $i < $nvars; $i++) {
                    $_SESSION[self::$sessionVars[$i]] = $sessionDatas[$i];
                }
            }
            catch(Error $e){
                echo $e->getMessage();
            }
        }
    }

    // Destroy the $_SESSION variables and redirects to home page
    public static function killSession(): void {
        if (self::isConnected()) {
            $_SESSION = array();
            session_destroy();
        }
    }
}
