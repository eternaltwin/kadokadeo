<?php declare(strict_types=1);
namespace Kadokadeo\Controllers;

use \Eternaltwin\OauthClient\RfcOauthClient;
use \Eternaltwin\Client\Auth as EtwinAuth;
use \Eternaltwin\Client\HttpEtwinClient;
use \Eternaltwin\User\UserId;
use \Eternaltwin\User\UserDisplayName;
use \Kadokadeo\Config;
use \Kadokadeo\Scripts\PdoSingleton;

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
final class SessionManager {
	public readonly RfcOauthClient $oauthClient;
	public readonly \PDO $pdo;
	public readonly HttpEtwinClient $etwinClient;
    // Define the $_SESSION variables. Changing this array needs also to adapt the calls to those $_SESSION variables in the website
    private static $sessionVars = array(
        "uuid",
        "username"
    );
	
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

    // Check if user is connected (return true or false)
    public static function isConnected(): bool {
        $result = true;
        foreach (self::$sessionVars as $value) {
            if (!isset($_SESSION[$value])) {
                $result = false;
                break;
            }
        }

        return $result;
    }

	// Send the user the the Eternal-twin connection form for sign in
	public static function signin(): void {
		$authObject = new SessionManager();

		$scope = 'base';
		$state = 'kadokadeo';

		$authorizationUri = $authObject->oauthClient->getAuthorizationUri($scope, $state);
		header("Location: " . $authorizationUri, true, 302);
	}
	
	// Get the callback from Eternal-twin when connected successfully, then create the session
	public static function signinCallback(): void {
		$authObject = new SessionManager();
		
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
        // $sessionDatas has to respect the $sessionVars property
        $sessionDatas = array(
            $userUuid,
            $username
        );
        // Creation of $_SESSION vars according to $sessionVars as keys and $sessionDatas as values
        if (count(self::$sessionVars) == count($sessionDatas)) {
            foreach (self::$sessionVars as $key => $value) {
                $_SESSION[$value] = $sessionDatas[$key];
            }
        }

		header("Location: /", true, 302);
	}

    // Signs the user out
	public static function signout(): void {
		if (self::isConnected()) {
            $_SESSION = array();
            session_destroy();
        }

        header("Location: /", true, 302);
	}
}
