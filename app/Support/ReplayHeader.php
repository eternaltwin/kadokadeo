<?php

namespace App\Support;

/**
 * Header of a replay sent by the game (resources/hx/lib/kado/ReplayManager.hx): base64 of the deflated (zlib) binary
 * replay, which starts with "KADO", the version and the flags.
 */
class ReplayHeader
{
    // the gameplay draws were stirred by the frames and the inputs (kado.Seed.stir)
    public const FLAG_RNG_STIR = 64;

    private function __construct(public readonly int $version, public readonly int $flags) {}

    public static function parse(?string $replay): ?self
    {
        if ($replay === null || $replay === '') {
            return null;
        }
        $decoded = base64_decode($replay, true);
        // the first replays were not deflated (ReplayManager.parseReplayString reads both)
        $binary = $decoded !== false && self::isZlib($decoded) ? (@zlib_decode($decoded) ?: false) : $decoded;
        if ($binary === false || strlen($binary) < 6 || !str_starts_with($binary, 'KADO')) {
            return null;
        }

        return new self(ord($binary[4]), ord($binary[5]));
    }

    // header of a zlib stream (what pako.deflate gives): CM 8, and CMF FLG a multiple of 31
    private static function isZlib(string $data): bool
    {
        return strlen($data) >= 2 && (ord($data[0]) & 0x0F) === 8 && ((ord($data[0]) << 8) | ord($data[1])) % 31 === 0;
    }

    public function hasRngStir(): bool
    {
        return ($this->flags & self::FLAG_RNG_STIR) !== 0;
    }
}
