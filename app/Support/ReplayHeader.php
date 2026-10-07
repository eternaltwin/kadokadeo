<?php

namespace App\Support;

/**
 * Header of a replay sent by the game (resources/hx/lib/kado/ReplayManager.hx): base64 of the deflated (zlib) binary
 * replay, which starts with "KADO", the version and the flags, and ends with "LEN" and the number of frames of the game.
 */
class ReplayHeader
{
    // the gameplay draws were stirred by the frames and the inputs (kado.Seed.stir)
    public const FLAG_RNG_STIR = 64;

    // version 4: the time of each input in its frame is recorded and stirs the draws too (the coming pieces can't be
    // predicted before the input)
    public const FLAG_INPUT_PHASES = 128;

    // frames: number of frames of the game ("LEN" trailer), null for the replays without it
    private function __construct(public readonly int $version, public readonly int $flags, public readonly ?int $frames = null) {}

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

        return new self(ord($binary[4]), ord($binary[5]), self::readFrames($binary));
    }

    // "LEN" then the number of frames as a varint (7 bits by byte, the high bit set on all bytes but the last), at the end
    private static function readFrames(string $binary): ?int
    {
        $length = strlen($binary);
        for ($size = 1; $size <= 5; $size++) {
            $start = $length - $size;
            if ($start - 3 < 6 || substr($binary, $start - 3, 3) !== 'LEN') {
                continue;
            }
            $frames = 0;
            $valid = true;
            for ($i = 0; $i < $size; $i++) {
                $byte = ord($binary[$start + $i]);
                $continues = ($byte & 0x80) !== 0;
                if ($continues !== $i < $size - 1) {
                    $valid = false;
                    break;
                }
                $frames |= ($byte & 0x7F) << (7 * $i);
            }
            if ($valid) {
                return $frames;
            }
        }

        return null;
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

    public function hasInputPhases(): bool
    {
        return $this->version >= 4 && ($this->flags & self::FLAG_INPUT_PHASES) !== 0;
    }
}
