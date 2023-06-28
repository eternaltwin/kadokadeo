<?php declare(strict_types=1);
namespace Kadokadeo\Models;

use \Kadokadeo\Scripts\PdoSingleton;

/* All that concerns users and needs the DB */
final class User {
    public readonly \PDO $pdo;
    public string $uuid = "";
    public int $kkid = 0;
    public string $username = ""; 

    public function __construct(string $uuid = "", int $kkid = 0, string $username = "") {
        $pdoSingleton = PdoSingleton::getInstance();
        $this->pdo = $pdoSingleton->getPdo();
        $this->setUuid($uuid);
        $this->setKkid($kkid);
        $this->setUsername($username);
    }

    public function upsert(): void {
        try {
            $query = $this->pdo->prepare("
                INSERT INTO \"user\"(user_id, display_name)
                VALUES(:uuid, :username)
                ON CONFLICT (user_id)
                DO UPDATE SET
                display_name = :username;
            ");
        
            $query->execute([
                'uuid' => $this->uuid,
                'username' => $this->username
            ]);
        } catch(\PDOException $e) {
            throw new \Exception("Erreur lors de la modification de l'utilisateur dans la base de données.");
        }
    }

    public function setUuid($uuid): void {
        if (self::isValidUuid($uuid)) {
            $this->uuid = $uuid;
        }
    }

    public function setKkid($kkid): void {
        if (is_numeric($kkid) && $kkid > 0) {
            $this->kkid = $kkid;
        }
    }

    public function setUsername($username): void {
        if (is_string($username)) {
            $this->username = $username;
        }
    }

    // Check if it is a conform UUID subtype
    public static function isValidUuid($uuid): bool {
        if (!is_string($uuid) || (preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/', $uuid) !== 1)) {
            return false;
        }
        return true;
    }
}