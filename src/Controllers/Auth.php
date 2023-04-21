<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

use \Eternaltwin\OauthClient\RfcOauthClient;
use \Eternaltwin\Client\Auth as EtwinAuth;
use \Eternaltwin\Client\HttpEtwinClient;
use \Eternaltwin\User\UserId;
use \Eternaltwin\User\UserDisplayName;
use \Kadokadeo\Config;

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

final class Auth {
	public readonly RfcOauthClient $oauthClient;
	public readonly \PDO $pdo;
	public readonly HttpEtwinClient $etwinClient;
	
	public function __construct() {
		$config = Config::load();
		$pdoOptions = Config::dbUrlToPdo($config->databaseUrl);
		$this->pdo = new \PDO($pdoOptions['dsn'], $pdoOptions['username'], $pdoOptions['password']);
		$this->etwinClient = new HttpEtwinClient($config->eternaltwinUrl);

		$this->oauthClient = new RfcOauthClient(
			$config->eternaltwinUrl . 'oauth/authorize',
			$config->eternaltwinUrl . 'oauth/token',
			$config->externalUrl . 'oauth/callback',
			$config->oauthId,
			$config->oauthSecret
		);
	}
	
	public function handleLogin() {
		// No need to change this (sets the privileges and Eternaltwin has only
		// one level of permissions at the moment)
		$scope = 'base';
		$state = 'kadokadeo';

		$authorizationUri = $this->oauthClient->getAuthorizationUri($scope, $state);
		header("Location: " . $authorizationUri, true, 302);
	}
	
	public function handleCallback() {
		echo 'hi';
		$code = $_GET["code"];
		$state = $_GET["state"];
		$accessToken = $this->oauthClient->getAccessTokenSync($code);
		$self = $this->etwinClient->getSelf(EtwinAuth::fromToken($accessToken->getAccessToken()));
		$user = $self->getUser();
		$userDisplayName = $user->getDisplayName()->getCurrent()->getValue();
		$userUuid = $user->getId();
		var_dump($userDisplayName);
		/*upsertUser($this->pdo, $userUuid, $userDisplayName);*/
		$_SESSION['userUuid'] = $userUuid->toString();
		$_SESSION['userName'] = $userDisplayName;
		header("Location: /", true, 302);
	}
}
