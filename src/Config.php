<?php declare(strict_types=1);

namespace Kadokadeo;

final class Config {
    public readonly string $databaseUrl;
    public readonly string $adminDatabaseUrl;
    public readonly string $externalUrl;
    public readonly string $eternaltwinUrl;
    public readonly string $identityServerUri;
    public readonly string $oauthId;
    public readonly string $oauthSecret;
    public readonly string $oauthTokenUri;

    public function __construct(
        string $databaseUrl,
        string $adminDatabaseUrl,
        string $externalUrl,
        string $eternaltwinUrl,
        string $identityServerUri,
        string $oauthId,
        string $oauthSecret,
        string $oauthTokenUri,
    ) {
        $this->databaseUrl = $databaseUrl;
        $this->adminDatabaseUrl = $adminDatabaseUrl;
        $this->externalUrl = $externalUrl;
        $this->eternaltwinUrl = $eternaltwinUrl;
        $this->identityServerUri = $identityServerUri;
        $this->oauthId = $oauthId;
        $this->oauthSecret = $oauthSecret;
        $this->oauthTokenUri = $oauthTokenUri;
    }

    /**
     * Load the local config.
     *
     * The config is retrieved by finding the closest `.env` file and merging
     * it with the process environment variables.
     */
    final public static function load(): self {
        $config = null;
        $dirCount = 0;
        $dir = __DIR__;
        for(;;) {
            $configPath = $dir . DIRECTORY_SEPARATOR . ".env";
            if (file_exists($configPath)) {
                $config = file_get_contents($configPath);
                if ($config === false) {
                    throw new \Error("failed to read `.env` path in $dir");
                } else {
                    break;
                }
            }
            $dirCount += 1;
            $parentDir = realpath($dir . DIRECTORY_SEPARATOR . "..");
            if ($dirCount >= 100 || $parentDir == $dir) {
                break;
            }
            $dir = $parentDir;
        }
        if ($config === null) {
            return self::fromEnv($_ENV);
        }
        $configData = parse_ini_string($config, false);
        if ($configData === false) {
            throw new \Error("failed to parse `.env` path in $dir");
        }
        return self::fromEnv(array_merge($_ENV, $configData));
    }

    final public static function fromEnv(array $env): self {
        return new Config(
            $env["DATABASE_URL"],
            $env["ADMIN_DATABASE_URL"],
            $env["EXTERNAL_URL"],
            $env["ETERNALTWIN_URL"],
            $env["IDENTITY_SERVER_URI"],
            $env["OAUTH_ID"],
            $env["OAUTH_SECRET"],
            $env["OAUTH_TOKEN_URI"],
        );
    }

    /**
     * Create or upgrade the db
     */
    final public static function sync(): void {
        echo "no db:sync yet.\n";
        die(0);
    }

    /**
     * Convert a Postgres database URL into PDO options.
     *
     * Example URL: `postgresql://kadokadeo.dev:dev@localhost:5432/kadokadeo?serverVersion=14&charset=utf8`
     *
     * @param string $url Postgresql database URL
     * @return array PDO options
     */
    final public static function dbUrlToPdo(string $url): array {
        $parsed = parse_url($url);
        if (!is_array($parsed)) {
            throw new \Error("Invalid postgresql URL $url");
        }
        if ($parsed["scheme"] !== "postgresql") {
            throw new \Error("Invalid postgresql URL $url: scheme must be `postgresql`");
        }
        $db = $parsed["path"];
        if (str_starts_with($db, "/")) {
            $db = substr($db, 1);
        }
        $dsn = "pgsql:"
            . "host=" . ($parsed["host"] ?? "localhost") . ";"
            . "port=" . ($parsed["port"] ?? 5432) . ";"
            . "dbname=" . $db;
        return [
            "dsn" => $dsn,
            "username" => $parsed["user"],
            "password" => $parsed["pass"],
        ];
    }
}
