<?php declare(strict_types=1);
require_once "../vendor/autoload.php";

use \Kadokadeo\Controllers\Home;
use \Kadokadeo\Controllers\Game;
use \Kadokadeo\Config;
use \Eternaltwin\User\UserId;
use \Eternaltwin\User\UserDisplayName;

$config = Config::load();
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

upsertUser($pdo, UserId::fromString("9f310484-963b-446b-af69-797feec6813f"), new UserDisplayName("Demurgos"));

$Home = new Home();
$Game = new Game();

$Home->render();
