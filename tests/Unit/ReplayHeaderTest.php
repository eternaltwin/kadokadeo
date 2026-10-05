<?php

namespace Tests\Unit;

use App\Support\ReplayHeader;
use PHPUnit\Framework\TestCase;

class ReplayHeaderTest extends TestCase
{
    // like ReplayManager.encodeReplayString: base64 of the zlib deflated binary replay
    public static function replay(int $flags): string
    {
        return base64_encode(gzcompress("KADO\x03".chr($flags)."\x00\x00", 9));
    }

    public function test_it_reads_the_version_and_the_flags(): void
    {
        $header = ReplayHeader::parse(self::replay(ReplayHeader::FLAG_RNG_STIR | 1));

        $this->assertSame(3, $header->version);
        $this->assertTrue($header->hasRngStir());
        $this->assertFalse(ReplayHeader::parse(self::replay(1))->hasRngStir());
    }

    public function test_it_reads_the_first_replays_which_were_not_deflated(): void
    {
        $this->assertSame(1, ReplayHeader::parse(base64_encode("KADO\x01\x01\x00"))->version);
    }

    public function test_it_ignores_what_is_not_a_replay(): void
    {
        $this->assertNull(ReplayHeader::parse(null));
        $this->assertNull(ReplayHeader::parse('not base64 !'));
        $this->assertNull(ReplayHeader::parse(base64_encode(gzcompress('NOPE'))));
        $this->assertNull(ReplayHeader::parse('936 bytes'));
    }
}
