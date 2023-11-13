<?php declare(strict_types=1);
namespace Kadokadeo\Models;

use \Kadokadeo\Scripts\PdoSingleton;

/* All that concerns users and needs the DB */
final class User {
    protected readonly \PDO $pdo;
    protected string $uuid = "";
    protected int $kkid = 0;
    protected string $username = ""; 

    public function __construct(string $uuid = "", int $kkid = 0, string $username = "") {
        $pdoSingleton = PdoSingleton::getInstance();
        $this->pdo = $pdoSingleton->getPdo();
        $this->setUuid($uuid);
        $this->setKkid($kkid);
        $this->setUsername($username);
    }

    public function upsert(): void {
        try {
            $checkKkid = self::getKkidFromUuid($this->uuid); // Getting the Kkid from Eternaltwin Uuid. If > 0, update existing user. Else insert new user.

            if ($checkKkid > 0) {
                $query = $this->pdo->prepare('
                    UPDATE "user"
                    SET display_name = :username, ts_signin = CURRENT_TIMESTAMP
                    WHERE user_uuid = :uuid
                ');

                $query->execute([
                    'uuid' => $this->uuid,
                    'username' => $this->username
                ]);

                self::setKkid($checkKkid);
            } else {
                $query = $this->pdo->prepare('
                    INSERT INTO "user" (user_uuid, user_kkid, display_name, ts_register, ts_signin)
                    VALUES (:uuid, DEFAULT, :username, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                ');

                $query->execute([
                    'uuid' => $this->uuid,
                    'username' => $this->username
                ]);

                self::setKkid(intval($this->pdo->lastInsertId()));
            }
        } catch(\PDOException $e) {
            throw new \Exception("Erreur avec la base de données lors de la connexion.");
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

    public function getUuid(): string {
        return $this->uuid;
    }

    public function getKkid(): int {
        return $this->kkid;
    }

    public function getUsername(): string {
        return $this->username;
    }

    // Check if it is a conform UUID subtype
    public static function isValidUuid($uuid): bool {
        if (!is_string($uuid) || (preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/', $uuid) !== 1)) {
            return false;
        }
        return true;
    }

    // Recover KKID from database, knowing the UUID
    public static function getKkidFromUuid($uuid): int {
        $return_kkid = 0;
        
        $pdoSingleton = PdoSingleton::getInstance();
        $pdo = $pdoSingleton->getPdo();
        $query = $pdo->prepare('
            SELECT user_kkid FROM "user" WHERE user_uuid = :uuid
        ');
        
        $query->execute([
            'uuid' => $uuid
        ]);
        
        $results = $query->fetchAll();
        foreach ($results as $result) {
            $return_kkid = (intval($result['user_kkid']));
        }
        
        return $return_kkid;
    }
}