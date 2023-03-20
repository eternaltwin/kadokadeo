<?php declare(strict_types=1);

namespace Kadokadeo\Scripts;

use Pgsafari\MigrationDirection;
use Pgsafari\Safari;
use Pgsafari\SchemaMeta;
use Kadokadeo\Config;

final class Db {
    /**
     * Reset the database: drop the whole database, then initialize it.
     *
     * This may be useful during development, avoid using it in production...
     */
    final public static function reset(): void {
        self::innerSync(true, false);
    }

    /**
     * Ensure the database has the latest schema and is populated with the initial data.
     */
    final public static function sync(): void {
        self::innerSync(false, false);
    }

    /**
     * Production variant of `sync` (non-interactive)
     */
    final public static function syncProduction(): void {
        self::innerSync(false, true);
    }

    private static function innerSync(bool $dropData, bool $isProd): void {
        $safari = self::getSafari();
        $config = Config::load();
        $pdoOptions = Config::dbUrlToPdo($config->adminDatabaseUrl);
        $pdo = new \PDO($pdoOptions["dsn"], $pdoOptions["username"], $pdoOptions["password"]);
        $curMeta = SchemaMeta::read($pdo);
        if ($curMeta == null) {
            echo "Current database was never initialized.\n";
            $curVersion = $safari->emptyVersion();
        } else {
            $curVersion = $curMeta->version;
            echo "Current database schema version: " . $curVersion . "\n";
            if ($dropData) {
                echo "DANGER:\n";
                echo "THE WHOLE DATABASE WILL BE DROPPED.\n";
                echo "ALL DATA WILL BE LOST.\n";
                $confirmed = self::confirm("Drop the database?", $isProd);
                if (!$confirmed) {
                    echo "Aborting.\n";
                    die(0);
                }
                echo "Dropping the database\n";
                $emptyVersion = $safari->emptyVersion();
                $migration = $safari->createMigration($curVersion, $emptyVersion, MigrationDirection::downgrade());
                $migration->exec($pdo);
                echo "Database dropped.\n";
                $curVersion = $emptyVersion;
                echo "Current database schema version: " . $curVersion . "\n";
            }
        }
        $latestVersion = $safari->latestVersion();
        echo "Latest available schema version: " . $latestVersion . "\n";
        if ($curVersion == $latestVersion) {
            echo "Database schema is up-to-date.\n";
        } else {
            $migration = $safari->createMigration($curVersion, $latestVersion, MigrationDirection::upgrade());
            $states = [$migration->start];
            foreach ($migration->transitions as $t) {
                $states[] = $t->end;
            }
            echo "Schema migration plan:\n";
            echo implode(" -> ", $states) . "\n";
            $confirmed = self::confirm("Apply schema migration?", $isProd);
            if (!$confirmed) {
                echo "Aborting.\n";
                die(0);
            }
            echo "Applying schema migration.\n";
            $migration->exec($pdo);
            echo "Schema migration complete.\n";
        }
        echo "Synchronizing initial database data.\n";
        self::populate($pdo);
        echo "Initial data synchronization complete.\n";
    }

    private static function populate(\PDO $pdo): void {
        if (!$pdo->beginTransaction()) {
            $info = $pdo->errorInfo();
            throw new \Exception("failed to begin transaction: " . $info[0] . ", " . $info[1] . ", " . $info[2]);
        }
        self::txPopulate($pdo);
        if (!$pdo->commit()) {
            $info = $pdo->errorInfo();
            throw new \Exception("failed to commit transaction: " . $info[0] . ", " . $info[1] . ", " . $info[2]);
        }
    }

    private static function txPopulate(\PDO $pdo): void {
        // Nothing to do
    }

    private static function getSafari(): Safari {
        $projectRoot = __DIR__ . "/../..";
        $dbDir = $projectRoot . "/db";
        return Safari::fromDirectory($dbDir);
    }

    private static function confirm(string $message, bool $isProd): bool {
        if($isProd || in_array("--no-confirm", $_SERVER['argv'])) {
            return true;
        }

        for (;;) {
            echo $message . " [yN] ";
            $input = trim(fgets(STDIN));
            switch (strtolower($input)) {
                case "n":
                case "no":
                case "":
                    return false;
                case "y":
                case "yes":
                    return true;
                default:
                    break;
            }
        }
    }
}
