<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Services\RunService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RunEndTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Same encryption as the game client (KadoEndRun): AES-128-CTR payload, AES key encrypted with the RSA public key.
     */
    private function encryptRun(array $request): array
    {
        $json = json_encode($request);
        $aesKey = random_bytes(16);
        $iv = random_bytes(16);
        $cipher = openssl_encrypt($json, 'aes-128-ctr', $aesKey, OPENSSL_RAW_DATA, $iv);
        openssl_public_encrypt(base64_encode($aesKey), $encryptedKey, app(RunService::class)->getPublicKey());

        return [
            'payload' => base64_encode($iv . $cipher),
            'key' => base64_encode($encryptedKey),
            'sign' => base64_encode(hash_hmac('sha256', $json, $aesKey, true)),
        ];
    }

    public function test_it_serves_the_current_public_key_without_cache(): void
    {
        $response = $this->getJson('/api/runs/public-key')->assertOk();

        $this->assertSame(app(RunService::class)->getPublicKey(), $response->json('data.public_key'));
        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
    }

    public function test_a_run_sent_twice_is_only_rewarded_once(): void
    {
        $user = User::factory()->create(['kado_points' => 0]);
        $game = Game::factory()->create();
        $run = Run::factory()->for($game)->for($user)->create([
            'score' => 0,
            'completed_at' => null,
            'contract_score' => 100,
            'contract_points' => 5,
        ]);
        Sanctum::actingAs($user);

        $body = $this->encryptRun([
            'run_id' => $run->id,
            'score' => 150,
            'timestamp' => now()->timestamp,
            'replay' => null,
            'data' => [],
            'ac' => 0,
        ]);

        $this->postJson("/api/runs/{$run->id}/finish", $body)->assertOk();
        $this->postJson("/api/runs/{$run->id}/finish", $body)->assertStatus(409);

        $this->assertSame(150, $run->fresh()->score);
        $this->assertSame(5, $user->fresh()->kado_points);
    }
}
