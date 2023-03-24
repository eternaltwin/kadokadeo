<?php declare(strict_types=1);
require_once "../vendor/autoload.php";

use \Eternaltwin\User\UserId;
use \Eternaltwin\User\UserDisplayName;
use \Kadokadeo\Config;
use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;
use \Kadokadeo\Routing;

/*$config = Config::load();
$pdoOptions = Config::dbUrlToPdo($config->databaseUrl);
$pdo = new \PDO($pdoOptions["dsn"], $pdoOptions["username"], $pdoOptions["password"]);

function upsertUser(\PDO $pdo, UserId $id, UserDisplayName $userDisplayName) {
    $query = $pdo->prepare(
        "INSERT INTO \"user\"(user_id, display_name)
        VALUES(:userId, :displayName)
        ON CONFLICT (user_id)
        DO UPDATE SET
          display_name = :displayName;
    ");

    $query->execute([
        'userId' => $id->toString(),
        'displayName' => $userDisplayName->toString(),
    ]);
}

upsertUser($pdo, UserId::fromString("9f310484-963b-446b-af69-797feec6813f"), new UserDisplayName("Demurgos"));*/


/* ROUTES */
// Default route

$classPath = "\Kadokadeo\Controllers\\";
$classAction = $classPath."Home";
$classMethod = "view";

// Route from URI
// Format : "domain/Action/method" with Action is a controller class and method is a method in the controller class
// The default method is "view" in each controller class
// First, we get the URI and make some corrections (deleting first character and too many "/" at the end)
// Then, we check if the class and method exist, else we remain with default route (home page)

$uri = htmlspecialchars($_SERVER['REQUEST_URI']);
$uri = ucfirst(substr($uri, 1));
$uri = rtrim($uri, "/");
if (!empty($uri)) {
	$uriExploded = explode("/", $uri);
	$nbItems = count($uriExploded);
	if (!in_array("", $uriExploded)) { // Checks if the URI doesn't contains several "///" following
		if ($nbItems == 1) {
			$actionFromUri = $classPath.$uriExploded[0];
			$methodFromUri = $classMethod;
		} else {
			$actionFromUri = $classPath.$uriExploded[0];
			$methodFromUri = $uriExploded[1];
		}
		
		if (class_exists($actionFromUri) && method_exists($actionFromUri, $methodFromUri)) {
			$classAction = $actionFromUri;
			$classMethod = $methodFromUri;
		}
	}
}

// Routing effective

$classAction::$classMethod();