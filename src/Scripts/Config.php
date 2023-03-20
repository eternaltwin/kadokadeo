<?php declare(strict_types=1);

namespace Kadokadeo\Scripts;

final class Config
{
    /**
     * Generate the app config from the data provided by the deployer
     */
    final public static function config(): void
    {
        $input = self::getInput();
        $backendConfig = self::toBackendConfig($input);
        $backendLines = [];
        foreach ($backendConfig as $key => $value) {
            $backendLines[] = "$key=".json_encode($value, JSON_UNESCAPED_SLASHES);
        }
        $backendLines[] = "\n";

        $output = json_encode(
            [
                "file" => ".env",
                "data" => implode("\n", $backendLines),
            ],
            JSON_UNESCAPED_SLASHES
        );

        $writeResult = fwrite(STDOUT, $output.PHP_EOL);
        if (false === $writeResult) {
            throw new \Error("failed to write output");
        }
    }

    /**
     * Get the input config:
     * - channel: deployment channel, `staging` or `production`
     * - revision: git commit revision (hash)
     * - secret: secret key that may be used internally by the app
     * - external_uri: canonical URL for this app
     * - database:
     *   - version: major database version (e.g. `15)
     *   - host: db host
     *   - port: db port
     *   - name: db name
     *   - roles: db roles (users)
     *     - admin: role with schema creation permissions
     *       - url: full DB url for this user
     *       - name: string
     *       - password: string
     *     - main: main role for the server (write permissions)
     *       - uri: full DB uri for this user
     *       - name: string
     *       - password: string
     * - eternaltwin: Eternaltwin integration
     *   - uri: URL for Eternaltwin
     *   - oauth: OAuth client details
     *     - id: client id
     *     - secret: client secret
     * - extra: extra configuration specific to this app
     *
     * @return array{
     *   channel: string,
     *   revision: string,
     *   secret: string,
     * }
     * @throws \JsonException
     */
    private static function getInput(): array
    {
        $inputBytes = fgets(STDIN);
        if (false === $inputBytes) {
            throw new \Error("failed to read STDIN line");
        }
        $input = json_decode($inputBytes, true, 512, JSON_THROW_ON_ERROR);
        if (gettype($input) !== "array") {
            throw new \Error("expected katal config to be provided through STDIN");
        }

        return $input;
    }

    /**
     * Convert input data to the backend config
     * @param array $input
     *
     * @return array
     */
    private static function toBackendConfig(array $input): array
    {
        return [
            "DATABASE_URL" => $input["database"]["roles"]["main"]["uri"],
            "ADMIN_DATABASE_URL" => $input["database"]["roles"]["admin"]["uri"],
            "EXTERNAL_URL" => $input["external_uri"],
            "ETERNALTWIN_URL" => $input["eternaltwin"]["uri"],
            "OAUTH_ID" => $input["eternaltwin"]["oauth"]["id"],
            "OAUTH_SECRET" => $input["eternaltwin"]["oauth"]["secret"],
        ];
    }
}
