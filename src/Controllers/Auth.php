<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

use \Eternaltwin\OauthClient\RfcOauthClient;
use \Eternaltwin\Client\Auth as EtwinAuth;
use \Eternaltwin\Client\HttpEtwinClient;
use \Eternaltwin\User\UserId;
use \Eternaltwin\User\UserDisplayName;
use \Kadokadeo\Config;
use \Kadokadeo\Scripts\PdoSingleton;
use \Kadokadeo\Scripts\SessionManager;

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

/* Connection to KadoKadeo via Eternal-twin */
final class Auth {
	public readonly RfcOauthClient $oauthClient;
	public readonly \PDO $pdo;
	public readonly HttpEtwinClient $etwinClient;
	
	public function __construct() {
		$config = Config::load();
        $pdoSingleton = PdoSingleton::getInstance();
        $this->pdo = $pdoSingleton->getPdo();
		$this->etwinClient = new HttpEtwinClient($config->eternaltwinUrl);

		$this->oauthClient = new RfcOauthClient(
			$config->eternaltwinUrl . 'oauth/authorize',
			$config->eternaltwinUrl . 'oauth/token',
			$config->externalUrl . 'oauth/callback',
			$config->oauthId,
			$config->oauthSecret
		);
	}

	// Send the user the the Eternal-twin connection form
	public static function login(): void {
		$authObject = new Auth();

		$scope = 'base';
		$state = 'kadokadeo';

		$authorizationUri = $authObject->oauthClient->getAuthorizationUri($scope, $state);
		header("Location: " . $authorizationUri, true, 302);
	}
	
	// Get the callback from Eternal-twin when connected successfully, then create the session
	public static function loginCallback(): void {
		$authObject = new Auth();
		
		$code = $_GET["code"];
		$state = $_GET["state"];
		$accessToken = $authObject->oauthClient->getAccessTokenSync($code);
		$self = $authObject->etwinClient->getSelf(EtwinAuth::fromToken($accessToken->getAccessToken()));
		$user = $self->getUser();
		$userDisplayName = $user->getDisplayName()->getCurrent()->getValue();
		$userUuid = $user->getId();
		
		upsertUser($authObject->pdo, $userUuid, $userDisplayName);

        // Vars used to define the $_SESSION variables
        $userUuid = $userUuid->toString();
		$username = $userDisplayName;
        // $sessionDatas has to respect the $sessionVars property as defined in class SessionManager
        $sessionDatas = array(
            $userUuid,
            $username
        );
        // The creation of the $_SESSION vars is done in SessionManager class
        SessionManager::setSession($sessionDatas);

		header("Location: /", true, 302);
	}

    // Signs the user out
	public static function signOut(): void {
		SessionManager::killSession();
        header("Location: /", true, 302);
	}
}
