<?php declare(strict_types=1);

namespace Kadokadeo;

final class Router {
    public readonly string $databaseUrl;
    public readonly string $adminDatabaseUrl;
    public readonly string $externalUrl;
    public readonly string $eternaltwinUrl;
    public readonly string $oauthId;
    public readonly string $oauthSecret;

    public function __construct(
        string $databaseUrl,
        string $adminDatabaseUrl,
        string $externalUrl,
        string $eternaltwinUrl,
        string $oauthId,
        string $oauthSecret,
    ) {
        $this->databaseUrl = $databaseUrl;
        $this->adminDatabaseUrl = $adminDatabaseUrl;
        $this->externalUrl = $externalUrl;
        $this->eternaltwinUrl = $eternaltwinUrl;
        $this->oauthId = $oauthId;
        $this->oauthSecret = $oauthSecret;
    }
}


