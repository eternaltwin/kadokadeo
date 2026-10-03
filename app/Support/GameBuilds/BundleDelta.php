<?php

namespace App\Support\GameBuilds;

use RuntimeException;

/**
 * An old version of a game bundle rebuilt from the current bundle and its delta ("KDD1", written at build time by
 * resources/js/games/builds/delta.mjs: keep both in sync).
 *
 * Layout (raw deflate): "KDD1" | base hash (12) | target hash (12) | varint target length, then until the target is
 * complete: varint literal length, literal bytes, varint copy length, zigzag varint (copy start - end of the
 * previous copy).
 */
class BundleDelta
{
    public static function hash(string $bytes): string
    {
        return substr(sha1($bytes), 0, 12);
    }

    /** @return array{base: string, target: string} */
    public static function header(string $delta): array
    {
        $raw = @gzinflate($delta);
        if ($raw === false || substr($raw, 0, 4) !== 'KDD1') {
            throw new RuntimeException('game build: not a bundle delta');
        }

        return ['base' => substr($raw, 4, 12), 'target' => substr($raw, 16, 12)];
    }

    public static function apply(string $base, string $delta): string
    {
        $raw = @gzinflate($delta);
        if ($raw === false || substr($raw, 0, 4) !== 'KDD1') {
            throw new RuntimeException('game build: not a bundle delta');
        }
        $baseHash = substr($raw, 4, 12);
        $targetHash = substr($raw, 16, 12);
        if (self::hash($base) !== $baseHash) {
            throw new RuntimeException("game build: the delta needs the bundle {$baseHash}");
        }

        $p = 28;
        $varint = function () use ($raw, &$p): int {
            $value = 0;
            $shift = 0;
            do {
                $c = ord($raw[$p++]);
                $value |= ($c & 0x7F) << $shift;
                $shift += 7;
            } while ($c >= 0x80);

            return $value;
        };

        $length = $varint();
        $parts = [];
        $size = 0;
        $expect = 0;
        while ($size < $length) {
            $literal = $varint();
            if ($literal > 0) {
                $parts[] = substr($raw, $p, $literal);
                $p += $literal;
                $size += $literal;
            }
            if ($size >= $length) {
                break;
            }
            $copy = $varint();
            $z = $varint();
            $offset = $expect + (($z & 1) ? -(($z + 1) >> 1) : ($z >> 1));
            $parts[] = substr($base, $offset, $copy);
            $size += $copy;
            $expect = $offset + $copy;
        }

        $out = implode('', $parts);
        if (strlen($out) !== $length || self::hash($out) !== $targetHash) {
            throw new RuntimeException("game build: the rebuilt bundle is not {$targetHash}");
        }

        return $out;
    }
}
