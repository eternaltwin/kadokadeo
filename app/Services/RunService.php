<?php

namespace App\Services;

use App\Models\Game;
use App\Models\GamePeriodStar;
use App\Models\Run;
use Carbon\Carbon;
use Illuminate\Support\Facades\Validator;

/**
 * le client génère une clé AES
 * il chiffre le message (= score, timestamp, replay) avec cette clé
 * il envoie au serveur :
 * le message chiffré avec AES
 * la clé AES chiffrée avec la public key du serveur
 * la signature du message avec la clé AES
 *
 * le back :
 * déchiffre la clé AES grace à sa clé privée
 * déchiffre le message chiffré AES
 * vérifie la signature
 */

class RunService
{
    private string $publicKey;
    private string $privateKey;

    public function __construct($config)
    {
        $this->publicKey = file_get_contents(data_get($config, 'public_key_path'));
        $this->privateKey = file_get_contents(data_get($config, 'private_key_path'));
    }

    public function getPublicKey()
    {
        return $this->publicKey;
    }

    public function decodeRun(string $payload, string $key, string $sign): array
    {
        $aesKey = $this->getAesKeyFromEncrypted($key);
        $decryptedPayload = $this->getDecryptedPayload($payload, $aesKey);

        // Check signature
        $expectedSign = base64_encode(hash_hmac('sha256', $decryptedPayload, $aesKey, true));

        if (!hash_equals($expectedSign, $sign)) {
            throw new \Exception("Signature invalide.");
        }

        $json = json_decode($decryptedPayload, true);

        // Validate json from Laravel Validator
        $validator = Validator::make($json, [
            'run_id' => 'required|exists:runs,id',
            'score' => 'required|integer|min:0',
            'timestamp' => 'required|integer',
            'replay' => 'nullable|string', // TODO: make a function to decode a replay.
        ]);

        if ($validator->fails()) {
            throw new \Illuminate\Validation\ValidationException($validator);
        }

        return $validator->validated();
    }

    public function confirmRun(Run $run, $decoded)
    {
        if ($run->id !== data_get($decoded, 'run_id')) {
            throw new \Error(sprintf('Run ID mismatch. Expected %s, got %s', $run->id, data_get($decoded, 'run_id')));
        }
        $score = data_get($decoded, 'score');
        $timestamp = data_get($decoded, 'timestamp');
        $replay = data_get($decoded, 'replay');

        $end = Carbon::createFromTimestamp($timestamp);
        $realEnd = now();

        // if ($end->clone()->diffInSeconds($realEnd, true) > 30) {
        //     throw new \Error('Invalid timestamp');
        // }
        $run->play_time_seconds = (int) $realEnd->diffInSeconds($run->created_at, true);
        $run->completed_at = $realEnd;
        $run->score = $score;
        $run->replay = $replay;
        $run->save();
        if ($run->contract_score > 0 && $run->score >= $run->contract_score) {
            $user = $run->user;
            $user->kado_points += $run->contract_points;
            $user->save();
            $user->userPoints()->create([
                'delta' => $run->contract_points,
                'reason' => 'contract completed',
                'source_type' => Run::class,
                'source_id' => $run->id,
            ]);
        }

        return $run;
    }

    public function rewardStars(Run $run)
    {
        if (!$run->period_id) {
            return;
        }
        $game = $run->game;
        $user = $run->user;
        $gainedStar = $game->getStarFromScore($run->score);
        // no star gained
        if ($gainedStar === -1) {
            return;
        }
        $gamePeriodStars = $user->gamePeriodStars()
            ->where('game_id', $game->id)
            ->where('period_id', $run->period_id)
            ->get();
        $userPeriodStars = $user->stars()->where('period_id', $run->period_id)->first();
        if (!$userPeriodStars) {
            $userPeriodStars = $user->stars()->create([
                'period_id' => $run->period_id,
            ]);
        }

        // Reward each star up to the gained star
        for ($i = 0; $i <= $gainedStar; $i++) {
            if (!$gamePeriodStars->where('star', $i)->first()) {
                GamePeriodStar::create([
                    'game_id' => $game->id,
                    'period_id' => $run->period_id,
                    'user_id' => $user->id,
                    'star' => $i,
                ]);
                match ($i) {
                    0 => $userPeriodStars->green_stars += 1,
                    1 => $userPeriodStars->orange_stars += 1,
                    2 => $userPeriodStars->red_stars += 1,
                    3 => $userPeriodStars->purple_stars += 1,
                };
            }
        }
        $userPeriodStars->save();
    }

    private function getAesKeyFromEncrypted(string $key): string
    {
        // Decrypt AES key with server's private key
        $privateKey = openssl_pkey_get_private($this->privateKey);
        if (!$privateKey) {
            throw new \Exception("Impossible de charger la clé privée du serveur.");
        }

        $decryptedAesKey = null;
        $decodeResult = openssl_private_decrypt(base64_decode($key), $decryptedAesKey, $privateKey);

        if (!$decodeResult || !$decryptedAesKey) {
            throw new \Exception("Échec du déchiffrement de la clé AES.");
        }

        $saveDecrypted = base64_encode($decryptedAesKey);
        $decryptedAesKey = base64_decode($decryptedAesKey, true);
        if ($decryptedAesKey === false) {
            throw new \Exception("Clé AES invalide : base64 incorrect: $saveDecrypted");
        }

        // Check that the decrypted AES key is a binary chain of 16, 24 or 32 bytes (AES-128, 192, 256)
        $aesKeyLength = strlen($decryptedAesKey);
        if (!in_array($aesKeyLength, [16, 24, 32])) {
            throw new \Exception("Clé AES invalide : longueur incorrecte ($aesKeyLength octets).");
        }

        return $decryptedAesKey;
    }

    private function getDecryptedPayload(string $payload, string $aesKey): string
    {
        $aesKeyLength = strlen($aesKey);

        $algo = match ($aesKeyLength) {
            16 => 'aes-128-ctr',
            24 => 'aes-192-ctr',
            32 => 'aes-256-ctr',
        };

        // Decrypt payload
        $ivLength = openssl_cipher_iv_length($algo);
        $payloadRaw = base64_decode($payload, true);

        if ($payloadRaw === false) {
            throw new \Exception("Le payload n'est pas un base64 valide.");
        }
        if (strlen($payloadRaw) < $ivLength) {
            throw new \Exception("Payload trop court pour contenir un IV.");
        }

        $iv = substr($payloadRaw, 0, $ivLength);
        $cipherText = substr($payloadRaw, $ivLength);

        $decryptedPayload = openssl_decrypt($cipherText, $algo, $aesKey, OPENSSL_RAW_DATA, $iv);

        if ($decryptedPayload === false) {
            throw new \Exception("Échec du déchiffrement du payload.");
        }

        return $decryptedPayload;
    }
}
