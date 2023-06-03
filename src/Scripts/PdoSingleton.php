<?php declare(strict_types=1);
namespace Kadokadeo\Scripts;

use \Kadokadeo\Config;

/* This class create and manage a unique PDO entity */
final class PdoSingleton {
    private static $instance = null;
    private ?\PDO $pdo = null;

    // Not allowing to create instances with keyword "new" outside this class
    private function __construct() {
        $config = Config::load();
		$pdoOptions = Config::dbUrlToPdo($config->databaseUrl);
		$this->pdo = new \PDO($pdoOptions['dsn'], $pdoOptions['username'], $pdoOptions['password']);
    }

    // Not allowing to clone
    private function __clone() { }

    // New instance of the singleton if not yet defined (null), then returns the already created singleton
    public static function getInstance(): PdoSingleton {
        if(is_null(self::$instance)) {
            self::$instance = new PdoSingleton();
        }
        return self::$instance;
    }

    public function getPdo(): \PDO {
        return $this->pdo;
    }
}
